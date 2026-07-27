phoenix.herb.Handlers <- {}

phoenix.herb.Handlers.lateSnapshotPid <- -1

phoenix.herb.Handlers.enabled <- function() {
	return phoenix.features.Settings.isEnabled("herbs.enabled")
}

phoenix.herb.Handlers.lateSnapshot <- function() {
	if (!phoenix.herb.Handlers.enabled()) return
	local pid = phoenix.herb.Handlers.lateSnapshotPid
	if (pid < 0) return
	try { phoenix.herb.Structure.sendSnapshot(pid) } catch (e) {}
}

phoenix.herb.Handlers.onCharacterSelected <- function(playerId, _characterId) {
	if (!phoenix.herb.Handlers.enabled()) return
	try { phoenix.herb.Structure.bootLoad() } catch (e) {}
	phoenix.herb.Structure.sendSnapshot(playerId)
	phoenix.herb.Handlers.lateSnapshotPid = playerId
	setTimer(phoenix.herb.Handlers.lateSnapshot, 1500, 1)
}

phoenix.herb.Handlers.onStartRequest <- function(playerId, message) {
	if (!phoenix.herb.Handlers.enabled()) return
	if (message == null || message.plantId == null || message.plantId == "") return
	phoenix.herb.Structure.start(playerId, message.plantId.tostring())
}

phoenix.herb.Handlers.onCancelRequest <- function(playerId, message) {
	local plantId = ""
	if (message != null && message.plantId != null) plantId = message.plantId.tostring()
	phoenix.herb.Structure.cancel(playerId, plantId, true)
}

phoenix.herb.Handlers.onDisconnect <- function(playerId, _reason) {
	phoenix.herb.Structure.cancel(playerId, "", false)
}

phoenix.herb.Message.StartRequest.bind(phoenix.herb.Handlers.onStartRequest)
phoenix.herb.Message.CancelRequest.bind(phoenix.herb.Handlers.onCancelRequest)

addEventHandler("phoenix.character.OnSelected", phoenix.herb.Handlers.onCharacterSelected)
addEventHandler("onPlayerDisconnect", phoenix.herb.Handlers.onDisconnect)