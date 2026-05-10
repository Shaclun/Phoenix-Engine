

local DEG_TO_RAD = PI / 180.0
local RAD_TO_DEG = 180.0 / PI

class phoenix.camera.OrbitalCamera {

	distance = 400.0
	minDistance = 80.0
	maxDistance = 600.0

	yaw = 0.0
	pitch = 25.0
	defaultPitch = 25.0

	yawSpeed = 0.15
	pitchSpeed = 0.15
	zoomSpeed = 25.0

	targetVob = null
	targetNode = ""

	isPitchInverted = false
	collisionEnabled = true
	alphaFadeEnabled = true

	followLerp = 0.025

	currentVisualAlpha = 1.0
	maxVisualAlpha = 1.0

	isActive = true
	isRightMouseDown = false
	isFrozen = false
	lockedPlayerAngle = 0.0

	lerpRatio = 0.15
	currentCamX = 0.0
	currentCamY = 0.0
	currentCamZ = 0.0

	smoothTargetX = 0.0
	smoothTargetY = 0.0
	smoothTargetZ = 0.0
	targetSmoothLerp = 0.1

	_onMouseMoveHandler = null
	_onMouseWheelHandler = null
	_onRenderHandler = null
	_onMouseDownHandler = null
	_onMouseUpHandler = null

	constructor(targetVob, targetNode = "") {
		this.targetVob = targetVob
		this.targetNode = targetNode

		local playerRot = getPlayerAngle(heroId)
		yaw = playerRot + 180.0
		yaw = (yaw % 360 + 360) % 360
		lockedPlayerAngle = playerRot

		local camPos = Camera.getPosition()
		currentCamX = camPos.x
		currentCamY = camPos.y
		currentCamZ = camPos.z

		try {
			local initMatrix = targetVob.getTrafoModelNodeToWorld(targetNode)
			local initPos = initMatrix.getTranslation()
			smoothTargetX = initPos.x
			smoothTargetY = initPos.y
			smoothTargetZ = initPos.z
		} catch (e) {
			local pos = getPlayerPosition(heroId)
			smoothTargetX = pos.x
			smoothTargetY = pos.y + 100.0
			smoothTargetZ = pos.z
		}

		try {
			currentVisualAlpha = targetVob.visualAlpha
			maxVisualAlpha = targetVob.visualAlpha
		} catch (e) {}

		Camera.movementEnabled = false
		Camera.modeChangeEnabled = false

		_onMouseMoveHandler = onMouseMove.bindenv(this)
		_onMouseWheelHandler = onMouseWheel.bindenv(this)
		_onRenderHandler = update.bindenv(this)
		_onMouseDownHandler = onMouseDown.bindenv(this)
		_onMouseUpHandler = onMouseUp.bindenv(this)

		addEventHandler("onMouseMove", _onMouseMoveHandler)
		addEventHandler("onMouseWheel", _onMouseWheelHandler)
		addEventHandler("onRender", _onRenderHandler)
		addEventHandler("onMouseDown", _onMouseDownHandler)
		addEventHandler("onMouseUp", _onMouseUpHandler)
	}

	function destroy() {
		isActive = false
		try { removeEventHandler("onMouseMove", _onMouseMoveHandler) } catch (e) {}
		try { removeEventHandler("onMouseWheel", _onMouseWheelHandler) } catch (e) {}
		try { removeEventHandler("onRender", _onRenderHandler) } catch (e) {}
		try { removeEventHandler("onMouseDown", _onMouseDownHandler) } catch (e) {}
		try { removeEventHandler("onMouseUp", _onMouseUpHandler) } catch (e) {}
		if (targetVob != null) {
			try { targetVob.visualAlpha = maxVisualAlpha } catch (e) {}
		}
		try { Camera.movementEnabled = true } catch (e) {}
		try { Camera.modeChangeEnabled = true } catch (e) {}
		if (isFrozen) {
			try { setFreeze(false) } catch (e) {}
			isFrozen = false
		}
		targetVob = null
	}

