phoenix.quest.Objectives <- {
	function register(typeName, validator, matcher) {
		if (!phoenix.quest.Schema.isKey(typeName)) return false
		phoenix.quest.Registry.objectives[typeName] <- { validate = validator, match = matcher }
		return true
	}

	function matchesReference(config, payload) {
		if ("refType" in config || "refValue" in config) {
			if (!("refType" in config) || !("refValue" in config) || config.refValue == null) return false
			local refType = config.refType.tostring()
			local expected = config.refValue.tostring()
			if (refType == phoenix.quest.NpcRefType.Spawn) return "spawnId" in payload && payload.spawnId.tointeger() == expected.tointeger()
			if (refType == phoenix.quest.NpcRefType.Preset) return "presetId" in payload && payload.presetId.tointeger() == expected.tointeger()
			if (refType == phoenix.quest.NpcRefType.Instance) return "instance" in payload && payload.instance.tostring().toupper() == expected.toupper()
			if (refType == phoenix.quest.NpcRefType.Tag) return "tag" in payload && payload.tag.tostring() == expected
			return false
		}
		if ("spawnId" in config) return "spawnId" in payload && payload.spawnId.tointeger() == config.spawnId.tointeger()
		if ("presetId" in config) return "presetId" in payload && payload.presetId.tointeger() == config.presetId.tointeger()
		if ("instance" in config) return "instance" in payload && payload.instance.tostring().toupper() == config.instance.tostring().toupper()
		if ("tag" in config) return "tag" in payload && payload.tag.tostring() == config.tag.tostring()
		return false
	}

	function delta(objective, event) {
		if (!("type" in objective) || !(objective.type in phoenix.quest.Registry.objectives)) return 0
		try { return phoenix.quest.Registry.objectives[objective.type].match(objective, event).tointeger() } catch (e) { return 0 }
	}
}

phoenix.quest.Objectives.register(phoenix.quest.ObjectiveType.Kill, null, function(objective, event) {
	if (event.type != "kill") return 0
	local config = ("config" in objective && objective.config != null) ? objective.config : objective
	return phoenix.quest.Objectives.matchesReference(config, event.payload) ? 1 : 0
})

phoenix.quest.Objectives.register(phoenix.quest.ObjectiveType.Talk, null, function(objective, event) {
	if (event.type != "talk") return 0
	local config = ("config" in objective && objective.config != null) ? objective.config : objective
	return phoenix.quest.Objectives.matchesReference(config, event.payload) ? 1 : 0
})

phoenix.quest.Objectives.register(phoenix.quest.ObjectiveType.Collect, null, function(objective, event) {
	if (event.type != "collect" || !("instance" in event.payload)) return 0
	local config = ("config" in objective && objective.config != null) ? objective.config : objective
	if (!("instance" in config) || config.instance.tostring().toupper() != event.payload.instance.tostring().toupper()) return 0
	return ("amount" in event.payload) ? event.payload.amount.tointeger() : 1
})

phoenix.quest.Objectives.register(phoenix.quest.ObjectiveType.Deliver, null, function(objective, event) {
	if (event.type != "deliver" || !("instance" in event.payload)) return 0
	local config = ("config" in objective && objective.config != null) ? objective.config : objective
	if (!("instance" in config) || config.instance.tostring().toupper() != event.payload.instance.tostring().toupper()) return 0
	return ("amount" in event.payload) ? event.payload.amount.tointeger() : 1
})

phoenix.quest.Objectives.register(phoenix.quest.ObjectiveType.Reach, null, function(objective, event) {
	if (event.type != "reach" || !("zoneKey" in event.payload)) return 0
	local config = ("config" in objective && objective.config != null) ? objective.config : objective
	return "zoneKey" in config && config.zoneKey.tostring() == event.payload.zoneKey.tostring() ? 1 : 0
})

phoenix.quest.Objectives.register(phoenix.quest.ObjectiveType.Interact, null, function(objective, event) {
	if (event.type != "interact") return 0
	local config = ("config" in objective && objective.config != null) ? objective.config : objective
	if ("targetKey" in config) return "targetKey" in event.payload && config.targetKey.tostring() == event.payload.targetKey.tostring() ? 1 : 0
	return phoenix.quest.Objectives.matchesReference(config, event.payload) ? 1 : 0
})

phoenix.quest.Objectives.register(phoenix.quest.ObjectiveType.CustomEvent, null, function(objective, event) {
	local config = ("config" in objective && objective.config != null) ? objective.config : objective
	return "eventName" in config && event.type == config.eventName.tostring() ? (("amount" in event.payload) ? event.payload.amount.tointeger() : 1) : 0
})