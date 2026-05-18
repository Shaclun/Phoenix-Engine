phoenix.player.HudClient <- {
	last = null
	knockedDown = false
	lastWeaponMode = -999
	lastWeaponProgress = ""
	lastWeaponEmit = 0

	function weaponKeyFromMode(mode) {
		try { if (mode == WEAPONMODE_1HS) return "oneHand" } catch (e) {}
		try { if (mode == WEAPONMODE_2HS) return "twoHand" } catch (e2) {}
		try { if (mode == WEAPONMODE_BOW) return "bow" } catch (e3) {}
		try { if (mode == WEAPONMODE_CBOW) return "crossbow" } catch (e4) {}
		return ""
	}

	function weaponLabel(key) {
		if (key == "oneHand") return "Broń jednoręczna"
		if (key == "twoHand") return "Broń dwuręczna"
		if (key == "bow") return "Łuk"
		if (key == "crossbow") return "Kusza"
		return ""
	}

	function emitWeapon(force = false, progressChanged = false) {
		local mode = 0
		try { mode = getPlayerWeaponMode(heroId) } catch (e) { mode = 0 }
		local modeChanged = mode != phoenix.player.HudClient.lastWeaponMode
		local now = getTickCount()
		if (!force && !progressChanged && !modeChanged && now - phoenix.player.HudClient.lastWeaponEmit < 250) return
		phoenix.player.HudClient.lastWeaponMode = mode
		phoenix.player.HudClient.lastWeaponEmit = now
		local key = phoenix.player.HudClient.weaponKeyFromMode(mode)
		local payload = {
			active = key != "",
			mode = mode,
			key = key,
			label = phoenix.player.HudClient.weaponLabel(key),
			weaponProgress = phoenix.player.HudClient.lastWeaponProgress,
			changed = modeChanged,
			updated = progressChanged
		}
		try { phoenix.web.Manager.emit("phoenix:hud:weapon", payload) } catch (e2) {}
	}

	function onSnapshot(message) {
		local oldWeaponProgress = phoenix.player.HudClient.lastWeaponProgress
		local payload = {
			name = message.name,
			level = message.level,
			experience = message.experience,
			experienceNext = message.experienceNext,
			hp = message.hp,
			hpMax = message.hpMax,
			mana = message.mana,
			manaMax = message.manaMax,
			stamina = message.stamina,
			staminaMax = message.staminaMax,
			weaponProgress = message.weaponProgress
		}
		phoenix.player.HudClient.lastWeaponProgress = message.weaponProgress
		phoenix.player.HudClient.last = payload
		try { phoenix.web.Manager.emit("phoenix:hud:snapshot", payload) } catch (e) {}
		phoenix.player.HudClient.emitWeapon(true, oldWeaponProgress != phoenix.player.HudClient.lastWeaponProgress)
	}

	function onKnockedDown(message) {
		phoenix.player.HudClient.knockedDown = true
		try { phoenix.ui.ActiveGui.setKnockedDown(true) } catch (e) {}
		try { disableControls(true) } catch (e) {}
		try { setFreeze(true) } catch (e) {}
		try { Camera.movementEnabled = false } catch (e) {}
		try { Camera.modeChangeEnabled = false } catch (e) {}
		try { setCursorVisible(true) } catch (e) {}
		try { phoenix.web.Manager.focusInput() } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:player:knockedDown", { secondsRemaining = message.secondsRemaining }) } catch (e) {}
	}

	function onRevived(message) {
		phoenix.player.HudClient.knockedDown = false
		try { phoenix.ui.ActiveGui.setKnockedDown(false) } catch (e) {}
		try { stopAni(heroId, "S_DEADB") } catch (e) {}
		try { stopAni(heroId, "T_DEADB") } catch (e) {}
		try { disableControls(false) } catch (e) {}
		try { setFreeze(false) } catch (e) {}
		try { Camera.movementEnabled = true } catch (e) {}
		try { Camera.modeChangeEnabled = true } catch (e) {}
		try { setCursorVisible(false) } catch (e) {}
		try {
			if ("camera" in phoenix && "Structure" in phoenix.camera) {
				phoenix.camera.Structure.destroyCamera()
				phoenix.camera.Structure.isActivated = true
				setTimer(phoenix.camera.Structure.activate, 250, 1)
			}
		} catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:player:revived", { hp = message.hp, hpMax = message.hpMax }) } catch (e) {}
	}

	function onRespawnChoice(payload) {
		local mode = "here"
		try {
			if (payload != null && "mode" in payload && payload.mode != null) mode = payload.mode.tostring()
		} catch (e) {}
		if (mode != "spawn") mode = "here"
		local msg = phoenix.player.Message.RespawnChoice()
		msg.mode = mode
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}
}

phoenix.player.Message.HudSnapshot.bind(phoenix.player.HudClient.onSnapshot)
phoenix.player.Message.KnockedDown.bind(phoenix.player.HudClient.onKnockedDown)
phoenix.player.Message.Revived.bind(phoenix.player.HudClient.onRevived)
phoenix.web.Router.on("phoenix:player:respawnChoice", phoenix.player.HudClient.onRespawnChoice)

