phoenix.vob.Ground <- {
	entries = {}
	objects = {}
	labels = []
	labelStacks = {}
	selected = ""
	focus = -1
	lastInteractAt = 0
	range = 360.0
	labelRange = 480.0

	function onSnapshot(message) {
		phoenix.vob.Ground.clearObjects()
		phoenix.vob.Ground.entries.clear()
		local list = message.entries != null ? message.entries : []
		foreach (entry in list) {
			phoenix.vob.Ground.entries[entry.vobId] <- entry
			phoenix.vob.Ground.createObject(entry)
		}
		try { if ("crafting" in phoenix && "Client" in phoenix.crafting) phoenix.crafting.Client.refreshVobInteractive() } catch (e) {}
	}

	function clearObjects() {
		foreach (_id, obj in phoenix.vob.Ground.objects) {
			try { obj.removeFromWorld() } catch (e) {}
			try { obj.remove() } catch (e2) {}
			try { obj.destroy() } catch (e3) {}
		}
		phoenix.vob.Ground.objects.clear()
	}

	function worldMatches(entry) {
		local w = entry.world != null ? entry.world.tostring() : ""
		if (w == "") return true
		local current = ""
		try { current = getPlayerWorld(heroId) } catch (e) {}
		if (current == null || current == "") { try { current = getWorld() } catch (e2) {} }
		if (current == null || current == "") return true
		local a = current.toupper()
		local b = w.toupper()
		if (a == b) return true
		if (a.find(b) != null) return true
		if (b.find(a) != null) return true
		return false
	}

	function isInteractive(entry) {
		if (entry == null) return false
		if (entry.interactive == true) return true
		if (entry.entryKind == "item" || entry.entryKind == "carcass") return true
		try { if ("craftInteraction" in entry && entry.craftInteraction == true) return true } catch (e0) {}
		local v = ""
		try { v = entry.visual != null ? entry.visual.tostring().toupper() : "" } catch (e) {}
		if (v == "") return false
		try {
			if ("crafting" in phoenix && "Client" in phoenix.crafting) {
				if (phoenix.crafting.Client.isStationVisual(v)) return true
			}
		} catch (e2) {}
		return false
	}

	function createObject(entry) {
		if (!phoenix.vob.Ground.worldMatches(entry)) return
		local visual = entry.visual != null ? entry.visual.tostring() : ""
		if (visual == "") return
		local obj = null
		local candidates = [visual]
		local up = visual.toupper()
		if (up.find(".3DS") != null) candidates.append(up.slice(0, up.find(".3DS")) + ".MRM")
		else if (up.find(".MRM") != null) candidates.append(up.slice(0, up.find(".MRM")) + ".3DS")
		try {
			if (entry.itemInstance != null && entry.itemInstance != "") {
				local inst = entry.itemInstance.tostring().toupper()
				candidates.append(inst + ".MRM")
				candidates.append(inst + ".3DS")
				candidates.append(inst)
			}
		} catch (ei) {}
		foreach (candidate in candidates) {
			if (obj != null) break
			try { obj = Vob(candidate) } catch (e2) { obj = null }
		}
		if (obj == null) return
		try { obj.name = phoenix.vob.Ground.label(entry) } catch (en) {}
		try { obj.setPosition(entry.x, entry.y, entry.z) } catch (e3) {}
		try { obj.setRotation(entry.rotX, entry.rotY, entry.rotZ) } catch (e4) {}
		local noCollision = false
		try { noCollision = entry.noCollision == true } catch (eC) {}
		if (entry.entryKind == "item" || entry.entryKind == "carcass") noCollision = true
		try { obj.cdDynamic = !noCollision } catch (e5) {}
		try { obj.cdStatic = !noCollision } catch (e6) {}
		try { obj.visualAlpha = 1.0 } catch (e7) {}
		try { obj.visible = true } catch (e8) {}
		try { obj.addToWorld() } catch (e9) {}
		try { if (entry.entryKind == "item") obj.floor() } catch (ef) {}
		phoenix.vob.Ground.objects[entry.vobId] <- obj
	}

	function dist(a, b) {
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function clearLabels() {
		foreach (label in phoenix.vob.Ground.labels) {
			try { label.visible = false } catch (e) {}
			try { label.remove() } catch (e2) {}
		}
		phoenix.vob.Ground.labels.clear()
		phoenix.vob.Ground.labelStacks.clear()
	}

	function stackIndex(entry) {
		local keyX = (entry.x / 45.0).tointeger()
		local keyZ = (entry.z / 45.0).tointeger()
		local key = keyX + ":" + keyZ
		local index = 0
		if (key in phoenix.vob.Ground.labelStacks) index = phoenix.vob.Ground.labelStacks[key]
		phoenix.vob.Ground.labelStacks[key] <- index + 1
		return index
	}

	function label(entry) {
		if (entry.name != null && entry.name != "") return entry.name
		local v = entry.visual != null ? entry.visual.tostring() : ""
		if (v == "") return "VOB"
		local upper = v.toupper()
		local at = upper.find(".3DS")
		if (at != null) return upper.slice(0, at)
		at = upper.find(".MRM")
		if (at != null) return upper.slice(0, at)
		return upper
	}

	function qualityColor(quality, selected) {
		local q = quality.tointeger()
		local alpha = selected ? 250 : 215
		if (q <= 0) return Color(125, 125, 125, alpha)
		if (q == 1) return Color(154, 160, 122, alpha)
		if (q == 3) return Color(94, 155, 255, alpha)
		if (q == 4) return Color(181, 108, 255, alpha)
		if (q >= 5) return Color(255, 184, 77, alpha)
		return Color(216, 211, 193, alpha)
	}

	function labelColor(entry, selected) {
		if (entry.entryKind == "item") return phoenix.vob.Ground.qualityColor(entry.itemQuality, selected)
		if (selected) return Color(255, 210, 80, 250)
		return Color(210, 220, 235, 215)
	}

	function renderLabel(entry, heroPos, selected) {
		local pos = { x = entry.x, y = entry.y, z = entry.z }
		local d = phoenix.vob.Ground.dist(heroPos, pos)
		if (d > phoenix.vob.Ground.labelRange) return
		local project = null
		local height = entry.entryKind == "item" ? 6.0 : 34.0
		try { project = Camera.project(entry.x, entry.y + height, entry.z) } catch (e) { project = null }
		if (project == null) return
		local text = phoenix.text.Encoding.forLabel(phoenix.vob.Ground.label(entry))
		local draw = null
		try { draw = Label(0, 0, text) } catch (e2) { return }
		local scale = selected ? 0.85 : 0.60
		try { draw.setScale(scale, scale) } catch (e3) {}
		try { draw.color = phoenix.vob.Ground.labelColor(entry, selected) } catch (e4) {}
		local offset = phoenix.vob.Ground.stackIndex(entry) * 18
		try { draw.setPositionPx(project.x - draw.widthPx / 2, project.y - 2 - offset); draw.visible = true } catch (e5) {}
		try { draw.top() } catch (e6) {}
		phoenix.vob.Ground.labels.push(draw)
	}

	function findFocused(heroPos) {
		local pointer = phoenix.vob.Ground.focus
		if (pointer == null || pointer < 0) return ""
		foreach (vobId, obj in phoenix.vob.Ground.objects) {
			try {
				if (obj == null || obj.ptr != pointer) continue
				if (!(vobId in phoenix.vob.Ground.entries)) continue
				local entry = phoenix.vob.Ground.entries[vobId]
				if (!phoenix.vob.Ground.isInteractive(entry)) continue
				if (!phoenix.vob.Ground.worldMatches(entry)) continue
				local d = phoenix.vob.Ground.dist(heroPos, { x = entry.x, y = entry.y, z = entry.z })
				if (d <= phoenix.vob.Ground.range) return vobId
			} catch (e) {}
		}
		return ""
	}

	function findNearest(heroPos) {
		// Only select a VOB the player is actually looking at (within ±35 degrees
		// of their facing direction). This prevents accidental interaction with
		// nearby VOBs the player doesn't intend to use.
		local heroAngle = 0.0
		try { heroAngle = getPlayerAngle(heroId) } catch (e) { return "" }
		local best = ""
		local bestDist = phoenix.vob.Ground.range
		foreach (vobId, entry in phoenix.vob.Ground.entries) {
			if (!phoenix.vob.Ground.isInteractive(entry)) continue
			if (!phoenix.vob.Ground.worldMatches(entry)) continue
			local d = phoenix.vob.Ground.dist(heroPos, { x = entry.x, y = entry.y, z = entry.z })
			if (d >= bestDist) continue
			// Check if VOB is within the player's view cone
			local dx = entry.x - heroPos.x
			local dz = entry.z - heroPos.z
			local angleToVob = atan2(dx, dz) * 180.0 / 3.14159265
			local diff = angleToVob - heroAngle
			while (diff > 180.0) diff -= 360.0
			while (diff < -180.0) diff += 360.0
			if (diff < -35.0 || diff > 35.0) continue
			bestDist = d
			best = vobId
		}
		return best
	}

	function onRender() {
		phoenix.vob.Ground.clearLabels()
		local heroPos = null
		try { heroPos = getPlayerPosition(heroId) } catch (e) { heroPos = null }
		if (heroPos == null) return
		local hide = false
		try { hide = phoenix.ui.ActiveGui.isAnyOpen() } catch (e2) {}
		if (hide) { phoenix.vob.Ground.selected = ""; return }
		local selected = phoenix.vob.Ground.findFocused(heroPos)
		if (selected == "") selected = phoenix.vob.Ground.findNearest(heroPos)
		phoenix.vob.Ground.selected = selected
		foreach (vobId, entry in phoenix.vob.Ground.entries) {
			if (!phoenix.vob.Ground.worldMatches(entry)) continue
			if (!phoenix.vob.Ground.isInteractive(entry)) continue
			phoenix.vob.Ground.renderLabel(entry, heroPos, vobId == selected)
		}
	}

	function tryInteract() {
		local id = phoenix.vob.Ground.selected
		if (id == "") return
		try { if (phoenix.ui.ActiveGui.isAnyOpen()) return } catch (e) {}
		local now = getTickCount()
		if (now - phoenix.vob.Ground.lastInteractAt < 350) return
		phoenix.vob.Ground.lastInteractAt = now
		local msg = phoenix.vob.Message.InteractRequest()
		msg.vobId = id
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onFocus(newFocus, _oldFocus) {
		phoenix.vob.Ground.focus = newFocus == null ? -1 : newFocus
	}

	function onMouseDown(button) {
		local left = 0
		try { left = MOUSE_BUTTONLEFT } catch (e) { left = 0 }
		if (button != left && button != 0) return
		phoenix.vob.Ground.tryInteract()
	}

	function onKey(key) {
		try { if (phoenix.chat.Client.inputOpen) return } catch (eChat) {}
		local interact = false
		try { if (key == KEY_LCONTROL || key == KEY_RCONTROL || key == KEY_E) interact = true } catch (e) {}
		if (interact) phoenix.vob.Ground.tryInteract()
	}
}

phoenix.vob.Message.Snapshot.bind(phoenix.vob.Ground.onSnapshot)
addEventHandler("onRender", function() { phoenix.vob.Ground.onRender() })
addEventHandler("onMouseDown", function(button) { phoenix.vob.Ground.onMouseDown(button) })
addEventHandler("onKeyDown", function(key) { phoenix.vob.Ground.onKey(key) })
addEventHandler("onFocus", function(newFocus, oldFocus) { phoenix.vob.Ground.onFocus(newFocus, oldFocus) })
