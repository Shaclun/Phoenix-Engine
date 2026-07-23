phoenix.quest.Model <- {
	characterId = 0,
	stateVersion = 0,
	entries = [],
	tracked = null,
	markers = [],
	dialog = null,

	function clear() {
		try { phoenix.quest.MarkerClient.clear() } catch (error) {}
		phoenix.quest.Model.characterId = 0
		phoenix.quest.Model.stateVersion = 0
		phoenix.quest.Model.entries = []
		phoenix.quest.Model.tracked = null
		phoenix.quest.Model.markers = []
		phoenix.quest.Model.dialog = null
	}

	function emitState() {
		phoenix.web.Manager.emit("phoenix:quest:snapshot", {
			characterId = phoenix.quest.Model.characterId,
			stateVersion = phoenix.quest.Model.stateVersion,
			entries = phoenix.quest.Model.entries,
			tracked = phoenix.quest.Model.tracked
		})
	}

	function onSnapshot(message) {
		if (phoenix.quest.Model.characterId != 0 && phoenix.quest.Model.characterId != message.characterId) phoenix.quest.Model.clear()
		phoenix.quest.Model.characterId = message.characterId
		phoenix.quest.Model.stateVersion = message.stateVersion
		local payload = message.payload != null ? message.payload : {}
		phoenix.quest.Model.entries = ("entries" in payload && payload.entries != null) ? payload.entries : []
		phoenix.quest.Model.tracked = null
		foreach (entry in phoenix.quest.Model.entries) {
			if ("tracked" in entry && entry.tracked == true) {
				phoenix.quest.Model.tracked = entry
				break
			}
		}
		phoenix.quest.Model.emitState()
	}

	function onDelta(message) {
		if (message.characterId != phoenix.quest.Model.characterId || message.stateVersion != phoenix.quest.Model.stateVersion + 1) {
			phoenix.quest.Model.request("snapshot", null)
			return
		}
		phoenix.quest.Model.stateVersion = message.stateVersion
		phoenix.web.Manager.emit("phoenix:quest:delta", message.payload)
	}

	function onResponse(message) {
		phoenix.web.Manager.emit("phoenix:quest:response", {
			action = message.action,
			requestId = message.requestId,
			success = message.success,
			error = message.error,
			stateVersion = message.stateVersion,
			payload = message.payload
		})
	}

	function request(action, payload = null) {
		local message = phoenix.quest.Message.Request()
		message.protocolVersion = phoenix.quest.ProtocolVersion
		message.action = action
		message.requestId = getTickCount().tostring()
		message.stateVersion = phoenix.quest.Model.stateVersion
		message.payload = payload
		message.serialize().send(RELIABLE_ORDERED)
	}
}

phoenix.quest.Message.Snapshot.bind(phoenix.quest.Model.onSnapshot)
phoenix.quest.Message.Delta.bind(phoenix.quest.Model.onDelta)
phoenix.quest.Message.Response.bind(phoenix.quest.Model.onResponse)