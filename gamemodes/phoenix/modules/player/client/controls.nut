phoenix.player.Controls <- {
	dettached = false
	sitting = false
	_keyHeld = {}

	function dettach() {
		if (dettached) return
		dettached = true
		try { Camera.movementEnabled = false } catch (e) {}
		try { Camera.modeChangeEnabled = false } catch (e) {}
		try { setHudMode(HUD_ALL, HUD_MODE_HIDDEN) } catch (e) {}
		try { setFreeze(true) } catch (e) {}
		try { setCursorVisible(true) } catch (e) {}
		for (local i = 0; i < 200; i++) {
			try { disableKey(i, true) } catch (e) {}
			try { disableLogicalKey(i, true) } catch (e) {}
		}
	}

	function attach() {
		if (!dettached) return
		dettached = false
		try { Camera.setTargetPlayer(heroId) } catch (e) {}
		try { Camera.movementEnabled = true } catch (e) {}
		try { Camera.modeChangeEnabled = true } catch (e) {}
		try { setHudMode(HUD_ALL, HUD_MODE_NORMAL) } catch (e) {}
		try { setFreeze(false) } catch (e) {}
		try { setCursorVisible(false) } catch (e) {}
		for (local i = 0; i < 200; i++) {
			try { disableKey(i, false) } catch (e) {}
			try { disableLogicalKey(i, false) } catch (e) {}
		}

		try { disableLogicalKey(GAME_END, true) } catch (e) {}
		try { disableLogicalKey(GAME_INVENTORY, true) } catch (e) {}
		try { disableLogicalKey(GAME_SCREEN_STATUS, true) } catch (e) {}
		try { disableLogicalKey(GAME_SCREEN_LOG, true) } catch (e) {}
		try { disableLogicalKey(GAME_SCREEN_MAP, true) } catch (e) {}
	}
}

addEventHandler("onInit", function() {
	phoenix.player.Controls.dettach()
})

addEventHandler("phoenix.character.OnSelected", function(_characterId, _name) {
	phoenix.player.Controls.attach()
	phoenix.player.Controls.sitting = false
})

addEventHandler("onKeyDown", function(key) {
	if (phoenix.player.Controls.dettached) return
	try { if (phoenix.player.HudClient.knockedDown) return } catch (e) {}
	try { if (phoenix.chat.Client.inputOpen) return } catch (e) {}
	try { if (phoenix.chat.Client.menuOpen) return } catch (e) {}
	try { if (phoenix.web.Manager.isUiBlocking()) return } catch (e) {}
	local slot = -1
	if (key == KEY_1) slot = 0
	else if (key == KEY_2) slot = 1
	else if (key == KEY_3) slot = 2
	else if (key == KEY_4) slot = 3
	else if (key == KEY_5) slot = 4
	else if (key == KEY_6) slot = 5
	else if (key == KEY_7) slot = 6
	else if (key == KEY_8) slot = 7
	if (slot < 0) return
	try { cancelEvent() } catch (e) {}
	local now = getTickCount()
	local last = (key in phoenix.player.Controls._keyHeld) ? phoenix.player.Controls._keyHeld[key] : 0
	if (now - last < 700) return
	phoenix.player.Controls._keyHeld[key] <- now
	try { phoenix.player.HotbarUse.use(slot) } catch (e) {}
})

addEventHandler("onKeyUp", function(key) {
	if (key in phoenix.player.Controls._keyHeld) phoenix.player.Controls._keyHeld.rawdelete(key)
})

addEventHandler("onKeyDown", function(key) {
	if (key != KEY_O) return
	if (phoenix.player.Controls.dettached) return
	try { if (phoenix.chat.Client.inputOpen) return } catch (e) {}
	try { if (phoenix.chat.Client.menuOpen) return } catch (e) {}
	try { if (phoenix.web.Manager.isUiBlocking()) return } catch (e) {}
	try { if (phoenix.player.HudClient.knockedDown) return } catch (e) {}
	try { if (getPlayerWeaponMode(heroId) != 0) return } catch (e) {}
	phoenix.player.Controls.sitting = !phoenix.player.Controls.sitting
	try {
		local m = phoenix.player.Message.Sit()
		m.sitting = phoenix.player.Controls.sitting
		m.serialize().send(RELIABLE_ORDERED)
	} catch (e) {}
	try { cancelEvent() } catch (e) {}
})
