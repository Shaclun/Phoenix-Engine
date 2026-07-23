phoenix.quest.Events <- {
	function register(typeName, validator) {
		if (!phoenix.quest.Schema.isKey(typeName) || validator == null) return false
		phoenix.quest.Registry.events[typeName] <- validator
		return true
	}

	function validate(typeName, payload) {
		if (!phoenix.quest.Schema.isKey(typeName) || !(typeName in phoenix.quest.Registry.events) || !phoenix.quest.Schema.isTable(payload)) return false
		try {
			local encoded = phoenix.web.Json.encode(payload)
			if (encoded.len() > phoenix.quest.Schema.Limits.Payload) return false
			return phoenix.quest.Registry.events[typeName](payload) == true
		} catch (error) { return false }
	}

	function emit(playerId, typeName, payload, eventId = "") {
		if (!phoenix.quest.Events.validate(typeName, payload)) return false
		callEvent("phoenix.quest.OnDomainEvent", playerId, typeName, payload, phoenix.quest.Schema.string(eventId, phoenix.quest.Schema.Limits.RequestId))
		return true
	}

	function playerForCharacter(characterId) {
		local maxSlots = getMaxSlots()
		for (local playerId = 0; playerId < maxSlots; playerId += 1) {
			try {
				if (!isPlayerConnected(playerId)) continue
				local record = phoenix.character.Structure.getActive(playerId)
				if (record != null && record.id == characterId) return playerId
			} catch (error) {}
		}
		return -1
	}

	function itemGranted(ownerType, ownerId, instance, amount, source, itemId) {
		if (ownerType != PhoenixInventoryOwner.Player || amount <= 0 || source == "quest") return
		local playerId = phoenix.quest.Events.playerForCharacter(ownerId)
		if (playerId < 0) return
		phoenix.quest.Events.emit(playerId, "collect", { instance = instance, amount = amount, source = source, itemId = itemId }, "item:add:" + itemId + ":" + amount + ":" + getTickCount())
	}

	function vobInteracted(playerId, vobId, entry) {
		phoenix.quest.Events.emit(playerId, "interact", {
			targetKey = vobId,
			vobId = vobId,
			visual = ("visual" in entry) ? entry.visual : "",
			entryKind = ("entryKind" in entry) ? entry.entryKind : ""
		}, "vob:" + vobId + ":" + getTickCount())
	}

	function hasReference(payload) {
		return "spawnId" in payload || "presetId" in payload || "instance" in payload || "tag" in payload || "targetKey" in payload
	}
}

phoenix.quest.Events.register("talk", function(payload) { return phoenix.quest.Events.hasReference(payload) })
phoenix.quest.Events.register("kill", function(payload) { return phoenix.quest.Events.hasReference(payload) })
phoenix.quest.Events.register("collect", function(payload) { return "instance" in payload && payload.instance != null && "amount" in payload && payload.amount.tointeger() > 0 })
phoenix.quest.Events.register("deliver", function(payload) { return "instance" in payload && payload.instance != null && "amount" in payload && payload.amount.tointeger() > 0 })
phoenix.quest.Events.register("reach", function(payload) { return "zoneKey" in payload && phoenix.quest.Schema.isKey(payload.zoneKey) })
phoenix.quest.Events.register("interact", function(payload) { return phoenix.quest.Events.hasReference(payload) })
phoenix.quest.Zones <- {
	inside = {},
	intervalMs = 500,
	timer = null,

	function config(objective) {
		if (objective == null) return null
		return "config" in objective && phoenix.quest.Schema.isTable(objective.config) ? objective.config : objective
	}

	function contains(playerId, config) {
		if (!("x" in config) || !("y" in config) || !("z" in config) || !("radius" in config)) return false
		local radius = config.radius.tofloat()
		if (radius <= 0.0) return false
		if ("world" in config && config.world != null && config.world.tostring() != "") {
			local world = ""
			try { world = getPlayerWorld(playerId).tostring() } catch (error) { return false }
			if (world != config.world.tostring()) return false
		}
		local position = null
		try { position = getPlayerPosition(playerId) } catch (error) { return false }
		if (position == null) return false
		local dx = position.x - config.x.tofloat()
		local dy = position.y - config.y.tofloat()
		local dz = position.z - config.z.tofloat()
		return dx * dx + dy * dy + dz * dz <= radius * radius
	}

	function tickPlayer(playerId, record) {
		if (!(record.id in phoenix.quest.Engine.objectiveIndex)) return
		local index = phoenix.quest.Engine.objectiveIndex[record.id]
		if (!(phoenix.quest.ObjectiveType.Reach in index)) return
		if (!(record.id in phoenix.quest.Zones.inside)) phoenix.quest.Zones.inside[record.id] <- {}
		local current = phoenix.quest.Zones.inside[record.id]
		foreach (candidate in index[phoenix.quest.ObjectiveType.Reach]) {
			local objective = candidate.objective
			local config = phoenix.quest.Zones.config(objective)
			if (config == null || !("zoneKey" in config) || !phoenix.quest.Schema.isKey(config.zoneKey)) continue
			local key = candidate.stateId + ":" + objective.key
			local wasInside = key in current && current[key]
			local isInside = phoenix.quest.Zones.contains(playerId, config)
			current[key] <- isInside
			if (isInside && !wasInside) phoenix.quest.Events.emit(playerId, "reach", { zoneKey = config.zoneKey.tostring() }, "reach:" + key + ":" + getTickCount())
		}
	}

	function tick() {
		for (local playerId = 0; playerId < getMaxSlots(); playerId += 1) {
			try {
				if (!isPlayerConnected(playerId)) continue
				local record = phoenix.character.Structure.getActive(playerId)
				if (record != null) phoenix.quest.Zones.tickPlayer(playerId, record)
			} catch (error) {}
		}
	}

	function start() {
		if (phoenix.quest.Zones.timer != null) return
		phoenix.quest.Zones.timer = setTimer(phoenix.quest.Zones.tick, phoenix.quest.Zones.intervalMs, 0)
	}
}

addEventHandler("onInit", function() { phoenix.quest.Zones.start() })
addEventHandler("onPlayerDisconnect", function(playerId, reason) {
	local record = phoenix.character.Structure.getActive(playerId)
	if (record != null && record.id in phoenix.quest.Zones.inside) phoenix.quest.Zones.inside.rawdelete(record.id)
})