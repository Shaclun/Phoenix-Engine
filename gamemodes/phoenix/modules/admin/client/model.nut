phoenix.admin.Model <- {
	invalidNpcId = -2147483648

	preview = {
		active = false,
		mode = "",
		npcId = -2147483648,
		cameraActive = false,
		orbitalCamera = null,
		cameraMode = "orbital",
		camDistance = 360.0,
		camPitch = 22.0,
		camYaw = 0.0,
		camDragging = false,
		cameraPaused = false,
		camLastMx = 0,
		camLastMy = 0,
		lastMoveAt = 0,
		instance = "",
		kind = "",
		x = 0.0,
		y = 0.0,
		z = 0.0,
		angle = 0.0,
		world = "",
		virtualWorld = 0,
		weapon = "",
		armor = "",
		ranged = "",
		bodyModel = "",
		headModel = "",
		bodyTex = 0,
		headTex = 0,
		orig = null
	}

	vobPreview = {
		active = false,
		obj = null,
		action = "adminHerbPreview",
		cameraActive = false,
		cameraPaused = false,
		camDistance = 360.0,
		camPitch = 22.0,
		camYaw = 0.0,
		camDragging = false,
		camLastMx = 0,
		camLastMy = 0,
		visual = "",
		instance = "",
		x = 0.0,
		y = 0.0,
		z = 0.0,
		rotX = 0.0,
		rotY = 0.0,
		rotZ = 0.0,
		interactive = false,
		lastMoveAt = 0
	}

	houseGhost = {
		active = false,
		obj = null,
		visual = "BOOTS.3DS",
		points = [],
		cameraActive = false,
		cameraPaused = false,
		camDistance = 360.0,
		camPitch = 22.0,
		camYaw = 0.0,
		camDragging = false,
		x = 0.0,
		y = 0.0,
		z = 0.0,
		rotY = 0.0,
		world = "",
		lastMoveAt = 0
	}

	routineGhost = {
		active = false,
		obj = null,
		markers = [],
		nodes = [],
		visual = "BOOTS.3DS",
		world = "",
		spawnId = 0,
		x = 0.0,
		y = 0.0,
		z = 0.0,
		rotY = 0.0,
		cameraActive = false,
		cameraPaused = false,
		camDistance = 360.0,
		camPitch = 22.0,
		camYaw = 0.0,
		camDragging = false,
		lastMoveAt = 0
	}

	spawnGhost = {
		active = false,
		mode = "spawn",
		useHuman = false,
		obj = null,
		arrow = null,
		npcId = -2147483648,
		visual = "BOOTS.3DS",
		arrowVisual = "ITAR_LARES.3DS",
		world = "",
		x = 0.0,
		y = 0.0,
		z = 0.0,
		angle = 0.0,
		camPitch = 0.0,
		camRoll = 0.0,
		cameraActive = false,
		cameraPaused = false,
		camDistance = 360.0,
		camCtrlPitch = 22.0,
		camYaw = 0.0,
		lastMoveAt = 0
	}

	ui = {
		locked = false,
		chatWasVisible = false,
		inputFocused = false
	}

	function handleLocal(action, payload) {
		if (action == "adminPanelOpen") { phoenix.admin.Model.lockUi(); return true }
		if (action == "adminPanelClose") { phoenix.admin.Model.unlockUi(); return true }
		if (action == "adminInputFocus") { phoenix.admin.Model.focusInput(); return true }
		if (action == "adminInputBlur") { phoenix.admin.Model.blurInput(); return true }
		if (action == "adminNpcPreviewStart") { phoenix.admin.Model.previewStart(payload); return true }
		if (action == "adminNpcPreviewUpdate") { phoenix.admin.Model.previewUpdate(payload); return true }
		if (action == "adminNpcPreviewNudge") { phoenix.admin.Model.previewNudge(payload); return true }
		if (action == "adminNpcPreviewAnim") { phoenix.admin.Model.previewAnim(payload); return true }
		if (action == "adminNpcPreviewStop") { phoenix.admin.Model.previewStop(); return true }
		if (action == "adminHerbPreviewStart") { phoenix.admin.Model.vobPreviewStart(payload); return true }
		if (action == "adminHerbPreviewUpdate") { phoenix.admin.Model.vobPreviewUpdate(payload); return true }
		if (action == "adminHerbPreviewNudge") { phoenix.admin.Model.vobPreviewNudge(payload); return true }
		if (action == "adminHerbPreviewFloor") { phoenix.admin.Model.vobPreviewFloor(); return true }
		if (action == "adminHerbPreviewStop") { phoenix.admin.Model.vobPreviewStop(); return true }
		if (action == "adminVobPreviewStart") { phoenix.admin.Model.vobPreviewStart(payload, "adminVobPreview"); return true }
		if (action == "adminVobPreviewUpdate") { phoenix.admin.Model.vobPreviewUpdate(payload, "adminVobPreview"); return true }
		if (action == "adminVobPreviewNudge") { phoenix.admin.Model.vobPreviewNudge(payload); return true }
		if (action == "adminVobPreviewFloor") { phoenix.admin.Model.vobPreviewFloor(); return true }
		if (action == "adminVobPreviewStop") { phoenix.admin.Model.vobPreviewStop(); return true }
		if (action == "adminHouseGhostStart") { phoenix.admin.Model.houseGhostStart(payload); return true }
		if (action == "adminHouseGhostSync") { phoenix.admin.Model.houseGhostSync(payload); return true }
		if (action == "adminHouseGhostFocus") { phoenix.admin.Model.houseGhostCameraStart(true); return true }
		if (action == "adminHouseGhostStop") { phoenix.admin.Model.houseGhostStop(); return true }
		if (action == "adminHouseCapture") { phoenix.admin.Model.houseCapture(payload); return true }
		if (action == "adminHouseBoundaryToggle") { try { phoenix.house.Ground.toggleAdminBoundaries(); return true } catch (e) {}; return true }
		if (action == "adminRoutineGhostStart") { phoenix.admin.Model.routineGhostStart(payload); return true }
		if (action == "adminRoutineGhostSync") { phoenix.admin.Model.routineGhostSync(payload); return true }
		if (action == "adminRoutineGhostStop") { phoenix.admin.Model.routineGhostStop(); return true }
		if (action == "adminSpawnGhostStart") { phoenix.admin.Model.spawnGhostStart(payload); return true }
		if (action == "adminSpawnGhostSync") { phoenix.admin.Model.spawnGhostSync(payload); return true }
		if (action == "adminSpawnGhostStop") { phoenix.admin.Model.spawnGhostStop(); return true }
		if (action == "adminSpawnGhostNudge") { phoenix.admin.Model.spawnGhostNudge(payload); return true }
		return false
	}

	function send(action, payload) {
		if (phoenix.admin.Model.handleLocal(action, payload)) return
		local m = phoenix.admin.Message.Request()
		m.action = action
		m.payload = payload
		m.serialize().send(RELIABLE_ORDERED)
	}

	function previewStart(payload) {
		if (preview.active) phoenix.admin.Model.previewStop()
		local requestedMode = (payload != null && "mode" in payload) ? payload.mode : "npc"
		local hasExplicitPos = payload != null && ("posX" in payload || "posY" in payload || "posZ" in payload)
		local p = null
		try { p = getPlayerPosition(heroId) } catch (e) {}
		if (hasExplicitPos) {
			if ("posX" in payload) preview.x = payload.posX.tofloat()
			if ("posY" in payload) preview.y = payload.posY.tofloat()
			if ("posZ" in payload) preview.z = payload.posZ.tofloat()
			if ("angle" in payload) preview.angle = payload.angle.tofloat()
		} else {
			if (p != null) { preview.x = p.x; preview.y = p.y; preview.z = p.z }
			try { preview.angle = getPlayerAngle(heroId) } catch (e) {}
			if (requestedMode != "human" && p != null) {
				local angleRad = preview.angle * 3.14159 / 180.0
				preview.x = p.x + sin(angleRad) * 180.0
				preview.z = p.z + cos(angleRad) * 180.0
			}
		}
		if (payload != null && "world" in payload && payload.world != "") {
			preview.world = payload.world
		} else {
			try { preview.world = getPlayerWorld(heroId) } catch (e) { try { preview.world = getWorld() } catch (e2) {} }
		}
		try { preview.virtualWorld = getPlayerVirtualWorld(heroId) } catch (e3) { preview.virtualWorld = 0 }
		preview.active = true
		preview.mode = requestedMode
		try { setCursorVisible(true) } catch (e) {}
		try { setFreeze(true) } catch (e) {}
		if (payload == null) payload = {}
		payload.posX <- preview.x
		payload.posY <- preview.y
		payload.posZ <- preview.z
		payload.angle <- preview.angle
		payload.world <- preview.world
		payload.virtualWorld <- preview.virtualWorld
		phoenix.admin.Model.previewUpdate(payload)
	}

	function previewUpdate(payload) {
		if (payload == null) payload = {}
		if (!preview.active) preview.active = true
		if ("mode" in payload) preview.mode = payload.mode
		if ("kind" in payload) preview.kind = payload.kind
		local oldCameraMode = preview.cameraMode
		if ("cameraMode" in payload) {
			local mode = payload.cameraMode.tostring()
			if (mode == "static" || mode == "orbital" || mode == "off") preview.cameraMode = mode
		}
		if (oldCameraMode != preview.cameraMode && preview.cameraActive) phoenix.admin.Model.previewCameraStop()
		local instance = ("instance" in payload && payload.instance != "") ? payload.instance.tostring() : (preview.instance != "" ? preview.instance : "PC_HERO")
		local needsRecreate = preview.npcId == phoenix.admin.Model.invalidNpcId || preview.instance != instance
		if (needsRecreate) phoenix.admin.Model.previewCreate(instance)
		if (needsRecreate) {
			if (preview.mode == "human") {
				try { setPlayerInstance(preview.npcId, instance.toupper()) } catch (e) { try { setPlayerInstance(preview.npcId, instance) } catch (e2) {} }
			} else {
				phoenix.admin.Model.previewSetMonsterInstance(instance)
			}
		}
		local hasVisualKey = "bodyModel" in payload || "headModel" in payload || "bodyTex" in payload || "headTex" in payload
		if (preview.mode == "human" && (needsRecreate || hasVisualKey)) {
			local body = ("bodyModel" in payload && payload.bodyModel != "") ? payload.bodyModel : (preview.bodyModel != "" ? preview.bodyModel : "Hum_Body_Naked0")
			local head = ("headModel" in payload && payload.headModel != "") ? payload.headModel : (preview.headModel != "" ? preview.headModel : "Hum_Head_Bald")
			local bodyTex = ("bodyTex" in payload) ? payload.bodyTex : preview.bodyTex
			local headTex = ("headTex" in payload) ? payload.headTex : preview.headTex
			local visualChanged = needsRecreate || body != preview.bodyModel || head != preview.headModel || bodyTex != preview.bodyTex || headTex != preview.headTex
			if (visualChanged) {
				try { setPlayerVisual(preview.npcId, body, bodyTex, head, headTex) } catch (e) {}
				preview.bodyModel = body
				preview.headModel = head
				preview.bodyTex = bodyTex
				preview.headTex = headTex
				if (!needsRecreate) {
					local cachedWeapon = preview.weapon
					local cachedArmor = preview.armor
					local cachedRanged = preview.ranged
					preview.weapon = ""
					preview.armor = ""
					preview.ranged = ""
					if (cachedWeapon != "") { phoenix.admin.Model.previewAutoStat(cachedWeapon); phoenix.admin.Model.previewEquip("weapon", cachedWeapon) }
					if (cachedArmor != "") phoenix.admin.Model.previewEquip("armor", cachedArmor)
					if (cachedRanged != "") { phoenix.admin.Model.previewAutoStat(cachedRanged); phoenix.admin.Model.previewEquip("ranged", cachedRanged) }
				}
			}
		}
		if (preview.mode == "human" && "fatness" in payload) {
			try { setPlayerFatness(preview.npcId, payload.fatness.tofloat()) } catch (e) {}
		}
		if ("scaleX" in payload || "scaleY" in payload || "scaleZ" in payload) {
			local sx = ("scaleX" in payload) ? payload.scaleX.tofloat() : 1.0
			local sy = ("scaleY" in payload) ? payload.scaleY.tofloat() : 1.0
			local sz = ("scaleZ" in payload) ? payload.scaleZ.tofloat() : 1.0
			try { setPlayerScale(preview.npcId, sx, sy, sz) } catch (e) {}
		}
		local hasPosKey = "posX" in payload || "posY" in payload || "posZ" in payload || "angle" in payload
		if ("posX" in payload) preview.x = payload.posX.tofloat()
		if ("posY" in payload) preview.y = payload.posY.tofloat()
		if ("posZ" in payload) preview.z = payload.posZ.tofloat()
		if ("angle" in payload) preview.angle = payload.angle.tofloat()
		if ("world" in payload && payload.world != "") preview.world = payload.world
		if ("virtualWorld" in payload) preview.virtualWorld = payload.virtualWorld.tointeger()
		if (needsRecreate || hasPosKey) phoenix.admin.Model.previewPlace()
		if (needsRecreate && preview.mode == "human") {
			if ("weapon" in payload && payload.weapon != "") phoenix.admin.Model.previewAutoStat(payload.weapon)
			if ("ranged" in payload && payload.ranged != "") phoenix.admin.Model.previewAutoStat(payload.ranged)
			if ("weapon" in payload) phoenix.admin.Model.previewEquip("weapon", payload.weapon)
			if ("armor" in payload) phoenix.admin.Model.previewEquip("armor", payload.armor)
			if ("ranged" in payload) phoenix.admin.Model.previewEquip("ranged", payload.ranged)
		} else {
			if ("weapon" in payload) {
				phoenix.admin.Model.previewAutoStat(payload.weapon)
				phoenix.admin.Model.previewEquip("weapon", payload.weapon)
			}
			if ("armor" in payload) phoenix.admin.Model.previewEquip("armor", payload.armor)
			if ("ranged" in payload) {
				phoenix.admin.Model.previewAutoStat(payload.ranged)
				phoenix.admin.Model.previewEquip("ranged", payload.ranged)
			}
		}
		phoenix.admin.Model.previewCameraStart()
		phoenix.admin.Model.previewEmit()
	}

	function previewAutoStat(instance) {
		if (preview.npcId == phoenix.admin.Model.invalidNpcId) return
		if (instance == null || instance == "") return
		try {
			local scheme = phoenix.item.find(instance)
			if (scheme == null || !("requirement" in scheme) || scheme.requirement == null) return
			foreach (r in scheme.requirement) {
				if (r == null || !("attr" in r) || !("value" in r)) continue
				local attr = r.attr.tostring()
				local val = r.value.tointeger()
				if (val <= 0) continue
				if (attr == "strength") {
					try { setPlayerStrength(preview.npcId, val) } catch (e) {}
				} else if (attr == "dexterity") {
					try { setPlayerDexterity(preview.npcId, val) } catch (e) {}
				}
			}
		} catch (e) {}
	}

	function previewCreate(instance) {
		if (preview.npcId != phoenix.admin.Model.invalidNpcId) {
			phoenix.admin.Model.previewCameraStop()
			phoenix.admin.Model.previewDestroyNpc()
		}
		preview.instance = instance
		preview.weapon = ""
		preview.armor = ""
		preview.ranged = ""
		preview.bodyModel = ""
		preview.headModel = ""
		preview.bodyTex = 0
		preview.headTex = 0
		local inst = instance.tostring().toupper()
		local engineInst = phoenix.admin.Model.previewEngineInstance(instance)
		preview.npcId = phoenix.admin.Model.previewCreateNpc(engineInst, inst, instance.tostring())
		if (preview.npcId == phoenix.admin.Model.invalidNpcId) return
		local spawned = false
		try { spawnNpc(preview.npcId); spawned = true } catch (e1) {}
		if (!spawned) { try { spawnNpc(preview.npcId, engineInst); spawned = true } catch (e2) {} }
		if (!spawned) { try { spawnNpc(preview.npcId, inst); spawned = true } catch (e3) {} }
		if (preview.mode == "human") {
			try { setPlayerInstance(preview.npcId, inst) } catch (eh) { try { setPlayerInstance(preview.npcId, instance) } catch (eh2) {} }
		} else {
			phoenix.admin.Model.previewSetMonsterInstance(instance)
		}
		phoenix.admin.Model.previewPlace()
		try { setPlayerVirtualWorld(preview.npcId, preview.virtualWorld) } catch (e6) {}
		phoenix.admin.Model.previewCameraStart()
	}

	function previewEngineInstance(instance) {
		if (instance == null) return ""
		local inst = instance.tostring()
		if (preview.mode != "human") return inst.tolower()
		return inst.toupper()
	}

	function previewCreateNpc(primary, secondary, tertiary) {
		local candidates = [primary, secondary, tertiary]
		foreach (candidate in candidates) {
			if (candidate == null || candidate == "") continue
			local npcId = phoenix.admin.Model.invalidNpcId
			try { npcId = createNpc(candidate) } catch (e) { npcId = phoenix.admin.Model.invalidNpcId }
			if (npcId != phoenix.admin.Model.invalidNpcId) return npcId
		}
		return phoenix.admin.Model.invalidNpcId
	}

	function previewSetMonsterInstance(instance) {
		if (preview.npcId == phoenix.admin.Model.invalidNpcId || preview.npcId == heroId) return
		local inst = instance.tostring()
		local engineInst = phoenix.admin.Model.previewEngineInstance(inst)
		local upperInst = inst.toupper()
		local applied = false
		try { setPlayerInstance(preview.npcId, engineInst); applied = true } catch (e) {}
		if (!applied) { try { setPlayerInstance(preview.npcId, upperInst); applied = true } catch (e2) {} }
		if (!applied) { try { setPlayerInstance(preview.npcId, inst); applied = true } catch (e3) {} }
	}

	function previewPlace() {
		if (preview.npcId == phoenix.admin.Model.invalidNpcId) return
		if (preview.npcId != heroId) {
			try { if (preview.world != "") setPlayerWorld(preview.npcId, preview.world, "") } catch (e2) {}
			try { setPlayerVirtualWorld(preview.npcId, preview.virtualWorld) } catch (e4) {}
		}
		try { setPlayerPosition(preview.npcId, preview.x, preview.y, preview.z) } catch (e) {}
		phoenix.admin.Model.previewApplyAngle()
	}

	function previewApplyAngle() {
		if (preview.npcId == phoenix.admin.Model.invalidNpcId) return
		try { setPlayerAngle(preview.npcId, preview.angle, true) } catch (e5) { try { setPlayerAngle(preview.npcId, preview.angle) } catch (e6) {} }
	}

	function lockUi() {
		if (ui.locked) return
		ui.locked = true
		try { phoenix.ui.ActiveGui.set("admin") } catch (e) {}
		ui.chatWasVisible = false
		try { ui.chatWasVisible = phoenix.chat.Client.chatVisible } catch (e) {}
		try { phoenix.chat.Client.closeInputLocal(false) } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:chat:hide", null) } catch (e) {}
		try { disableControls(true) } catch (e) {}
		try { setFreeze(true) } catch (e) {}
		try { phoenix.camera.Structure.freeze() } catch (e) {}
		try { Camera.movementEnabled = false } catch (e) {}
		try { Camera.modeChangeEnabled = false } catch (e) {}
		try { setCursorVisible(true) } catch (e) {}
	}

	function unlockUi() {
		if (!ui.locked) return
		ui.locked = false
		try { if (phoenix.ui.ActiveGui.is("admin")) phoenix.ui.ActiveGui.clear() } catch (e) {}
		phoenix.admin.Model.previewStop()
		phoenix.admin.Model.routineGhostStop()
		phoenix.admin.Model.spawnGhostStop()
		try { disableControls(false) } catch (e) {}
		try { setFreeze(false) } catch (e) {}
		try { phoenix.camera.Structure.release() } catch (e) {}
		phoenix.admin.Model.restoreWorldCamera()
		try { setCursorVisible(false) } catch (e) {}
		if (ui.chatWasVisible) {
			try { phoenix.web.Manager.emit("phoenix:chat:show", null) } catch (e) {}
		}
		ui.chatWasVisible = false
		ui.inputFocused = false
	}

	function focusInput() {
		ui.inputFocused = true
		try { phoenix.web.Manager.focusInput() } catch (e) {}
	}

	function blurInput() {
		ui.inputFocused = false
		try { phoenix.web.Manager.focusInput() } catch (e) {}
	}

	function restoreWorldCamera() {
		phoenix.admin.Model.restoreWorldCameraTick()
		try { setTimer(phoenix.admin.Model.restoreWorldCameraTick, 120, 1) } catch (e) {}
	}

	function restoreWorldCameraTick() {
		try { phoenix.camera.Structure.rebuildForHero() } catch (e) {
			try { phoenix.camera.Structure.pauseDepth = 0 } catch (e2) {}
			try { phoenix.camera.Structure.destroyCamera() } catch (e3) {}
			try { phoenix.camera.Structure.activate() } catch (e4) {}
			try { if (phoenix.camera.Structure.orbitalCamera != null) phoenix.camera.Structure.orbitalCamera.setEnabled(true) } catch (e5) {}
		}
		try { Camera.movementEnabled = false } catch (e6) {}
		try { Camera.modeChangeEnabled = false } catch (e7) {}
	}

	function previewCameraStart() {
		if (preview.npcId == phoenix.admin.Model.invalidNpcId) return
		if (preview.cameraActive) return
		if (preview.cameraMode == "off") {
			preview.cameraActive = true
			try { Camera.movementEnabled = false } catch (e) {}
			try { Camera.modeChangeEnabled = false } catch (e2) {}
			return
		}
		preview.cameraPaused = false
		if (!ui.locked) {
			try { phoenix.camera.Structure.freeze(); preview.cameraPaused = true } catch (e) {}
		}
		try { Camera.movementEnabled = false } catch (e2) {}
		try { Camera.modeChangeEnabled = false } catch (e3) {}
		preview.camDistance = 360.0
		preview.camPitch = 22.0
		preview.camYaw = preview.angle + 180.0
		preview.cameraActive = true
	}

	function previewCameraStop() {
		preview.cameraActive = false
		preview.camDragging = false
		if (preview.orbitalCamera != null) {
			try { preview.orbitalCamera.destroy() } catch (e) {}
			preview.orbitalCamera = null
		}
		if (preview.cameraPaused) {
			try { phoenix.camera.Structure.release() } catch (e) {}
		}
		preview.cameraPaused = false
	}

	function previewCameraTick() {
		if (!preview.cameraActive || preview.npcId == phoenix.admin.Model.invalidNpcId) return
		if (preview.cameraMode == "off") return
		local p = null
		try { p = getPlayerPosition(preview.npcId) } catch (e) {}
		if (p == null) return
		if (p.x == 0 && p.y == 0 && p.z == 0) return
		local npcAngle = preview.angle
		local finalAngle = preview.cameraMode == "orbital" ? preview.camYaw : (npcAngle + 180.0)
		local angleRad = finalAngle * 3.14159 / 180.0
		local cx = p.x + sin(angleRad) * preview.camDistance
		local cy = p.y + 100.0 + preview.camPitch
		local cz = p.z + cos(angleRad) * preview.camDistance
		try { Camera.setPosition(cx, cy, cz) } catch (e3) {}
		local dx = p.x - cx
		local dz = p.z - cz
		local dy = (p.y + 90.0) - cy
		local yaw = atan2(dx, dz) * 180.0 / 3.14159
		local d2 = sqrt(dx * dx + dz * dz)
		local pitch = -atan2(dy, d2) * 180.0 / 3.14159
		try { Camera.setRotation(pitch, yaw, 0) } catch (e4) {}
	}

	function previewEquip(slot, instance) {
		if (preview.npcId == phoenix.admin.Model.invalidNpcId) return
		local old = preview[slot]
		if (old == instance) return
		if (old != "") {
			try { unequipItem(preview.npcId, old) } catch (e) {}
			try { removeItem(preview.npcId, old, 1) } catch (e) {}
		}
		preview[slot] = instance
		if (instance == null || instance == "") return
		try { giveItem(preview.npcId, instance, 1) } catch (e) {}
		try { equipItem(preview.npcId, instance) } catch (e) {}
	}

	function previewAnim(payload) {
		if (preview.npcId == phoenix.admin.Model.invalidNpcId) return
		local ani = ""
		if (payload != null && "animation" in payload) ani = payload.animation
		try { stopAni(preview.npcId, "S_RUN") } catch (e) {}
		try { stopAni(preview.npcId, "T_STAND_2_TALK") } catch (e) {}
		try { stopAni(preview.npcId, "T_WARN") } catch (e) {}
		try { stopAni(preview.npcId, "T_1HATTACK") } catch (e) {}
		try { stopAni(preview.npcId, "T_2HATTACK") } catch (e) {}
		try { stopAni(preview.npcId, "T_FISTATTACK") } catch (e) {}
		if (ani != null && ani != "") { try { playAni(preview.npcId, ani) } catch (e) {} }
	}

	function previewNudge(payload) {
		if (payload == null) return
		local axis = ("axis" in payload) ? payload.axis : ""
		local step = ("step" in payload) ? payload.step.tofloat() : 50.0
		if (axis == "x+") preview.x += step
		else if (axis == "x-") preview.x -= step
		else if (axis == "z+") preview.z += step
		else if (axis == "z-") preview.z -= step
		else if (axis == "y+") preview.y += step
		else if (axis == "y-") preview.y -= step
		else if (axis == "a+") preview.angle += 15.0
		else if (axis == "a-") preview.angle -= 15.0
		while (preview.angle >= 360.0) preview.angle -= 360.0
		while (preview.angle < 0.0) preview.angle += 360.0
		phoenix.admin.Model.previewPlace()
		phoenix.admin.Model.previewEmit()
	}

	function previewKeyboard() {
		if (!preview.active || preview.npcId == phoenix.admin.Model.invalidNpcId) return
		if (ui.inputFocused) return
		local now = getTickCount()
		if (now - preview.lastMoveAt < 30) return
		preview.lastMoveAt = now
		local pos = null
		try { pos = getPlayerPosition(preview.npcId) } catch (e) {}
		if (pos == null) return
		local angle = preview.angle
		local step = 5.0
		try { if (isKeyPressed(KEY_LSHIFT) || isKeyPressed(KEY_RSHIFT)) step = 50.0 } catch (e) {}
		try { if (isKeyPressed(KEY_LCONTROL) || isKeyPressed(KEY_RCONTROL)) step = 0.5 } catch (e) {}
		local moved = false
		try { if (isKeyPressed(KEY_W)) { pos.x += step * sin(angle * 3.14159 / 180.0); pos.z += step * cos(angle * 3.14159 / 180.0); moved = true } } catch (e) {}
		try { if (isKeyPressed(KEY_S)) { pos.x -= step * sin(angle * 3.14159 / 180.0); pos.z -= step * cos(angle * 3.14159 / 180.0); moved = true } } catch (e) {}
		try { if (isKeyPressed(KEY_A)) { pos.x -= step * cos(angle * 3.14159 / 180.0); pos.z += step * sin(angle * 3.14159 / 180.0); moved = true } } catch (e) {}
		try { if (isKeyPressed(KEY_D)) { pos.x += step * cos(angle * 3.14159 / 180.0); pos.z -= step * sin(angle * 3.14159 / 180.0); moved = true } } catch (e) {}
		try { if (isKeyPressed(KEY_Q)) { pos.y += step; moved = true } } catch (e) {}
		try { if (isKeyPressed(KEY_E)) { pos.y -= step; moved = true } } catch (e) {}
		try { if (isKeyPressed(KEY_LEFT)) { angle += 2.0; moved = true } } catch (e) {}
		try { if (isKeyPressed(KEY_RIGHT)) { angle -= 2.0; moved = true } } catch (e) {}
		if (!moved) return
		while (angle >= 360.0) angle -= 360.0
		while (angle < 0.0) angle += 360.0
		preview.x = pos.x
		preview.y = pos.y
		preview.z = pos.z
		preview.angle = angle
		phoenix.admin.Model.previewPlace()
		phoenix.admin.Model.previewEmit()
	}

	function previewStop() {
		phoenix.admin.Model.previewEquip("weapon", "")
		phoenix.admin.Model.previewEquip("armor", "")
		phoenix.admin.Model.previewEquip("ranged", "")
		phoenix.admin.Model.previewCameraStop()
		phoenix.admin.Model.previewDestroyNpc()
		preview.active = false
		preview.mode = ""
		preview.kind = ""
		preview.cameraMode = "orbital"
		preview.cameraPaused = false
		if (ui.locked) {
			try { disableControls(true) } catch (e) {}
			try { setFreeze(true) } catch (e) {}
			try { Camera.movementEnabled = false } catch (e) {}
			try { Camera.modeChangeEnabled = false } catch (e) {}
			try { setCursorVisible(true) } catch (e) {}
		} else {
			try { setFreeze(false) } catch (e) {}
		}
	}

	function previewDestroyNpc() {
		if (preview.npcId != phoenix.admin.Model.invalidNpcId && preview.npcId != heroId) {
			try { unspawnNpc(preview.npcId) } catch (eu) {}
			try { destroyNpc(preview.npcId) } catch (e) {}
		}
		local m = phoenix.admin.Message.Request()
		m.action = "npcPreviewRestore"
		m.payload = {}
		try { m.serialize().send(RELIABLE_ORDERED) } catch (e2) {}
		preview.npcId = phoenix.admin.Model.invalidNpcId
		preview.instance = ""
		preview.kind = ""
		preview.weapon = ""
		preview.armor = ""
		preview.ranged = ""
	}

	function vobVisual(payload) {
		if (payload != null && "visual" in payload && payload.visual != null && payload.visual != "") return phoenix.admin.Model.normalizeVobVisual(payload.visual)
		local instance = (payload != null && "instance" in payload && payload.instance != null) ? payload.instance.tostring().toupper() : ""
		if (instance != "") {
			try { local looked = phoenix.item.lookupVisual(instance); if (looked != null && looked != "") return phoenix.admin.Model.normalizeVobVisual(looked) } catch (e) {}
			return instance + ".MRM"
		}
		return ""
	}

	function normalizeVobVisual(visual) {
		if (visual == null) return ""
		return visual.tostring().toupper()
	}

	function vobPreviewStart(payload, action = "adminHerbPreview") {
		phoenix.admin.Model.vobPreviewStop()
		if (payload == null) payload = {}
		vobPreview.action = action
		local pos = null
		try { pos = getPlayerPosition(heroId) } catch (e) {}
		if (pos != null) { vobPreview.x = pos.x; vobPreview.y = pos.y; vobPreview.z = pos.z }
		if ("posX" in payload) vobPreview.x = payload.posX.tofloat()
		if ("posY" in payload) vobPreview.y = payload.posY.tofloat()
		if ("posZ" in payload) vobPreview.z = payload.posZ.tofloat()
		vobPreview.rotX = ("rotX" in payload) ? payload.rotX.tofloat() : 0.0
		vobPreview.rotY = ("rotY" in payload) ? payload.rotY.tofloat() : 0.0
		vobPreview.rotZ = ("rotZ" in payload) ? payload.rotZ.tofloat() : 0.0
		vobPreview.active = true
		phoenix.admin.Model.vobPreviewUpdate(payload, action)
	}

	function vobPreviewUsesCamera() {
		return vobPreview.action == "adminVobPreview"
	}

	function vobPreviewCameraStart() {
		if (!phoenix.admin.Model.vobPreviewUsesCamera()) return
		if (!vobPreview.active || vobPreview.obj == null) return
		if (vobPreview.cameraActive) return
		vobPreview.cameraPaused = false
		if (!ui.locked) {
			try { phoenix.camera.Structure.freeze(); vobPreview.cameraPaused = true } catch (e) {}
		}
		try { Camera.movementEnabled = false } catch (e2) {}
		try { Camera.modeChangeEnabled = false } catch (e3) {}
		vobPreview.camDistance = 360.0
		vobPreview.camPitch = 22.0
		vobPreview.camYaw = vobPreview.rotY + 180.0
		vobPreview.cameraActive = true
	}

	function vobPreviewCameraStop() {
		vobPreview.cameraActive = false
		vobPreview.camDragging = false
		if (vobPreview.cameraPaused) {
			try { phoenix.camera.Structure.release() } catch (e) {}
		}
		vobPreview.cameraPaused = false
	}

	function vobPreviewCameraTick() {
		if (!vobPreview.cameraActive || vobPreview.obj == null) return
		local angleRad = vobPreview.camYaw * 3.14159 / 180.0
		local cx = vobPreview.x + sin(angleRad) * vobPreview.camDistance
		local cy = vobPreview.y + 100.0 + vobPreview.camPitch
		local cz = vobPreview.z + cos(angleRad) * vobPreview.camDistance
		try { Camera.setPosition(cx, cy, cz) } catch (e) {}
		local dx = vobPreview.x - cx
		local dz = vobPreview.z - cz
		local dy = (vobPreview.y + 90.0) - cy
		local yaw = atan2(dx, dz) * 180.0 / 3.14159
		local d2 = sqrt(dx * dx + dz * dz)
		local pitch = -atan2(dy, d2) * 180.0 / 3.14159
		try { Camera.setRotation(pitch, yaw, 0) } catch (e2) {}
	}

	function vobPreviewUpdate(payload, action = null) {
		if (payload == null) payload = {}
		if (!vobPreview.active) vobPreview.active = true
		if (action != null) vobPreview.action = action
		local visual = phoenix.admin.Model.vobVisual(payload)
		local instance = ("instance" in payload && payload.instance != null) ? payload.instance.tostring().toupper() : vobPreview.instance
		local interactive = false
		try { if ("interactive" in payload) interactive = payload.interactive.tointeger() != 0 } catch (ei) {}
		if (visual == "") return
		if (vobPreview.obj == null || vobPreview.visual.toupper() != visual.toupper() || vobPreview.interactive != interactive) {
			phoenix.admin.Model.vobPreviewDestroyObject()
			if (interactive) { try { vobPreview.obj = MobInter(visual) } catch (e) { vobPreview.obj = null } }
			if (vobPreview.obj == null) { try { vobPreview.obj = Vob(visual) } catch (e1) { vobPreview.obj = null } }
			if (vobPreview.obj == null) return
			vobPreview.visual = visual
			vobPreview.interactive = interactive
			try { vobPreview.obj.cdDynamic = false } catch (e2) {}
			try { vobPreview.obj.cdStatic = false } catch (e3) {}
			try { vobPreview.obj.visualAlpha = 0.75 } catch (e4) {}
			try { vobPreview.obj.visible = true } catch (e5) {}
		}
		vobPreview.instance = instance
		if ("posX" in payload) vobPreview.x = payload.posX.tofloat()
		if ("posY" in payload) vobPreview.y = payload.posY.tofloat()
		if ("posZ" in payload) vobPreview.z = payload.posZ.tofloat()
		if ("rotX" in payload) vobPreview.rotX = payload.rotX.tofloat()
		if ("rotY" in payload) vobPreview.rotY = payload.rotY.tofloat()
		if ("rotZ" in payload) vobPreview.rotZ = payload.rotZ.tofloat()
		try { vobPreview.obj.setPosition(vobPreview.x, vobPreview.y, vobPreview.z) } catch (e5) {}
		try { vobPreview.obj.setRotation(vobPreview.rotX, vobPreview.rotY, vobPreview.rotZ) } catch (e6) {}
		try { vobPreview.obj.addToWorld() } catch (e7) {}
		phoenix.admin.Model.vobPreviewCameraStart()
		phoenix.admin.Model.vobPreviewEmit()
	}

	function vobPreviewDestroyObject() {
		if (vobPreview.obj != null) {
			try { vobPreview.obj.removeFromWorld() } catch (e) {}
			try { vobPreview.obj.remove() } catch (e2) {}
			try { vobPreview.obj.destroy() } catch (e3) {}
		}
		vobPreview.obj = null
		vobPreview.visual = ""
	}

	function vobPreviewStop() {
		phoenix.admin.Model.vobPreviewCameraStop()
		phoenix.admin.Model.vobPreviewDestroyObject()
		vobPreview.active = false
		vobPreview.instance = ""
		vobPreview.interactive = false
		vobPreview.action = "adminHerbPreview"
	}

	function vobPreviewFloor() {
		if (vobPreview.obj == null) return
		try { vobPreview.obj.floor() } catch (e) {}
		try { local p = vobPreview.obj.getPosition(); if (p != null) { vobPreview.x = p.x; vobPreview.y = p.y; vobPreview.z = p.z } } catch (e2) {}
		phoenix.admin.Model.vobPreviewEmit()
	}

	function vobPreviewNudge(payload) {
		if (payload == null || vobPreview.obj == null) return
		local axis = ("axis" in payload) ? payload.axis : ""
		local step = ("step" in payload) ? payload.step.tofloat() : 50.0
		if (axis == "x+") vobPreview.x += step
		else if (axis == "x-") vobPreview.x -= step
		else if (axis == "z+") vobPreview.z += step
		else if (axis == "z-") vobPreview.z -= step
		else if (axis == "y+") vobPreview.y += step
		else if (axis == "y-") vobPreview.y -= step
		else if (axis == "rx+") vobPreview.rotX += step
		else if (axis == "rx-") vobPreview.rotX -= step
		else if (axis == "ry+") vobPreview.rotY += step
		else if (axis == "ry-") vobPreview.rotY -= step
		else if (axis == "rz+") vobPreview.rotZ += step
		else if (axis == "rz-") vobPreview.rotZ -= step
		try { vobPreview.obj.setPosition(vobPreview.x, vobPreview.y, vobPreview.z) } catch (e) {}
		try { vobPreview.obj.setRotation(vobPreview.rotX, vobPreview.rotY, vobPreview.rotZ) } catch (e2) {}
		phoenix.admin.Model.vobPreviewEmit()
	}

	function vobPreviewKeyboard() {
		if (!vobPreview.active || vobPreview.obj == null) return
		if (ui.inputFocused) return
		local now = getTickCount()
		if (now - vobPreview.lastMoveAt < 30) return
		vobPreview.lastMoveAt = now
		local speed = 5.0
		try { if (isKeyPressed(KEY_LSHIFT) || isKeyPressed(KEY_RSHIFT)) speed = 50.0 } catch (e) {}
		try { if (isKeyPressed(KEY_LCONTROL) || isKeyPressed(KEY_RCONTROL)) speed = 0.5 } catch (e2) {}
		local moved = false
		try { if (isKeyPressed(KEY_W)) { vobPreview.x += speed * sin(vobPreview.rotY * 3.14159 / 180.0); vobPreview.z += speed * cos(vobPreview.rotY * 3.14159 / 180.0); moved = true } } catch (e3) {}
		try { if (isKeyPressed(KEY_S)) { vobPreview.x -= speed * sin(vobPreview.rotY * 3.14159 / 180.0); vobPreview.z -= speed * cos(vobPreview.rotY * 3.14159 / 180.0); moved = true } } catch (e4) {}
		try { if (isKeyPressed(KEY_A)) { vobPreview.x += speed * sin((vobPreview.rotY - 90.0) * 3.14159 / 180.0); vobPreview.z += speed * cos((vobPreview.rotY - 90.0) * 3.14159 / 180.0); moved = true } } catch (e5) {}
		try { if (isKeyPressed(KEY_D)) { vobPreview.x += speed * sin((vobPreview.rotY + 90.0) * 3.14159 / 180.0); vobPreview.z += speed * cos((vobPreview.rotY + 90.0) * 3.14159 / 180.0); moved = true } } catch (e6) {}
		try { if (isKeyPressed(KEY_Q)) { vobPreview.y += speed; moved = true } } catch (e7) {}
		try { if (isKeyPressed(KEY_E)) { vobPreview.y -= speed; moved = true } } catch (e8) {}
		try { if (isKeyPressed(KEY_LEFT)) { vobPreview.rotY += 2.0; moved = true } } catch (e9) {}
		try { if (isKeyPressed(KEY_RIGHT)) { vobPreview.rotY -= 2.0; moved = true } } catch (e10) {}
		if (!moved) return
		try { vobPreview.obj.setPosition(vobPreview.x, vobPreview.y, vobPreview.z) } catch (e11) {}
		try { vobPreview.obj.setRotation(vobPreview.rotX, vobPreview.rotY, vobPreview.rotZ) } catch (e12) {}
		phoenix.admin.Model.vobPreviewEmit()
	}

	function vobPreviewEmit() {
		try {
			phoenix.web.Manager.emit("phoenix:admin:response", {
				action = vobPreview.action,
				success = true,
				error = "",
				payload = { instance = vobPreview.instance, visual = vobPreview.visual, posX = vobPreview.x, posY = vobPreview.y, posZ = vobPreview.z, rotX = vobPreview.rotX, rotY = vobPreview.rotY, rotZ = vobPreview.rotZ }
			})
		} catch (e) {}
	}

	function houseCapture(payload) {
		local pos = null
		if (houseGhost.active && houseGhost.obj != null) {
			pos = { x = houseGhost.x, y = houseGhost.y, z = houseGhost.z }
		} else {
			try { pos = getPlayerPosition(heroId) } catch (e) {}
		}
		if (pos == null) pos = { x = 0.0, y = 0.0, z = 0.0 }
		local angle = 0.0
		if (houseGhost.active) angle = houseGhost.rotY
		else { try { angle = getPlayerAngle(heroId) } catch (e2) {} }
		local world = ""
		try { world = getPlayerWorld(heroId) } catch (e3) { try { world = getWorld() } catch (e4) {} }
		local slot = ""
		local index = -1
		try { if (payload != null && "slot" in payload && payload.slot != null) slot = payload.slot } catch (e5) {}
		try { if (payload != null && "index" in payload && payload.index != null) index = payload.index.tointeger() } catch (e6) {}
		try {
			phoenix.web.Manager.emit("phoenix:admin:response", {
				action = "adminHouseCapture",
				success = true,
				error = "",
				payload = { slot = slot, index = index, posX = pos.x, posY = pos.y, posZ = pos.z, angle = angle, world = world, ghost = houseGhost.active ? 1 : 0 }
			})
		} catch (e7) {}
	}

	function houseGhostStart(payload) {
		if (payload == null) payload = {}
		if (!houseGhost.active) {
			local pos = null
			try { pos = getPlayerPosition(heroId) } catch (e) {}
			if (pos != null) { houseGhost.x = pos.x; houseGhost.y = pos.y; houseGhost.z = pos.z }
			try { houseGhost.rotY = getPlayerAngle(heroId) } catch (e2) {}
		}
		if ("visual" in payload && payload.visual != null && payload.visual != "") houseGhost.visual = phoenix.admin.Model.normalizeVobVisual(payload.visual)
		phoenix.admin.Model.houseGhostSync(payload)
		if (houseGhost.obj == null) {
			try { houseGhost.obj = Vob(houseGhost.visual) } catch (e3) { houseGhost.obj = null }
			if (houseGhost.obj != null) {
				try { houseGhost.obj.cdDynamic = false } catch (e4) {}
				try { houseGhost.obj.cdStatic = false } catch (e5) {}
				try { houseGhost.obj.visualAlpha = 0.65 } catch (e6) {}
				try { houseGhost.obj.visible = true } catch (e7) {}
			}
		}
		if (houseGhost.obj != null) {
			try { houseGhost.obj.setPosition(houseGhost.x, houseGhost.y, houseGhost.z) } catch (e8) {}
			try { houseGhost.obj.setRotation(0.0, houseGhost.rotY, 0.0) } catch (e9) {}
			try { houseGhost.obj.addToWorld() } catch (e10) {}
		}
		houseGhost.active = true
		phoenix.admin.Model.houseGhostCameraStart(false)
		phoenix.admin.Model.houseGhostEmit()
	}

	function houseGhostSync(payload) {
		if (payload == null) return
		if ("points" in payload && payload.points != null) {
			houseGhost.points.clear()
			foreach (p in payload.points) {
				if (p == null) continue
				local px = ("x" in p) ? p.x.tofloat() : 0.0
				local py = ("y" in p) ? p.y.tofloat() : 0.0
				local pz = ("z" in p) ? p.z.tofloat() : 0.0
				houseGhost.points.append({ x = px, y = py, z = pz })
			}
			if (houseGhost.points.len() > 0 && !houseGhost.active) {
				local last = houseGhost.points[houseGhost.points.len() - 1]
				houseGhost.x = last.x; houseGhost.y = last.y; houseGhost.z = last.z
			}
		}
		try { if ("world" in payload && payload.world != null) houseGhost.world = payload.world.tostring() } catch (e) {}
	}

	function houseGhostStop() {
		phoenix.admin.Model.houseGhostCameraStop()
		if (houseGhost.obj != null) {
			try { houseGhost.obj.removeFromWorld() } catch (e) {}
			try { houseGhost.obj.remove() } catch (e2) {}
			try { houseGhost.obj.destroy() } catch (e3) {}
		}
		houseGhost.obj = null
		houseGhost.active = false
		houseGhost.camDragging = false
		houseGhost.points.clear()
		phoenix.admin.Model.houseGhostEmit()
	}

	function houseGhostCameraStart(force) {
		if (!houseGhost.active || houseGhost.obj == null) return
		if (!force && houseGhost.cameraActive) return
		houseGhost.cameraPaused = false
		if (!ui.locked) {
			try { phoenix.camera.Structure.freeze(); houseGhost.cameraPaused = true } catch (e) {}
		}
		try { Camera.movementEnabled = false } catch (e2) {}
		try { Camera.modeChangeEnabled = false } catch (e3) {}
		houseGhost.camDistance = 360.0
		houseGhost.camPitch = 22.0
		houseGhost.camYaw = houseGhost.rotY + 180.0
		houseGhost.cameraActive = true
	}

	function houseGhostCameraStop() {
		houseGhost.cameraActive = false
		houseGhost.camDragging = false
		if (houseGhost.cameraPaused) {
			try { phoenix.camera.Structure.release() } catch (e) {}
		}
		houseGhost.cameraPaused = false
	}

	function houseGhostCameraTick() {
		if (!houseGhost.cameraActive || !houseGhost.active) return
		local angleRad = houseGhost.camYaw * 3.14159 / 180.0
		local cx = houseGhost.x + sin(angleRad) * houseGhost.camDistance
		local cy = houseGhost.y + 100.0 + houseGhost.camPitch
		local cz = houseGhost.z + cos(angleRad) * houseGhost.camDistance
		try { Camera.setPosition(cx, cy, cz) } catch (e) {}
		local dx = houseGhost.x - cx
		local dz = houseGhost.z - cz
		local dy = (houseGhost.y + 90.0) - cy
		local yaw = atan2(dx, dz) * 180.0 / 3.14159
		local d2 = sqrt(dx * dx + dz * dz)
		local pitch = -atan2(dy, d2) * 180.0 / 3.14159
		try { Camera.setRotation(pitch, yaw, 0) } catch (e2) {}
	}

	function houseGhostKeyboard() {
		if (!houseGhost.active || houseGhost.obj == null) return
		if (ui.inputFocused) return
		local now = getTickCount()
		if (now - houseGhost.lastMoveAt < 30) return
		houseGhost.lastMoveAt = now
		local speed = 5.0
		try { if (isKeyPressed(KEY_LSHIFT) || isKeyPressed(KEY_RSHIFT)) speed = 50.0 } catch (e) {}
		try { if (isKeyPressed(KEY_LCONTROL) || isKeyPressed(KEY_RCONTROL)) speed = 0.5 } catch (e2) {}
		local moved = false
		try { if (isKeyPressed(KEY_W)) { houseGhost.x += speed * sin(houseGhost.rotY * 3.14159 / 180.0); houseGhost.z += speed * cos(houseGhost.rotY * 3.14159 / 180.0); moved = true } } catch (e3) {}
		try { if (isKeyPressed(KEY_S)) { houseGhost.x -= speed * sin(houseGhost.rotY * 3.14159 / 180.0); houseGhost.z -= speed * cos(houseGhost.rotY * 3.14159 / 180.0); moved = true } } catch (e4) {}
		try { if (isKeyPressed(KEY_A)) { houseGhost.x += speed * sin((houseGhost.rotY - 90.0) * 3.14159 / 180.0); houseGhost.z += speed * cos((houseGhost.rotY - 90.0) * 3.14159 / 180.0); moved = true } } catch (e5) {}
		try { if (isKeyPressed(KEY_D)) { houseGhost.x += speed * sin((houseGhost.rotY + 90.0) * 3.14159 / 180.0); houseGhost.z += speed * cos((houseGhost.rotY + 90.0) * 3.14159 / 180.0); moved = true } } catch (e6) {}
		try { if (isKeyPressed(KEY_Q)) { houseGhost.y += speed; moved = true } } catch (e7) {}
		try { if (isKeyPressed(KEY_E)) { houseGhost.y -= speed; moved = true } } catch (e8) {}
		try { if (isKeyPressed(KEY_LEFT)) { houseGhost.rotY += 2.0; moved = true } } catch (e9) {}
		try { if (isKeyPressed(KEY_RIGHT)) { houseGhost.rotY -= 2.0; moved = true } } catch (e10) {}
		if (!moved) return
		try { houseGhost.obj.setPosition(houseGhost.x, houseGhost.y, houseGhost.z) } catch (e11) {}
		try { houseGhost.obj.setRotation(0.0, houseGhost.rotY, 0.0) } catch (e12) {}
		phoenix.admin.Model.houseGhostEmit()
	}

	function houseGhostDraw() {
		if (!houseGhost.active) return
		try { if (!("drawLine3d" in getroottable())) return } catch (e) { return }
		local count = houseGhost.points.len()
		for (local i = 0; i < count; i += 1) {
			local a = houseGhost.points[i]
			local b = houseGhost.points[(i + 1) % count]
			if (count > 1) { try { drawLine3d(a.x, a.y, a.z, b.x, b.y, b.z, 120, 200, 255, true) } catch (e2) {} }
			try { drawLine3d(a.x, a.y, a.z, a.x, a.y + 120.0, a.z, 255, 210, 90, true) } catch (e3) {}
		}
		if (count > 0) {
			local last = houseGhost.points[count - 1]
			try { drawLine3d(last.x, last.y, last.z, houseGhost.x, houseGhost.y, houseGhost.z, 90, 240, 170, true) } catch (e4) {}
		}
		try { drawLine3d(houseGhost.x, houseGhost.y, houseGhost.z, houseGhost.x, houseGhost.y + 150.0, houseGhost.z, 90, 240, 170, true) } catch (e5) {}
	}

	function houseGhostEmit() {
		try {
			phoenix.web.Manager.emit("phoenix:admin:response", {
				action = "adminHouseGhost",
				success = true,
				error = "",
				payload = { active = houseGhost.active ? 1 : 0, posX = houseGhost.x, posY = houseGhost.y, posZ = houseGhost.z, angle = houseGhost.rotY, world = houseGhost.world }
			})
		} catch (e) {}
	}

	function routineGhostStart(payload) {
		if (payload == null) payload = {}
		if (!routineGhost.active) {
			local pos = null
			try { pos = getPlayerPosition(heroId) } catch (e) {}
			if (pos != null) { routineGhost.x = pos.x; routineGhost.y = pos.y; routineGhost.z = pos.z }
			try { routineGhost.rotY = getPlayerAngle(heroId) } catch (e2) {}
		}
		if ("spawnId" in payload) routineGhost.spawnId = payload.spawnId.tointeger()
		if ("visual" in payload && payload.visual != null && payload.visual != "") {
			routineGhost.visual = phoenix.admin.Model.normalizeVobVisual(payload.visual)
		}
		try { routineGhost.world = getPlayerWorld(heroId) } catch (e) {}
		phoenix.admin.Model.routineGhostSync(payload)
		if (routineGhost.obj == null) {
			try { routineGhost.obj = Vob(routineGhost.visual) } catch (e3) { routineGhost.obj = null }
			if (routineGhost.obj != null) {
				try { routineGhost.obj.cdDynamic = false } catch (e4) {}
				try { routineGhost.obj.cdStatic = false } catch (e5) {}
				try { routineGhost.obj.visualAlpha = 0.65 } catch (e6) {}
				try { routineGhost.obj.visible = true } catch (e7) {}
			}
		}
		if (routineGhost.obj != null) {
			try { routineGhost.obj.setPosition(routineGhost.x, routineGhost.y, routineGhost.z) } catch (e8) {}
			try { routineGhost.obj.addToWorld() } catch (e9) {}
		}
		routineGhost.active = true
		phoenix.admin.Model.routineGhostCameraStart(false)
		phoenix.admin.Model.routineGhostEmit()
	}

	function routineGhostSync(payload) {
		if (payload == null) return
		if ("nodes" in payload && payload.nodes != null) {
			routineGhost.nodes.clear()
			foreach (n in payload.nodes) {
				if (n == null) continue
				local type = ("type" in n) ? n.type.tostring() : "waypoint"
				local nx = ("x" in n) ? n.x.tofloat() : 0.0
				local ny = ("y" in n) ? n.y.tofloat() : 0.0
				local nz = ("z" in n) ? n.z.tofloat() : 0.0
				routineGhost.nodes.append({ type = type, x = nx, y = ny, z = nz })
			}
			if (routineGhost.nodes.len() > 0 && !routineGhost.active) {
				local last = routineGhost.nodes[routineGhost.nodes.len() - 1]
				routineGhost.x = last.x; routineGhost.y = last.y; routineGhost.z = last.z
			}
		}
		phoenix.admin.Model.routineGhostRebuildMarkers()
	}

	function routineGhostClearMarkers() {
		foreach (obj in routineGhost.markers) {
			try { obj.removeFromWorld() } catch (e) {}
			try { obj.remove() } catch (e2) {}
			try { obj.destroy() } catch (e3) {}
		}
		routineGhost.markers.clear()
	}

	function routineGhostRebuildMarkers() {
		phoenix.admin.Model.routineGhostClearMarkers()
		if (!routineGhost.active) return
		foreach (n in routineGhost.nodes) {
			if (n.type == "wait") continue
			local obj = null
			try { obj = Vob(routineGhost.visual) } catch (e) { obj = null }
			if (obj == null) continue
			try { obj.cdDynamic = false } catch (e2) {}
			try { obj.cdStatic = false } catch (e3) {}
			try { obj.visualAlpha = 0.75 } catch (e4) {}
			try { obj.visible = true } catch (e5) {}
			try { obj.setPosition(n.x, n.y, n.z) } catch (e6) {}
			try { obj.addToWorld() } catch (e7) {}
			routineGhost.markers.append(obj)
		}
	}

	function routineGhostStop() {
		phoenix.admin.Model.routineGhostCameraStop()
		phoenix.admin.Model.routineGhostClearMarkers()
		if (routineGhost.obj != null) {
			try { routineGhost.obj.removeFromWorld() } catch (e) {}
			try { routineGhost.obj.remove() } catch (e2) {}
			try { routineGhost.obj.destroy() } catch (e3) {}
		}
		routineGhost.obj = null
		routineGhost.active = false
		routineGhost.camDragging = false
		routineGhost.nodes.clear()
	}

	function routineGhostCameraStart(force) {
		if (!routineGhost.active || routineGhost.obj == null) return
		if (!force && routineGhost.cameraActive) return
		routineGhost.cameraPaused = false
		if (!ui.locked) {
			try { phoenix.camera.Structure.freeze(); routineGhost.cameraPaused = true } catch (e) {}
		}
		try { Camera.movementEnabled = false } catch (e2) {}
		try { Camera.modeChangeEnabled = false } catch (e3) {}
		routineGhost.camDistance = 360.0
		routineGhost.camPitch = 22.0
		routineGhost.camYaw = routineGhost.rotY + 180.0
		routineGhost.cameraActive = true
	}

	function routineGhostCameraStop() {
		routineGhost.cameraActive = false
		routineGhost.camDragging = false
		if (routineGhost.cameraPaused) {
			try { phoenix.camera.Structure.release() } catch (e) {}
		}
		routineGhost.cameraPaused = false
	}

	function routineGhostCameraTick() {
		if (!routineGhost.cameraActive || !routineGhost.active) return
		local angleRad = routineGhost.camYaw * 3.14159 / 180.0
		local cx = routineGhost.x + sin(angleRad) * routineGhost.camDistance
		local cy = routineGhost.y + 100.0 + routineGhost.camPitch
		local cz = routineGhost.z + cos(angleRad) * routineGhost.camDistance
		try { Camera.setPosition(cx, cy, cz) } catch (e) {}
		local dx = routineGhost.x - cx
		local dz = routineGhost.z - cz
		local dy = (routineGhost.y + 90.0) - cy
		local yaw = atan2(dx, dz) * 180.0 / 3.14159
		local d2 = sqrt(dx * dx + dz * dz)
		local pitch = -atan2(dy, d2) * 180.0 / 3.14159
		try { Camera.setRotation(pitch, yaw, 0) } catch (e2) {}
	}

	function routineGhostKeyboard() {
		if (!routineGhost.active || routineGhost.obj == null) return
		if (ui.inputFocused) return
		local now = getTickCount()
		if (now - routineGhost.lastMoveAt < 30) return
		routineGhost.lastMoveAt = now
		local speed = 5.0
		try { if (isKeyPressed(KEY_LSHIFT) || isKeyPressed(KEY_RSHIFT)) speed = 50.0 } catch (e) {}
		try { if (isKeyPressed(KEY_LCONTROL) || isKeyPressed(KEY_RCONTROL)) speed = 0.5 } catch (e2) {}
		local moved = false
		try { if (isKeyPressed(KEY_W)) { routineGhost.x += speed * sin(routineGhost.camYaw * 3.14159 / 180.0); routineGhost.z += speed * cos(routineGhost.camYaw * 3.14159 / 180.0); moved = true } } catch (e3) {}
		try { if (isKeyPressed(KEY_S)) { routineGhost.x -= speed * sin(routineGhost.camYaw * 3.14159 / 180.0); routineGhost.z -= speed * cos(routineGhost.camYaw * 3.14159 / 180.0); moved = true } } catch (e4) {}
		try { if (isKeyPressed(KEY_A)) { routineGhost.x += speed * sin((routineGhost.camYaw - 90.0) * 3.14159 / 180.0); routineGhost.z += speed * cos((routineGhost.camYaw - 90.0) * 3.14159 / 180.0); moved = true } } catch (e5) {}
		try { if (isKeyPressed(KEY_D)) { routineGhost.x += speed * sin((routineGhost.camYaw + 90.0) * 3.14159 / 180.0); routineGhost.z += speed * cos((routineGhost.camYaw + 90.0) * 3.14159 / 180.0); moved = true } } catch (e6) {}
		try { if (isKeyPressed(KEY_Q)) { routineGhost.y += speed; moved = true } } catch (e7) {}
		try { if (isKeyPressed(KEY_E)) { routineGhost.y -= speed; moved = true } } catch (e8) {}
		try { if (isKeyPressed(KEY_LEFT)) { routineGhost.camYaw += 2.0; moved = true } } catch (e9) {}
		try { if (isKeyPressed(KEY_RIGHT)) { routineGhost.camYaw -= 2.0; moved = true } } catch (e10) {}
		if (!moved) return
		try { routineGhost.obj.setPosition(routineGhost.x, routineGhost.y, routineGhost.z) } catch (e11) {}
		phoenix.admin.Model.routineGhostEmit()
	}

	function routineGhostDraw() {
		if (!routineGhost.active) return
		try { if (!("drawLine3d" in getroottable())) return } catch (e) { return }
		local count = routineGhost.nodes.len()
		for (local i = 0; i < count; i += 1) {
			local a = routineGhost.nodes[i]
			if (a.type == "wait") continue
			try { drawLine3d(a.x, a.y, a.z, a.x, a.y + 150.0, a.z, 255, 210, 90, true) } catch (e2) {}
			if (i > 0) {
				local prev = null
				for (local j = i - 1; j >= 0; j -= 1) {
					if (routineGhost.nodes[j].type != "wait") { prev = routineGhost.nodes[j]; break }
				}
				if (prev != null) {
					try { drawLine3d(prev.x, prev.y + 40.0, prev.z, a.x, a.y + 40.0, a.z, 120, 200, 255, true) } catch (e3) {}
				}
			}
		}
		if (count > 0) {
			local last = null
			for (local k = count - 1; k >= 0; k -= 1) {
				if (routineGhost.nodes[k].type != "wait") { last = routineGhost.nodes[k]; break }
			}
			if (last != null) {
				try { drawLine3d(last.x, last.y + 40.0, last.z, routineGhost.x, routineGhost.y + 40.0, routineGhost.z, 90, 240, 170, true) } catch (e4) {}
			}
		}
		try { drawLine3d(routineGhost.x, routineGhost.y, routineGhost.z, routineGhost.x, routineGhost.y + 200.0, routineGhost.z, 90, 240, 170, true) } catch (e5) {}
	}

	function routineGhostEmit() {
		try {
			phoenix.web.Manager.emit("phoenix:admin:response", {
				action = "adminRoutineGhost",
				success = true,
				error = "",
				payload = { active = routineGhost.active ? 1 : 0, posX = routineGhost.x, posY = routineGhost.y, posZ = routineGhost.z }
			})
		} catch (e) {}
	}

	function spawnGhostStart(payload) {
		if (payload == null) payload = {}
		if (spawnGhost.active) phoenix.admin.Model.spawnGhostStop()
		local mode = ("mode" in payload) ? payload.mode.tostring() : "spawn"
		spawnGhost.mode = (mode == "lobby") ? "lobby" : "spawn"
		spawnGhost.useHuman = ("useHuman" in payload) && payload.useHuman == true
		local p = null
		try { p = getPlayerPosition(heroId) } catch (e) {}
		if (p != null) { spawnGhost.x = p.x; spawnGhost.y = p.y; spawnGhost.z = p.z }
		try { spawnGhost.angle = getPlayerAngle(heroId) } catch (e) {}
		try { spawnGhost.world = getPlayerWorld(heroId) } catch (e) {}
		if ("x" in payload) spawnGhost.x = payload.x.tofloat()
		if ("y" in payload) spawnGhost.y = payload.y.tofloat()
		if ("z" in payload) spawnGhost.z = payload.z.tofloat()
		if ("angle" in payload) spawnGhost.angle = payload.angle.tofloat()
		if ("camPitch" in payload) spawnGhost.camPitch = payload.camPitch.tofloat()
		if ("camRoll" in payload) spawnGhost.camRoll = payload.camRoll.tofloat()
		if (spawnGhost.useHuman) {
			local inst = "PC_HERO"
			spawnGhost.npcId = phoenix.admin.Model.previewCreateNpc(inst, inst, inst)
			if (spawnGhost.npcId != phoenix.admin.Model.invalidNpcId) {
				try { spawnNpc(spawnGhost.npcId) } catch (eS1) { try { spawnNpc(spawnGhost.npcId, inst) } catch (eS2) {} }
				try { setPlayerInstance(spawnGhost.npcId, inst) } catch (eIn) {}
				try { setPlayerVisual(spawnGhost.npcId, "Hum_Body_Naked0", 1, "Hum_Head_Pony", 0) } catch (eVi) {}
				try { setPlayerPosition(spawnGhost.npcId, spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (eP) {}
				try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle, true) } catch (eA) { try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle) } catch (eA2) {} }
			}
		} else {
			try { spawnGhost.obj = Vob(spawnGhost.visual) } catch (e) { spawnGhost.obj = null }
			if (spawnGhost.obj != null) {
				try { spawnGhost.obj.cdDynamic = false } catch (e2) {}
				try { spawnGhost.obj.cdStatic = false } catch (e3) {}
				try { spawnGhost.obj.visualAlpha = 0.65 } catch (e4) {}
				try { spawnGhost.obj.visible = true } catch (e5) {}
				try { spawnGhost.obj.setPosition(spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e6) {}
				try { spawnGhost.obj.addToWorld() } catch (e7) {}
			}
		}
		try { spawnGhost.arrow = Vob(spawnGhost.arrowVisual) } catch (e8) { spawnGhost.arrow = null }
		if (spawnGhost.arrow != null) {
			try { spawnGhost.arrow.cdDynamic = false } catch (e9) {}
			try { spawnGhost.arrow.cdStatic = false } catch (e10) {}
			try { spawnGhost.arrow.visualAlpha = 0.55 } catch (e11) {}
			try { spawnGhost.arrow.visible = true } catch (e12) {}
			try { spawnGhost.arrow.addToWorld() } catch (e13) {}
		}
		spawnGhost.active = true
		phoenix.admin.Model.spawnGhostUpdateArrow()
		phoenix.admin.Model.spawnGhostCameraStart(false)
		phoenix.admin.Model.spawnGhostEmit()
	}

	function spawnGhostSync(payload) {
		if (payload == null) return
		if ("x" in payload) spawnGhost.x = payload.x.tofloat()
		if ("y" in payload) spawnGhost.y = payload.y.tofloat()
		if ("z" in payload) spawnGhost.z = payload.z.tofloat()
		if ("angle" in payload) spawnGhost.angle = payload.angle.tofloat()
		if ("camPitch" in payload) spawnGhost.camPitch = payload.camPitch.tofloat()
		if ("camRoll" in payload) spawnGhost.camRoll = payload.camRoll.tofloat()
		if ("mode" in payload) spawnGhost.mode = payload.mode.tostring()
		if (!spawnGhost.active) return
		if (spawnGhost.useHuman && spawnGhost.npcId != phoenix.admin.Model.invalidNpcId) {
			try { setPlayerPosition(spawnGhost.npcId, spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e) {}
			try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle, true) } catch (eA) { try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle) } catch (eA2) {} }
		} else if (spawnGhost.obj != null) {
			try { spawnGhost.obj.setPosition(spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e) {}
		}
		phoenix.admin.Model.spawnGhostUpdateArrow()
		phoenix.admin.Model.spawnGhostEmit()
	}

	function spawnGhostUpdateArrow() {
		if (spawnGhost.arrow == null) return
		local rad = spawnGhost.angle * 3.14159 / 180.0
		local ax = spawnGhost.x + sin(rad) * 90.0
		local az = spawnGhost.z + cos(rad) * 90.0
		try { spawnGhost.arrow.setPosition(ax, spawnGhost.y + 30.0, az) } catch (e) {}
	}

	function spawnGhostStop() {
		phoenix.admin.Model.spawnGhostCameraStop()
		if (spawnGhost.useHuman && spawnGhost.npcId != phoenix.admin.Model.invalidNpcId && spawnGhost.npcId != heroId) {
			try { unspawnNpc(spawnGhost.npcId) } catch (eU) {}
			try { destroyNpc(spawnGhost.npcId) } catch (eD) {}
		}
		spawnGhost.npcId = phoenix.admin.Model.invalidNpcId
		if (spawnGhost.obj != null) {
			try { spawnGhost.obj.removeFromWorld() } catch (e) {}
			try { spawnGhost.obj.remove() } catch (e2) {}
			try { spawnGhost.obj.destroy() } catch (e3) {}
		}
		if (spawnGhost.arrow != null) {
			try { spawnGhost.arrow.removeFromWorld() } catch (e4) {}
			try { spawnGhost.arrow.remove() } catch (e5) {}
			try { spawnGhost.arrow.destroy() } catch (e6) {}
		}
		spawnGhost.obj = null
		spawnGhost.arrow = null
		spawnGhost.active = false
		spawnGhost.useHuman = false
		phoenix.admin.Model.spawnGhostEmit()
	}

	function spawnGhostNudge(payload) {
		if (!spawnGhost.active) return
		if (payload == null) return
		local axis = ("axis" in payload) ? payload.axis.tostring() : ""
		local step = ("step" in payload) ? payload.step.tofloat() : 50.0
		if (axis == "x+") spawnGhost.x += step
		else if (axis == "x-") spawnGhost.x -= step
		else if (axis == "z+") spawnGhost.z += step
		else if (axis == "z-") spawnGhost.z -= step
		else if (axis == "y+") spawnGhost.y += step
		else if (axis == "y-") spawnGhost.y -= step
		else if (axis == "a+") spawnGhost.angle += 15.0
		else if (axis == "a-") spawnGhost.angle -= 15.0
		else if (axis == "pitch+") spawnGhost.camPitch += 5.0
		else if (axis == "pitch-") spawnGhost.camPitch -= 5.0
		else if (axis == "roll+") spawnGhost.camRoll += 5.0
		else if (axis == "roll-") spawnGhost.camRoll -= 5.0
		while (spawnGhost.angle >= 360.0) spawnGhost.angle -= 360.0
		while (spawnGhost.angle < 0.0) spawnGhost.angle += 360.0
		if (spawnGhost.useHuman && spawnGhost.npcId != phoenix.admin.Model.invalidNpcId) {
			try { setPlayerPosition(spawnGhost.npcId, spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e) {}
			try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle, true) } catch (eA) { try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle) } catch (eA2) {} }
		} else if (spawnGhost.obj != null) {
			try { spawnGhost.obj.setPosition(spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e) {}
		}
		phoenix.admin.Model.spawnGhostUpdateArrow()
		phoenix.admin.Model.spawnGhostEmit()
	}

	function spawnGhostCameraStart(force) {
		if (!spawnGhost.active) return
		if (!spawnGhost.useHuman && spawnGhost.obj == null) return
		if (!force && spawnGhost.cameraActive) return
		spawnGhost.cameraPaused = false
		if (!ui.locked) {
			try { phoenix.camera.Structure.freeze(); spawnGhost.cameraPaused = true } catch (e) {}
		}
		try { Camera.movementEnabled = false } catch (e2) {}
		try { Camera.modeChangeEnabled = false } catch (e3) {}
		spawnGhost.camDistance = 360.0
		spawnGhost.camCtrlPitch = 22.0
		spawnGhost.camYaw = spawnGhost.angle + 180.0
		spawnGhost.cameraActive = true
	}

	function spawnGhostCameraStop() {
		spawnGhost.cameraActive = false
		if (spawnGhost.cameraPaused) {
			try { phoenix.camera.Structure.release() } catch (e) {}
		}
		spawnGhost.cameraPaused = false
	}

	function spawnGhostCameraTick() {
		if (!spawnGhost.cameraActive || !spawnGhost.active) return
		if (spawnGhost.mode == "lobby") {
			try { Camera.setPosition(spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e) {}
			try { Camera.setRotation(spawnGhost.camPitch, spawnGhost.angle, spawnGhost.camRoll) } catch (e2) {}
			return
		}
		local angleRad = spawnGhost.camYaw * 3.14159 / 180.0
		local pitchRad = spawnGhost.camCtrlPitch * 3.14159 / 180.0
		local desiredDist = spawnGhost.camDistance
		local horizDist = desiredDist * cos(pitchRad)
		local cx = spawnGhost.x + sin(angleRad) * horizDist
		local cz = spawnGhost.z + cos(angleRad) * horizDist
		local cy = spawnGhost.y + 100.0 + desiredDist * sin(pitchRad)
		try {
			local origin = Vec3(spawnGhost.x, spawnGhost.y + 90.0, spawnGhost.z)
			local direction = Vec3(cx - spawnGhost.x, cy - (spawnGhost.y + 90.0), cz - spawnGhost.z)
			local report = GameWorld.traceRayNearestHit(origin, direction, TRACERAY_STAT_POLY | TRACERAY_POLY_NORMAL | TRACERAY_VOB_IGNORE_NO_CD_DYN)
			if (report != null) {
				local dx = report.intersect.x - spawnGhost.x
				local dy = report.intersect.y - (spawnGhost.y + 90.0)
				local dz = report.intersect.z - spawnGhost.z
				local hitDist = sqrt(dx * dx + dy * dy + dz * dz) - 30.0
				if (hitDist < 90.0) hitDist = 90.0
				if (hitDist < desiredDist) {
					local nh = hitDist * cos(pitchRad)
					cx = spawnGhost.x + sin(angleRad) * nh
					cz = spawnGhost.z + cos(angleRad) * nh
					cy = spawnGhost.y + 100.0 + hitDist * sin(pitchRad)
				}
			}
		} catch (eRC) {}
		try { Camera.setPosition(cx, cy, cz) } catch (e3) {}
		local dx = spawnGhost.x - cx
		local dz = spawnGhost.z - cz
		local dy = (spawnGhost.y + 90.0) - cy
		local yaw = atan2(dx, dz) * 180.0 / 3.14159
		local d2 = sqrt(dx * dx + dz * dz)
		local pitch = -atan2(dy, d2) * 180.0 / 3.14159
		try { Camera.setRotation(pitch, yaw, 0) } catch (e4) {}
	}

	function spawnGhostKeyboard() {
		if (!spawnGhost.active) return
		if (!spawnGhost.useHuman && spawnGhost.obj == null) return
		if (ui.inputFocused) return
		local now = getTickCount()
		if (now - spawnGhost.lastMoveAt < 30) return
		spawnGhost.lastMoveAt = now
		local speed = 5.0
		try { if (isKeyPressed(KEY_LSHIFT) || isKeyPressed(KEY_RSHIFT)) speed = 50.0 } catch (e) {}
		try { if (isKeyPressed(KEY_LCONTROL) || isKeyPressed(KEY_RCONTROL)) speed = 0.5 } catch (e2) {}
		local moved = false
		local refYaw = spawnGhost.mode == "lobby" ? spawnGhost.angle : spawnGhost.camYaw
		try { if (isKeyPressed(KEY_W)) { spawnGhost.x += speed * sin(refYaw * 3.14159 / 180.0); spawnGhost.z += speed * cos(refYaw * 3.14159 / 180.0); moved = true } } catch (e3) {}
		try { if (isKeyPressed(KEY_S)) { spawnGhost.x -= speed * sin(refYaw * 3.14159 / 180.0); spawnGhost.z -= speed * cos(refYaw * 3.14159 / 180.0); moved = true } } catch (e4) {}
		try { if (isKeyPressed(KEY_A)) { spawnGhost.x += speed * sin((refYaw - 90.0) * 3.14159 / 180.0); spawnGhost.z += speed * cos((refYaw - 90.0) * 3.14159 / 180.0); moved = true } } catch (e5) {}
		try { if (isKeyPressed(KEY_D)) { spawnGhost.x += speed * sin((refYaw + 90.0) * 3.14159 / 180.0); spawnGhost.z += speed * cos((refYaw + 90.0) * 3.14159 / 180.0); moved = true } } catch (e6) {}
		try { if (isKeyPressed(KEY_Q)) { spawnGhost.y += speed; moved = true } } catch (e7) {}
		try { if (isKeyPressed(KEY_E)) { spawnGhost.y -= speed; moved = true } } catch (e8) {}
		try { if (isKeyPressed(KEY_LEFT)) { spawnGhost.angle += 2.0; moved = true } } catch (e9) {}
		try { if (isKeyPressed(KEY_RIGHT)) { spawnGhost.angle -= 2.0; moved = true } } catch (e10) {}
		if (spawnGhost.mode == "lobby") {
			try { if (isKeyPressed(KEY_UP))   { spawnGhost.camPitch += 1.0; moved = true } } catch (e11) {}
			try { if (isKeyPressed(KEY_DOWN)) { spawnGhost.camPitch -= 1.0; moved = true } } catch (e12) {}
			try { if (isKeyPressed(KEY_PRIOR)) { spawnGhost.camRoll += 1.0; moved = true } } catch (e13) {}
			try { if (isKeyPressed(KEY_NEXT))  { spawnGhost.camRoll -= 1.0; moved = true } } catch (e14) {}
		}
		while (spawnGhost.angle >= 360.0) spawnGhost.angle -= 360.0
		while (spawnGhost.angle < 0.0) spawnGhost.angle += 360.0
		if (!moved) return
		if (spawnGhost.useHuman && spawnGhost.npcId != phoenix.admin.Model.invalidNpcId) {
			try { setPlayerPosition(spawnGhost.npcId, spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e15) {}
			try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle, true) } catch (eA) { try { setPlayerAngle(spawnGhost.npcId, spawnGhost.angle) } catch (eA2) {} }
		} else if (spawnGhost.obj != null) {
			try { spawnGhost.obj.setPosition(spawnGhost.x, spawnGhost.y, spawnGhost.z) } catch (e15b) {}
		}
		phoenix.admin.Model.spawnGhostUpdateArrow()
		phoenix.admin.Model.spawnGhostEmit()
	}

	function spawnGhostDraw() {
		if (!spawnGhost.active) return
		try { if (!("drawLine3d" in getroottable())) return } catch (e) { return }
		try { drawLine3d(spawnGhost.x, spawnGhost.y, spawnGhost.z, spawnGhost.x, spawnGhost.y + 200.0, spawnGhost.z, 90, 240, 170, true) } catch (e2) {}
		local rad = spawnGhost.angle * 3.14159 / 180.0
		local tipX = spawnGhost.x + sin(rad) * 120.0
		local tipZ = spawnGhost.z + cos(rad) * 120.0
		try { drawLine3d(spawnGhost.x, spawnGhost.y + 30.0, spawnGhost.z, tipX, spawnGhost.y + 30.0, tipZ, 255, 220, 90, true) } catch (e3) {}
		local leftRad = (spawnGhost.angle + 25.0) * 3.14159 / 180.0
		local rightRad = (spawnGhost.angle - 25.0) * 3.14159 / 180.0
		local lx = tipX - sin(leftRad) * 30.0
		local lz = tipZ - cos(leftRad) * 30.0
		local rx = tipX - sin(rightRad) * 30.0
		local rz = tipZ - cos(rightRad) * 30.0
		try { drawLine3d(tipX, spawnGhost.y + 30.0, tipZ, lx, spawnGhost.y + 30.0, lz, 255, 220, 90, true) } catch (e4) {}
		try { drawLine3d(tipX, spawnGhost.y + 30.0, tipZ, rx, spawnGhost.y + 30.0, rz, 255, 220, 90, true) } catch (e5) {}
	}

	function spawnGhostEmit() {
		try {
			phoenix.web.Manager.emit("phoenix:admin:response", {
				action = "adminSpawnGhost",
				success = true,
				error = "",
				payload = {
					active = spawnGhost.active ? 1 : 0,
					mode = spawnGhost.mode,
					posX = spawnGhost.x, posY = spawnGhost.y, posZ = spawnGhost.z,
					angle = spawnGhost.angle,
					camPitch = spawnGhost.camPitch,
					camRoll = spawnGhost.camRoll,
					world = spawnGhost.world
				}
			})
		} catch (e) {}
	}

	function previewEmit() {
		if (preview.npcId != phoenix.admin.Model.invalidNpcId) {
			try { local p = getPlayerPosition(preview.npcId); if (p != null) { preview.x = p.x; preview.y = p.y; preview.z = p.z } } catch (e) {}
			try { preview.world = getPlayerWorld(preview.npcId) } catch (e) {}
		}
		try {
			phoenix.web.Manager.emit("phoenix:admin:response", {
				action = "adminNpcPreview",
				success = true,
				error = "",
				payload = { mode = preview.mode, posX = preview.x, posY = preview.y, posZ = preview.z, angle = preview.angle, world = preview.world }
			})
		} catch (e) {}
	}

	function onRender() {
		if (preview.active && preview.npcId != phoenix.admin.Model.invalidNpcId && !preview.cameraActive) phoenix.admin.Model.previewCameraStart()
		phoenix.admin.Model.previewKeyboard()
		phoenix.admin.Model.vobPreviewKeyboard()
		phoenix.admin.Model.houseGhostKeyboard()
		phoenix.admin.Model.previewCameraTick()
		phoenix.admin.Model.vobPreviewCameraTick()
		phoenix.admin.Model.houseGhostCameraTick()
		phoenix.admin.Model.houseGhostDraw()
		phoenix.admin.Model.routineGhostKeyboard()
		phoenix.admin.Model.routineGhostCameraTick()
		phoenix.admin.Model.routineGhostDraw()
		phoenix.admin.Model.spawnGhostKeyboard()
		phoenix.admin.Model.spawnGhostCameraTick()
		phoenix.admin.Model.spawnGhostDraw()
		if (preview.active && preview.npcId != phoenix.admin.Model.invalidNpcId) phoenix.admin.Model.previewApplyAngle()
	}

	function onMouseMove(x, y) {
		if (spawnGhost.cameraActive && spawnGhost.camDragging) {
			spawnGhost.camYaw += x * 0.3
			spawnGhost.camCtrlPitch -= y * 0.6
			if (spawnGhost.camCtrlPitch < -200.0) spawnGhost.camCtrlPitch = -200.0
			if (spawnGhost.camCtrlPitch > 400.0) spawnGhost.camCtrlPitch = 400.0
			return
		}
		if (houseGhost.cameraActive && houseGhost.camDragging) {
			houseGhost.camYaw += x * 0.3
			houseGhost.camPitch -= y * 0.6
			if (houseGhost.camPitch < -200.0) houseGhost.camPitch = -200.0
			if (houseGhost.camPitch > 400.0) houseGhost.camPitch = 400.0
			return
		}
		if (vobPreview.cameraActive && vobPreview.camDragging) {
			vobPreview.camLastMx = x
			vobPreview.camLastMy = y
			vobPreview.camYaw += x * 0.3
			vobPreview.camPitch -= y * 0.6
			if (vobPreview.camPitch < -200.0) vobPreview.camPitch = -200.0
			if (vobPreview.camPitch > 400.0) vobPreview.camPitch = 400.0
			return
		}
		if (vobPreview.cameraActive) {
			vobPreview.camLastMx = x
			vobPreview.camLastMy = y
		}
		if (!preview.cameraActive || preview.cameraMode != "orbital" || !preview.camDragging) {
			preview.camLastMx = x
			preview.camLastMy = y
			return
		}
		local dx = x
		local dy = y
		preview.camLastMx = x
		preview.camLastMy = y
		preview.camYaw += dx * 0.3
		preview.camPitch -= dy * 0.6
		if (preview.camPitch < -200.0) preview.camPitch = -200.0
		if (preview.camPitch > 400.0) preview.camPitch = 400.0
	}

	function onMouseDown(button) {
		if (spawnGhost.cameraActive && spawnGhost.mode == "spawn") {
			local sgRightButton = 1
			try { sgRightButton = MOUSE_BUTTONRIGHT } catch (e) {}
			if (button == sgRightButton || button == 1) spawnGhost.camDragging = true
			return
		}
		if (houseGhost.cameraActive) {
			local houseRightButton = 1
			try { houseRightButton = MOUSE_BUTTONRIGHT } catch (e) {}
			if (button == houseRightButton || button == 1) houseGhost.camDragging = true
			return
		}
		if (vobPreview.cameraActive) {
			local vobRightButton = 1
			try { vobRightButton = MOUSE_BUTTONRIGHT } catch (e) {}
			if (button == vobRightButton || button == 1) vobPreview.camDragging = true
			return
		}
		if (!preview.cameraActive) return
		if (preview.cameraMode != "orbital") return
		local rightButton = 1
		try { rightButton = MOUSE_BUTTONRIGHT } catch (e) {}
		if (button == rightButton || button == 1) preview.camDragging = true
	}

	function onMouseUp(button) {
		local rightButton = 1
		try { rightButton = MOUSE_BUTTONRIGHT } catch (e) {}
		if (button == rightButton || button == 1) spawnGhost.camDragging = false
		if (button == rightButton || button == 1) houseGhost.camDragging = false
		if (button == rightButton || button == 1) vobPreview.camDragging = false
		if (button == rightButton || button == 1) preview.camDragging = false
	}

	function onMouseWheel(delta) {
		if (spawnGhost.cameraActive && spawnGhost.mode == "spawn") {
			spawnGhost.camDistance -= delta * 30.0
			if (spawnGhost.camDistance < 90.0) spawnGhost.camDistance = 90.0
			if (spawnGhost.camDistance > 850.0) spawnGhost.camDistance = 850.0
			return
		}
		if (vobPreview.cameraActive) {
			vobPreview.camDistance -= delta * 30.0
			if (vobPreview.camDistance < 90.0) vobPreview.camDistance = 90.0
			if (vobPreview.camDistance > 850.0) vobPreview.camDistance = 850.0
			return
		}
		if (!preview.cameraActive) return
		if (preview.cameraMode != "orbital") return
		preview.camDistance -= delta * 30.0
		if (preview.camDistance < 90.0) preview.camDistance = 90.0
		if (preview.camDistance > 850.0) preview.camDistance = 850.0
	}

	function onResponse(message) {
		try {
			phoenix.web.Manager.emit("phoenix:admin:response", {
				action = message.action,
				success = message.success,
				error = message.error,
				payload = message.payload
			})
		} catch (e) {}
	}
}

phoenix.admin.Message.Response.bind(phoenix.admin.Model.onResponse)

addEventHandler("onRender", function() {
	try { phoenix.admin.Model.onRender() } catch (e) {}
})

addEventHandler("onMouseMove", function(x, y) {
	try { phoenix.admin.Model.onMouseMove(x, y) } catch (e) {}
})

addEventHandler("onMouseDown", function(button) {
	try { phoenix.admin.Model.onMouseDown(button) } catch (e) {}
})

addEventHandler("onMouseUp", function(button) {
	try { phoenix.admin.Model.onMouseUp(button) } catch (e) {}
})

addEventHandler("onMouseWheel", function(delta) {
	try { phoenix.admin.Model.onMouseWheel(delta) } catch (e) {}
})
