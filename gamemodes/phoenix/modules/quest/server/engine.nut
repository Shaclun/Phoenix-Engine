phoenix.quest.Engine <- {
	activeByCharacter = {},
	objectiveIndex = {},

	function indexCharacter(characterId) {
		local index = {}
		if (characterId in phoenix.quest.State.byCharacter) {
			foreach (stateId, state in phoenix.quest.State.byCharacter[characterId]) {
				if (state.status != phoenix.quest.Status.Active) continue
				local stage = phoenix.quest.State.stageOf(state)
				foreach (objective in phoenix.quest.State.objectiveList(stage)) {
					if (!(objective.type in index)) index[objective.type] <- []
					index[objective.type].append({ stateId = stateId, objective = objective })
				}
			}
		}
		phoenix.quest.Engine.objectiveIndex[characterId] <- index
		phoenix.quest.Engine.activeByCharacter[characterId] <- true
	}

	function targetGroups(characterId, event) {
		local groups = {}
		if (!(characterId in phoenix.quest.Engine.objectiveIndex)) return groups
		local index = phoenix.quest.Engine.objectiveIndex[characterId]
		local candidates = []
		if (event.type in index) candidates.extend(index[event.type])
		if (phoenix.quest.ObjectiveType.CustomEvent in index) candidates.extend(index[phoenix.quest.ObjectiveType.CustomEvent])
		foreach (candidate in candidates) {
			local delta = phoenix.quest.Objectives.delta(candidate.objective, event)
			if (delta <= 0) continue
			if (!(candidate.stateId in groups)) groups[candidate.stateId] <- []
			groups[candidate.stateId].append({ objective = candidate.objective, delta = delta })
		}
		return groups
	}

	function claimEventSync(characterId, event) {
		if (event.id == null || event.id == "") return true
		local escapedId = phoenix.quest.Repository.escape(event.id)
		local rows = ORM.engine.execute("SELECT `resultCode` FROM `phoenix_quest_event_dedup` WHERE `characterId`=" + characterId + " AND `eventId`='" + escapedId + "' FOR UPDATE")
		if (rows != null && rows.len() > 0) return false
		ORM.engine.execute("INSERT INTO `phoenix_quest_event_dedup` (`characterId`,`eventId`,`eventType`,`resultCode`) VALUES (" + characterId + ",'" + escapedId + "','" + phoenix.quest.Repository.escape(event.type) + "','processing')")
		return true
	}

	function finishEventSync(characterId, event) {
		if (event.id == null || event.id == "") return
		ORM.engine.execute("UPDATE `phoenix_quest_event_dedup` SET `resultCode`='applied' WHERE `characterId`=" + characterId + " AND `eventId`='" + phoenix.quest.Repository.escape(event.id) + "'")
	}

	function stageCompleteSync(stateId, stage) {
		local objectives = phoenix.quest.State.objectiveList(stage)
		if (objectives.len() == 0) return true
		local rows = ORM.engine.execute("SELECT `objectiveKey`,`progress`,`required` FROM `phoenix_character_quest_objectives` WHERE `characterQuestId`=" + stateId)
		local completed = {}
		if (rows != null) foreach (row in rows) completed[row.objectiveKey.tostring()] <- row.progress.tointeger() >= row.required.tointeger()
		local mode = ("objectiveMode" in stage) ? stage.objectiveMode.tostring() : "all"
		if (mode == "any") {
			foreach (objective in objectives) if (objective.key in completed && completed[objective.key]) return true
			return false
		}
		foreach (objective in objectives) if (!(objective.key in completed) || !completed[objective.key]) return false
		return true
	}
	function nextTransition(stage, context) {
		local transitions = ("transitions" in stage && phoenix.quest.Schema.isArray(stage.transitions)) ? stage.transitions : []
		foreach (transition in transitions) {
			local condition = ("condition" in transition) ? transition.condition : null
			if (phoenix.quest.Conditions.evaluate(condition, context)) return transition
		}
		return null
	}

	function historySync(stateId, fromStageKey, toStageKey, eventType, correlationId) {
		local sequenceRows = ORM.engine.execute("SELECT COALESCE(MAX(`sequenceNo`),0)+1 AS sequenceNo FROM `phoenix_character_quest_history` WHERE `characterQuestId`=" + stateId)
		local fromSql = fromStageKey == null ? "NULL" : "'" + phoenix.quest.Repository.escape(fromStageKey) + "'"
		local toSql = toStageKey == null ? "NULL" : "'" + phoenix.quest.Repository.escape(toStageKey) + "'"
		ORM.engine.execute("INSERT INTO `phoenix_character_quest_history` (`characterQuestId`,`sequenceNo`,`fromStageKey`,`toStageKey`,`eventType`,`correlationId`) VALUES (" + stateId + "," + sequenceRows[0].sequenceNo.tointeger() + "," + fromSql + "," + toSql + ",'" + phoenix.quest.Repository.escape(eventType) + "','" + phoenix.quest.Repository.escape(correlationId) + "')")
	}

	function applyToStateSync(playerId, record, stateId, targets, event) {
		if (!(record.id in phoenix.quest.State.byCharacter) || !(stateId in phoenix.quest.State.byCharacter[record.id])) throw "STATE_NOT_LOADED"
		local cached = phoenix.quest.State.byCharacter[record.id][stateId]
		local stage = phoenix.quest.State.stageOf(cached)
		if (stage == null) throw "STAGE_NOT_FOUND"
		local stateRows = ORM.engine.execute("SELECT `status`,`currentStageKey`,`stateVersion` FROM `phoenix_character_quests` WHERE `id`=" + stateId + " AND `characterId`=" + record.id + " FOR UPDATE")
		if (stateRows == null || stateRows.len() == 0 || stateRows[0].status.tostring() != phoenix.quest.Status.Active || stateRows[0].currentStageKey.tostring() != cached.currentStageKey) throw "STALE"
		foreach (target in targets) {
			local key = phoenix.quest.Repository.escape(target.objective.key)
			local delta = target.delta.tointeger()
			ORM.engine.execute("UPDATE `phoenix_character_quest_objectives` SET `progress`=LEAST(`required`,`progress`+" + delta + "),`completedAt`=IF(`progress`+" + delta + ">=`required`,COALESCE(`completedAt`,NOW()),`completedAt`) WHERE `characterQuestId`=" + stateId + " AND `objectiveKey`='" + key + "'")
		}
		local rewardPending = false
		local historyType = "objective_progress"
		local historyTarget = cached.currentStageKey
		if (phoenix.quest.Engine.stageCompleteSync(stateId, stage)) {
			local terminal = ("terminal" in stage) ? stage.terminal.tostring() : ""
			if (terminal == "success") {
				if ("turnInBindingKey" in stage && stage.turnInBindingKey != null && stage.turnInBindingKey.tostring() != "") {
					ORM.engine.execute("UPDATE `phoenix_character_quests` SET `status`='ready_to_turn_in',`stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId)
					historyType = "ready_to_turn_in"
				} else {
					phoenix.quest.Rewards.prepareSync(stateId, phoenix.quest.Rewards.rewardsFor(cached))
					ORM.engine.execute("UPDATE `phoenix_character_quests` SET `status`='reward_pending',`stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId)
					historyType = "reward_pending"
					rewardPending = true
				}
			} else if (terminal == "failure") {
				ORM.engine.execute("UPDATE `phoenix_character_quests` SET `status`='failed',`failedAt`=NOW(),`stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId)
				historyType = "failed"
			} else {
				local transition = phoenix.quest.Engine.nextTransition(stage, { playerId = playerId, record = record, state = cached, event = event })
				if (transition == null || !("target" in transition)) throw "NO_TRANSITION"
				local targetKey = transition.target.tostring()
				local targetStage = null
				foreach (candidate in cached.content.stages) if (candidate.key == targetKey) targetStage = candidate
				if (targetStage == null) throw "NO_TRANSITION"
				ORM.engine.execute("UPDATE `phoenix_character_quests` SET `currentStageKey`='" + phoenix.quest.Repository.escape(targetKey) + "',`stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId)
				phoenix.quest.State.insertStageObjectivesSync(stateId, targetStage)
				historyType = event.type
				historyTarget = targetKey
			}
		} else ORM.engine.execute("UPDATE `phoenix_character_quests` SET `stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId)
		phoenix.quest.Engine.historySync(stateId, cached.currentStageKey, historyTarget, historyType, event.id)
		return rewardPending
	}
	function process(playerId, typeName, payload, eventId = "") {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || !phoenix.quest.Events.validate(typeName, payload)) return false
		local event = { id = phoenix.quest.Schema.string(eventId, phoenix.quest.Schema.Limits.RequestId), type = typeName, payload = payload }
		local groups = phoenix.quest.Engine.targetGroups(record.id, event)
		if (groups.len() == 0) return false
		local rewardStates = []
		try {
			ORM.engine.execute("START TRANSACTION")
			if (!phoenix.quest.Engine.claimEventSync(record.id, event)) { ORM.engine.execute("ROLLBACK"); return false }
			local stateIds = []
			foreach (stateId, targets in groups) stateIds.append(stateId)
			stateIds.sort()
			foreach (stateId in stateIds) if (phoenix.quest.Engine.applyToStateSync(playerId, record, stateId, groups[stateId], event)) rewardStates.append(stateId)
			phoenix.quest.Engine.finishEventSync(record.id, event)
			ORM.engine.execute("COMMIT")
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			return false
		}
		if (rewardStates.len() == 0) phoenix.quest.State.reloadAndSync(record.id)
		else foreach (stateId in rewardStates) phoenix.quest.Rewards.complete(playerId, stateId)
		return true
	}
}

addEventHandler("phoenix.quest.OnDomainEvent", function(playerId, typeName, payload, eventId) {
	phoenix.quest.Engine.process(playerId, typeName, payload, eventId)
})