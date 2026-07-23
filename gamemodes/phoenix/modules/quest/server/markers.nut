phoenix.quest.Markers <- {
	byCharacter = {},
	refreshTimer = null,
	refreshIntervalMs = 2000,

	function bindingMatches(binding, spawnId, row) {
		if (!("refType" in binding) || !("refValue" in binding)) return false
		local refType = binding.refType.tostring()
		local refValue = binding.refValue.tostring()
		if (refType == phoenix.quest.NpcRefType.Spawn) return spawnId == refValue.tointeger()
		if (refType == phoenix.quest.NpcRefType.Preset) return row.presetId == refValue.tointeger()
		if (refType == phoenix.quest.NpcRefType.Instance) return row.instance.tostring().toupper() == refValue.toupper()
		if (refType == phoenix.quest.NpcRefType.Tag) return row.tag.tostring() == refValue
		return false
	}

	function appendBinding(result, binding, markerType, priority) {
		foreach (spawnId, live in phoenix.npc.Spawn.live) {
			if (!live.alive || !phoenix.quest.Markers.bindingMatches(binding, spawnId, live.row)) continue
			if (spawnId in result && result[spawnId].priority >= priority) continue
			local virtualWorld = 0
			try { virtualWorld = getPlayerVirtualWorld(live.npcId) } catch (error) {}
			result[spawnId] <- {
				spawnId = spawnId,
				npcId = live.npcId,
				world = ("world" in live.row && live.row.world != null) ? live.row.world.tostring() : "",
				virtualWorld = virtualWorld,
				markerType = markerType,
				offset = ("markerOffset" in binding) ? binding.markerOffset : 165.0,
				priority = priority
			}
		}
	}

	function bindings(content) {
		local out = {}
		if (content != null && "npcBindings" in content && phoenix.quest.Schema.isArray(content.npcBindings)) {
			foreach (binding in content.npcBindings) if ("key" in binding) out[binding.key.tostring()] <- binding
		}
		return out
	}

	function stateByDefinition(characterId) {
		local out = {}
		if (characterId in phoenix.quest.State.byCharacter) foreach (stateId, state in phoenix.quest.State.byCharacter[characterId]) out[state.definitionId] <- state
		return out
	}

	function project(playerId, characterId) {
		local result = {}
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || record.id != characterId) return []
		local stateMap = phoenix.quest.Markers.stateByDefinition(characterId)
		foreach (definitionId, definition in phoenix.quest.Repository.definitions) {
			local content = definition.content
			local bindingMap = phoenix.quest.Markers.bindings(content)
			if (!(definitionId in stateMap)) {
				local available = phoenix.quest.Conditions.evaluate(("availability" in content) ? content.availability : null, { playerId = playerId, record = record })
				if (!available) continue
				foreach (key, binding in bindingMap) {
					if ("role" in binding && binding.role == phoenix.quest.NpcRole.Giver) phoenix.quest.Markers.appendBinding(result, binding, "available", 1)
				}
				continue
			}
			local state = stateMap[definitionId]
			if (state.status != phoenix.quest.Status.Active && state.status != phoenix.quest.Status.ReadyToTurnIn) continue
			local stage = phoenix.quest.State.stageOf(state)
			if (stage == null) continue
			if (state.status == phoenix.quest.Status.ReadyToTurnIn && "turnInBindingKey" in stage && stage.turnInBindingKey in bindingMap) phoenix.quest.Markers.appendBinding(result, bindingMap[stage.turnInBindingKey], "turn_in", 3)
			if (state.status == phoenix.quest.Status.Active && "markerBindings" in stage && phoenix.quest.Schema.isArray(stage.markerBindings)) foreach (marker in stage.markerBindings) {
				if (!("bindingKey" in marker) || !(marker.bindingKey in bindingMap)) continue
				local markerType = ("markerType" in marker) ? marker.markerType.tostring() : "continue"
				phoenix.quest.Markers.appendBinding(result, bindingMap[marker.bindingKey], markerType, 2)
			}
		}
		local out = []
		foreach (spawnId, entry in result) {
			entry.rawdelete("priority")
			out.append(entry)
		}
		phoenix.quest.Markers.byCharacter[characterId] <- out
		return out
	}

	function refreshAll() {
		foreach (characterId, playerId in phoenix.quest.State.playerByCharacter) {
			try {
				if (!isPlayerConnected(playerId)) continue
				local record = phoenix.character.Structure.getActive(playerId)
				if (record == null || record.id != characterId) continue
				local version = characterId in phoenix.quest.State.syncVersion ? phoenix.quest.State.syncVersion[characterId] : 1
				phoenix.quest.Markers.send(playerId, characterId, version)
			} catch (error) {}
		}
	}

	function start() {
		if (phoenix.quest.Markers.refreshTimer != null) return
		phoenix.quest.Markers.refreshTimer = setTimer(phoenix.quest.Markers.refreshAll, phoenix.quest.Markers.refreshIntervalMs, 0)
	}

	function send(playerId, characterId, stateVersion) {
		local message = phoenix.quest.Message.Markers()
		message.characterId = characterId
		message.stateVersion = stateVersion
		message.entries = phoenix.quest.Markers.project(playerId, characterId)
		message.serialize().send(playerId, RELIABLE_ORDERED)
	}
}


addEventHandler("onInit", function() { phoenix.quest.Markers.start() })