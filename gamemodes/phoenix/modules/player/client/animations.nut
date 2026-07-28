phoenix.player.AnimationClient <- {
	visible = false
	characterId = 0
	bindings = ["", "", "", "", "", "", "", "", "", "", "", ""]
	activeId = ""
	lastGuardAt = 0

	function enabled() {
		return phoenix.features.Client.effectiveEnabled("player.animations")
	}

	function isBusy() {
		try { if (phoenix.chat.Client.inputOpen || phoenix.chat.Client.menuOpen) return true } catch (e) {}
		try { if (phoenix.player.HudClient.knockedDown) return true } catch (e2) {}
		try { if (phoenix.player.Controls.dettached) return true } catch (e3) {}
		try { if (phoenix.quest.DialogClient.active) return true } catch (e4) {}
		try { if (getPlayerWeaponMode(heroId) != WEAPONMODE_NONE) return true } catch (e5) {}
		return false
	}

	function blocksActiveAnimation() {
		try { if (phoenix.chat.Client.inputOpen || phoenix.chat.Client.menuOpen) return true } catch (e) {}
		try { if (phoenix.player.HudClient.knockedDown) return true } catch (e2) {}
		// A web panel temporarily detaches controls after a click. It must not cancel
		// an animation that the same click has just started.
		try { if (phoenix.quest.DialogClient.active) return true } catch (e3) {}
		try { if (getPlayerWeaponMode(heroId) != WEAPONMODE_NONE) return true } catch (e4) {}
		return false
	}

	function hasMovementInput() {
		try {
			return isKeyPressed(KEY_W) || isKeyPressed(KEY_A) || isKeyPressed(KEY_S) || isKeyPressed(KEY_D) || isKeyPressed(KEY_UP) || isKeyPressed(KEY_DOWN) || isKeyPressed(KEY_LEFT) || isKeyPressed(KEY_RIGHT) || isKeyPressed(KEY_SPACE)
		} catch (e) {}
		return false
	}

	function slotForKey(key) {
		if (key == KEY_F1) return 0
		if (key == KEY_F2) return 1
		if (key == KEY_F3) return 2
		if (key == KEY_F4) return 3
		if (key == KEY_F5) return 4
		if (key == KEY_F6) return 5
		if (key == KEY_F7) return 6
		if (key == KEY_F8) return 7
		if (key == KEY_F9) return 8
		if (key == KEY_F10) return 9
		if (key == KEY_F11) return 10
		if (key == KEY_F12) return 11
		return -1
	}

	function onKeyDown(key) {
		if (key == KEY_N) {
			if (!phoenix.player.AnimationClient.enabled() || phoenix.player.AnimationClient.characterId <= 0) return
			if (phoenix.player.AnimationClient.visible) phoenix.player.AnimationClient.close()
			else {
				try { if (phoenix.web.Manager.isUiBlocking()) return } catch (e) {}
				if (!phoenix.player.AnimationClient.isBusy()) phoenix.player.AnimationClient.open()
			}
			try { cancelEvent() } catch (e2) {}
			return
		}
		local slot = phoenix.player.AnimationClient.slotForKey(key)
		if (slot < 0) return
		if (!phoenix.player.AnimationClient.enabled() || phoenix.player.AnimationClient.characterId <= 0) return
		try { if (phoenix.web.Manager.isUiBlocking()) return } catch (e3) {}
		if (phoenix.player.AnimationClient.isBusy()) return
		local id = phoenix.player.AnimationClient.bindings[slot]
		if (id == "") return
		phoenix.player.AnimationClient.requestPlay(id)
		try { cancelEvent() } catch (e4) {}
	}

	function open() {
		if (phoenix.player.AnimationClient.visible || !phoenix.player.AnimationClient.enabled()) return
		phoenix.player.AnimationClient.visible = true
		try { phoenix.web.Manager.show("animations") } catch (e) {}
		try { phoenix.ui.ActiveGui.set("animations") } catch (e2) {}
		phoenix.player.AnimationClient.emitState()
	}

	function close() {
		if (!phoenix.player.AnimationClient.visible) return
		phoenix.player.AnimationClient.visible = false
		try { phoenix.web.Manager.hide() } catch (e) {}
		try { if (phoenix.ui.ActiveGui.is("animations")) phoenix.ui.ActiveGui.clear() } catch (e2) {}
	}

	function forceClose(_payload = null) {
		phoenix.player.AnimationClient.close()
	}

	function emitState(_payload = null) {
		try {
			phoenix.web.Manager.emit("phoenix:animations:state", {
				enabled = phoenix.player.AnimationClient.enabled(),
				characterId = phoenix.player.AnimationClient.characterId,
				bindings = phoenix.player.AnimationClient.bindings,
				activeId = phoenix.player.AnimationClient.activeId,
				catalog = phoenix.player.AnimationsCatalog.publicEntries()
			})
		} catch (e) {}
	}

	function onBindings(payload) {
		if (payload == null || !("slots" in payload) || typeof payload.slots != "array") return
		local next = ["", "", "", "", "", "", "", "", "", "", "", ""]
		for (local i = 0; i < 12 && i < payload.slots.len(); i += 1) {
			local id = payload.slots[i] == null ? "" : payload.slots[i].tostring()
			local entry = phoenix.player.AnimationsCatalog.find(id)
			if (entry != null && entry.playable) next[i] = entry.id
		}
		phoenix.player.AnimationClient.bindings = next
		phoenix.player.AnimationClient.emitState()
	}

	function requestPlay(id) {
		if (!phoenix.player.AnimationClient.enabled() || phoenix.player.AnimationClient.isBusy()) return
		local entry = phoenix.player.AnimationsCatalog.find(id)
		if (entry == null || !entry.playable) return
		local message = phoenix.player.Message.AnimationPlayRequest()
		message.id = entry.id
		try { message.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onWebPlay(payload) {
		if (payload == null || !("id" in payload)) return
		phoenix.player.AnimationClient.requestPlay(payload.id.tostring())
	}

	function requestStop(_payload = null) {
		try { phoenix.player.Message.AnimationStopRequest().serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onResult(message) {
		if (message.success && message.active) {
			local entry = phoenix.player.AnimationsCatalog.find(message.id)
			phoenix.player.AnimationClient.activeId = entry != null ? entry.id : ""
		} else if (message.success && !message.active) {
			phoenix.player.AnimationClient.activeId = ""
		}
		try {
			phoenix.web.Manager.emit("phoenix:animations:result", {
				success = message.success,
				error = message.error,
				id = message.id,
				active = message.active
			})
		} catch (e2) {}
	}

	function stopForGuard() {
		if (phoenix.player.AnimationClient.activeId == "") return
		phoenix.player.AnimationClient.activeId = ""
		phoenix.player.AnimationClient.requestStop()
	}

	function onRender() {
		if (phoenix.player.AnimationClient.activeId == "") return
		local now = getTickCount()
		if (now - phoenix.player.AnimationClient.lastGuardAt < 100) return
		phoenix.player.AnimationClient.lastGuardAt = now
		local entry = phoenix.player.AnimationsCatalog.find(phoenix.player.AnimationClient.activeId)
		local stopOnMove = entry == null || !("stopOnMove" in entry) || entry.stopOnMove
		if (!phoenix.player.AnimationClient.enabled() || phoenix.player.AnimationClient.blocksActiveAnimation() || (stopOnMove && phoenix.player.AnimationClient.hasMovementInput())) phoenix.player.AnimationClient.stopForGuard()
	}

	function onCharacterSelected(characterId, _name) {
		phoenix.player.AnimationClient.close()
		phoenix.player.AnimationClient.characterId = characterId
		phoenix.player.AnimationClient.bindings = ["", "", "", "", "", "", "", "", "", "", "", ""]
		phoenix.player.AnimationClient.activeId = ""
		phoenix.player.AnimationClient.emitState()
	}

	function onFeatureChanged(key, enabled) {
		if (key != "player.animations") return
		if (!enabled) {
			phoenix.player.AnimationClient.close()
			phoenix.player.AnimationClient.activeId = ""
		}
		phoenix.player.AnimationClient.emitState()
	}
}
addEventHandler("onKeyDown", function(key) { phoenix.player.AnimationClient.onKeyDown(key) })
addEventHandler("onRender", function() { phoenix.player.AnimationClient.onRender() })
addEventHandler("onFocus", function(newFocus, _oldFocus) { if (!newFocus) phoenix.player.AnimationClient.close() })
local phoenixAnimationsClientSelectedEvent = "phoenix.character." + "OnSelected"
local phoenixAnimationsClientFeatureEvent = "phoenix.features." + "ClientChanged"
local phoenixAnimationsWebReadyEvent = "phoenix.web." + "OnReady"
addEventHandler(phoenixAnimationsClientSelectedEvent, function(characterId, name) { phoenix.player.AnimationClient.onCharacterSelected(characterId, name) })
addEventHandler(phoenixAnimationsClientFeatureEvent, function(key, enabled) { phoenix.player.AnimationClient.onFeatureChanged(key, enabled) })
addEventHandler(phoenixAnimationsWebReadyEvent, function() { phoenix.player.AnimationClient.emitState() })
phoenix.player.Message.AnimationResult.bind(phoenix.player.AnimationClient.onResult)
phoenix.web.Router.on("phoenix:animations:request", phoenix.player.AnimationClient.emitState)
phoenix.web.Router.on("phoenix:animations:bindings", phoenix.player.AnimationClient.onBindings)
phoenix.web.Router.on("phoenix:animations:play", phoenix.player.AnimationClient.onWebPlay)
phoenix.web.Router.on("phoenix:animations:stop", phoenix.player.AnimationClient.requestStop)
phoenix.web.Router.on("phoenix:animations:close", phoenix.player.AnimationClient.forceClose)
try { phoenix.ui.ActiveGui.register("animations", phoenix.player.AnimationClient.forceClose) } catch (e) {}