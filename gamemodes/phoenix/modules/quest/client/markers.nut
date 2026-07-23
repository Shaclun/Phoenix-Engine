phoenix.quest.MarkerClient <- {
	entries = {},
	projections = {},
	maxDistance = 2200,
	reconcileInterval = 500,
	lastReconcile = 0,

	function removeEntry(key) {
		if (!(key in phoenix.quest.MarkerClient.entries)) return
		local entry = phoenix.quest.MarkerClient.entries[key]
		try { if (entry.draw != null) entry.draw.remove() } catch (error) {}
		phoenix.quest.MarkerClient.entries.rawdelete(key)
	}

	function clear() {
		local keys = []
		foreach (key, entry in phoenix.quest.MarkerClient.entries) keys.append(key)
		foreach (key in keys) phoenix.quest.MarkerClient.removeEntry(key)
		phoenix.quest.MarkerClient.projections = {}
	}

	function color(markerType) {
		if (markerType == "turn_in" || markerType == "continue") return Color(255, 225, 80, 255)
		return Color(255, 215, 40, 255)
	}

	function symbol(markerType) {
		if (markerType == "turn_in" || markerType == "continue") return "?"
		return "!"
	}

	function resolveNpcId(data) {
		if ("spawnId" in data) foreach (npcId, entry in phoenix.npc.Nameplates.entries) if (entry.spawnId == data.spawnId) return npcId
		if ("npcId" in data) {
			local npcId = data.npcId.tointeger()
			try { if (npcId >= 0 && getPlayerPosition(npcId) != null) return npcId } catch (error) {}
		}
		return -1
	}

	function makeDraw(entry) {
		try {
			local position = getPlayerPosition(entry.npcId)
			if (position == null) return null
			local draw = Draw3d(position.x, position.y + entry.offset, position.z)
			try { draw.setFont("FONT_OLD_10_WHITE_HI.TGA") } catch (error) {}
			draw.insertText(phoenix.text.Encoding.forLabel(phoenix.quest.MarkerClient.symbol(entry.markerType), "pl"))
			try { draw.setScale(2.0, 2.0) } catch (error) {}
			try { draw.setColor(phoenix.quest.MarkerClient.color(entry.markerType)) } catch (error) {}
			draw.distance = phoenix.quest.MarkerClient.maxDistance
			draw.visible = true
			try { draw.top() } catch (error) {}
			return draw
		} catch (error) { return null }
	}

	function create(data, npcId) {
		if (npcId < 0) return null
		local position = getPlayerPosition(npcId)
		if (position == null) return null
		local entry = { npcId = npcId, offset = "offset" in data ? data.offset.tofloat() : 165.0, markerType = data.markerType, world = "world" in data ? data.world.tostring() : "", virtualWorld = "virtualWorld" in data ? data.virtualWorld.tointeger() : -1, draw = null }
		entry.draw = phoenix.quest.MarkerClient.makeDraw(entry)
		return entry
	}

	function reconcile() {
		local retained = {}
		foreach (key, data in phoenix.quest.MarkerClient.projections) {
			retained[key] <- true
			local npcId = phoenix.quest.MarkerClient.resolveNpcId(data)
			if (npcId < 0) {
				phoenix.quest.MarkerClient.removeEntry(key)
				continue
			}
			if (key in phoenix.quest.MarkerClient.entries) {
				local current = phoenix.quest.MarkerClient.entries[key]
				if (current.npcId == npcId && current.markerType == data.markerType) {
					current.offset = "offset" in data ? data.offset.tofloat() : 165.0
					current.world = "world" in data ? data.world.tostring() : ""
					current.virtualWorld = "virtualWorld" in data ? data.virtualWorld.tointeger() : -1
					continue
				}
				phoenix.quest.MarkerClient.removeEntry(key)
			}
			local created = null
			try { created = phoenix.quest.MarkerClient.create(data, npcId) } catch (error) { created = null }
			if (created != null) phoenix.quest.MarkerClient.entries[key] <- created
		}
		local stale = []
		foreach (key, entry in phoenix.quest.MarkerClient.entries) if (!(key in retained)) stale.append(key)
		foreach (key in stale) phoenix.quest.MarkerClient.removeEntry(key)
	}

	function onSnapshot(message) {
		if (message.characterId != phoenix.quest.Model.characterId) return
		local projections = {}
		local list = message.entries != null ? message.entries : []
		foreach (data in list) if ("spawnId" in data) projections[data.spawnId.tostring()] <- data
		phoenix.quest.MarkerClient.projections = projections
		phoenix.quest.MarkerClient.reconcile()
	}

	function render() {
		local now = getTickCount()
		if (now - phoenix.quest.MarkerClient.lastReconcile >= phoenix.quest.MarkerClient.reconcileInterval) {
			phoenix.quest.MarkerClient.lastReconcile = now
			phoenix.quest.MarkerClient.reconcile()
		}
		local uiBlocking = false
		try { uiBlocking = phoenix.web.Manager.isUiBlocking() } catch (error) {}
		if (uiBlocking) {
			foreach (key, entry in phoenix.quest.MarkerClient.entries) try { if (entry.draw != null) entry.draw.visible = false } catch (error) {}
			return
		}
		foreach (key, entry in phoenix.quest.MarkerClient.entries) {
			try {
				if (entry.draw == null) entry.draw = phoenix.quest.MarkerClient.makeDraw(entry)
				if (entry.draw == null) continue
				local position = getPlayerPosition(entry.npcId)
				if (position == null) { entry.draw.visible = false; continue }
				entry.draw.setWorldPosition(position.x, position.y + entry.offset, position.z)
				entry.draw.visible = true
				try { entry.draw.top() } catch (topError) {}
			} catch (error) { try { if (entry.draw != null) entry.draw.visible = false } catch (hideError) {} }
		}
	}
}

phoenix.quest.Message.Markers.bind(phoenix.quest.MarkerClient.onSnapshot)
addEventHandler("onRender", function() { phoenix.quest.MarkerClient.render() })