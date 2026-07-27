phoenix.quest.State <- {
	byCharacter = {},
	playerByCharacter = {},
	syncVersion = {},

	function nextSyncVersion(characterId, reset = false) {
		if (reset || !(characterId in phoenix.quest.State.syncVersion)) phoenix.quest.State.syncVersion[characterId] <- 1
		else phoenix.quest.State.syncVersion[characterId] += 1
		return phoenix.quest.State.syncVersion[characterId]
	}

	function stageOf(state) {
		if (state == null || state.content == null || !("stages" in state.content)) return null
		foreach (stage in state.content.stages) if ("key" in stage && stage.key == state.currentStageKey) return stage
		return null
	}

	function objectiveList(stage) {
		if (stage == null || !("objectives" in stage) || !phoenix.quest.Schema.isArray(stage.objectives)) return []
		return stage.objectives
	}

	function publicEntry(state) {
		local metadata = ("metadata" in state.content && state.content.metadata != null) ? state.content.metadata : {}
		local stage = phoenix.quest.State.stageOf(state)
		local objectives = []
		foreach (definition in phoenix.quest.State.objectiveList(stage)) {
			local visible = !("visible" in definition) || definition.visible == true
			if (!visible) continue
			local progress = 0
			local completed = false
			if (definition.key in state.objectives) {
				progress = state.objectives[definition.key].progress
				completed = state.objectives[definition.key].completed
			}
			objectives.append({
				key = definition.key,
				type = definition.type,
				label = ("label" in definition) ? definition.label : "",
				progress = progress,
				required = ("required" in definition) ? definition.required : 1,
				completed = completed
			})
		}
		local rewardChoices = []
		if (state.status == phoenix.quest.Status.ReadyToTurnIn) foreach (reward in phoenix.quest.Rewards.choiceOptions(state)) rewardChoices.append({ key = reward.key, label = "label" in reward ? reward.label : reward.key, type = reward.type, amount = "amount" in reward ? reward.amount : 1, instance = "instance" in reward ? reward.instance : "" })
		return {
			id = state.id,
			definitionId = state.definitionId,
			revisionId = state.revisionId,
			code = state.code,
			status = state.status,
			stateVersion = state.stateVersion,
			currentStageKey = state.currentStageKey,
			tracked = state.tracked,
			title = ("title" in metadata) ? metadata.title : state.code,
			description = ("description" in metadata) ? metadata.description : "",
			stageTitle = stage != null && "title" in stage ? stage.title : "",
			rewardChoices = rewardChoices,
			objectives = objectives
		}
	}


	function loadFor(playerId, characterId, callback = null) {
		local sql = "SELECT cq.*,qr.`definitionId`,qr.`contentJson`,qd.`code`,qo.`objectiveKey`,qo.`progress`,qo.`required`,qo.`completedAt` FROM `phoenix_character_quests` cq INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` INNER JOIN `phoenix_quest_definitions` qd ON qd.`id`=qr.`definitionId` LEFT JOIN `phoenix_character_quest_objectives` qo ON qo.`characterQuestId`=cq.`id` WHERE cq.`characterId`=" + characterId + " ORDER BY cq.`id`,qo.`id`"
		ORM.engine.executeAsync(sql, function(rows) {
			local map = {}
			if (rows != null) foreach (row in rows) {
				local id = row.id.tointeger()
				if (!(id in map)) {
					local content = phoenix.quest.Repository.parseContent(row.contentJson)
					if (content == null) continue
					map[id] <- {
						id = id,
						characterId = characterId,
						definitionId = row.definitionId.tointeger(),
						revisionId = row.revisionId.tointeger(),
						code = row.code.tostring(),
						status = row.status.tostring(),
						currentStageKey = row.currentStageKey.tostring(),
						stateVersion = row.stateVersion.tointeger(),
						rewardChoiceKey = row.rewardChoiceKey != null ? row.rewardChoiceKey.tostring() : "",
						tracked = row.tracked.tointeger() == 1,
						content = content,
						objectives = {}
					}
				}
				if (row.objectiveKey != null) {
					map[id].objectives[row.objectiveKey.tostring()] <- {
						progress = row.progress.tointeger(),
						required = row.required.tointeger(),
						completed = row.completedAt != null
					}
				}
			}
			phoenix.quest.State.byCharacter[characterId] <- map
			phoenix.quest.State.playerByCharacter[characterId] <- playerId
			phoenix.quest.Engine.indexCharacter(characterId)
			if (callback != null) callback(map)
		})
	}

	function snapshotEntries(characterId) {
		local out = []
		if (!(characterId in phoenix.quest.State.byCharacter)) return out
		foreach (id, state in phoenix.quest.State.byCharacter[characterId]) out.append(phoenix.quest.State.publicEntry(state))
		return out
	}

	function sendSnapshot(playerId, characterId, resetVersion = false) {
		local message = phoenix.quest.Message.Snapshot()
		message.characterId = characterId
		message.stateVersion = phoenix.quest.State.nextSyncVersion(characterId, resetVersion)
		message.payload = { entries = phoenix.quest.State.snapshotEntries(characterId) }
		message.serialize().send(playerId, RELIABLE_ORDERED)
		phoenix.quest.Markers.send(playerId, characterId, message.stateVersion)
	}

	function reloadAndSync(characterId, callback = null) {
		if (!(characterId in phoenix.quest.State.playerByCharacter)) { if (callback != null) callback(); return }
		local playerId = phoenix.quest.State.playerByCharacter[characterId]
		phoenix.quest.State.loadFor(playerId, characterId, function(states) {
			phoenix.quest.State.sendSnapshot(playerId, characterId, false)
			if (callback != null) callback()
		})
	}


	function insertStageObjectivesSync(characterQuestId, stage) {
		foreach (objective in phoenix.quest.State.objectiveList(stage)) {
			local required = ("required" in objective) ? objective.required.tointeger() : 1
			if (required < 1) required = 1
			ORM.engine.execute("INSERT INTO `phoenix_character_quest_objectives` (`characterQuestId`,`objectiveKey`,`progress`,`required`) VALUES (" + characterQuestId + ",'" + phoenix.quest.Repository.escape(objective.key) + "',0," + required + ") ON DUPLICATE KEY UPDATE `required`=VALUES(`required`)")
		}
	}

	function start(playerId, definitionId, callback) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || !(definitionId in phoenix.quest.Repository.definitions)) { callback(false, phoenix.quest.Error.NotAvailable, null); return }
		if (record.id in phoenix.quest.State.playerByCharacter)
			phoenix.quest.State.playerByCharacter[record.id] = playerId
		else
			phoenix.quest.State.playerByCharacter[record.id] <- playerId
		local definition = phoenix.quest.Repository.definitions[definitionId]
		local content = definition.content
		local availability = ("availability" in content) ? content.availability : null
		if (!phoenix.quest.Conditions.evaluate(availability, { playerId = playerId, record = record })) { callback(false, phoenix.quest.Error.NotAvailable, null); return }
		local startKey = content.startStageKey.tostring()
		local startStage = null
		foreach (stage in content.stages) if (stage.key == startKey) startStage = stage
		if (startStage == null) { callback(false, phoenix.quest.Error.InvalidTransition, null); return }
		try {
			ORM.engine.execute("START TRANSACTION")
			local existing = ORM.engine.execute("SELECT `id`,`status` FROM `phoenix_character_quests` WHERE `characterId`=" + record.id + " AND `revisionId`=" + definition.revisionId + " FOR UPDATE")
			if (existing != null && existing.len() > 0) throw "EXISTS"
			ORM.engine.execute("INSERT INTO `phoenix_character_quests` (`characterId`,`revisionId`,`status`,`currentStageKey`,`stateVersion`) VALUES (" + record.id + "," + definition.revisionId + ",'active','" + phoenix.quest.Repository.escape(startKey) + "',1)")
			local idRows = ORM.engine.execute("SELECT LAST_INSERT_ID() AS id")
			local stateId = idRows[0].id.tointeger()
			phoenix.quest.State.insertStageObjectivesSync(stateId, startStage)
			ORM.engine.execute("INSERT INTO `phoenix_character_quest_history` (`characterQuestId`,`sequenceNo`,`fromStageKey`,`toStageKey`,`eventType`) VALUES (" + stateId + ",1,NULL,'" + phoenix.quest.Repository.escape(startKey) + "','start')")
			ORM.engine.execute("COMMIT")
			phoenix.quest.State.reloadAndSync(record.id, function() { callback(true, "", { id = stateId }) })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			if (error.tostring() == "EXISTS") {
				phoenix.quest.State.reloadAndSync(record.id, function() { callback(false, phoenix.quest.Error.NotAvailable, null) })
				return
			}
			callback(false, phoenix.quest.Error.Internal, null)
		}
	}

	function track(playerId, stateId, callback) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) { callback(false, phoenix.quest.Error.NotAvailable, null); return }
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT `id`,`status` FROM `phoenix_character_quests` WHERE `id`=" + stateId + " AND `characterId`=" + record.id + " FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "NOT_AVAILABLE"
			local status = rows[0].status.tostring()
			if (status != phoenix.quest.Status.Active && status != phoenix.quest.Status.ReadyToTurnIn && status != phoenix.quest.Status.RewardPending) throw "NOT_AVAILABLE"
			ORM.engine.execute("UPDATE `phoenix_character_quests` SET `tracked`=0 WHERE `characterId`=" + record.id)
			ORM.engine.execute("UPDATE `phoenix_character_quests` SET `tracked`=1,`stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId + " AND `characterId`=" + record.id)
			ORM.engine.execute("COMMIT")
			phoenix.quest.State.reloadAndSync(record.id, function() { callback(true, "", null) })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			if (error.tostring() == "NOT_AVAILABLE") { callback(false, phoenix.quest.Error.NotAvailable, null); return }
			callback(false, phoenix.quest.Error.Internal, null)
		}
	}

	function turnIn(playerId, stateId, npcId, rewardChoiceKey, callback) {
		if (!phoenix.features.Settings.isEnabled("quests.rewards")) { callback(false, phoenix.quest.Error.NotAvailable, null); return }
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || !(record.id in phoenix.quest.State.byCharacter) || !(stateId in phoenix.quest.State.byCharacter[record.id])) { callback(false, phoenix.quest.Error.NotAvailable, null); return }
		local cached = phoenix.quest.State.byCharacter[record.id][stateId]
		local stage = phoenix.quest.State.stageOf(cached)
		local live = phoenix.quest.Dialog.liveByNpcId(npcId)
		local bindings = phoenix.quest.Markers.bindings(cached.content)
		local bindingKey = stage != null && "turnInBindingKey" in stage && stage.turnInBindingKey != null ? stage.turnInBindingKey.tostring() : ""
		if (cached.status != phoenix.quest.Status.ReadyToTurnIn || live == null || !phoenix.quest.Dialog.inRange(playerId, npcId) || bindingKey == "" || !(bindingKey in bindings) || !phoenix.quest.Markers.bindingMatches(bindings[bindingKey], live.spawnId, live.entry.row)) { callback(false, phoenix.quest.Error.InvalidTransition, null); return }
		if ("turnInCondition" in stage && !phoenix.quest.Conditions.evaluate(stage.turnInCondition, { playerId = playerId, record = record, state = cached })) { callback(false, phoenix.quest.Error.NotAvailable, null); return }
		local choiceKey = rewardChoiceKey != null ? rewardChoiceKey.tostring() : ""
		if (choiceKey != "" && !phoenix.quest.Schema.isKey(choiceKey)) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local selectedRewards = phoenix.quest.Rewards.rewardsFor(cached, choiceKey)
		if (selectedRewards == null) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT `status`,`currentStageKey`,`revisionId` FROM `phoenix_character_quests` WHERE `id`=" + stateId + " AND `characterId`=" + record.id + " FOR UPDATE")
			if (rows == null || rows.len() == 0 || rows[0].status.tostring() != phoenix.quest.Status.ReadyToTurnIn || rows[0].currentStageKey.tostring() != cached.currentStageKey || rows[0].revisionId.tointeger() != cached.revisionId) throw "STALE"
			phoenix.quest.Rewards.prepareSync(stateId, selectedRewards)
			local sequenceRows = ORM.engine.execute("SELECT COALESCE(MAX(`sequenceNo`),0)+1 AS sequenceNo FROM `phoenix_character_quest_history` WHERE `characterQuestId`=" + stateId)
			local sequenceNo = sequenceRows[0].sequenceNo.tointeger()
			local choiceSql = choiceKey == "" ? "NULL" : "'" + phoenix.quest.Repository.escape(choiceKey) + "'"
			ORM.engine.execute("UPDATE `phoenix_character_quests` SET `status`='reward_pending',`rewardChoiceKey`=" + choiceSql + ",`stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId + " AND `status`='ready_to_turn_in'")
			ORM.engine.execute("INSERT INTO `phoenix_character_quest_history` (`characterQuestId`,`sequenceNo`,`fromStageKey`,`toStageKey`,`eventType`,`correlationId`) VALUES (" + stateId + "," + sequenceNo + ",'" + phoenix.quest.Repository.escape(cached.currentStageKey) + "','" + phoenix.quest.Repository.escape(cached.currentStageKey) + "','turn_in','" + phoenix.quest.Repository.escape(choiceKey) + "')")
			ORM.engine.execute("COMMIT")
			local completed = phoenix.quest.Rewards.complete(playerId, stateId)
			callback(completed, completed ? "" : phoenix.quest.Error.RewardPending, { status = completed ? phoenix.quest.Status.Completed : phoenix.quest.Status.RewardPending })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			callback(false, error.tostring() == "STALE" ? phoenix.quest.Error.StaleVersion : phoenix.quest.Error.Internal, null)
		}
	}

	function listFor(characterId, callback) {
		local playerId = characterId in phoenix.quest.State.playerByCharacter ? phoenix.quest.State.playerByCharacter[characterId] : -1
		phoenix.quest.State.loadFor(playerId, characterId, function(states) { callback(phoenix.quest.State.snapshotEntries(characterId)) })
	}
}