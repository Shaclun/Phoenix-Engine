phoenix.herb.Ground <- {
	entries = {}
	objects = {}
	labels = []
	labelStacks = {}
	cooldowns = {}
	selected = ""
	focus = -1
	busy = false
	busyAnimEndAt = 0
	gatherStartedAt = 0
	gatherTotalMs = 0
	gatherPlantId = ""
	gatherLabel = ""
	gatherStartPos = null
	gatherAnimTimerId = null
	gatherLastAnimAt = 0
	cancelSent = false
	lastClickAt = 0
	lang = "pl"
	range = 180.0
	labelRange = 320.0

	function onSnapshot(message) {
		phoenix.herb.Ground.clearObjects()
		phoenix.herb.Ground.entries.clear()
		local list = message.entries != null ? message.entries : []
		foreach (entry in list) {
			phoenix.herb.Ground.entries[entry.plantId] <- entry
			try {
				if (entry.cooldownLeftSec > 0) phoenix.herb.Ground.cooldowns[entry.plantId] <- getTickCount() + entry.cooldownLeftSec * 1000
				else if (entry.plantId in phoenix.herb.Ground.cooldowns) phoenix.herb.Ground.cooldowns.rawdelete(entry.plantId)
			} catch (ec) {}
			phoenix.herb.Ground.createObject(entry)
		}
	}

	function clearObjects() {
		foreach (id, obj in phoenix.herb.Ground.objects) {
			try { obj.removeFromWorld() } catch (e) {}
			try { obj.remove() } catch (e2) {}
			try { obj.destroy() } catch (e3) {}
		}
		phoenix.herb.Ground.objects.clear()
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

	function createObject(entry) {
		if (!phoenix.herb.Ground.worldMatches(entry)) return
		local obj = null
		local instance = entry.instance != null ? entry.instance.tostring().toupper() : ""
		local visual = instance
		try {
			local daedalus = Daedalus.instance(instance)
			if (daedalus != null && daedalus.visual != null && daedalus.visual != "") visual = daedalus.visual
		} catch (ed) {}
		if (visual == instance || visual == "") {
			try { local looked = phoenix.item.lookupVisual(instance); if (looked != null && looked != "") visual = looked } catch (el) {}
		}
		if (visual == "") visual = instance + ".MRM"
		try { obj = Vob(visual) } catch (e) { obj = null }
		if (obj == null) { try { obj = Vob(instance + ".MRM") } catch (e2) { obj = null } }
		if (obj == null) { try { obj = Vob(instance) } catch (e3) { obj = null } }
		if (obj == null) return
		try { obj.name = phoenix.herb.Ground.label(entry) } catch (e4) {}
		try { obj.setPosition(entry.x, entry.y, entry.z) } catch (e5) {}
		try { obj.setRotation(0, rand() % 360, 0) } catch (e6) {}
		try { obj.cdDynamic = false } catch (e7) {}
		try { obj.cdStatic = true } catch (e8) {}
		try { obj.visualAlpha = 1.0 } catch (e9) {}
		try { obj.visible = true } catch (e10) {}
		try { obj.addToWorld() } catch (e11) {}
		try { obj.floor() } catch (e12) {}
		phoenix.herb.Ground.objects[entry.plantId] <- obj
	}

	function label(entry) {
		if (phoenix.herb.Ground.lang == "en" && entry.nameEn != "") return entry.nameEn
		if (phoenix.herb.Ground.lang == "de" && entry.nameDe != "") return entry.nameDe
		if (phoenix.herb.Ground.lang == "ru" && entry.nameRu != "") return entry.nameRu
		return entry.namePl
	}

	function setLang(value) {
		if (value == null) return
		local v = value.tostring()
		if (v == "pl" || v == "en" || v == "de" || v == "ru") phoenix.herb.Ground.lang = v
	}

	function dist(a, b) {
		local dx = a.x - b.x
		local dz = a.z - b.z
		return sqrt(dx * dx + dz * dz)
	}

	function clearLabels() {
		foreach (label in phoenix.herb.Ground.labels) {
			try { label.visible = false } catch (e) {}
			try { label.remove() } catch (e) {}
		}
		phoenix.herb.Ground.labels.clear()
		phoenix.herb.Ground.labelStacks.clear()
	}

	function stackIndex(entry) {
		local keyX = (entry.x / 45.0).tointeger()
		local keyZ = (entry.z / 45.0).tointeger()
		local key = keyX + ":" + keyZ
		local index = 0
		if (key in phoenix.herb.Ground.labelStacks) index = phoenix.herb.Ground.labelStacks[key]
		phoenix.herb.Ground.labelStacks[key] <- index + 1
		return index
	}

	function isOnCooldown(plantId) {
		if (!(plantId in phoenix.herb.Ground.cooldowns)) return false
		local until = phoenix.herb.Ground.cooldowns[plantId]
		if (until <= getTickCount()) {
			phoenix.herb.Ground.cooldowns.rawdelete(plantId)
			return false
		}
		return true
	}

	function labelColor(entry, selected) {
		local onCooldown = phoenix.herb.Ground.isOnCooldown(entry.plantId)
		if (onCooldown) return selected ? Color(255, 238, 116, 255) : Color(198, 158, 48, 205)
		return selected ? Color(142, 255, 164, 255) : Color(64, 176, 84, 205)
	}

	function sameWorld(entry) {
		return phoenix.herb.Ground.worldMatches(entry)
	}

	function renderLabel(entry, heroPos, selected) {
		local pos = { x = entry.x, y = entry.y, z = entry.z }
		local d = phoenix.herb.Ground.dist(heroPos, pos)
		if (d > phoenix.herb.Ground.labelRange) return 999999.0
		local project = null
		try { project = Camera.project(entry.x, entry.y + 4.0, entry.z) } catch (e) { project = null }
		if (project == null) return 999999.0
		local text = phoenix.text.Encoding.forLabel(phoenix.herb.Ground.label(entry), phoenix.herb.Ground.lang)
		local draw = null
		try { draw = Label(0, 0, text) } catch (e) { return 999999.0 }
		local centerX = 4096.0
		local centerY = 4096.0
		local sx = project.x - centerX
		local sy = project.y - centerY
		local score = sqrt(sx * sx + sy * sy) + d * 0.15
		local scale = selected ? 0.85 : 0.65
		try { draw.setScale(scale, scale) } catch (e) {}
		try { draw.color = phoenix.herb.Ground.labelColor(entry, selected) } catch (e) {}
		local offset = phoenix.herb.Ground.stackIndex(entry) * 18
		try { draw.setPositionPx(project.x - draw.widthPx / 2, project.y - 2 - offset); draw.visible = true } catch (e) {}
		try { draw.top() } catch (e) {}
		phoenix.herb.Ground.labels.push(draw)
		return score
	}

	function findFocused(heroPos) {
		local pointer = phoenix.herb.Ground.focus
		if (pointer == null || pointer < 0) return ""
		foreach (plantId, obj in phoenix.herb.Ground.objects) {
			try {
				if (obj == null || obj.ptr != pointer) continue
				if (!(plantId in phoenix.herb.Ground.entries)) continue
				local entry = phoenix.herb.Ground.entries[plantId]
				if (!phoenix.herb.Ground.sameWorld(entry)) continue
				local d = phoenix.herb.Ground.dist(heroPos, { x = entry.x, y = entry.y, z = entry.z })
				if (d <= phoenix.herb.Ground.range) return plantId
			} catch (e) {}
		}
		return ""
	}

	function findNearest(heroPos) {
		local best = ""
		local bestDist = phoenix.herb.Ground.range
		foreach (plantId, entry in phoenix.herb.Ground.entries) {
			if (!phoenix.herb.Ground.sameWorld(entry)) continue
			local d = phoenix.herb.Ground.dist(heroPos, { x = entry.x, y = entry.y, z = entry.z })
			if (d < bestDist) { bestDist = d; best = plantId }
		}
		return best
	}

	function onRender() {
		phoenix.herb.Ground.clearLabels()
		local heroPos = null
		try { heroPos = getPlayerPosition(heroId) } catch (e) { heroPos = null }
		if (heroPos == null) return
		if (phoenix.herb.Ground.busy) phoenix.herb.Ground.checkCancel(heroPos)
		local hide = false
		try { hide = phoenix.ui.ActiveGui.isAnyOpen() } catch (e) {}
		if (hide) { phoenix.herb.Ground.selected = ""; return }
		local selected = phoenix.herb.Ground.findFocused(heroPos)
		if (selected == "") selected = phoenix.herb.Ground.findNearest(heroPos)
		phoenix.herb.Ground.selected = selected
		foreach (plantId, entry in phoenix.herb.Ground.entries) {
			if (!phoenix.herb.Ground.sameWorld(entry)) continue
			phoenix.herb.Ground.renderLabel(entry, heroPos, plantId == selected)
		}
	}

	function onMouseDown(button) {
		local left = 0
		try { left = MOUSE_BUTTONLEFT } catch (e) { left = 0 }
		if (button != left && button != 0) return
		if (phoenix.herb.Ground.busy) return
		local now = getTickCount()
		if (now - phoenix.herb.Ground.lastClickAt < 250) return
		phoenix.herb.Ground.lastClickAt = now
		phoenix.herb.Ground.tryGatherSelected()
	}

	function tryGatherSelected() {
		local id = phoenix.herb.Ground.selected
		if (id == "") return
		try { if (phoenix.ui.ActiveGui.isAnyOpen()) return } catch (e) {}
		local msg = phoenix.herb.Message.StartRequest()
		msg.plantId = id
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onFocus(newFocus, _oldFocus) {
		phoenix.herb.Ground.focus = newFocus == null ? -1 : newFocus
	}

	function onKey(key) {
		if (phoenix.herb.Ground.busy) {
			if (phoenix.herb.Ground.isMoveKey(key)) phoenix.herb.Ground.cancelGather()
			return
		}
		local interact = false
		try { if (key == KEY_LCONTROL || key == KEY_RCONTROL || key == KEY_E) interact = true } catch (e) {}
		if (!interact) return
		phoenix.herb.Ground.tryGatherSelected()
	}

	function isMoveKey(key) {
		local moving = false
		try { if (key == KEY_W || key == KEY_A || key == KEY_S || key == KEY_D || key == KEY_UP || key == KEY_DOWN || key == KEY_LEFT || key == KEY_RIGHT) moving = true } catch (e) {}
		return moving
	}

	function hasMovementInput() {
		local moving = false
		try { if (isKeyPressed(KEY_W) || isKeyPressed(KEY_A) || isKeyPressed(KEY_S) || isKeyPressed(KEY_D) || isKeyPressed(KEY_UP) || isKeyPressed(KEY_DOWN) || isKeyPressed(KEY_LEFT) || isKeyPressed(KEY_RIGHT)) moving = true } catch (e) {}
		return moving
	}

	function checkCancel(heroPos) {
		if (!phoenix.herb.Ground.busy || phoenix.herb.Ground.cancelSent) return
		if (phoenix.herb.Ground.hasMovementInput()) { phoenix.herb.Ground.cancelGather(); return }
	}

	function playGatherAnimation(force = false) {
		if (!phoenix.herb.Ground.busy || phoenix.herb.Ground.cancelSent) return
		local now = getTickCount()
		local current = ""
		try { current = getPlayerAni(heroId).toupper() } catch (e) { current = "" }
		local shouldRefresh = force
		if (current == "T_STAND" || current == "S_STAND") shouldRefresh = true
		if (now - phoenix.herb.Ground.gatherLastAnimAt >= 900) shouldRefresh = true
		if (!shouldRefresh) return
		try { stopAni(heroId, "S_RUN") } catch (e) {}
		try { stopAni(heroId, "S_WALK") } catch (e2) {}
		try { playAni(heroId, "T_PLUNDER") } catch (e3) {}
		phoenix.herb.Ground.gatherLastAnimAt = now
	}

	function refreshGatherAnimation() {
		if (!phoenix.herb.Ground.busy || phoenix.herb.Ground.cancelSent) {
			phoenix.herb.Ground.stopGatherAnimation()
			return
		}
		local now = getTickCount()
		if (phoenix.herb.Ground.gatherTotalMs > 0 && now - phoenix.herb.Ground.gatherStartedAt > phoenix.herb.Ground.gatherTotalMs + 500) {
			phoenix.herb.Ground.stopGatherAnimation()
			return
		}
		phoenix.herb.Ground.playGatherAnimation(false)
	}

	function startGatherAnimation() {
		phoenix.herb.Ground.stopGatherAnimation()
		phoenix.herb.Ground.gatherLastAnimAt = 0
		phoenix.herb.Ground.playGatherAnimation(true)
		phoenix.herb.Ground.gatherAnimTimerId = setTimer(phoenix.herb.Ground.refreshGatherAnimation, 180, 0)
	}

	function stopGatherAnimation() {
		if (phoenix.herb.Ground.gatherAnimTimerId != null) {
			try { removeTimer(phoenix.herb.Ground.gatherAnimTimerId) } catch (e) {}
			phoenix.herb.Ground.gatherAnimTimerId = null
		}
	}

	function cancelGather() {
		if (!phoenix.herb.Ground.busy || phoenix.herb.Ground.cancelSent) return
		phoenix.herb.Ground.cancelSent = true
		phoenix.herb.Ground.busy = false
		phoenix.herb.Ground.stopGatherAnimation()
		try { stopAni(heroId, "T_PLUNDER") } catch (e) {}
		try { stopAni(heroId, "S_PLUNDER") } catch (e2) {}
		try { playAni(heroId, "T_STAND_2_RUN") } catch (e3) {}
		local msg = phoenix.herb.Message.CancelRequest()
		msg.plantId = phoenix.herb.Ground.gatherPlantId
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e4) {}
		try { phoenix.web.Manager.emit("phoenix:herb:result", { plantId = phoenix.herb.Ground.gatherPlantId, success = false, instance = "", label = phoenix.herb.Ground.gatherLabel, error = "cancelled", cooldownSec = 0 }) } catch (e5) {}
	}

	function onStarted(message) {
		phoenix.herb.Ground.busy = true
		phoenix.herb.Ground.cancelSent = false
		phoenix.herb.Ground.gatherStartedAt = getTickCount()
		phoenix.herb.Ground.gatherTotalMs = message.gatherMs > 0 ? message.gatherMs : 4000
		phoenix.herb.Ground.gatherPlantId = message.plantId
		phoenix.herb.Ground.gatherLabel = message.label
		try { phoenix.herb.Ground.gatherStartPos = getPlayerPosition(heroId) } catch (e) { phoenix.herb.Ground.gatherStartPos = null }
		phoenix.herb.Ground.startGatherAnimation()
		try { phoenix.web.Manager.emit("phoenix:herb:start", { plantId = message.plantId, label = message.label, gatherMs = message.gatherMs }) } catch (e4) {}
	}

	function onResult(message) {
		try {
			if (message.plantId != null && message.cooldownSec > 0 && (message.success || message.error == "cooldown"))
				phoenix.herb.Ground.cooldowns[message.plantId] <- getTickCount() + message.cooldownSec * 1000
		} catch (ec) {}
		if (!phoenix.herb.Ground.busy && phoenix.herb.Ground.cancelSent && message.error == "cancelled") {
			phoenix.herb.Ground.cancelSent = false
			phoenix.herb.Ground.gatherPlantId = ""
			phoenix.herb.Ground.gatherLabel = ""
			phoenix.herb.Ground.gatherStartPos = null
			return
		}
		phoenix.herb.Ground.busy = false
		phoenix.herb.Ground.cancelSent = false
		phoenix.herb.Ground.stopGatherAnimation()
		phoenix.herb.Ground.gatherPlantId = ""
		phoenix.herb.Ground.gatherLabel = ""
		phoenix.herb.Ground.gatherStartPos = null
		try { stopAni(heroId, "T_PLUNDER") } catch (e) {}
		try { stopAni(heroId, "S_PLUNDER") } catch (e2) {}
		try { playAni(heroId, "T_STAND_2_RUN") } catch (e3) {}
		try { phoenix.web.Manager.emit("phoenix:herb:result", { plantId = message.plantId, success = message.success, instance = message.instance, label = message.label, error = message.error, cooldownSec = message.cooldownSec }) } catch (e4) {}
	}
}

try { phoenix.herb.Ground.setLang(phoenix.web.Storage.read("phoenix:lang")) } catch (e) {}

try {
	phoenix.web.Router.on("phoenix:storage:set", function(payload) {
		if (payload == null || !("key" in payload)) return
		if (payload.key == "phoenix:lang") phoenix.herb.Ground.setLang(("value" in payload) ? payload.value : null)
	})
} catch (e) {}

phoenix.herb.Message.Snapshot.bind(phoenix.herb.Ground.onSnapshot)
phoenix.herb.Message.Started.bind(phoenix.herb.Ground.onStarted)
phoenix.herb.Message.Result.bind(phoenix.herb.Ground.onResult)

addEventHandler("onRender", function() { phoenix.herb.Ground.onRender() })
addEventHandler("onMouseDown", function(button) { phoenix.herb.Ground.onMouseDown(button) })
addEventHandler("onKeyDown", function(key) { phoenix.herb.Ground.onKey(key) })
addEventHandler("onFocus", function(newFocus, oldFocus) { phoenix.herb.Ground.onFocus(newFocus, oldFocus) })