	function onMouseDown(button) {
		if (!isActive) return
		if (button == MOUSE_BUTTONRIGHT) {
			isRightMouseDown = true
			lockedPlayerAngle = getPlayerAngle(heroId)
			local isMoving = isKeyPressed(KEY_W) || isKeyPressed(KEY_S) || isKeyPressed(KEY_A) || isKeyPressed(KEY_D)
				|| isKeyPressed(KEY_UP) || isKeyPressed(KEY_DOWN) || isKeyPressed(KEY_LEFT) || isKeyPressed(KEY_RIGHT)
			if (!isMoving) {
				setFreeze(true)
				isFrozen = true
			}
		}
	}

	function onMouseUp(button) {
		if (!isActive) return
		if (button == MOUSE_BUTTONRIGHT) {
			isRightMouseDown = false
			if (isFrozen) {
				setFreeze(false)
				isFrozen = false
			}
		}
	}

	function onMouseMove(x, y) {
		if (!isActive) return
		if (!isRightMouseDown) return
		if (x == 0 && y == 0) return
		local pitchMultiplier = isPitchInverted ? -1 : 1
		yaw -= x * yawSpeed
		pitch += y * pitchSpeed * pitchMultiplier
		yaw = (yaw % 360 + 360) % 360
		pitch = clamp(pitch, 10.0, 85.0)
	}

	function onMouseWheel(direction) {
		if (!isActive) return
		try { if (phoenix.ui.ActiveGui.isAnyOpen()) return } catch (e) {}
		distance -= direction * zoomSpeed
		distance = clamp(distance, minDistance, maxDistance)
	}

	function update() {
		if (!isActive || targetVob == null) return

		if (isRightMouseDown && isFrozen) {
			if (isKeyPressed(KEY_W) || isKeyPressed(KEY_S) || isKeyPressed(KEY_A) || isKeyPressed(KEY_D)
				|| isKeyPressed(KEY_UP) || isKeyPressed(KEY_DOWN) || isKeyPressed(KEY_LEFT) || isKeyPressed(KEY_RIGHT)) {
				setFreeze(false)
				isFrozen = false
			}
		}

		if (isRightMouseDown && !isFrozen) {
			setPlayerAngle(heroId, lockedPlayerAngle)
		}

		if (isRightMouseDown && !isFrozen) {
			if (!isKeyPressed(KEY_W) && !isKeyPressed(KEY_S) && !isKeyPressed(KEY_A) && !isKeyPressed(KEY_D)
				&& !isKeyPressed(KEY_UP) && !isKeyPressed(KEY_DOWN) && !isKeyPressed(KEY_LEFT) && !isKeyPressed(KEY_RIGHT)) {
				setFreeze(true)
				isFrozen = true
			}
		}

		if (!isRightMouseDown) {
			local playerAngle = getPlayerAngle(heroId)
			local behindYaw = playerAngle + 180.0
			behindYaw = (behindYaw % 360 + 360) % 360
			local yawDiff = behindYaw - yaw
			if (yawDiff > 180.0) yawDiff -= 360.0
			if (yawDiff < -180.0) yawDiff += 360.0
			yaw += yawDiff * followLerp
			yaw = (yaw % 360 + 360) % 360
			local pitchDiff = defaultPitch - pitch
			pitch += pitchDiff * followLerp
		}

		local rawTargetX = smoothTargetX
		local rawTargetY = smoothTargetY
		local rawTargetZ = smoothTargetZ
		try {
			local targetVobMatrix = targetVob.getTrafoModelNodeToWorld(targetNode)
			local rawPos = targetVobMatrix.getTranslation()
			rawTargetX = rawPos.x
			rawTargetY = rawPos.y
			rawTargetZ = rawPos.z
		} catch (e) {
			local pp = getPlayerPosition(heroId)
			rawTargetX = pp.x
			rawTargetY = pp.y + 100.0
			rawTargetZ = pp.z
		}

		smoothTargetX = lerp(smoothTargetX, rawTargetX, targetSmoothLerp)
		smoothTargetY = lerp(smoothTargetY, rawTargetY, targetSmoothLerp)
		smoothTargetZ = lerp(smoothTargetZ, rawTargetZ, targetSmoothLerp)

		local targetVobPosition = { x = smoothTargetX, y = smoothTargetY, z = smoothTargetZ }

		local yawRad = yaw * DEG_TO_RAD
		local pitchRad = pitch * DEG_TO_RAD

		local verticalFactor = sin(pitchRad)
		local horizontalFactor = cos(pitchRad)

		local orbitalX = targetVobPosition.x + sin(yawRad) * distance * horizontalFactor
		local orbitalY = targetVobPosition.y + distance * verticalFactor
		local orbitalZ = targetVobPosition.z + cos(yawRad) * distance * horizontalFactor

		local currentDist = distance
		if (collisionEnabled) {
			local safeDistance = getSafeDistance(targetVobPosition, orbitalX, orbitalY, orbitalZ)
			if (safeDistance < distance) {
				currentDist = safeDistance
				orbitalX = targetVobPosition.x + sin(yawRad) * currentDist * horizontalFactor
				orbitalY = targetVobPosition.y + currentDist * verticalFactor
				orbitalZ = targetVobPosition.z + cos(yawRad) * currentDist * horizontalFactor
			}
		}

		currentCamX = lerp(currentCamX, orbitalX, lerpRatio)
		currentCamY = lerp(currentCamY, orbitalY, lerpRatio)
		currentCamZ = lerp(currentCamZ, orbitalZ, lerpRatio)

		local dx = targetVobPosition.x - currentCamX
		local dy = targetVobPosition.y - currentCamY
		local dz = targetVobPosition.z - currentCamZ

		local camYaw = atan2(dx, dz) * RAD_TO_DEG
		local horizDist = sqrt(dx * dx + dz * dz)
		local camPitch = -atan2(dy, horizDist) * RAD_TO_DEG

		Camera.setPosition(currentCamX, currentCamY, currentCamZ)
		Camera.setRotation(camPitch, camYaw, 0)

		if (alphaFadeEnabled) {
			updateAlpha(currentDist)
		}

		if (isRightMouseDown) {
			setPlayerAngle(heroId, lockedPlayerAngle)
		}
	}

