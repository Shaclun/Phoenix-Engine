phoenix.quest.Handlers <- {
	lastRequestAt = {},
	recentRequests = {},
	requestRetentionMs = 60000,

	function reply(playerId, action, requestId, success, error, stateVersion, payload) {
		local message = phoenix.quest.Message.Response()
		message.action = action
		message.requestId = requestId
		message.success = success
		message.error = error
		message.stateVersion = stateVersion
		message.payload = payload
		message.serialize().send(playerId, RELIABLE_ORDERED)
	}

	function currentSyncVersion(characterId) {
		return characterId in phoenix.quest.State.syncVersion ? phoenix.quest.State.syncVersion[characterId] : 0
	}

	function actionInterval(action) {
		if (action == "snapshot") return 1000
		if (action == "track") return 300
		if (action == "dialogChoose") return 150
		if (action == "dialogClose") return 100
		return 500
	}

	function allowed(playerId, action) {
		local now = getTickCount()
		local key = playerId + ":" + action
		local interval = phoenix.quest.Handlers.actionInterval(action)
		if (key in phoenix.quest.Handlers.lastRequestAt && now - phoenix.quest.Handlers.lastRequestAt[key] < interval) return false
		phoenix.quest.Handlers.lastRequestAt[key] <- now
		return true
	}

	function payloadAllowed(payload) {
		if (payload == null) return true
		try { return phoenix.web.Json.encode(payload).len() <= phoenix.quest.Schema.Limits.Payload } catch (error) { return false }
	}

	function claimRequest(playerId, action, requestId) {
		local now = getTickCount()
		if (!(playerId in phoenix.quest.Handlers.recentRequests)) phoenix.quest.Handlers.recentRequests[playerId] <- {}
		local requests = phoenix.quest.Handlers.recentRequests[playerId]
		local expired = []
		foreach (key, createdAt in requests) if (now - createdAt > phoenix.quest.Handlers.requestRetentionMs) expired.append(key)
		foreach (key in expired) requests.rawdelete(key)
		local key = action + ":" + requestId
		if (key in requests) return false
		requests[key] <- now
		return true
	}

	function stateVersionMatches(characterId, stateVersion) {
		return stateVersion.tointeger() == phoenix.quest.Handlers.currentSyncVersion(characterId)
	}

	function sendSnapshot(playerId, characterId, resetVersion = false) {
		phoenix.quest.State.loadFor(playerId, characterId, function(states) {
			phoenix.quest.State.sendSnapshot(playerId, characterId, resetVersion)
			phoenix.quest.Rewards.recoverCharacter(playerId, characterId)
		})
	}

	function onRequest(playerId, message) {
		local action = message.action != null ? message.action.tostring() : ""
		local requestId = phoenix.quest.Schema.string(message.requestId, phoenix.quest.Schema.Limits.RequestId)
		local actionKnown = action == "snapshot" || action == "track" || action == "dialogChoose" || action == "dialogClose"
		if (message.protocolVersion != phoenix.quest.ProtocolVersion || action.len() < 1 || action.len() > 48 || requestId == "" || !actionKnown || !phoenix.quest.Handlers.payloadAllowed(message.payload)) {
			phoenix.quest.Handlers.reply(playerId, action, requestId, false, phoenix.quest.Error.InvalidRequest, 0, null)
			return
		}
		if (!phoenix.quest.Handlers.allowed(playerId, action) || !phoenix.quest.Handlers.claimRequest(playerId, action, requestId)) {
			phoenix.quest.Handlers.reply(playerId, action, requestId, false, phoenix.quest.Error.InvalidRequest, 0, null)
			return
		}
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) {
			phoenix.quest.Handlers.reply(playerId, action, requestId, false, phoenix.quest.Error.NotAvailable, 0, null)
			return
		}
		if (action == "snapshot") {
			phoenix.quest.Handlers.sendSnapshot(playerId, record.id, true)
			return
		}
		if (action != "dialogClose" && !phoenix.quest.Handlers.stateVersionMatches(record.id, message.stateVersion)) {
			phoenix.quest.Handlers.reply(playerId, action, requestId, false, phoenix.quest.Error.StaleVersion, phoenix.quest.Handlers.currentSyncVersion(record.id), null)
			phoenix.quest.State.sendSnapshot(playerId, record.id, false)
			return
		}
		if (action == "track") {
			local stateId = message.payload != null && typeof message.payload == "table" && "stateId" in message.payload ? phoenix.quest.Schema.integer(message.payload.stateId, 0, 1) : 0
			if (stateId <= 0 || !(record.id in phoenix.quest.State.byCharacter) || !(stateId in phoenix.quest.State.byCharacter[record.id])) {
				phoenix.quest.Handlers.reply(playerId, action, requestId, false, phoenix.quest.Error.NotAvailable, phoenix.quest.Handlers.currentSyncVersion(record.id), null)
				return
			}
			phoenix.quest.State.track(playerId, stateId, function(success, error, payload) {
				phoenix.quest.Handlers.reply(playerId, "track", requestId, success, error, phoenix.quest.Handlers.currentSyncVersion(record.id), payload)
			})
			return
		}
		if (action == "dialogChoose") {
			if (message.payload == null || typeof message.payload != "table") {
				phoenix.quest.Handlers.reply(playerId, action, requestId, false, phoenix.quest.Error.InvalidRequest, phoenix.quest.Handlers.currentSyncVersion(record.id), null)
				return
			}
			phoenix.quest.Dialog.choose(playerId, message.payload, function(success, error, payload) {
				phoenix.quest.Handlers.reply(playerId, "dialogChoose", requestId, success, error, phoenix.quest.Handlers.currentSyncVersion(record.id), payload)
			})
			return
		}
		phoenix.quest.Dialog.close(playerId, true)
		phoenix.quest.Handlers.reply(playerId, "dialogClose", requestId, true, "", phoenix.quest.Handlers.currentSyncVersion(record.id), null)
	}
}

