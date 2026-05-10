phoenix.player.Lobby <- {

	cameraSpots = [
		{ pos = { x = -107441.0, y = 4105.83, z = 131140.0 }, rot = { x = 20.0,  y = -30.0, z = 0.0 } },
		{ pos = { x = 1850.0,    y = 8500.0,  z = 5635.0   }, rot = { x = 35.0,  y = 0.0,   z = 0.0 } },
		{ pos = { x = -36000.0,  y = 6000.0,  z = 14000.0  }, rot = { x = 25.0,  y = 90.0,  z = 0.0 } },
		{ pos = { x = 21000.0,   y = 5000.0,  z = 4400.0   }, rot = { x = 15.0,  y = 180.0, z = 0.0 } },
		{ pos = { x = -19000.0,  y = 4500.0,  z = -12000.0 }, rot = { x = 10.0,  y = 270.0, z = 0.0 } }
	]
	currentSpot = null

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
addEventHandler("onRender", function() {

	if (phoenix.player.Lobby.currentSpot == null) return
	if (phoenix.character.Preview.active) return
	if (phoenix.player.Controls.dettached) phoenix.player.Lobby.applyLobbyCamera()
})
