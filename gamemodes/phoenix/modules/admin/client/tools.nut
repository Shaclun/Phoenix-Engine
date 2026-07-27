phoenix.admin.Tools <- {
	flying = false
	freecam = false
	godmode = false
	mapOpen = false
	flyPosition = null
	flyYaw = 0.0
	flyLastTick = 0
	flySpeed = 0.35
	flyTurnSpeed = 0.12
	freecamCameraPaused = false
	freecamPosition = null
	freecamYaw = 0.0
	freecamPitch = 0.0
	freecamLastTick = 0
	freecamSpeed = 0.5

	function isAdmin() {
		try { return phoenix.account.Model.role == 1 } catch (e) {}
		return false
	}

	function notify(title, text) {
		try {
			phoenix.web.Manager.emit("phoenix:notification:show", {
				kind = "info",
				title = title,
				text = text,
				durationMs = 2200
			})
		} catch (e) {}
	}

	function emitState() {
		try {
			phoenix.web.Manager.emit("phoenix:adminmap:state", {
				fly = phoenix.admin.Tools.flying,
				freecam = phoenix.admin.Tools.freecam,
				godmode = phoenix.admin.Tools.godmode
			})
		} catch (e) {}
	}

	function applyPlayerLock() {
		local frozen = phoenix.admin.Tools.flying || phoenix.admin.Tools.freecam || phoenix.admin.Tools.mapOpen
		local controlsLocked = phoenix.admin.Tools.flying || phoenix.admin.Tools.freecam || phoenix.admin.Tools.mapOpen
		try { setFreeze(frozen) } catch (e) {}
		try { disableControls(controlsLocked) } catch (e) {}
	}

	function applyFly(enabled, showNotification = true) {
		local nextState = enabled == true || enabled == 1
		local changed = phoenix.admin.Tools.flying != nextState
		phoenix.admin.Tools.flying = nextState
		phoenix.admin.Tools.flyPosition = null
		phoenix.admin.Tools.flyLastTick = getTickCount()
		if (phoenix.admin.Tools.flying) {
			try {
				local pos = getPlayerPosition(heroId)
				if (pos != null) phoenix.admin.Tools.flyPosition = { x = pos.x.tofloat(), y = pos.y.tofloat(), z = pos.z.tofloat() }
				phoenix.admin.Tools.flyYaw = getPlayerAngle(heroId).tofloat()
			} catch (e) {}
		}
		try { setPlayerCollision(heroId, !phoenix.admin.Tools.flying) } catch (e) {}
		phoenix.admin.Tools.applyPlayerLock()
		phoenix.admin.Tools.emitState()
		if (showNotification && changed) phoenix.admin.Tools.notify("Fly", phoenix.admin.Tools.flying ? "Latanie wlaczone" : "Latanie wylaczone")
	}

	function applyFreecam() {
		if (phoenix.admin.Tools.freecam) {
			if (phoenix.admin.Tools.freecamPosition == null) {
				try {
					local camPos = Camera.getPosition()
					phoenix.admin.Tools.freecamPosition = { x = camPos.x.tofloat(), y = camPos.y.tofloat(), z = camPos.z.tofloat() }
				} catch (e) {}
				try {
					if (phoenix.camera.Structure.orbitalCamera != null) {
						phoenix.admin.Tools.freecamYaw = phoenix.camera.Structure.orbitalCamera.yaw - 180.0
						phoenix.admin.Tools.freecamPitch = phoenix.camera.Structure.orbitalCamera.pitch
					}
				} catch (e) {}
				phoenix.admin.Tools.freecamLastTick = getTickCount()
			}
			if (!phoenix.admin.Tools.freecamCameraPaused) {
				try { phoenix.camera.Structure.freeze(); phoenix.admin.Tools.freecamCameraPaused = true } catch (e) {}
			}
			try { if (phoenix.camera.Structure.orbitalCamera != null) phoenix.camera.Structure.orbitalCamera.setEnabled(false) } catch (e) {}
			try { Camera.movementEnabled = false } catch (e) {}
			try { Camera.modeChangeEnabled = false } catch (e) {}
		} else {
			phoenix.admin.Tools.freecamPosition = null
			try { Camera.movementEnabled = false } catch (e) {}
			try { Camera.modeChangeEnabled = false } catch (e) {}
			if (phoenix.admin.Tools.freecamCameraPaused) {
				try { phoenix.camera.Structure.release() } catch (e) {}
				phoenix.admin.Tools.freecamCameraPaused = false
			}
		}
		phoenix.admin.Tools.applyPlayerLock()
	}
	function openMap() {
		if (!phoenix.admin.Tools.isAdmin() || phoenix.admin.Tools.mapOpen) return
		try { if (phoenix.ui.ActiveGui.isAnyOpen()) return } catch (e) {}
		phoenix.admin.Tools.mapOpen = true
		try { phoenix.ui.ActiveGui.set("adminMap") } catch (e) {}
		try { phoenix.web.Manager.activate() } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:adminmap:open", null) } catch (e) {}
		phoenix.admin.Tools.emitState()
	}

	function closeMap() {
		if (!phoenix.admin.Tools.mapOpen) return
		phoenix.admin.Tools.mapOpen = false
		try { phoenix.web.Manager.emit("phoenix:adminmap:close", null) } catch (e) {}
		try { if (phoenix.ui.ActiveGui.is("adminMap")) phoenix.ui.ActiveGui.clear() } catch (e) {}
		try { phoenix.web.Manager.deactivate() } catch (e) {}
		phoenix.admin.Tools.applyFreecam()
	}

	function requestFly() {
		if (!phoenix.admin.Tools.isAdmin()) return
		phoenix.admin.Model.send("adminFly", null)
	}

	function requestGodmode() {
		if (!phoenix.admin.Tools.isAdmin()) return
		phoenix.admin.Model.send("adminGodmode", null)
	}

	function toggleFreecam() {
		if (!phoenix.admin.Tools.isAdmin()) return
		phoenix.admin.Tools.freecam = !phoenix.admin.Tools.freecam
		if (phoenix.admin.Tools.mapOpen) phoenix.admin.Tools.closeMap()
		else phoenix.admin.Tools.applyFreecam()
		phoenix.admin.Tools.emitState()
		phoenix.admin.Tools.notify("Freecam", phoenix.admin.Tools.freecam ? "Freecam wlaczony" : "Freecam wylaczony")
	}

	function onFlyTick() {
		if (!phoenix.admin.Tools.flying) return
		if (phoenix.admin.Tools.flyPosition == null) {
			try {
				local current = getPlayerPosition(heroId)
				if (current != null) phoenix.admin.Tools.flyPosition = { x = current.x.tofloat(), y = current.y.tofloat(), z = current.z.tofloat() }
			} catch (e) {}
		}
		if (phoenix.admin.Tools.flyPosition == null) return
		local now = getTickCount()
		local elapsed = now - phoenix.admin.Tools.flyLastTick
		phoenix.admin.Tools.flyLastTick = now
		if (elapsed < 1) elapsed = 1
		if (elapsed > 50) elapsed = 50
		local inputEnabled = !phoenix.admin.Tools.freecam && !phoenix.admin.Tools.mapOpen
		try { if (phoenix.chat.Client.inputOpen) inputEnabled = false } catch (e) {}
		try { if (phoenix.ui.ActiveGui.isAnyOpen()) inputEnabled = false } catch (e) {}
		local angle = phoenix.admin.Tools.flyYaw
		if (inputEnabled) {
			local step = phoenix.admin.Tools.flySpeed * elapsed
			try { if (isKeyPressed(KEY_LSHIFT) || isKeyPressed(KEY_RSHIFT)) step *= 3.0 } catch (e) {}
			local turnStep = phoenix.admin.Tools.flyTurnSpeed * elapsed
			try { if (isKeyPressed(KEY_Q)) angle -= turnStep } catch (e) {}
			try { if (isKeyPressed(KEY_E)) angle += turnStep } catch (e) {}
			while (angle >= 360.0) angle -= 360.0
			while (angle < 0.0) angle += 360.0
			phoenix.admin.Tools.flyYaw = angle
			local rad = angle * 3.14159265 / 180.0
			try { if (isKeyPressed(KEY_W) || isKeyPressed(KEY_UP)) { phoenix.admin.Tools.flyPosition.x += sin(rad) * step; phoenix.admin.Tools.flyPosition.z += cos(rad) * step } } catch (e) {}
			try { if (isKeyPressed(KEY_S) || isKeyPressed(KEY_DOWN)) { phoenix.admin.Tools.flyPosition.x -= sin(rad) * step; phoenix.admin.Tools.flyPosition.z -= cos(rad) * step } } catch (e) {}
			try { if (isKeyPressed(KEY_A) || isKeyPressed(KEY_LEFT)) { phoenix.admin.Tools.flyPosition.x -= cos(rad) * step; phoenix.admin.Tools.flyPosition.z += sin(rad) * step } } catch (e) {}
			try { if (isKeyPressed(KEY_D) || isKeyPressed(KEY_RIGHT)) { phoenix.admin.Tools.flyPosition.x += cos(rad) * step; phoenix.admin.Tools.flyPosition.z -= sin(rad) * step } } catch (e) {}
			try { if (isKeyPressed(KEY_SPACE)) phoenix.admin.Tools.flyPosition.y += step } catch (e) {}
			try { if (isKeyPressed(KEY_LCONTROL) || isKeyPressed(KEY_RCONTROL) || isKeyPressed(KEY_X)) phoenix.admin.Tools.flyPosition.y -= step } catch (e) {}
		}
		try { setPlayerAngle(heroId, angle) } catch (e) {}
		try { setPlayerPosition(heroId, phoenix.admin.Tools.flyPosition.x, phoenix.admin.Tools.flyPosition.y, phoenix.admin.Tools.flyPosition.z) } catch (e) {}
	}

	function onFreecamTick() {
		if (!phoenix.admin.Tools.freecam || phoenix.admin.Tools.mapOpen || phoenix.admin.Tools.freecamPosition == null) return
		local now = getTickCount()
		local elapsed = now - phoenix.admin.Tools.freecamLastTick
		phoenix.admin.Tools.freecamLastTick = now
		if (elapsed < 1) elapsed = 1
		if (elapsed > 50) elapsed = 50
		local step = phoenix.admin.Tools.freecamSpeed * elapsed
		try { if (isKeyPressed(KEY_LSHIFT) || isKeyPressed(KEY_RSHIFT)) step *= 3.0 } catch (e) {}
		local yawRad = phoenix.admin.Tools.freecamYaw * 3.14159265 / 180.0
		local pitchRad = phoenix.admin.Tools.freecamPitch * 3.14159265 / 180.0
		local horizontal = cos(pitchRad)
		try { if (isKeyPressed(KEY_W) || isKeyPressed(KEY_UP)) { phoenix.admin.Tools.freecamPosition.x += sin(yawRad) * horizontal * step; phoenix.admin.Tools.freecamPosition.y -= sin(pitchRad) * step; phoenix.admin.Tools.freecamPosition.z += cos(yawRad) * horizontal * step } } catch (e) {}
		try { if (isKeyPressed(KEY_S) || isKeyPressed(KEY_DOWN)) { phoenix.admin.Tools.freecamPosition.x -= sin(yawRad) * horizontal * step; phoenix.admin.Tools.freecamPosition.y += sin(pitchRad) * step; phoenix.admin.Tools.freecamPosition.z -= cos(yawRad) * horizontal * step } } catch (e) {}
		try { if (isKeyPressed(KEY_A) || isKeyPressed(KEY_LEFT)) { phoenix.admin.Tools.freecamPosition.x -= cos(yawRad) * step; phoenix.admin.Tools.freecamPosition.z += sin(yawRad) * step } } catch (e) {}
		try { if (isKeyPressed(KEY_D) || isKeyPressed(KEY_RIGHT)) { phoenix.admin.Tools.freecamPosition.x += cos(yawRad) * step; phoenix.admin.Tools.freecamPosition.z -= sin(yawRad) * step } } catch (e) {}
		try { if (isKeyPressed(KEY_SPACE)) phoenix.admin.Tools.freecamPosition.y += step } catch (e) {}
		try { if (isKeyPressed(KEY_LCONTROL) || isKeyPressed(KEY_RCONTROL) || isKeyPressed(KEY_X)) phoenix.admin.Tools.freecamPosition.y -= step } catch (e) {}
		try { Camera.setPosition(phoenix.admin.Tools.freecamPosition.x, phoenix.admin.Tools.freecamPosition.y, phoenix.admin.Tools.freecamPosition.z) } catch (e) {}
		try { Camera.setRotation(phoenix.admin.Tools.freecamPitch, phoenix.admin.Tools.freecamYaw, 0.0) } catch (e) {}
	}

	function onFreecamMouseMove(x, y) {
		if (!phoenix.admin.Tools.freecam || phoenix.admin.Tools.mapOpen) return
		if (x == 0 && y == 0) return
		phoenix.admin.Tools.freecamYaw -= x * 0.15
		phoenix.admin.Tools.freecamPitch += y * 0.15
		while (phoenix.admin.Tools.freecamYaw >= 360.0) phoenix.admin.Tools.freecamYaw -= 360.0
		while (phoenix.admin.Tools.freecamYaw < 0.0) phoenix.admin.Tools.freecamYaw += 360.0
		if (phoenix.admin.Tools.freecamPitch > 89.0) phoenix.admin.Tools.freecamPitch = 89.0
		if (phoenix.admin.Tools.freecamPitch < -89.0) phoenix.admin.Tools.freecamPitch = -89.0
	}

	function onKeyDown(key) {
		try { if (phoenix.chat.Client.inputOpen) return } catch (e) {}
		if (!phoenix.admin.Tools.isAdmin()) return
		if (key == KEY_M) {
			if (phoenix.admin.Tools.mapOpen) phoenix.admin.Tools.closeMap()
			else phoenix.admin.Tools.openMap()
			return
		}
		if (key == KEY_ESCAPE && phoenix.admin.Tools.mapOpen) phoenix.admin.Tools.closeMap()
	}
	function resolveTeleportY(x, z) {
		try {
			local origin = Vec3(x.tofloat(), 100000.0, z.tofloat())
			local direction = Vec3(0.0, -200000.0, 0.0)
			local report = GameWorld.traceRayNearestHit(origin, direction, TRACERAY_STAT_POLY | TRACERAY_POLY_NORMAL | TRACERAY_VOB_IGNORE_NO_CD_DYN)
			if (report != null) return report.intersect.y.tofloat() + 120.0
		} catch (e) {}
		return null
	}

	function onMapTeleport(payload) {
		if (!phoenix.admin.Tools.isAdmin() || payload == null || !("x" in payload) || !("z" in payload)) return
		local y = phoenix.admin.Tools.resolveTeleportY(payload.x, payload.z)
		if (y == null) {
			phoenix.admin.Tools.notify("Teleport", "Nie znaleziono bezpiecznego podloza")
			return
		}
		payload.y <- y
		phoenix.admin.Model.send("adminMapTeleport", payload)
		phoenix.admin.Tools.closeMap()
	}

	function onMapTool(payload) {
		if (!phoenix.admin.Tools.isAdmin() || payload == null || !("action" in payload)) return
		if (payload.action == "fly") phoenix.admin.Tools.requestFly()
		else if (payload.action == "freecam") phoenix.admin.Tools.toggleFreecam()
		else if (payload.action == "godmode") phoenix.admin.Tools.requestGodmode()
	}

	function onResponse(message) {
		if (message.action == "adminFly") {
			if (!message.success) {
				phoenix.admin.Tools.notify("Fly", "Nie mozna przelaczyc latania")
				return
			}
			local enabled = false
			try { enabled = message.payload.enabled == true || message.payload.enabled == 1 } catch (e) {}
			phoenix.admin.Tools.applyFly(enabled)
			return
		}
		if (message.action == "adminGodmode") {
			if (!message.success) {
				phoenix.admin.Tools.notify("Godmode", "Nie mozna przelaczyc godmode")
				return
			}
			local enabled = false
			try { enabled = message.payload.enabled == true || message.payload.enabled == 1 } catch (e) {}
			phoenix.admin.Tools.godmode = enabled
			phoenix.admin.Tools.emitState()
			phoenix.admin.Tools.notify("Godmode", enabled ? "Godmode wlaczony" : "Godmode wylaczony")
			return
		}
		if (message.action == "adminMapTeleport" && message.success && phoenix.admin.Tools.flying) {
			try {
				phoenix.admin.Tools.flyPosition = {
					x = message.payload.x.tofloat(),
					y = message.payload.y.tofloat(),
					z = message.payload.z.tofloat()
				}
			} catch (e) {}
		}
	}

	function reset() {
		if (phoenix.admin.Tools.mapOpen) phoenix.admin.Tools.closeMap()
		phoenix.admin.Tools.flying = false
		phoenix.admin.Tools.flyPosition = null
		phoenix.admin.Tools.flyLastTick = 0
		phoenix.admin.Tools.freecam = false
		phoenix.admin.Tools.godmode = false
		try { setPlayerCollision(heroId, true) } catch (e) {}
		phoenix.admin.Tools.applyFreecam()
		phoenix.admin.Tools.emitState()
	}
}

addEventHandler("onKeyDown", function(key) { phoenix.admin.Tools.onKeyDown(key) })
addEventHandler("onRender", function() {
	phoenix.admin.Tools.onFlyTick()
	phoenix.admin.Tools.onFreecamTick()
})
addEventHandler("onMouseMove", function(x, y) { phoenix.admin.Tools.onFreecamMouseMove(x, y) })
local phoenixAdminAuthenticatedEvent = "phoenix.account." + "OnAuthenticated"
addEventHandler(phoenixAdminAuthenticatedEvent, function() {
	if (!phoenix.admin.Tools.isAdmin()) phoenix.admin.Tools.reset()
})
addEventHandler("phoenix.character.OnSelected", function(_characterId, _name) {
	phoenix.admin.Tools.reset()
})
phoenix.web.Router.on("phoenix:adminmap:close", function(_payload) { phoenix.admin.Tools.closeMap() })
phoenix.web.Router.on("phoenix:adminmap:teleport", phoenix.admin.Tools.onMapTeleport)
phoenix.web.Router.on("phoenix:adminmap:tool", phoenix.admin.Tools.onMapTool)
try { phoenix.ui.ActiveGui.register("adminMap", phoenix.admin.Tools.closeMap) } catch (e) {}