phoenix.vob.Handlers <- {}
phoenix.vob.Handlers.lateSnapshotPid <- -1

phoenix.vob.Handlers.enabled <- function() {
	return phoenix.features.Settings.isEnabled("worldVobs.enabled")
}

phoenix.vob.Handlers.lateSnapshot <- function() {
	if (!phoenix.vob.Handlers.enabled()) return
	local pid = phoenix.vob.Handlers.lateSnapshotPid
	if (pid < 0) return
	try { phoenix.vob.Structure.sendSnapshot(pid) } catch (e) {}
}

phoenix.vob.Handlers.onCharacterSelected <- function(playerId, _characterId) {
	if (!phoenix.vob.Handlers.enabled()) return
	try { phoenix.vob.Structure.bootLoad() } catch (e) {}
	phoenix.vob.Structure.sendSnapshot(playerId)
	phoenix.vob.Handlers.lateSnapshotPid = playerId
	setTimer(phoenix.vob.Handlers.lateSnapshot, 1500, 1)
}

phoenix.vob.Handlers.onPlayerJoin <- function(playerId) {
	if (!phoenix.vob.Handlers.enabled()) return
	try { phoenix.vob.Structure.bootLoad() } catch (e) {}
	phoenix.vob.Structure.sendSnapshot(playerId)
	phoenix.vob.Handlers.lateSnapshotPid = playerId
	setTimer(phoenix.vob.Handlers.lateSnapshot, 1500, 1)
	setTimer(phoenix.vob.Handlers.lateSnapshot, 3500, 1)
}

phoenix.vob.Handlers.isInRange <- function(playerId, entry, maxDistance = 450.0) {
	try {
		local playerWorld = phoenix.vob.Structure.normalizeWorld(getPlayerWorld(playerId))
		local entryWorld = ("world" in entry && entry.world != null) ? phoenix.vob.Structure.normalizeWorld(entry.world) : ""
		if (entryWorld != "" && playerWorld != entryWorld) return false
		local position = getPlayerPosition(playerId)
		if (position == null) return false
		local dx = position.x - entry.x.tofloat()
		local dy = position.y - entry.y.tofloat()
		local dz = position.z - entry.z.tofloat()
		return sqrt(dx * dx + dy * dy + dz * dz) <= maxDistance
	} catch (e) { return false }
}

phoenix.vob.Handlers.onInteractRequest <- function(playerId, message) {
	if (!phoenix.vob.Handlers.enabled()) return
	if (message == null || message.vobId == null || message.vobId == "") return
	local id = message.vobId.tostring()
	if (!(id in phoenix.vob.Structure.entries)) return
	local entry = phoenix.vob.Structure.entries[id]
	if (!phoenix.vob.Handlers.isInRange(playerId, entry)) {
		try { phoenix.notification.notify(playerId, "error", "Interakcja", "Podejdz blizej do obiektu.", 2500) } catch (eRange) {}
		return
	}
	local entryVisual = ""
	try { entryVisual = ("visual" in entry && entry.visual != null) ? entry.visual.tostring() : "" } catch (eV) {}
	local isStation = false
	try {
		if ("crafting" in phoenix && phoenix.crafting != null && "Structure" in phoenix.crafting)
			isStation = phoenix.crafting.Structure.isStationVisual(entryVisual)
	} catch (eC) {}
	local wantsCraft = false
	try { if ("craftInteraction" in entry && entry.craftInteraction == true) wantsCraft = true } catch (eCi) {}
	if (entry.interactive != true && !isStation && !wantsCraft && entry.entryKind != "item" && entry.entryKind != "carcass") return
	if (entry.entryKind == "carcass") {
		try {
			if (phoenix.profession.Hunting.interact(playerId, id)) {
				try { phoenix.quest.Events.vobInteracted(playerId, id, entry) } catch (eQuest) {}
				return
			}
		} catch (eHunting) {}
	}
	if (phoenix.vob.Structure.pickupDroppedItem(playerId, id)) {
		try { phoenix.quest.Events.vobInteracted(playerId, id, entry) } catch (eQuest) {}
		return
	}
	if (isStation || wantsCraft) {
		try {
			phoenix.crafting.Crafter.open(playerId, id)
			try { phoenix.quest.Events.vobInteracted(playerId, id, entry) } catch (eQuest) {}
			return
		} catch (eS) {}
	}
	try { phoenix.notification.notify(playerId, "info", "VOB", phoenix.vob.GroundLabel(entry), 2500) } catch (e) {}
	try { phoenix.quest.Events.vobInteracted(playerId, id, entry) } catch (eQuest) {}
}

phoenix.vob.GroundLabel <- function(entry) {
	if (entry == null) return "VOB"
	if (entry.name != null && entry.name != "") return entry.name
	return entry.visual
}

phoenix.vob.Message.InteractRequest.bind(phoenix.vob.Handlers.onInteractRequest)
local phoenixVobSelectedEvent = "phoenix.character." + "OnSelected"
try { addEventHandler("onInit", function() { if (phoenix.vob.Handlers.enabled()) phoenix.vob.Structure.bootLoad() }) } catch (e) {}
try { addEventHandler("onPlayerJoin", function(playerId) { phoenix.vob.Handlers.onPlayerJoin(playerId) }) } catch (e) {}
try { addEventHandler(phoenixVobSelectedEvent, phoenix.vob.Handlers.onCharacterSelected) } catch (e) {}
try { addEventHandler("phoenix.features.OnChanged", function(key, enabled) { if (key == "worldVobs.enabled" && enabled) phoenix.vob.Structure.bootLoad() }) } catch (e) {}
