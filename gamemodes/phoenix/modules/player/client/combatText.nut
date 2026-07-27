phoenix.player.CombatText <- {
	floats = []
	bucket = []
	duration = 1150
	defaultHeight = 165
	maxDistance = 1600.0
	lang = "pl"

	function enabled() {
		return phoenix.features.Client.effectiveEnabled("player.combatText")
	}

	function clear() {
		phoenix.player.CombatText.floats.clear()
		phoenix.player.CombatText.clearBucket()
	}

	function clearBucket() {
		foreach (draw in phoenix.player.CombatText.bucket) {
			try { draw.visible = false } catch (e) {}
			try { draw.remove() } catch (e) {}
		}
		phoenix.player.CombatText.bucket.clear()
	}

	function colorFor(kind, alpha) {
		if (kind == "levelup") return Color(255, 210, 55, alpha)
		if (kind == "crit") return Color(255, 70, 35, alpha)
		if (kind == "miss") return Color(180, 190, 205, alpha)
		if (kind == "dodge") return Color(120, 190, 255, alpha)
		return Color(255, 224, 150, alpha)
	}

	function labelFor(kind, amount) {
		if (kind == "levelup") {
			if (phoenix.player.CombatText.lang == "en") return "LEVEL UP!"
			if (phoenix.player.CombatText.lang == "de") return "STUFENAUFSTIEG!"
			if (phoenix.player.CombatText.lang == "ru") return "НОВЫЙ УРОВЕНЬ!"
			return "AWANS!"
		}
		if (kind == "miss") return "MISS"
		if (kind == "dodge") return "UNIK"
		if (kind == "crit") return "CRIT " + amount
		return amount.tostring()
	}

	function heightFor(targetId) {
		try {
			if (targetId in phoenix.npc.Nameplates.entries) {
				local value = phoenix.npc.Nameplates.entries[targetId].height
				if (value > 0) return value
			}
		} catch (e) {}
		return phoenix.player.CombatText.defaultHeight
	}

	function distance(a, b) {
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function push(message) {
		if (!phoenix.player.CombatText.enabled()) {
			phoenix.player.CombatText.clear()
			return
		}
		local targetId = 0
		local amount = 0
		local kind = "damage"
		try { targetId = message.targetId.tointeger() } catch (e) { return }
		try { amount = message.amount.tointeger() } catch (e2) { amount = 0 }
		try { kind = message.kind.tostring() } catch (e3) { kind = "damage" }
		if (kind != "damage" && kind != "crit" && kind != "miss" && kind != "dodge" && kind != "levelup") kind = "damage"
		local now = getTickCount()
		phoenix.player.CombatText.floats.append({ targetId = targetId, amount = amount, kind = kind, start = now, seed = rand() % 31 })
	}

	function renderOne(item, now, heroPos) {
		local elapsed = now - item.start
		if (elapsed < 0 || elapsed > phoenix.player.CombatText.duration) return false
		local pos = null
		try { pos = getPlayerPosition(item.targetId) } catch (e) { return true }
		if (pos == null || (pos.x == 0 && pos.y == 0 && pos.z == 0)) return true
		if (heroPos != null && phoenix.player.CombatText.distance(heroPos, pos) > phoenix.player.CombatText.maxDistance) return true
		local t = elapsed.tofloat() / phoenix.player.CombatText.duration.tofloat()
		local height = phoenix.player.CombatText.heightFor(item.targetId) + 16 + t * 82
		local side = (item.seed - 15).tofloat() * 0.45
		local project = null
		try { project = Camera.project(pos.x + side, pos.y + height, pos.z) } catch (e2) { project = null }
		if (project == null) return true
		local text = phoenix.player.CombatText.labelFor(item.kind, item.amount)
		try { text = phoenix.text.Encoding.forLabel(text, phoenix.player.CombatText.lang) } catch (e3) {}
		local draw = null
		try { draw = Label(0, 0, text) } catch (e4) { return true }
		local scale = 0.7 + (1.0 - t) * 0.18
		if (item.kind == "levelup") scale = 1.0 + (1.0 - t) * 0.26
		if (item.kind == "crit") scale = 0.95 + (1.0 - t) * 0.28
		if (item.kind == "miss" || item.kind == "dodge") scale = 0.72 + (1.0 - t) * 0.1
		local alpha = (245.0 * (1.0 - t)).tointeger()
		if (alpha < 0) alpha = 0
		if (alpha > 245) alpha = 245
		try { draw.setScale(scale, scale) } catch (e5) {}
		try { draw.color = phoenix.player.CombatText.colorFor(item.kind, alpha) } catch (e6) {}
		try {
			draw.setPositionPx(project.x - draw.widthPx / 2, project.y)
			draw.visible = true
		} catch (e7) { return true }
		try { draw.top() } catch (e8) {}
		phoenix.player.CombatText.bucket.push(draw)
		return true
	}

	function onRender() {
		if (!phoenix.player.CombatText.enabled()) {
			phoenix.player.CombatText.clear()
			return
		}
		phoenix.player.CombatText.clearBucket()
		local now = getTickCount()
		local heroPos = null
		try { heroPos = getPlayerPosition(heroId) } catch (e) { heroPos = null }
		local next = []
		foreach (item in phoenix.player.CombatText.floats) {
			if (phoenix.player.CombatText.renderOne(item, now, heroPos)) next.append(item)
		}
		phoenix.player.CombatText.floats = next
	}

	function setLang(value) {
		if (value == null) return
		local v = value.tostring()
		if (v == "pl" || v == "en" || v == "de" || v == "ru") phoenix.player.CombatText.lang = v
	}
}

try { phoenix.player.CombatText.setLang(phoenix.web.Storage.read("phoenix:lang")) } catch (e) {}

try {
	phoenix.web.Router.on("phoenix:storage:set", function(payload) {
		if (payload == null || !("key" in payload)) return
		if (payload.key == "phoenix:lang") phoenix.player.CombatText.setLang(("value" in payload) ? payload.value : null)
	})
} catch (e) {}

addEventHandler("phoenix.features.ClientChanged", function(key, enabled) {
	if (key == "player.combatText" && !enabled) phoenix.player.CombatText.clear()
})

phoenix.player.Message.CombatText.bind(phoenix.player.CombatText.push)
addEventHandler("onRender", function () { phoenix.player.CombatText.onRender() })