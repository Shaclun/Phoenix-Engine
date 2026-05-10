phoenix.npc.Interaction <- {
	visible = false
	currentNpcId = -1
	currentIdleAnimation = ""
	dialogCameraFrozen = false
	lastClickAt = 0

	function init() {
		phoenix.web.Router.on("phoenix:teacher:close", phoenix.npc.Interaction.forceClose)
		phoenix.web.Router.on("phoenix:teacher:train", phoenix.npc.Interaction.onTrain)
		phoenix.web.Router.on("phoenix:npc:dialogAction", phoenix.npc.Interaction.onDialogAction)
		phoenix.web.Router.on("phoenix:npc:dialogStage", phoenix.npc.Interaction.onDialogStage)
		phoenix.web.Router.on("phoenix:merchant:trade", phoenix.npc.Interaction.onMerchantTrade)
		try { phoenix.ui.ActiveGui.register("teacher", phoenix.npc.Interaction.forceClose) } catch (e) {}
	}

	function isBusy() {
		try { if (phoenix.web.Manager.isUiBlocking()) return true } catch (e) {}
		return false
	}

	function open(payload) {
		if (phoenix.npc.Interaction.visible) {
			try { phoenix.npc.Interaction.emitPayload(payload) } catch (e) {}
			return
		}
		phoenix.npc.Interaction.visible = true
		phoenix.npc.Interaction.currentNpcId = ("npcId" in payload) ? payload.npcId : -1
		phoenix.npc.Interaction.currentIdleAnimation = ("idleAnimation" in payload) ? payload.idleAnimation : ""
		try { phoenix.web.Manager.show("teacher") } catch (e) {}
		try { phoenix.npc.Interaction.emitPayload(payload) } catch (e) {}
		try { phoenix.ui.ActiveGui.set("teacher") } catch (e) {}
	}

	function emitPayload(payload) {
		local mode = (payload != null && "mode" in payload) ? payload.mode : "teacher"
		if (mode == "dialog") { phoenix.web.Manager.emit("phoenix:npc:dialog", payload); return }
		if (mode == "merchant") { phoenix.web.Manager.emit("phoenix:merchant:dialog", payload); return }
		phoenix.web.Manager.emit("phoenix:teacher:dialog", payload)
	}

	function close() {
		if (!phoenix.npc.Interaction.visible) return
		local closingNpcId = phoenix.npc.Interaction.currentNpcId
		try { phoenix.npc.Interaction.restoreAfterDialog() } catch (e) {}
		phoenix.npc.Interaction.visible = false
		phoenix.npc.Interaction.currentNpcId = -1
		phoenix.npc.Interaction.currentIdleAnimation = ""
		try { phoenix.web.Manager.hide() } catch (e) {}
		try {
			if (phoenix.ui.ActiveGui.is("teacher")) phoenix.ui.ActiveGui.clear()
		} catch (e) {}
		if (closingNpcId >= 0) {
			try {
				local m = phoenix.npc.Message.DialogAction()
				m.npcId = closingNpcId
				m.action = "close"
				m.serialize().send(RELIABLE_ORDERED)
			} catch (e) {}
		}
	}

	function forceClose(_a = null) { phoenix.npc.Interaction.close() }

	function onTrain(payload) {
		if (payload == null || !("skill" in payload)) return
		local m = phoenix.npc.Message.TeacherTrain()
		m.npcId = phoenix.npc.Interaction.currentNpcId
		m.skill = payload.skill.tostring()
		try { m.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onDialogAction(payload) {
		if (payload == null || !("action" in payload)) return
		local m = phoenix.npc.Message.DialogAction()
		m.npcId = phoenix.npc.Interaction.currentNpcId
		m.action = payload.action.tostring()
		try { m.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onDialogStage(payload) {
		if (payload == null || !("speaker" in payload)) return
		local speaker = payload.speaker.tostring()
		local npcId = phoenix.npc.Interaction.currentNpcId
		if (!phoenix.npc.Interaction.dialogCameraFrozen) {
			try { phoenix.camera.Structure.freeze() } catch (e) {}
			phoenix.npc.Interaction.dialogCameraFrozen = true
		}
		try { disableControls(true) } catch (e) {}
		try { setFreeze(true) } catch (e) {}
		if (speaker == "player") {
			phoenix.npc.Interaction.focusSpeaker(heroId)
			try { phoenix.npc.Interaction.playGesture(heroId) } catch (e) {}
			return
		}
		phoenix.npc.Interaction.focusSpeaker(npcId)
		try { phoenix.npc.Interaction.playGesture(npcId) } catch (e) {}
	}

	function focusSpeaker(playerId) {
		try { Camera.setBeforePlayer(playerId, 240); return } catch (e) {}
		local pos = null
		try { pos = getPlayerPosition(playerId) } catch (e) { return }
		if (pos == null) return
		local angle = 0.0
		try { angle = getPlayerAngle(playerId) } catch (e) {}
		local rad = angle * 3.14159 / 180.0
		local distance = 245.0
		local camX = pos.x + sin(rad) * distance
		local camY = pos.y + 118.0
		local camZ = pos.z + cos(rad) * distance
		try { Camera.setPosition(camX, camY, camZ) } catch (e) {}
		local dX = pos.x - camX
		local dZ = pos.z - camZ
		local dY = (pos.y + 95.0) - camY
		local yaw = atan2(dX, dZ) * 180.0 / 3.14159
		local distance2D = sqrt(dX * dX + dZ * dZ)
		local pitch = -atan2(dY, distance2D) * 180.0 / 3.14159
		try { Camera.setRotation(pitch, yaw, 0) } catch (e) {}
	}

	function playGesture(playerId) {
		local index = 1 + (rand() % 18)
		local suffix = index < 10 ? "0" + index : index.tostring()
		try { playAni(playerId, "T_DIALOGGESTURE_" + suffix) } catch (e) { try { playAni(playerId, "T_STAND_2_TALK") } catch (e2) {} }
	}

	function stopDialogPose(playerId) {
		try { stopAni(playerId, "T_STAND_2_TALK") } catch (e) {}
		try { stopAni(playerId, "S_TALK") } catch (e) {}
		for (local i = 1; i <= 18; i += 1) {
			local suffix = i < 10 ? "0" + i : i.tostring()
			try { stopAni(playerId, "T_DIALOGGESTURE_" + suffix) } catch (eGesture) {}
		}
	}

	function onMerchantTrade(payload) {
		if (payload == null || !("mode" in payload)) return
		local m = phoenix.npc.Message.MerchantTrade()
		m.npcId = phoenix.npc.Interaction.currentNpcId
		m.mode = payload.mode.tostring()
		m.instance = ("instance" in payload && payload.instance != null) ? payload.instance.tostring() : ""
		m.itemId = ("itemId" in payload && payload.itemId != null) ? payload.itemId : 0
		m.amount = ("amount" in payload && payload.amount != null) ? payload.amount : 1
		try { m.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onNpcDialog(message) {
		phoenix.npc.Interaction.open({
			mode = "dialog",
			npcId = message.npcId,
			npcName = message.npcName,
			idleAnimation = message.idleAnimation,
			hasTeacher = message.hasTeacher,
			hasMerchant = message.hasMerchant
		})
	}

	function onDialog(message) {
		phoenix.npc.Interaction.open({
			mode = "teacher",
			npcId = message.npcId,
			npcName = message.npcName,
			skills = message.skills,
			cost = message.cost,
			playerGold = message.playerGold,
			playerLearnPoints = message.playerLearnPoints,
			weaponProgress = message.weaponProgress
		})
	}

	function onResult(message) {
		try {
			phoenix.web.Manager.emit("phoenix:teacher:result", { success = message.success, error = message.error })
		} catch (e) {}
	}

	function onMerchantDialog(message) {
		phoenix.npc.Interaction.open({
			mode = "merchant",
			npcId = message.npcId,
			npcName = message.npcName,
			items = message.items,
			playerItems = message.playerItems,
			playerGold = message.playerGold
		})
	}

	function onMerchantResult(message) {
		try {
			phoenix.web.Manager.emit("phoenix:merchant:result", { success = message.success, error = message.error, playerGold = message.playerGold })
		} catch (e) {}
	}

	function restoreAfterDialog() {
		local npcId = phoenix.npc.Interaction.currentNpcId
		local idle = phoenix.npc.Interaction.currentIdleAnimation
		local upIdle = idle != null ? idle.tostring().toupper() : ""
		if (upIdle == "S_RUN" || upIdle.find("RUN") != null || upIdle.find("WALK") != null || upIdle.find("ATTACK") != null || upIdle.find("WARN") != null) idle = "S_STAND"
		try { phoenix.npc.Interaction.stopDialogPose(heroId) } catch (e) {}
		try { phoenix.npc.Interaction.stopDialogPose(npcId) } catch (e) {}
		try { if (npcId >= 0 && idle != "") playAni(npcId, idle) } catch (e) {}
		if (phoenix.npc.Interaction.dialogCameraFrozen) {
			try { phoenix.camera.Structure.release() } catch (e) {}
			phoenix.npc.Interaction.dialogCameraFrozen = false
		}
	}
}

phoenix.npc.InteractionMouseDown <- function(button) {
	local left = 0
	try { left = MOUSE_BUTTONLEFT } catch (e) { left = 0 }
	if (button != left && button != 0) return
	local now = getTickCount()
	if ((now - phoenix.npc.Interaction.lastClickAt) < 250) return
	phoenix.npc.Interaction.lastClickAt = now
	if (phoenix.npc.Interaction.visible) return
	if (phoenix.npc.Interaction.isBusy()) return
	local id = phoenix.npc.Nameplates.visibleId
	if (id < 0) return
	if (!(id in phoenix.npc.Nameplates.entries)) return
	try {
		local hp = getPlayerHealth(id)
		if (hp <= 0) return
		local heroPos = getPlayerPosition(heroId)
		local npcPos = getPlayerPosition(id)
		if (heroPos == null || npcPos == null) return
		if (phoenix.npc.Nameplates.distance(heroPos, npcPos) > 300.0) return
	} catch (e) { return }
	local m = phoenix.npc.Message.InteractRequest()
	m.npcId = id
	try { m.serialize().send(RELIABLE_ORDERED) } catch (e) {}
}

addEventHandler("onMouseDown", function(button) { phoenix.npc.InteractionMouseDown(button) })
phoenix.npc.Message.Dialog.bind(phoenix.npc.Interaction.onNpcDialog)
phoenix.npc.Message.TeacherDialog.bind(phoenix.npc.Interaction.onDialog)
phoenix.npc.Message.TeacherResult.bind(phoenix.npc.Interaction.onResult)
phoenix.npc.Message.MerchantDialog.bind(phoenix.npc.Interaction.onMerchantDialog)
phoenix.npc.Message.MerchantResult.bind(phoenix.npc.Interaction.onMerchantResult)
phoenix.npc.Interaction.init()
