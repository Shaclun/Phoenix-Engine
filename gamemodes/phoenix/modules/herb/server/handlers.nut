phoenix.herb.Handlers <- {}

phoenix.herb.Handlers.lateSnapshotPid <- -1

phoenix.herb.Handlers.lateSnapshot <- function() {
	local pid = phoenix.herb.Handlers.lateSnapshotPid
	if (pid < 0) return
	try { phoenix.herb.Structure.sendSnapshot(pid) } catch (e) {}
}

phoenix.herb.Handlers.onCharacterSelected <- function(playerId, _characterId) {
	try { phoenix.herb.Structure.bootLoad() } catch (e) {}
	phoenix.herb.Structure.sendSnapshot(playerId)
	phoenix.herb.Handlers.lateSnapshotPid = playerId
	setTimer(phoenix.herb.Handlers.lateSnapshot, 1500, 1)
}

phoenix.herb.Handlers.onStartRequest <- function(playerId, message) {
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

phoenix.herb.Handlers.tryAdminCommand <- function(playerId, text) {
	if (text == null || text.len() < 9 || text.slice(0, 9) != "/herbspot") return false
	if (!phoenix.account.Auth.requireAdmin(playerId)) return true
	local rest = text.len() > 10 ? text.slice(10) : ""
	local parts = rest != "" ? split(rest, " ") : []
	local instance = parts.len() > 0 ? parts[0].toupper() : "ITPL_HEALTH_HERB_01"
	if (phoenix.herb.catalogOf(instance) == null) {
		try { sendMessageToPlayer(playerId, 255, 80, 60, "[Herb] Nieznana roslina: " + instance) } catch (e) {}
		return true
	}
	local id = parts.len() > 1 ? parts[1] : ("herb_" + instance.tolower() + "_" + getTickCount())
	local pos = null
	try { pos = getPlayerPosition(playerId) } catch (e) {}
	if (pos == null) return true
	local world = "NEWWORLD"
	try { local w = getPlayerWorld(playerId); if (w != null && w != "") world = w } catch (e) {}
	world = phoenix.herb.Structure.normalizeWorld(world)
	local line = "\t{ id = \"" + id + "\", instance = \"" + instance + "\", world = \"" + world + "\", x = " + pos.x + ", y = " + pos.y + ", z = " + pos.z + " },\n"
	phoenix.herb.Structure.saveSpotFromAdmin(playerId, { plantId = id, instance = instance, world = world, posX = pos.x, posY = pos.y, posZ = pos.z }, function(_, __, ___) {})
	try {
		local f = file("positions.txt", "a+")
		local b = blob(line.len())
		foreach (idx, ch in line) b.writen(ch, 'b')
		b.seek(0)
		f.writeblob(b)
		f.close()
	} catch (e) {}
	try { sendMessageToPlayer(playerId, 180, 220, 140, "[Herb] Spot zapisany do positions.txt: " + id) } catch (e) {}
	return true
}

phoenix.herb.Message.StartRequest.bind(phoenix.herb.Handlers.onStartRequest)
phoenix.herb.Message.CancelRequest.bind(phoenix.herb.Handlers.onCancelRequest)

addEventHandler("phoenix.character.OnSelected", phoenix.herb.Handlers.onCharacterSelected)
addEventHandler("onPlayerDisconnect", phoenix.herb.Handlers.onDisconnect)