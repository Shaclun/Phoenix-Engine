

phoenix.item.Interface <- {
	visible = false
	cameraWasActive = false
	cameraSettings = null

	function init() {
		addEventHandler("onKeyDown", function(key) { phoenix.item.Interface.onKeyDown(key) })
		phoenix.web.Router.on("phoenix:item:requestRefresh", phoenix.item.Interface.onRefresh)
		try { phoenix.ui.ActiveGui.register("inventory", phoenix.item.Interface.forceClose) } catch (e) {}
	}

	function isBusy() {
		try { if (phoenix.web.Manager.isUiBlocking()) return true } catch (e) {}
		try { if (phoenix.chat.Client.inputOpen) return true } catch (e) {}
		try { if (phoenix.chat.Client.menuOpen) return true } catch (e) {}
		try { if (!phoenix.chat.Client.chatVisible) return true } catch (e) {}
		return false
	}

	function stopHeroPose() {
		try { stopAni(heroId, "T_STAND_2_TALK") } catch (e) {}
		try { stopAni(heroId, "S_TALK") } catch (e) {}
		try { stopAni(heroId, "S_RUN") } catch (e) {}
		for (local i = 1; i <= 18; i += 1) {
			local suffix = i < 10 ? "0" + i : i.tostring()
			try { stopAni(heroId, "T_DIALOGGESTURE_" + suffix) } catch (eGesture) {}
		}
	}

	function onKeyDown(key) {
		if (key != KEY_I && key != KEY_TAB) return
		try { if (phoenix.chat.Client.inputOpen) return } catch (eChat) {}

		if (phoenix.item.Interface.visible) {
			phoenix.item.Interface.close()
			try { cancelEvent() } catch (e) {}
			return
		}
		if (phoenix.item.Interface.isBusy()) return
		phoenix.item.Interface.open()
		try { cancelEvent() } catch (e) {}
	}

	function open() {
		if (phoenix.item.Interface.visible) return
		phoenix.item.Interface.visible = true
		phoenix.item.Interface.cameraWasActive = false
		phoenix.item.Interface.cameraSettings = null
		try {
			phoenix.item.Interface.stopHeroPose()
			if (phoenix.camera.Structure.orbitalCamera == null) {
				phoenix.camera.Structure.activate()
			} else {
				phoenix.item.Interface.cameraWasActive = true
				phoenix.camera.Structure.orbitalCamera.setEnabled(true)
			}
			if (phoenix.camera.Structure.orbitalCamera != null) {
				phoenix.item.Interface.cameraSettings = {
					distance = phoenix.camera.Structure.orbitalCamera.distance,
					minDistance = phoenix.camera.Structure.orbitalCamera.minDistance,
					maxDistance = phoenix.camera.Structure.orbitalCamera.maxDistance,
					yaw = phoenix.camera.Structure.orbitalCamera.yaw,
					pitch = phoenix.camera.Structure.orbitalCamera.pitch,
					defaultPitch = phoenix.camera.Structure.orbitalCamera.defaultPitch,
					followLerp = phoenix.camera.Structure.orbitalCamera.followLerp,
					targetSmoothLerp = phoenix.camera.Structure.orbitalCamera.targetSmoothLerp,
					lerpRatio = phoenix.camera.Structure.orbitalCamera.lerpRatio,
					collisionEnabled = phoenix.camera.Structure.orbitalCamera.collisionEnabled
				}
				local playerAngle = 0.0
				try { playerAngle = getPlayerAngle(heroId) } catch (eAngle) {}
				phoenix.camera.Structure.orbitalCamera.minDistance = 180.0
				phoenix.camera.Structure.orbitalCamera.maxDistance = 520.0
				phoenix.camera.Structure.orbitalCamera.setDistance(340.0)
				phoenix.camera.Structure.orbitalCamera.setRotation(playerAngle, 18.0)
				phoenix.camera.Structure.orbitalCamera.defaultPitch = 18.0
				phoenix.camera.Structure.orbitalCamera.followLerp = 0.0
				phoenix.camera.Structure.orbitalCamera.targetSmoothLerp = 0.35
				phoenix.camera.Structure.orbitalCamera.setSensitivity(0.10, 0.10)
				phoenix.camera.Structure.orbitalCamera.lerpRatio = 0.32
				phoenix.camera.Structure.orbitalCamera.collisionEnabled = true
			}
		} catch (e) {}
		try { phoenix.web.Manager.show("inventory") } catch (e) {}
		try { phoenix.ui.ActiveGui.set("inventory") } catch (e) {}
		phoenix.item.Interface.stopHeroPose()

		phoenix.item.Interface.onRefresh(null)
	}

	function close() {
		if (!phoenix.item.Interface.visible) return
		phoenix.item.Interface.visible = false
		try { phoenix.web.Manager.hide() } catch (e) {}
		try {
			if (phoenix.ui.ActiveGui.is("inventory")) phoenix.ui.ActiveGui.clear()
		} catch (e) {}
		try {
			if (!phoenix.item.Interface.cameraWasActive && phoenix.camera.Structure.orbitalCamera != null) phoenix.camera.Structure.destroyCamera()
			else if (phoenix.camera.Structure.orbitalCamera != null) {
				local s = phoenix.item.Interface.cameraSettings
				if (s != null) {
					try { phoenix.camera.Structure.orbitalCamera.minDistance = s.minDistance } catch (eMin) {}
					try { phoenix.camera.Structure.orbitalCamera.maxDistance = s.maxDistance } catch (eMax) {}
					try { phoenix.camera.Structure.orbitalCamera.setDistance(s.distance) } catch (eDist) {}
					try { phoenix.camera.Structure.orbitalCamera.setRotation(s.yaw, s.pitch) } catch (eRot) {}
					try { phoenix.camera.Structure.orbitalCamera.defaultPitch = s.defaultPitch } catch (eDef) {}
					try { phoenix.camera.Structure.orbitalCamera.followLerp = s.followLerp } catch (eFollow) {}
					try { phoenix.camera.Structure.orbitalCamera.targetSmoothLerp = s.targetSmoothLerp } catch (eSmooth) {}
					try { phoenix.camera.Structure.orbitalCamera.lerpRatio = s.lerpRatio } catch (eLerp) {}
					try { phoenix.camera.Structure.orbitalCamera.collisionEnabled = s.collisionEnabled } catch (eCol) {}
				}
				try { Camera.movementEnabled = false } catch (e) {}
				try { Camera.modeChangeEnabled = false } catch (e) {}
			}
		} catch (e) {}
		phoenix.item.Interface.cameraSettings = null
	}

	function forceClose(_a = null, _b = null) {
		phoenix.item.Interface.close()
	}

	function onRefresh(_payload) {
		try {
			phoenix.web.Manager.emit("phoenix:item:inventory", {
				ownerType = phoenix.item.Model.ownerType,
				ownerId   = phoenix.item.Model.ownerId,
				gold      = phoenix.item.Model.gold,
				items     = phoenix.item.Model.items
			})
		} catch (e) {}
	}
}

phoenix.item.Interface.init()
