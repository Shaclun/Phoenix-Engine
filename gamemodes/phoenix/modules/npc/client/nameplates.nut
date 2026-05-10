phoenix.npc.Nameplates <- {
	entries = {}
	baseHeight = 130
	lang = "pl"
	lastSweep = 0
	visibleId = -1
	showAll = true
	uiBlocked = false
	bucket = []

	function clearMissing(alive) {
		local remove = []
		foreach (npcId, entry in phoenix.npc.Nameplates.entries) {
			if (!(npcId in alive)) remove.append(npcId)
		}
		foreach (npcId in remove) phoenix.npc.Nameplates.remove(npcId)
	}

	function colorFor(kind) {
		if (kind == "monster") return Color(255, 120, 105, 235)
		return Color(235, 220, 170, 235)
	}

	function displayName(entry) {
		if (entry.name != null && entry.name != "") return entry.name
		if (phoenix.npc.Nameplates.lang == "en" && entry.labelEn != "") return entry.labelEn
		if (phoenix.npc.Nameplates.lang == "de" && entry.labelDe != "") return entry.labelDe
		if (phoenix.npc.Nameplates.lang == "ru" && entry.labelRu != "") return entry.labelRu
		if (entry.labelPl != "") return entry.labelPl
		return entry.instance
	}

	function createDraw(npcId, name, kind, height) {
		try {
			local pos = getPlayerPosition(npcId)
			if (pos == null) return null
			if (pos.x == 0 && pos.y == 0 && pos.z == 0) return null
			local d = Draw3d(pos.x, pos.y + height, pos.z)
			try { d.setFont("FONT_OLD_10_WHITE_HI.TGA") } catch (e) {}
			try { d.setColor(phoenix.npc.Nameplates.colorFor(kind)) } catch (e) {}
			d.insertText(name != "" ? phoenix.text.Encoding.forLabel(name, phoenix.npc.Nameplates.lang) : " ")
			d.distance = 3000
			d.visible = false
			try { d.top() } catch (e) {}
			return d
		} catch (e) { return null }
	}

	function upsert(npcId, spawnId, name, instance, kind, height, level, hp, hpMax, mana, manaMax, testPlayer, labelPl, labelEn, labelDe, labelRu) {
		if (height <= 0) height = phoenix.npc.Nameplates.baseHeight
		if (!(npcId in phoenix.npc.Nameplates.entries)) {
			local entry = { spawnId = spawnId, name = name, instance = instance, kind = kind, height = height, level = level, hp = hp, hpMax = hpMax, mana = mana, manaMax = manaMax, testPlayer = testPlayer, labelPl = labelPl, labelEn = labelEn, labelDe = labelDe, labelRu = labelRu, draw = null }
			local label = phoenix.npc.Nameplates.displayName(entry)
			entry.draw = phoenix.npc.Nameplates.createDraw(npcId, label, kind, height)
			phoenix.npc.Nameplates.entries[npcId] <- entry
			return
		}
		local entry = phoenix.npc.Nameplates.entries[npcId]
		entry.spawnId = spawnId
		entry.name = name
		entry.instance = instance
		entry.kind = kind
		entry.height = height
		entry.level = level
		entry.hp = hp
		entry.hpMax = hpMax
		entry.mana = mana
		entry.manaMax = manaMax
		entry.testPlayer = testPlayer
		entry.labelPl = labelPl
		entry.labelEn = labelEn
		entry.labelDe = labelDe
		entry.labelRu = labelRu
		local label = phoenix.npc.Nameplates.displayName(entry)
		if (entry.draw == null) entry.draw = phoenix.npc.Nameplates.createDraw(npcId, label, kind, height)
		else {
			try { entry.draw.setText(label != "" ? phoenix.text.Encoding.forLabel(label, phoenix.npc.Nameplates.lang) : " ") } catch (e) {}
			try { entry.draw.setColor(phoenix.npc.Nameplates.colorFor(kind)) } catch (e) {}
		}
	}

	function refreshTexts() {
		foreach (npcId, entry in phoenix.npc.Nameplates.entries) {
			try {
				if (entry.draw != null) {
					local label = phoenix.npc.Nameplates.displayName(entry)
					entry.draw.setText(label != "" ? phoenix.text.Encoding.forLabel(label, phoenix.npc.Nameplates.lang) : " ")
				}
			} catch (e) {}
		}
	}

	function setLang(value) {
		if (value == null) return
		local v = value.tostring()
		if (v != "pl" && v != "en" && v != "de" && v != "ru") return
		phoenix.npc.Nameplates.lang = v
		phoenix.npc.Nameplates.refreshTexts()
	}

	function remove(npcId) {
		if (!(npcId in phoenix.npc.Nameplates.entries)) return
		try { if (phoenix.npc.Nameplates.entries[npcId].draw != null) phoenix.npc.Nameplates.entries[npcId].draw.remove() } catch (e) {}
		phoenix.npc.Nameplates.entries.rawdelete(npcId)
	}

	function onSnapshot(message) {
		local alive = {}
		local list = message.entries != null ? message.entries : []
		foreach (entry in list) {
			alive[entry.npcId] <- true
			phoenix.npc.Nameplates.upsert(entry.npcId, entry.spawnId, entry.name, entry.instance, entry.kind, entry.height, entry.level, entry.hp, entry.hpMax, entry.mana, entry.manaMax, entry.testPlayer, entry.labelPl, entry.labelEn, entry.labelDe, entry.labelRu)
		}
		phoenix.npc.Nameplates.clearMissing(alive)
	}

	function setVisibleId(id) {
		phoenix.npc.Nameplates.visibleId = (id == null) ? -1 : id
	}

	function setShowAll(value) {
		phoenix.npc.Nameplates.showAll = value == true
	}

	function nearestNpc(maxDistance = 650.0) {
		local heroPos = null
		try { heroPos = getPlayerPosition(heroId) } catch (e) { return -1 }
		if (heroPos == null) return -1
		local best = -1
		local bestDist = maxDistance
		foreach (npcId, entry in phoenix.npc.Nameplates.entries) {
			try {
				local hp = getPlayerHealth(npcId)
				if (hp <= 0) continue
				local pos = getPlayerPosition(npcId)
				if (pos == null) continue
				local d = phoenix.npc.Nameplates.distance(heroPos, pos)
				if (d < bestDist) { bestDist = d; best = npcId }
			} catch (e) {}
		}
		return best
	}

	function clearBucket() {
		foreach (draw in phoenix.npc.Nameplates.bucket) {
			try { draw.visible = false } catch (e) {}
			try { draw.remove() } catch (e) {}
		}
		phoenix.npc.Nameplates.bucket.clear()
	}

	function distance(a, b) {
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function renderLabel(npcId, entry, pos, heroPos, selected) {
		local project = null
		try { project = Camera.project(pos.x, pos.y + entry.height, pos.z) } catch (e) { project = null }
		if (project == null) return false

		local text = phoenix.text.Encoding.forLabel(phoenix.npc.Nameplates.displayName(entry), phoenix.npc.Nameplates.lang)
		if (text == null || text == "") return true

		local d = phoenix.npc.Nameplates.distance(heroPos, pos)
		local scale = 0.5 + 0.5 * (((800.0 - d) / 800.0) * 1.0)
		if (scale < 0.35) scale = 0.35
		if (scale > 1.0) scale = 1.0

		local draw = null
		try { draw = Label(0, 0, text) } catch (e) { return false }
		try { draw.setScale(scale, scale) } catch (e) {}
		try {
			if (selected) draw.color = Color(255, 10, 10, 240)
			else draw.color = phoenix.npc.Nameplates.colorFor(entry.kind)
		} catch (e) {}
		try {
			draw.setPositionPx(project.x - draw.widthPx / 2, project.y)
			draw.visible = true
		} catch (e) { return false }
		try { draw.top() } catch (e) {}
		phoenix.npc.Nameplates.bucket.push(draw)
		return true
	}

	function onRender() {
		local now = getTickCount()
		local vid = phoenix.npc.Nameplates.visibleId
		local showAll = phoenix.npc.Nameplates.showAll
		local hideAll = phoenix.npc.Nameplates.uiBlocked
		try { if (phoenix.ui.ActiveGui.isAnyOpen()) hideAll = true } catch (e) {}
		phoenix.npc.Nameplates.clearBucket()
		local heroPos = null
		try { heroPos = getPlayerPosition(heroId) } catch (e) { heroPos = null }
		foreach (npcId, entry in phoenix.npc.Nameplates.entries) {
			try {
				if (entry.draw == null) entry.draw = phoenix.npc.Nameplates.createDraw(npcId, phoenix.npc.Nameplates.displayName(entry), entry.kind, entry.height)
				if (entry.draw != null) entry.draw.visible = false
				local pos = getPlayerPosition(npcId)
				if (pos == null || (pos.x == 0 && pos.y == 0 && pos.z == 0)) continue
				if (heroPos == null) continue
				local selected = npcId == vid
				local shouldShow = !hideAll && (showAll || selected)
				if (!shouldShow) continue
				local dist = phoenix.npc.Nameplates.distance(heroPos, pos)
				if (dist > 800.0) continue
				if (!phoenix.npc.Nameplates.renderLabel(npcId, entry, pos, heroPos, selected) && entry.draw != null) {
					entry.draw.setWorldPosition(pos.x, pos.y + entry.height, pos.z)
					entry.draw.visible = true
				}
			} catch (e) {}
		}
		if (now - phoenix.npc.Nameplates.lastSweep > 5000) {
			phoenix.npc.Nameplates.lastSweep = now
			local remove = []
			foreach (npcId, entry in phoenix.npc.Nameplates.entries) {
				try { getPlayerPosition(npcId) } catch (e) { remove.append(npcId) }
			}
			foreach (npcId in remove) phoenix.npc.Nameplates.remove(npcId)
		}
	}
}

try {
	local storedLang = phoenix.web.Storage.read("phoenix:lang")
	phoenix.npc.Nameplates.setLang(storedLang)
} catch (e) {}

try {
	phoenix.web.Router.on("phoenix:storage:set", function(payload) {
		if (payload == null || !("key" in payload)) return
		if (payload.key == "phoenix:lang") phoenix.npc.Nameplates.setLang(("value" in payload) ? payload.value : null)
	})
} catch (e) {}

phoenix.npc.Message.Nameplates.bind(phoenix.npc.Nameplates.onSnapshot)
addEventHandler("onRender", function () { phoenix.npc.Nameplates.onRender() })

addEventHandler("phoenix.ui.OnOpen", function (page) {
	phoenix.npc.Nameplates.uiBlocked = true
})
addEventHandler("phoenix.ui.OnClose", function (page) {
	try { phoenix.npc.Nameplates.uiBlocked = phoenix.ui.ActiveGui.isAnyOpen() } catch (e) { phoenix.npc.Nameplates.uiBlocked = false }
})