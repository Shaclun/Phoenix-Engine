
phoenix.camera.Structure <- {
	orbitalCamera = null
	orbitalEnabled = true
	characterReady = false
	isActivated = false
	activationTimerId = null
	pauseDepth = 0

	function onCharacterSelected(_characterId, _name) {
		phoenix.camera.Structure.characterReady = true
		if (!phoenix.camera.Structure.orbitalEnabled) {
			phoenix.camera.Structure.destroyCamera()
			try { Camera.movementEnabled = true } catch (e) {}
			try { Camera.modeChangeEnabled = true } catch (e) {}
			return
		}
		if (phoenix.camera.Structure.isActivated && phoenix.camera.Structure.orbitalCamera != null) return
		phoenix.camera.Structure.isActivated = true
		if (phoenix.camera.Structure.activationTimerId != null) {
			try { removeTimer(phoenix.camera.Structure.activationTimerId) } catch (e) {}
			phoenix.camera.Structure.activationTimerId = null
		}
		phoenix.camera.Structure.activationTimerId = setTimer(phoenix.camera.Structure.activate, 800, 1)
	}

	function setOrbitalEnabled(value) {
		phoenix.camera.Structure.orbitalEnabled = value == true
		if (!phoenix.camera.Structure.orbitalEnabled) {
			local paused = phoenix.camera.Structure.pauseDepth > 0
			phoenix.camera.Structure.destroyCamera()
			try { Camera.movementEnabled = !paused } catch (e) {}
			try { Camera.modeChangeEnabled = !paused } catch (e) {}
			return
		}
		if (!phoenix.camera.Structure.characterReady) return
		phoenix.camera.Structure.isActivated = true
		phoenix.camera.Structure.activate()
		if (phoenix.camera.Structure.pauseDepth > 0 && phoenix.camera.Structure.orbitalCamera != null) {
			try { phoenix.camera.Structure.orbitalCamera.setEnabled(false) } catch (e) {}
			try { Camera.movementEnabled = false } catch (e2) {}
			try { Camera.modeChangeEnabled = false } catch (e3) {}
		}
	}

	function activate() {
		phoenix.camera.Structure.activationTimerId = null
		if (!phoenix.camera.Structure.orbitalEnabled) {
			phoenix.camera.Structure.destroyCamera()
			return
		}
		if (!phoenix.camera.Structure.characterReady) return
		if (phoenix.camera.Structure.orbitalCamera != null) return
		phoenix.camera.Structure.isActivated = true
		phoenix.camera.Structure.createForHero()
	}

	function createForHero() {
		if (!phoenix.camera.Structure.orbitalEnabled || !phoenix.camera.Structure.characterReady) return
		try { Camera.movementEnabled = true } catch (e) {}
		try { Camera.modeChangeEnabled = true } catch (e) {}

		local playerVob = null
		try { playerVob = Vob(getPlayerPtr(heroId)) } catch (e) { return }
		local cam = phoenix.camera.OrbitalCamera(playerVob, "BIP01 HEAD")
		cam.setDistance(400.0)
		cam.setSensitivity(0.15, 0.15)
		cam.minDistance = 80.0
		cam.maxDistance = 600.0
		cam.pitch = 25.0
		cam.lerpRatio = 0.15
		cam.collisionEnabled = true
		phoenix.camera.Structure.orbitalCamera = cam
	}

	function rebuildForHero() {
		if (!phoenix.camera.Structure.orbitalEnabled) {
			phoenix.camera.Structure.destroyCamera()
			phoenix.camera.Structure.pauseDepth = 0
			try { Camera.movementEnabled = true } catch (e) {}
			try { Camera.modeChangeEnabled = true } catch (e2) {}
			return
		}
		if (phoenix.camera.Structure.activationTimerId != null) {
			try { removeTimer(phoenix.camera.Structure.activationTimerId) } catch (e) {}
			phoenix.camera.Structure.activationTimerId = null
		}
		if (phoenix.camera.Structure.orbitalCamera != null) {
			try { phoenix.camera.Structure.orbitalCamera.destroy() } catch (e2) {}
			phoenix.camera.Structure.orbitalCamera = null
		}
		phoenix.camera.Structure.pauseDepth = 0
		phoenix.camera.Structure.characterReady = true
		phoenix.camera.Structure.isActivated = true
		phoenix.camera.Structure.createForHero()
		if (phoenix.camera.Structure.orbitalCamera != null) {
			try { phoenix.camera.Structure.orbitalCamera.setEnabled(true) } catch (e3) {}
		}
		try { Camera.movementEnabled = false } catch (e4) {}
		try { Camera.modeChangeEnabled = false } catch (e5) {}
	}

	function destroyCamera() {
		if (phoenix.camera.Structure.activationTimerId != null) {
			try { removeTimer(phoenix.camera.Structure.activationTimerId) } catch (e) {}
			phoenix.camera.Structure.activationTimerId = null
		}
		if (phoenix.camera.Structure.orbitalCamera != null) {
			try { phoenix.camera.Structure.orbitalCamera.destroy() } catch (e2) {}
			phoenix.camera.Structure.orbitalCamera = null
		}
		phoenix.camera.Structure.isActivated = false
	}

	function freeze() {
		phoenix.camera.Structure.pauseDepth += 1
		if (phoenix.camera.Structure.orbitalCamera != null) {
			try { phoenix.camera.Structure.orbitalCamera.setEnabled(false) } catch (e) {}
		}
		try { Camera.movementEnabled = false } catch (e) {}
		try { Camera.modeChangeEnabled = false } catch (e) {}
	}

	function release() {
		phoenix.camera.Structure.pauseDepth -= 1
		if (phoenix.camera.Structure.pauseDepth > 0) return
		phoenix.camera.Structure.pauseDepth = 0
		if (phoenix.camera.Structure.orbitalEnabled && phoenix.camera.Structure.orbitalCamera != null) {
			try { phoenix.camera.Structure.orbitalCamera.setEnabled(true) } catch (e) {}
			try { Camera.movementEnabled = false } catch (e) {}
			try { Camera.modeChangeEnabled = false } catch (e) {}
		} else {
			try { Camera.movementEnabled = true } catch (e) {}
			try { Camera.modeChangeEnabled = true } catch (e) {}
		}
	}
}

addEventHandler("phoenix.character.OnSelected", phoenix.camera.Structure.onCharacterSelected)

phoenix.web.Router.on("phoenix:camera:orbital:set", function(payload) {
	local enabled = true
	try { if (payload != null && "enabled" in payload) enabled = payload.enabled == true } catch (e) {}
	phoenix.camera.Structure.setOrbitalEnabled(enabled)
})