	function getSafeDistance(vobPos, camX, camY, camZ) {
		try {
			local direction = Vec3(camX - vobPos.x, camY - vobPos.y, camZ - vobPos.z)
			local origin = Vec3(vobPos.x, vobPos.y, vobPos.z)
			local report = GameWorld.traceRayNearestHit(
				origin,
				direction,
				TRACERAY_STAT_POLY | TRACERAY_POLY_NORMAL | TRACERAY_VOB_IGNORE_NO_CD_DYN
			)
			if (report == null) return distance
			local dx = report.intersect.x - vobPos.x
			local dy = report.intersect.y - vobPos.y
			local dz = report.intersect.z - vobPos.z
			local hitDist = sqrt(dx*dx + dy*dy + dz*dz) - 30.0
			if (hitDist < minDistance) return minDistance
			return hitDist
		} catch (e) { return distance }
	}

	function updateAlpha(dist) {
		try {
			local targetRatio = maxVisualAlpha
			if (dist < 120) targetRatio = ((dist - 60) / 60.0) * maxVisualAlpha
			else if (pitch > 75) targetRatio = ((85.0 - pitch) / 10.0) * maxVisualAlpha
			targetRatio = clamp(targetRatio, 0.1, maxVisualAlpha)
			currentVisualAlpha = lerp(currentVisualAlpha, targetRatio, 0.1)
			targetVob.visualAlpha = currentVisualAlpha
		} catch (e) {}
	}

	function setDistance(newDistance) { distance = clamp(newDistance, minDistance, maxDistance) }
	function setRotation(newYaw, newPitch) {
		yaw = (newYaw % 360 + 360) % 360
		pitch = clamp(newPitch, 10.0, 85.0)
	}
	function setSensitivity(newYawSpeed, newPitchSpeed) {
		yawSpeed = newYawSpeed
		pitchSpeed = newPitchSpeed
	}
	function setEnabled(enabled) { isActive = enabled }
}