phoenix.quest.Message.Request.bind(phoenix.quest.Handlers.onRequest)

addEventHandler("phoenix.player.OnSpawned", function(playerId, characterId, record) {
	phoenix.quest.Handlers.sendSnapshot(playerId, characterId, true)
})

addEventHandler("onPlayerDisconnect", function(playerId, reason) {
	local characterId = 0
	try {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record != null) characterId = record.id
	} catch (e) {}
	if (characterId > 0) {
		if (characterId in phoenix.quest.Engine.activeByCharacter) phoenix.quest.Engine.activeByCharacter.rawdelete(characterId)
		if (characterId in phoenix.quest.Engine.objectiveIndex) phoenix.quest.Engine.objectiveIndex.rawdelete(characterId)
		if (characterId in phoenix.quest.Markers.byCharacter) phoenix.quest.Markers.byCharacter.rawdelete(characterId)
		if (characterId in phoenix.quest.State.byCharacter) phoenix.quest.State.byCharacter.rawdelete(characterId)
		if (characterId in phoenix.quest.State.playerByCharacter) phoenix.quest.State.playerByCharacter.rawdelete(characterId)
		if (characterId in phoenix.quest.State.syncVersion) phoenix.quest.State.syncVersion.rawdelete(characterId)
	}
	if (playerId in phoenix.quest.Dialog.sessions) phoenix.quest.Dialog.sessions.rawdelete(playerId)
	local requestKeys = []
	local prefix = playerId + ":"
	foreach (key, value in phoenix.quest.Handlers.lastRequestAt) if (key.find(prefix) == 0) requestKeys.append(key)
	foreach (key in requestKeys) phoenix.quest.Handlers.lastRequestAt.rawdelete(key)
	if (playerId in phoenix.quest.Handlers.recentRequests) phoenix.quest.Handlers.recentRequests.rawdelete(playerId)
})