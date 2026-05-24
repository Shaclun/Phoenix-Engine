phoenix.player.Lobby <- {

	cameraSpots = [
		{ pos = { x = -107441.0, y = 4105.83, z = 131140.0 }, rot = { x = 20.0,  y = -30.0, z = 0.0 } },
		{ pos = { x = 1850.0,    y = 8500.0,  z = 5635.0   }, rot = { x = 35.0,  y = 0.0,   z = 0.0 } },
		{ pos = { x = -36000.0,  y = 6000.0,  z = 14000.0  }, rot = { x = 25.0,  y = 90.0,  z = 0.0 } },
		{ pos = { x = 21000.0,   y = 5000.0,  z = 4400.0   }, rot = { x = 15.0,  y = 180.0, z = 0.0 } },
		{ pos = { x = -19000.0,  y = 4500.0,  z = -12000.0 }, rot = { x = 10.0,  y = 270.0, z = 0.0 } }
	]
	currentSpot = null
	createSpot = null
	selectSpot = null

	function applyServerConfig(payload) {
		if (payload == null) return
		local rawLobby = ("lobbyCameras" in payload) ? payload.lobbyCameras.tostring() : ""
		if (rawLobby != null && rawLobby != "" && rawLobby != "[]") {
			try {
				local parsed = phoenix.player.Lobby._parseSpots(rawLobby)
				if (parsed != null && parsed.len() > 0) {
					phoenix.player.Lobby.cameraSpots = parsed
					if (phoenix.player.Lobby.currentSpot != null) {
						phoenix.player.Lobby.pickSpot()
						phoenix.player.Lobby.applyLobbyCamera()
					}
				}
			} catch (e) {}
		}
		local rawCreate = ("characterCreateCamera" in payload) ? payload.characterCreateCamera.tostring() : ""
		phoenix.player.Lobby.createSpot = phoenix.player.Lobby._parseSingleSpot(rawCreate)
		local rawSelect = ("characterSelectCamera" in payload) ? payload.characterSelectCamera.tostring() : ""
		phoenix.player.Lobby.selectSpot = phoenix.player.Lobby._parseSingleSpot(rawSelect)
		local rawHudPortrait = ("hudPortrait" in payload) ? payload.hudPortrait.tostring() : ""
		try { phoenix.web.Manager.emit("phoenix:hud:portraitConfig", { data = rawHudPortrait }) } catch (eHp) {}
	}

	function _parseSingleSpot(raw) {
		if (raw == null || raw == "" || raw == "{}") return null
		local x = phoenix.player.Lobby._readNumber(raw, "x")
		local y = phoenix.player.Lobby._readNumber(raw, "y")
		local z = phoenix.player.Lobby._readNumber(raw, "z")
		local rx = phoenix.player.Lobby._readNumber(raw, "rotX")
		local ry = phoenix.player.Lobby._readNumber(raw, "rotY")
		local rz = phoenix.player.Lobby._readNumber(raw, "rotZ")
		if (x == 0.0 && y == 0.0 && z == 0.0) return null
		return { pos = { x = x, y = y, z = z }, rot = { x = rx, y = ry, z = rz } }
	}

	function applyCreateCamera() {
		if (phoenix.player.Lobby.createSpot != null) {
			phoenix.player.Lobby.currentSpot = phoenix.player.Lobby.createSpot
			phoenix.player.Lobby.applyLobbyCamera()
			return
		}
		phoenix.player.Lobby.pickSpot()
		phoenix.player.Lobby.applyLobbyCamera()
	}

	function applySelectCamera() {
		if (phoenix.player.Lobby.selectSpot != null) {
			phoenix.player.Lobby.currentSpot = phoenix.player.Lobby.selectSpot
			phoenix.player.Lobby.applyLobbyCamera()
			return
		}
		phoenix.player.Lobby.pickSpot()
		phoenix.player.Lobby.applyLobbyCamera()
	}

	function _parseSpots(raw) {
		local result = []
		local trimmed = raw
		try { trimmed = raw.tostring() } catch (e) { return null }
		if (trimmed == null || trimmed == "") return null
		local entries = []
		local depth = 0
		local start = -1
		for (local i = 0; i < trimmed.len(); i += 1) {
			local ch = trimmed[i]
			if (ch == '{') {
				if (depth == 0) start = i
				depth += 1
			} else if (ch == '}') {
				depth -= 1
				if (depth == 0 && start >= 0) { entries.append(trimmed.slice(start, i + 1)); start = -1 }
			}
		}
		foreach (entry in entries) {
			local x = phoenix.player.Lobby._readNumber(entry, "x")
			local y = phoenix.player.Lobby._readNumber(entry, "y")
			local z = phoenix.player.Lobby._readNumber(entry, "z")
			local rx = phoenix.player.Lobby._readNumber(entry, "rotX")
			local ry = phoenix.player.Lobby._readNumber(entry, "rotY")
			local rz = phoenix.player.Lobby._readNumber(entry, "rotZ")
			result.append({ pos = { x = x, y = y, z = z }, rot = { x = rx, y = ry, z = rz } })
		}
		return result
	}

	function _readNumber(text, key) {
		local needle = "\"" + key + "\""
		local at = text.find(needle)
		if (at == null) return 0.0
		local after = text.slice(at + needle.len())
		local n = ""
		local started = false
		for (local i = 0; i < after.len(); i += 1) {
			local ch = after[i]
			if (ch == ',' || ch == '}') break
			if ((ch >= '0' && ch <= '9') || ch == '-' || ch == '.' || ch == 'e' || ch == 'E' || ch == '+') { n += ch.tochar(); started = true }
			else if (started) break
		}
		try { return n.tofloat() } catch (e) { return 0.0 }
	}

	function pickSpot() {
		local idx = (rand() % phoenix.player.Lobby.cameraSpots.len())
		phoenix.player.Lobby.currentSpot = phoenix.player.Lobby.cameraSpots[idx]
	}

	function applyLobbyCamera() {
		local s = phoenix.player.Lobby.currentSpot
		if (s == null) return
		try { Camera.movementEnabled = false } catch (e) {}
		try { Camera.modeChangeEnabled = false } catch (e) {}
		try { Camera.setPosition(s.pos.x, s.pos.y, s.pos.z) } catch (e) {}
		try { Camera.setRotation(s.rot.x, s.rot.y, s.rot.z) } catch (e) {}
	}

	function onWebReady() {
		phoenix.player.Lobby.pickSpot()
		phoenix.player.Lobby.applyLobbyCamera()

		setTimer(phoenix.player.Lobby.applyLobbyCamera, 100, 4)
		phoenix.account.Interface.showLogin()
	}

	function onCharacterSelected(_characterId, _name) {

		try { Camera.movementEnabled = true } catch (e) {}
		try { Camera.modeChangeEnabled = true } catch (e) {}
		try { Camera.setTargetPlayer(heroId) } catch (e) {}
	}
}

addEventHandler("phoenix.web.OnReady", phoenix.player.Lobby.onWebReady)
addEventHandler("phoenix.character.OnSelected", phoenix.player.Lobby.onCharacterSelected)
phoenix.player.Message.LobbyConfig.bind(phoenix.player.Lobby.applyServerConfig)
addEventHandler("onRender", function() {

	if (phoenix.player.Lobby.currentSpot == null) return
	if (phoenix.character.Preview.active) return
	if (phoenix.player.Controls.dettached) phoenix.player.Lobby.applyLobbyCamera()
})
