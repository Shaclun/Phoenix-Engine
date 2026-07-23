phoenix.quest.Dialog <- {
	sessions = {},
	locks = {},
	timeoutMs = 60000,
	maxDistance = 450.0,
	sweepIntervalMs = 1000,
	sweepTimer = null,

	function liveByNpcId(npcId) {
		foreach (spawnId, entry in phoenix.npc.Spawn.live) if (entry.npcId == npcId && entry.alive) return { spawnId = spawnId, entry = entry }
		return null
	}

	function sameContext(playerId, npcId) {
		try {
			if (!isPlayerConnected(playerId) || getPlayerHealth(playerId) <= 0 || getPlayerHealth(npcId) <= 0) return false
			if (getPlayerWorld(playerId) != getPlayerWorld(npcId)) return false
			if (getPlayerVirtualWorld(playerId) != getPlayerVirtualWorld(npcId)) return false
			return true
		} catch (error) { return false }
	}

	function inRange(playerId, npcId) {
		if (!phoenix.quest.Dialog.sameContext(playerId, npcId)) return false
		try {
			local playerPos = getPlayerPosition(playerId)
			local npcPos = getPlayerPosition(npcId)
			if (playerPos == null || npcPos == null) return false
			local dx = playerPos.x - npcPos.x
			local dy = playerPos.y - npcPos.y
			local dz = playerPos.z - npcPos.z
			return sqrt(dx * dx + dy * dy + dz * dz) <= phoenix.quest.Dialog.maxDistance
		} catch (e) { return false }
	}

	function graphKeyFor(content, bindingKey, mode) {
		local graphs = ("dialogGraphs" in content && phoenix.quest.Schema.isArray(content.dialogGraphs)) ? content.dialogGraphs : []
		foreach (graph in graphs) {
			if (!("key" in graph) || !("bindingKey" in graph) || graph.bindingKey.tostring() != bindingKey.tostring()) continue
			if (!("mode" in graph) || graph.mode.tostring() == mode) return graph.key.tostring()
		}
		return ""
	}

	function optionsFor(playerId, characterId, live) {
		local options = []
		local stateByDefinition = phoenix.quest.Markers.stateByDefinition(characterId)
		local record = phoenix.character.Structure.getActive(playerId)
		foreach (definitionId, definition in phoenix.quest.Repository.definitions) {
			local content = definition.content
			local bindingMap = phoenix.quest.Markers.bindings(content)
			local metadata = ("metadata" in content && content.metadata != null) ? content.metadata : {}
			if (!(definitionId in stateByDefinition)) {
				if (!phoenix.quest.Conditions.evaluate(("availability" in content) ? content.availability : null, { playerId = playerId, record = record })) continue
				foreach (key, binding in bindingMap) {
					if (!("role" in binding) || binding.role != phoenix.quest.NpcRole.Giver) continue
					if (!phoenix.quest.Markers.bindingMatches(binding, live.spawnId, live.entry.row)) continue
					options.append({ key = "start:" + definitionId, kind = "start", definitionId = definitionId, dialogGraphKey = phoenix.quest.Dialog.graphKeyFor(content, key, "start"), title = ("title" in metadata) ? metadata.title : definition.code })
					break
				}
				continue
			}
			local state = stateByDefinition[definitionId]
			if (state.status != phoenix.quest.Status.Active && state.status != phoenix.quest.Status.ReadyToTurnIn) continue
			local stage = phoenix.quest.State.stageOf(state)
			if (stage == null) continue
			local bindingKeys = []
			if (state.status == phoenix.quest.Status.ReadyToTurnIn && "turnInBindingKey" in stage) bindingKeys.append(stage.turnInBindingKey)
			if (state.status == phoenix.quest.Status.Active && "markerBindings" in stage && phoenix.quest.Schema.isArray(stage.markerBindings)) foreach (marker in stage.markerBindings) if ("bindingKey" in marker) bindingKeys.append(marker.bindingKey)
			foreach (bindingKey in bindingKeys) {
				if (!(bindingKey in bindingMap) || !phoenix.quest.Markers.bindingMatches(bindingMap[bindingKey], live.spawnId, live.entry.row)) continue
				local mode = state.status == phoenix.quest.Status.ReadyToTurnIn ? "turn_in" : "continue"
				local graphKey = phoenix.quest.Dialog.graphKeyFor(content, bindingKey, mode)
				local title = ("title" in metadata) ? metadata.title : definition.code
				local rewardChoices = state.status == phoenix.quest.Status.ReadyToTurnIn ? phoenix.quest.Rewards.choiceOptions(state) : []
				if (rewardChoices.len() > 0) {
					foreach (reward in rewardChoices) {
						local rewardKey = reward.key.tostring()
						local rewardLabel = "label" in reward && reward.label != null ? reward.label.tostring() : rewardKey
						options.append({ key = "continue:" + state.id + ":reward:" + rewardKey, kind = "continue", stateId = state.id, definitionId = definitionId, rewardChoiceKey = rewardKey, dialogGraphKey = graphKey, title = title + " — " + rewardLabel })
					}
				} else options.append({ key = "continue:" + state.id, kind = "continue", stateId = state.id, definitionId = definitionId, rewardChoiceKey = "", dialogGraphKey = graphKey, title = title })
				break
			}
		}
		return options
	}


	function send(playerId, sessionId, action, payload) {
		local message = phoenix.quest.Message.Dialog()
		message.sessionId = sessionId
		message.action = action
		message.payload = payload
		message.serialize().send(playerId, RELIABLE_ORDERED)
	}

	function openForNpc(playerId, npcId) {
		local record = phoenix.character.Structure.getActive(playerId)
		local live = phoenix.quest.Dialog.liveByNpcId(npcId)
		if (record == null || live == null || !phoenix.quest.Dialog.inRange(playerId, npcId)) return false
		if (npcId in phoenix.quest.Dialog.locks && phoenix.quest.Dialog.locks[npcId] != playerId) return false
		local options = phoenix.quest.Dialog.optionsFor(playerId, record.id, live)
		if (options.len() == 0) return false
		try {
			if (phoenix.npc.Teacher._hasTeacher(live.entry.row)) options.append({ key = "service:teacher", kind = "teacher", title = "Nauka" })
			if (phoenix.npc.Teacher._hasMerchant(live.entry.row)) options.append({ key = "service:merchant", kind = "merchant", title = "Handel" })
		} catch (serviceError) {}
		phoenix.quest.Dialog.close(playerId, false)
		local sessionId = playerId + "-" + getTickCount()
		local idleAnimation = "S_STAND"
		try {
			phoenix.npc.Teacher._gesture(playerId, npcId)
			idleAnimation = phoenix.npc.Teacher._safeIdleAnimation(live.entry.row.idleAnimation)
		} catch (dialogSetupError) {}
		phoenix.quest.Dialog.sessions[playerId] <- { id = sessionId, mode = "root", npcId = npcId, spawnId = live.spawnId, characterId = record.id, expiresAt = getTickCount() + phoenix.quest.Dialog.timeoutMs, options = options, nodeKey = "" }
		phoenix.quest.Dialog.locks[npcId] <- playerId
		live.entry.ai.dialogPartner <- playerId
		live.entry.ai.dialogPartnerSince <- getTickCount()
		live.entry.ai.routineWaitUntil <- 0
		phoenix.quest.Dialog.send(playerId, sessionId, "open", { npcId = npcId, npcName = live.entry.row.name, idleAnimation = idleAnimation, options = options })
		return true
	}

	function sessionValid(playerId, session) {
		if (session == null || getTickCount() > session.expiresAt) return false
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || record.id != session.characterId) return false
		local live = phoenix.quest.Dialog.liveByNpcId(session.npcId)
		if (live == null || live.spawnId != session.spawnId) return false
		if (!(session.npcId in phoenix.quest.Dialog.locks) || phoenix.quest.Dialog.locks[session.npcId] != playerId) return false
		return phoenix.quest.Dialog.inRange(playerId, session.npcId)
	}

	function graphByKey(definitionId, graphKey) {
		if (!(definitionId in phoenix.quest.Repository.definitions)) return null
		local content = phoenix.quest.Repository.definitions[definitionId].content
		local graphs = ("dialogGraphs" in content && phoenix.quest.Schema.isArray(content.dialogGraphs)) ? content.dialogGraphs : []
		foreach (graph in graphs) if ("key" in graph && graph.key.tostring() == graphKey) return graph
		return null
	}

	function nodeByKey(graph, nodeKey) {
		local nodes = (graph != null && "nodes" in graph && phoenix.quest.Schema.isArray(graph.nodes)) ? graph.nodes : []
		foreach (node in nodes) if ("key" in node && node.key.tostring() == nodeKey) return node
		return null
	}

	function sendNode(playerId, session, nodeKey) {
		local graph = phoenix.quest.Dialog.graphByKey(session.definitionId, session.graphKey)
		local node = phoenix.quest.Dialog.nodeByKey(graph, nodeKey)
		if (node == null) return false
		session.nodeKey = nodeKey
		session.expiresAt = getTickCount() + phoenix.quest.Dialog.timeoutMs
		local record = phoenix.character.Structure.getActive(playerId)
		local choices = []
		local source = ("choices" in node && phoenix.quest.Schema.isArray(node.choices)) ? node.choices : []
		foreach (choice in source) {
			local condition = ("condition" in choice) ? choice.condition : null
			if (!phoenix.quest.Conditions.evaluate(condition, { playerId = playerId, record = record })) continue
			choices.append({ key = choice.key, text = ("text" in choice) ? choice.text : choice.key })
		}
		local live = phoenix.quest.Dialog.liveByNpcId(session.npcId)
		phoenix.quest.Dialog.send(playerId, session.id, "node", {
			npcId = session.npcId,
			npcName = live != null ? live.entry.row.name : "",
			nodeKey = nodeKey,
			speaker = ("speaker" in node) ? node.speaker : "npc",
			text = ("text" in node) ? node.text : "",
			choices = choices
		})
		return true
	}

	function consumeDeliveries(playerId, session, deliveries, index, callback) {
		if (index >= deliveries.len()) {
			local record = phoenix.character.Structure.getActive(playerId)
			if (record != null) try { phoenix.item.Structure.sendInventorySnapshot(playerId, record.id) } catch (error) {}
			callback(true, "", true)
			return
		}
		local delivery = deliveries[index]
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) { callback(false, phoenix.quest.Error.InvalidRequest, true); return }
		phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, record.id, delivery.instance, delivery.amount, function(success) {
			if (!success) { callback(false, "ITEM_REQUIRED", true); return }
			local applied = phoenix.quest.Engine.process(playerId, "deliver", { instance = delivery.instance, amount = delivery.amount }, session.id + ":auto-deliver:" + delivery.instance)
			if (!applied) { callback(false, phoenix.quest.Error.InvalidTransition, true); return }
			phoenix.quest.Dialog.consumeDeliveries(playerId, session, deliveries, index + 1, callback)
		})
	}

	function deliverActiveObjectives(playerId, session, state, callback) {
		local stage = phoenix.quest.State.stageOf(state)
		if (stage == null) { callback(true, "", false); return }
		local objectives = ("objectives" in stage && phoenix.quest.Schema.isArray(stage.objectives)) ? stage.objectives : []
		local deliverObjectives = []
		foreach (objective in objectives) if ("type" in objective && objective.type == phoenix.quest.ObjectiveType.Deliver) deliverObjectives.append(objective)
		if (deliverObjectives.len() == 0) { callback(true, "", false); return }
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) { callback(false, phoenix.quest.Error.InvalidRequest, true); return }
		local progress = {}
		try {
			local rows = ORM.engine.execute("SELECT `objectiveKey`,`progress` FROM `phoenix_character_quest_objectives` WHERE `characterQuestId`=" + state.id)
			if (rows != null) foreach (row in rows) progress[row.objectiveKey.tostring()] <- row.progress.tointeger()
		} catch (error) { callback(false, phoenix.quest.Error.Internal, true); return }
		local candidates = []
		foreach (objective in deliverObjectives) {
			local config = ("config" in objective && phoenix.quest.Schema.isTable(objective.config)) ? objective.config : objective
			if (!("instance" in config) || config.instance == null) { callback(false, phoenix.quest.Error.InvalidRequest, true); return }
			local instance = config.instance.tostring().toupper()
			local required = "required" in objective ? objective.required.tointeger() : 1
			local current = objective.key in progress ? progress[objective.key] : 0
			local remaining = required - current
			if (remaining > 0) candidates.append({ instance = instance, amount = remaining })
		}
		if (candidates.len() == 0) { callback(true, "", true); return }
		local mode = "objectiveMode" in stage ? stage.objectiveMode.tostring() : "all"
		if (mode == "any") {
			foreach (candidate in candidates) {
				if (phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, record.id, candidate.instance) < candidate.amount) continue
				phoenix.quest.Dialog.consumeDeliveries(playerId, session, [candidate], 0, callback)
				return
			}
			callback(false, "ITEM_REQUIRED", true)
			return
		}
		local totals = {}
		foreach (candidate in candidates) {
			if (!(candidate.instance in totals) || totals[candidate.instance] < candidate.amount) totals[candidate.instance] <- candidate.amount
		}
		local deliveries = []
		foreach (instance, amount in totals) {
			if (phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, record.id, instance) < amount) { callback(false, "ITEM_REQUIRED", true); return }
			deliveries.append({ instance = instance, amount = amount })
		}
		phoenix.quest.Dialog.consumeDeliveries(playerId, session, deliveries, 0, callback)
	}

	function performOption(playerId, session, option, callback) {
		if (option.kind == "teacher" || option.kind == "merchant") {
			local npcId = session.npcId
			phoenix.quest.Dialog.close(playerId)
			if (option.kind == "teacher") phoenix.npc.Teacher.openDialog(playerId, npcId)
			else phoenix.npc.Teacher.openMerchant(playerId, npcId)
			local live = phoenix.quest.Dialog.liveByNpcId(npcId)
			if (live != null) {
				live.entry.ai.dialogPartner <- playerId
				live.entry.ai.dialogPartnerSince <- getTickCount()
				live.entry.ai.routineWaitUntil <- 0
			}
			callback(true, "", null)
			return
		}
		if (option.kind == "start") {
			phoenix.quest.State.start(playerId, option.definitionId, function(success, error, result) {
				if (success) {
					local live = phoenix.quest.Dialog.liveByNpcId(session.npcId)
					if (live != null) phoenix.quest.Engine.process(playerId, "talk", { spawnId = live.spawnId, presetId = live.entry.row.presetId, instance = live.entry.row.instance, tag = live.entry.row.tag }, session.id + ":start")
				}
				phoenix.quest.Dialog.close(playerId)
				callback(success, error, result)
			})
			return
		}
		if (option.kind == "continue") {
			local state = null
			if (session.characterId in phoenix.quest.State.byCharacter && option.stateId in phoenix.quest.State.byCharacter[session.characterId]) state = phoenix.quest.State.byCharacter[session.characterId][option.stateId]
			if (state != null && state.status == phoenix.quest.Status.ReadyToTurnIn) {
				local rewardChoiceKey = "rewardChoiceKey" in option ? option.rewardChoiceKey : ""
				phoenix.quest.State.turnIn(playerId, option.stateId, session.npcId, rewardChoiceKey, function(success, error, result) { phoenix.quest.Dialog.close(playerId); callback(success, error, result) })
				return
			}
			phoenix.quest.Dialog.deliverActiveObjectives(playerId, session, state, function(success, error, handled) {
				if (!success) { callback(false, error, null); return }
				if (!handled) {
					local live = phoenix.quest.Dialog.liveByNpcId(session.npcId)
					if (live != null) phoenix.quest.Engine.process(playerId, "talk", { spawnId = live.spawnId, presetId = live.entry.row.presetId, instance = live.entry.row.instance, tag = live.entry.row.tag }, session.id + ":continue")
				}
				phoenix.quest.Dialog.close(playerId)
				callback(true, "", null)
			})
			return
		}
		callback(false, phoenix.quest.Error.InvalidRequest, null)
	}

	function applyChoiceActions(playerId, session, choice, index, callback) {
		if (!phoenix.quest.Dialog.sessionValid(playerId, session)) { callback(false, phoenix.quest.Error.NpcOutOfRange); return }
		local actions = ("actions" in choice && phoenix.quest.Schema.isArray(choice.actions)) ? choice.actions : []
		if (index >= actions.len()) { callback(true, ""); return }
		local action = actions[index]
		if (!phoenix.quest.Schema.isTable(action) || !("type" in action)) { phoenix.quest.Dialog.applyChoiceActions(playerId, session, choice, index + 1, callback); return }
		local record = phoenix.character.Structure.getActive(playerId)
		if (action.type == "deliver") {
			if (record == null || !("instance" in action)) { callback(false, phoenix.quest.Error.InvalidRequest); return }
			local instance = action.instance.tostring().toupper()
			local amount = ("amount" in action) ? action.amount.tointeger() : 1
			if (amount < 1 || phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, record.id, instance) < amount) { callback(false, "ITEM_REQUIRED"); return }
			phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, record.id, instance, amount, function(success) {
				if (!success) { callback(false, "ITEM_REQUIRED"); return }
				try { phoenix.item.Structure.sendInventorySnapshot(playerId, record.id) } catch (e) {}
				phoenix.quest.Engine.process(playerId, "deliver", { instance = instance, amount = amount }, session.id + ":deliver:" + session.nodeKey + ":" + choice.key)
				phoenix.quest.Dialog.applyChoiceActions(playerId, session, choice, index + 1, callback)
			})
			return
		}
		if (action.type == "event" && "eventName" in action) phoenix.quest.Engine.process(playerId, action.eventName.tostring(), ("payload" in action) ? action.payload : {}, session.id + ":" + session.nodeKey + ":" + choice.key)
		if (action.type == "setFlag" && record != null && "key" in action && phoenix.quest.Schema.isKey(action.key)) {
			local value = ("value" in action && action.value != null) ? action.value.tostring() : "1"
			ORM.engine.execute("INSERT INTO `phoenix_character_flags` (`characterId`,`flagKey`,`flagValue`) VALUES (" + record.id + ",'" + phoenix.quest.Repository.escape(action.key) + "','" + phoenix.quest.Repository.escape(value) + "') ON DUPLICATE KEY UPDATE `flagValue`=VALUES(`flagValue`)")
		}
		phoenix.quest.Dialog.applyChoiceActions(playerId, session, choice, index + 1, callback)
	}

	function choose(playerId, payload, callback) {
		if (!(playerId in phoenix.quest.Dialog.sessions) || !phoenix.quest.Schema.isTable(payload)) { callback(false, phoenix.quest.Error.NotAvailable, null); return }
		local session = phoenix.quest.Dialog.sessions[playerId]
		if (!("sessionId" in payload) || payload.sessionId != session.id || !phoenix.quest.Dialog.sessionValid(playerId, session)) {
			phoenix.quest.Dialog.close(playerId)
			callback(false, phoenix.quest.Error.NpcOutOfRange, null)
			return
		}
		local key = ("optionKey" in payload) ? payload.optionKey.tostring() : ""
		if (session.mode == "graph") {
			local graph = phoenix.quest.Dialog.graphByKey(session.definitionId, session.graphKey)
			local node = phoenix.quest.Dialog.nodeByKey(graph, session.nodeKey)
			if (node == null) { callback(false, phoenix.quest.Error.InvalidTransition, null); return }
			local choice = null
			local choices = ("choices" in node && phoenix.quest.Schema.isArray(node.choices)) ? node.choices : []
			foreach (candidate in choices) if ("key" in candidate && candidate.key.tostring() == key) choice = candidate
			local record = phoenix.character.Structure.getActive(playerId)
			if (choice == null || !phoenix.quest.Conditions.evaluate(("condition" in choice) ? choice.condition : null, { playerId = playerId, record = record })) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
			phoenix.quest.Dialog.applyChoiceActions(playerId, session, choice, 0, function(actionsSuccess, actionsError) {
				if (!actionsSuccess) { callback(false, actionsError, null); return }
				local target = ("target" in choice && choice.target != null) ? choice.target.tostring() : ""
				if (target != "") {
					if (!phoenix.quest.Dialog.sendNode(playerId, session, target)) { callback(false, phoenix.quest.Error.InvalidTransition, null); return }
					callback(true, "", null)
					return
				}
				phoenix.quest.Dialog.performOption(playerId, session, session.selectedOption, callback)
			})
			return
		}
		local option = null
		foreach (candidate in session.options) if (candidate.key == key) option = candidate
		if (option == null) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		if ("dialogGraphKey" in option && option.dialogGraphKey != null && option.dialogGraphKey.tostring() != "") {
			local graph = phoenix.quest.Dialog.graphByKey(option.definitionId, option.dialogGraphKey)
			if (graph == null || !("startNodeKey" in graph)) { callback(false, phoenix.quest.Error.InvalidTransition, null); return }
			session.mode = "graph"
			session.definitionId <- option.definitionId
			session.graphKey <- option.dialogGraphKey
			session.selectedOption <- option
			if (!phoenix.quest.Dialog.sendNode(playerId, session, graph.startNodeKey.tostring())) { callback(false, phoenix.quest.Error.InvalidTransition, null); return }
			callback(true, "", null)
			return
		}
		phoenix.quest.Dialog.performOption(playerId, session, option, callback)
	}

	function sweep() {
		local expired = []
		foreach (playerId, session in phoenix.quest.Dialog.sessions) if (!phoenix.quest.Dialog.sessionValid(playerId, session)) expired.append(playerId)
		foreach (playerId in expired) phoenix.quest.Dialog.close(playerId)
	}

	function startSweeper() {
		if (phoenix.quest.Dialog.sweepTimer != null) return
		phoenix.quest.Dialog.sweepTimer = setTimer(phoenix.quest.Dialog.sweep, phoenix.quest.Dialog.sweepIntervalMs, 0)
	}

	function close(playerId, notify = true) {
		if (!(playerId in phoenix.quest.Dialog.sessions)) return
		local session = phoenix.quest.Dialog.sessions[playerId]
		if (session.npcId in phoenix.quest.Dialog.locks && phoenix.quest.Dialog.locks[session.npcId] == playerId) phoenix.quest.Dialog.locks.rawdelete(session.npcId)
		local live = phoenix.quest.Dialog.liveByNpcId(session.npcId)
		if (live != null && "dialogPartner" in live.entry.ai && live.entry.ai.dialogPartner == playerId) live.entry.ai.dialogPartner <- -1
		phoenix.quest.Dialog.sessions.rawdelete(playerId)
		if (notify) phoenix.quest.Dialog.send(playerId, session.id, "close", null)
	}
}

addEventHandler("onPlayerDisconnect", function(playerId, reason) { phoenix.quest.Dialog.close(playerId, false) })

addEventHandler("onInit", function() { phoenix.quest.Dialog.startSweeper() })