phoenix.player.HotbarClient <- {
	function onSnapshot(message) {
		try { phoenix.web.Manager.emit("phoenix:hotbar:snapshot", { data = message.data }) } catch (e) {}
	}

	function onSave(payload) {
		if (payload == null || !("data" in payload)) return
		local m = phoenix.player.Message.HotbarUpdate()
		m.data = payload.data.tostring()
		try { m.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}
}

phoenix.player.HotbarUse <- {
	function use(slot) {
		local m = phoenix.player.Message.HotbarActivate()
		m.slot = slot
		try { m.serialize().send(RELIABLE) } catch (e) {}
	}
}

phoenix.player.Message.HotbarSnapshot.bind(phoenix.player.HotbarClient.onSnapshot)
phoenix.web.Router.on("phoenix:hotbar:save", phoenix.player.HotbarClient.onSave)

addEventHandler("onRender", function () {
	if (!phoenix.player.HudClient.knockedDown) return
	try {
		local cur = getPlayerAni(heroId)
		if (cur != "T_VICTIM" && cur != "S_DEADB" && cur != "T_DEADB") {
			playAni(heroId, "S_DEADB")
		}
	} catch (e) {}
	try { if (getPlayerWeaponMode(heroId) != 0) setPlayerWeaponMode(heroId, 0) } catch (e) {}
})

addEventHandler("onRender", function () {
	phoenix.player.HudClient.emitWeapon(false, false)
})


phoenix.player.Target <- {
	scanInterval = 200
	scanRange = 1500.0
	current = -1
	focus = -1
	timer = null
	lastScan = 0

	function onFocus(newFocus, oldFocus) {
		phoenix.player.Target.focus = newFocus == null ? -1 : newFocus
		phoenix.player.Target.scan()
	}

	function onRenderFocus(_type, id, _x, _y, _name) {
		if (id != null && id >= 0 && id != phoenix.player.Target.focus) {
			phoenix.player.Target.focus = id
			phoenix.player.Target.scan()
		}
	}

	function scan() {
		if (heroId < 0) return
		local pos = null
		try { pos = getPlayerPosition(heroId) } catch (e) { return }
		if (pos == null) return

		local best = phoenix.player.Target.focus
		if (best == null) best = -1
		local bestKind = phoenix.player.Target.kindOf(best)
		if (!phoenix.player.Target.isValidFocus(best, pos)) best = -1

		try { phoenix.npc.Nameplates.setVisibleId(best) } catch (e) {}

		if (best < 0) {
			if (phoenix.player.Target.current != -1) {
				phoenix.player.Target.current = -1
				try { phoenix.web.Manager.emit("phoenix:hud:target:clear", { cleared = 1 }) } catch (e) {}
			}
			return
		}
		phoenix.player.Target.current = best

		local weaponMode = 0
		try { weaponMode = getPlayerWeaponMode(heroId) } catch (e) {}
		if (weaponMode == 0) {
			try { phoenix.web.Manager.emit("phoenix:hud:target:clear", { cleared = 1 }) } catch (e) {}
			return
		}

		local data = phoenix.player.Target._collect(best)
		if (data != null) {
			data.kind <- bestKind
			try { phoenix.web.Manager.emit("phoenix:hud:target", data) } catch (e) {}
		}
	}

	function kindOf(pid) {
		try { if (pid in phoenix.npc.Nameplates.entries) return "npc" } catch (e) {}
		return "player"
	}

	function isValidFocus(pid, heroPos) {
		if (pid == null || pid < 0 || pid == heroId) return false
		local hp = 0
		try { hp = getPlayerHealth(pid) } catch (e) {}
		if (hp <= 0) return false
		local tp = null
		try { tp = getPlayerPosition(pid) } catch (e) {}
		if (tp == null) return false
		local dx = tp.x - heroPos.x
		local dz = tp.z - heroPos.z
		local dy = tp.y - heroPos.y
		local distance = sqrt(dx * dx + dy * dy + dz * dz)
		return distance <= phoenix.player.Target.scanRange
	}

	function _collect(pid) {
		local name = ""
		try { name = getPlayerName(pid) } catch (e) {}
		if (name == null || name == "") {
			try { name = getPlayerInstance(pid) } catch (e) {}
		}
		local hp = 0
		try { hp = getPlayerHealth(pid) } catch (e) {}
		local hpMax = hp
		try { hpMax = getPlayerMaxHealth(pid) } catch (e) {}
		if (hpMax <= 0) hpMax = 1
		local mana = 0
		try { mana = getPlayerMana(pid) } catch (e) {}
		local manaMax = 0
		try { manaMax = getPlayerMaxMana(pid) } catch (e) {}
		local level = 1
		try {
			if (pid in phoenix.npc.Nameplates.entries) {
				local entry = phoenix.npc.Nameplates.entries[pid]
				name = phoenix.npc.Nameplates.displayName(entry)
				if ("level" in entry) level = entry.level
				if ("hp" in entry) hp = entry.hp
				if ("hpMax" in entry) hpMax = entry.hpMax
				if (("manaMax" in entry) && entry.manaMax > 0) {
					if ("mana" in entry) mana = entry.mana
					manaMax = entry.manaMax
				}
			}
		} catch (e) {}

		return {
			name = name == null ? "" : name,
			level = level,
			hp = hp, hpMax = hpMax,
			mana = mana, manaMax = manaMax
		}
	}

	function start() {
		if (phoenix.player.Target.timer != null) return
		phoenix.player.Target.timer = setTimer(phoenix.player.Target.scan, phoenix.player.Target.scanInterval, 0)
	}

	function onRender() {
		local now = getTickCount()
		if (now - phoenix.player.Target.lastScan < phoenix.player.Target.scanInterval) return
		phoenix.player.Target.lastScan = now
		phoenix.player.Target.scan()
	}
}

addEventHandler("phoenix.character.OnSelected", function (_characterId, _name) {
	phoenix.player.Target.start()
})

addEventHandler("onFocus", function (newFocus, oldFocus) {
	phoenix.player.Target.onFocus(newFocus, oldFocus)
})

addEventHandler("onRenderFocus", function (_type, _id, _x, _y, _name) {
	phoenix.player.Target.onRenderFocus(_type, _id, _x, _y, _name)
	cancelEvent()
})

addEventHandler("onRender", function () {
	phoenix.player.Target.onRender()
})

phoenix.player.Target.start()
