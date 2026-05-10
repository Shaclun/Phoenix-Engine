phoenix.house.Ground <- {
	entries = {}
	labels = []
	selected = 0
	visible = false
	adminBoundaries = false
	range = 360.0
	labelRange = 700.0

	function init() {
		phoenix.web.Router.on("phoenix:house:close", phoenix.house.Ground.forceClose)
		phoenix.web.Router.on("phoenix:house:panelRequest", phoenix.house.Ground.requestPanel)
		phoenix.web.Router.on("phoenix:house:rent", phoenix.house.Ground.onRent)
		phoenix.web.Router.on("phoenix:house:extend", phoenix.house.Ground.onExtend)
		phoenix.web.Router.on("phoenix:house:invite", phoenix.house.Ground.onInvite)
		phoenix.web.Router.on("phoenix:house:requestAccess", phoenix.house.Ground.onRequestAccess)
		phoenix.web.Router.on("phoenix:house:accept", phoenix.house.Ground.onAccept)
		phoenix.web.Router.on("phoenix:house:deny", phoenix.house.Ground.onDeny)
		phoenix.web.Router.on("phoenix:house:kick", phoenix.house.Ground.onKick)
		try { phoenix.ui.ActiveGui.register("house", phoenix.house.Ground.forceClose) } catch (e) {}
	}

	function onSnapshot(message) {
		phoenix.house.Ground.entries.clear()
		local list = message.entries != null ? message.entries : []
		foreach (entry in list) phoenix.house.Ground.entries[entry.id] <- entry
	}

	function decodePoints(text) {
		local out = []
		if (text == null || text == "") return out
		local raw = text.tostring()
		local start = 0
		while (start <= raw.len()) {
			local sep = raw.find("|", start)
			local chunk = sep == null ? raw.slice(start) : raw.slice(start, sep)
			local first = chunk.find(",")
			local second = first == null ? null : chunk.find(",", first + 1)
			if (first != null && second != null) {
				try { out.append({ x = chunk.slice(0, first).tofloat(), y = chunk.slice(first + 1, second).tofloat(), z = chunk.slice(second + 1).tofloat() }) } catch (e) {}
			}
			if (sep == null) break
			start = sep + 1
		}
		return out
	}

	function sameWorld(entry) {
		local w = entry.world != null ? entry.world.tostring().toupper() : ""
		if (w == "") return true
		local current = ""
		try { current = getPlayerWorld(heroId) } catch (e) {}
		if (current == null || current == "") { try { current = getWorld() } catch (e2) {} }
		if (current == null || current == "") return true
		current = current.tostring().toupper()
		return current == w || current.find(w) != null || w.find(current) != null
	}

	function dist2d(a, x, z) {
		local dx = a.x - x
		local dz = a.z - z
		return sqrt(dx * dx + dz * dz)
	}

	function isAdminClient() {
		try { return phoenix.account.Model.role == 1 } catch (e) {}
		return false
	}

	function clearLabels() {
		foreach (label in phoenix.house.Ground.labels) {
			try { label.visible = false } catch (e) {}
			try { label.remove() } catch (e2) {}
		}
		phoenix.house.Ground.labels.clear()
	}

	function labelText(entry) {
		local price = entry.priceGold + entry.weeklyRentGold
		if (entry.ownerId <= 0) return entry.name + " | Kup: " + price + " szt. zlota"
		return entry.name + " | Czynsz: " + entry.weeklyRentGold + " / tydz."
	}

	function renderLabel(entry, heroPos, selected) {
		if (!phoenix.house.Ground.sameWorld(entry)) return 999999.0
		local d = phoenix.house.Ground.dist2d(heroPos, entry.entryX, entry.entryZ)
		if (d > phoenix.house.Ground.labelRange) return 999999.0
		local project = null
		try { project = Camera.project(entry.entryX, entry.entryY + 90.0, entry.entryZ) } catch (e) { project = null }
		if (project == null) return 999999.0
		local text = phoenix.text.Encoding.forLabel(phoenix.house.Ground.labelText(entry), "pl")
		local draw = null
		try { draw = Label(0, 0, text) } catch (e2) { return 999999.0 }
		try { draw.setScale(selected ? 0.85 : 0.68, selected ? 0.85 : 0.68) } catch (e3) {}
		try { draw.color = selected ? Color(255, 225, 120, 255) : Color(120, 200, 255, 215) } catch (e4) {}
		try { draw.setPositionPx(project.x - draw.widthPx / 2, project.y - 8); draw.visible = true; draw.top() } catch (e5) {}
		phoenix.house.Ground.labels.append(draw)
		return d
	}

	function findNearest(heroPos) {
		local best = 0
		local bestDist = phoenix.house.Ground.range
		foreach (id, entry in phoenix.house.Ground.entries) {
			if (!phoenix.house.Ground.sameWorld(entry)) continue
			local d = phoenix.house.Ground.dist2d(heroPos, entry.entryX, entry.entryZ)
			if (d <= bestDist) { bestDist = d; best = id }
		}
		return best
	}

	function drawAdminBoundaries() {
		if (!phoenix.house.Ground.isAdminClient()) return
		if (!phoenix.house.Ground.adminBoundaries) return
		try { if (!("drawLine3d" in getroottable())) return } catch (e) { return }
		foreach (_id, entry in phoenix.house.Ground.entries) {
			if (!phoenix.house.Ground.sameWorld(entry)) continue
			local points = phoenix.house.Ground.decodePoints(entry.points)
			if (points.len() < 2) continue
			for (local i = 0; i < points.len(); i += 1) {
				local a = points[i]
				local b = points[(i + 1) % points.len()]
				try { drawLine3d(a.x, a.y, a.z, b.x, b.y, b.z, 120, 200, 255, true) } catch (e2) {}
				try { drawLine3d(a.x, a.y, a.z, a.x, a.y + 120.0, a.z, 255, 210, 90, true) } catch (e3) {}
			}
			try { drawLine3d(entry.entryX, entry.entryY, entry.entryZ, entry.entryX, entry.entryY + 150.0, entry.entryZ, 90, 240, 170, true) } catch (e4) {}
		}
	}

	function onRender() {
		phoenix.house.Ground.clearLabels()
		phoenix.house.Ground.drawAdminBoundaries()
		local heroPos = null
		try { heroPos = getPlayerPosition(heroId) } catch (e) { heroPos = null }
		if (heroPos == null) return
		local hide = false
		try { hide = phoenix.ui.ActiveGui.isAnyOpen() } catch (e2) {}
		if (hide) { phoenix.house.Ground.selected = 0; return }
		local selected = phoenix.house.Ground.findNearest(heroPos)
		phoenix.house.Ground.selected = selected
		foreach (_id, entry in phoenix.house.Ground.entries) phoenix.house.Ground.renderLabel(entry, heroPos, entry.id == selected)
	}

	function tryInteract() {
		if (phoenix.house.Ground.selected <= 0) return
		try { if (phoenix.ui.ActiveGui.isAnyOpen()) return } catch (e) {}
		local msg = phoenix.house.Message.InteractRequest()
		msg.houseId = phoenix.house.Ground.selected
		msg.action = "open"
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e2) {}
	}

	function onKey(key) {
		if (key == KEY_H) {
			if (phoenix.house.Ground.visible) phoenix.house.Ground.close()
			else phoenix.house.Ground.openPanel()
			try { cancelEvent() } catch (ec) {}
			return
		}
		local interact = false
		try { if (key == KEY_LCONTROL || key == KEY_RCONTROL || key == KEY_E) interact = true } catch (e) {}
		if (interact) phoenix.house.Ground.tryInteract()
	}

	function openPanel() {
		try { if (phoenix.web.Manager.isUiBlocking()) return } catch (e) {}
		phoenix.house.Ground.visible = true
		try { phoenix.web.Manager.show("house") } catch (e2) {}
		try { phoenix.ui.ActiveGui.set("house") } catch (e3) {}
		phoenix.house.Ground.requestPanel(null)
	}

	function openEntry(payload) {
		phoenix.house.Ground.visible = true
		try { phoenix.web.Manager.show("house") } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:house:entry", payload) } catch (e2) {}
		try { phoenix.ui.ActiveGui.set("house") } catch (e3) {}
	}

	function close() {
		if (!phoenix.house.Ground.visible) return
		phoenix.house.Ground.visible = false
		try { phoenix.web.Manager.hide() } catch (e) {}
		try { if (phoenix.ui.ActiveGui.is("house")) phoenix.ui.ActiveGui.clear() } catch (e2) {}
	}

	function forceClose(_payload = null) { phoenix.house.Ground.close() }

	function requestPanel(_payload) {
		local msg = phoenix.house.Message.PanelRequest()
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function sendAction(houseId, action, weeks = 0, target = "") {
		local msg = phoenix.house.Message.InteractRequest()
		msg.houseId = houseId
		msg.action = action
		msg.weeks = weeks
		msg.target = target
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onRent(payload) {
		if (payload == null || !("houseId" in payload)) return
		phoenix.house.Ground.sendAction(payload.houseId.tointeger(), "rent", 1, "")
	}

	function onExtend(payload) {
		if (payload == null || !("houseId" in payload)) return
		local weeks = ("weeks" in payload) ? payload.weeks.tointeger() : 1
		phoenix.house.Ground.sendAction(payload.houseId.tointeger(), "extend", weeks, "")
	}

	function onInvite(payload) {
		if (payload == null || !("houseId" in payload)) return
		local target = ("target" in payload && payload.target != null) ? payload.target.tostring() : ""
		phoenix.house.Ground.sendAction(payload.houseId.tointeger(), "invite", 0, target)
	}

	function onRequestAccess(payload) {
		if (payload == null || !("houseId" in payload)) return
		phoenix.house.Ground.sendAction(payload.houseId.tointeger(), "request", 0, "")
	}

	function onAccept(payload) {
		if (payload == null || !("houseId" in payload)) return
		local target = ("target" in payload && payload.target != null) ? payload.target.tostring() : ""
		phoenix.house.Ground.sendAction(payload.houseId.tointeger(), "accept", 0, target)
	}

	function onDeny(payload) {
		if (payload == null || !("houseId" in payload)) return
		local target = ("target" in payload && payload.target != null) ? payload.target.tostring() : ""
		phoenix.house.Ground.sendAction(payload.houseId.tointeger(), "deny", 0, target)
	}

	function onKick(payload) {
		if (payload == null || !("houseId" in payload)) return
		local target = ("target" in payload && payload.target != null) ? payload.target.tostring() : ""
		phoenix.house.Ground.sendAction(payload.houseId.tointeger(), "kick", 0, target)
	}

	function toggleAdminBoundaries() {
		phoenix.house.Ground.adminBoundaries = !phoenix.house.Ground.adminBoundaries
		try { phoenix.web.Manager.emit("phoenix:admin:response", { action = "adminHouseBoundaryToggle", success = true, error = "", payload = { active = phoenix.house.Ground.adminBoundaries ? 1 : 0 } }) } catch (e) {}
	}

	function resultPayload(message) {
		return {
			success = message.success, canEnter = message.canEnter, error = message.error, access = message.access, mode = message.mode,
			houseId = message.houseId, name = message.name, priceGold = message.priceGold,
			weeklyRentGold = message.weeklyRentGold, rentPaidUntil = message.rentPaidUntil,
			ownerId = message.ownerId, ownerName = message.ownerName, playerGold = message.playerGold,
			guests = message.guests, guestsData = message.guestsData,
			friends = message.friends, requests = message.requests,
			maxExtendWeeks = message.maxExtendWeeks
		}
	}

	function onResult(message) {
		local payload = phoenix.house.Ground.resultPayload(message)
		if (message.mode == "panel") {
			try { phoenix.web.Manager.emit("phoenix:house:panel", payload) } catch (e0) {}
			return
		}
		if (message.mode == "entry" && message.error == "open") {
			phoenix.house.Ground.openEntry(payload)
			return
		}
		try { phoenix.web.Manager.emit("phoenix:house:result", payload) } catch (e1) {}
	}
}

phoenix.house.Ground.init()
try { addEventHandler("onRender", function() { phoenix.house.Ground.onRender() }) } catch (e) {}
try { addEventHandler("onKeyDown", function(key) { phoenix.house.Ground.onKey(key) }) } catch (e) {}
try { phoenix.house.Message.Snapshot.bind(phoenix.house.Ground.onSnapshot) } catch (e) {}
try { phoenix.house.Message.InteractResult.bind(phoenix.house.Ground.onResult) } catch (e) {}
