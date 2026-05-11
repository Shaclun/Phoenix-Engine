phoenix.vob.Handlers <- {}
phoenix.vob.Handlers.lateSnapshotPid <- -1

phoenix.vob.Handlers.lateSnapshot <- function() {
	local pid = phoenix.vob.Handlers.lateSnapshotPid
	if (pid < 0) return
	try { phoenix.vob.Structure.sendSnapshot(pid) } catch (e) {}
}

phoenix.vob.Handlers.onCharacterSelected <- function(playerId, _characterId) {
	try { phoenix.vob.Structure.bootLoad() } catch (e) {}
	phoenix.vob.Structure.sendSnapshot(playerId)
	phoenix.vob.Handlers.lateSnapshotPid = playerId
	setTimer(phoenix.vob.Handlers.lateSnapshot, 1500, 1)
}

phoenix.vob.Handlers.onPlayerJoin <- function(playerId) {
	try { phoenix.vob.Structure.bootLoad() } catch (e) {}
	phoenix.vob.Structure.sendSnapshot(playerId)
	phoenix.vob.Handlers.lateSnapshotPid = playerId
	setTimer(phoenix.vob.Handlers.lateSnapshot, 1500, 1)
	setTimer(phoenix.vob.Handlers.lateSnapshot, 3500, 1)
}

phoenix.vob.Handlers.onInteractRequest <- function(playerId, message) {
	if (message == null || message.vobId == null || message.vobId == "") return
	local id = message.vobId.tostring()
	if (!(id in phoenix.vob.Structure.entries)) return
	local entry = phoenix.vob.Structure.entries[id]
	local entryVisual = ""
	try { entryVisual = ("visual" in entry && entry.visual != null) ? entry.visual.tostring().toupper() : "" } catch (eV) {}
	local isStation = false
	try {
		if ("crafting" in phoenix && phoenix.crafting != null && "Structure" in phoenix.crafting) {
			if (entryVisual != "" && entryVisual in phoenix.crafting.Structure.stationByVisual && phoenix.crafting.Structure.stationByVisual[entryVisual].len() > 0) isStation = true
		}
	} catch (eC) {}
	local wantsCraft = false
	try { if ("craftInteraction" in entry && entry.craftInteraction == true) wantsCraft = true } catch (eCi) {}
	if (entry.interactive != true && !isStation && !wantsCraft && entry.entryKind != "item") return
	if (phoenix.vob.Structure.pickupDroppedItem(playerId, id)) return
	if (isStation || wantsCraft) {
		try { phoenix.crafting.Crafter.open(playerId, id); return } catch (eS) {}
	}
	try { phoenix.notification.notify(playerId, "info", "VOB", phoenix.vob.GroundLabel(entry), 2500) } catch (e) {}
}

phoenix.vob.GroundLabel <- function(entry) {
	if (entry == null) return "VOB"
	if (entry.name != null && entry.name != "") return entry.name
	return entry.visual
}

phoenix.vob.Message.InteractRequest.bind(phoenix.vob.Handlers.onInteractRequest)
local phoenixVobSelectedEvent = "phoenix.character." + "OnSelected"
try { addEventHandler("onInit", function() { phoenix.vob.Structure.bootLoad() }) } catch (e) {}
try { addEventHandler("onPlayerJoin", function(playerId) { phoenix.vob.Handlers.onPlayerJoin(playerId) }) } catch (e) {}
try { addEventHandler(phoenixVobSelectedEvent, phoenix.vob.Handlers.onCharacterSelected) } catch (e) {}
