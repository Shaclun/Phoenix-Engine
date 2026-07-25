phoenix.social.Interface <- {
	visible = false
	focusedTarget = -1

	function isBusy() {
		try { if (phoenix.web.Manager.isUiBlocking() && !phoenix.social.Interface.visible) return true } catch (e) {}
		try { if (phoenix.chat.Client.inputOpen) return true } catch (e2) {}
		try { if (phoenix.chat.Client.menuOpen) return true } catch (e3) {}
		return false
	}

	function hasWeaponDrawn() {
		try { return getPlayerWeaponMode(heroId) != WEAPONMODE_NONE } catch (e) {}
		return false
	}

	function distance(a, b) {
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function focusTarget() {
		local target = phoenix.social.Interface.focusedTarget
		if (target == null || target < 0 || target == heroId) return -1
		return target
	}

	function onKeyDown(key) {
		if (key == KEY_K) {
			if (phoenix.social.Interface.visible) phoenix.social.Interface.close()
			else if (!phoenix.social.Interface.isBusy()) phoenix.social.Interface.open()
			try { cancelEvent() } catch (e) {}
			return
		}
		if (key != KEY_C) return
		if (phoenix.social.Interface.isBusy()) return
		if (phoenix.social.Interface.hasWeaponDrawn()) return
		local target = phoenix.social.Interface.focusTarget()
		if (target >= 0) phoenix.social.Model.send("interact", { targetId = target })
		try { cancelEvent() } catch (e2) {}
	}

	function open(mode = "social") {
		if (!phoenix.social.Interface.visible) {
			phoenix.social.Interface.visible = true
			try { phoenix.web.Manager.show("social") } catch (e) {}
			try { phoenix.ui.ActiveGui.set("social") } catch (e2) {}
		}
		try { phoenix.web.Manager.emit("phoenix:social:mode", { mode = mode }) } catch (eMode) {}
		phoenix.social.Model.send("requestPanel")
		try {
			phoenix.web.Manager.emit("phoenix:item:inventory", { ownerType = phoenix.item.Model.ownerType, ownerId = phoenix.item.Model.ownerId, gold = phoenix.item.Model.gold, items = phoenix.item.Model.items })
		} catch (e3) {}
	}

	function close() {
		if (!phoenix.social.Interface.visible) return
		phoenix.social.Interface.visible = false
		try { phoenix.web.Manager.hide() } catch (e) {}
		try { if (phoenix.ui.ActiveGui.is("social")) phoenix.ui.ActiveGui.clear() } catch (e2) {}
	}

	function forceClose(_payload = null) { phoenix.social.Interface.close() }
}

function phoenixSocialOnFocus(newFocus, _oldFocus) {
	phoenix.social.Interface.focusedTarget = newFocus == null ? -1 : newFocus
}

function phoenixSocialOnKeyDown(key) {
	try { if (phoenix.chat.Client.inputOpen) return } catch (eChat) {}
	if (key == KEY_K) {
		if (phoenix.social.Interface.visible) phoenix.social.Interface.close()
		else if (!phoenix.social.Interface.isBusy()) phoenix.social.Interface.open()
		try { cancelEvent() } catch (e) {}
		return
	}
	if (key != KEY_C) return
	if (phoenix.social.Interface.isBusy()) return
	if (phoenix.social.Interface.hasWeaponDrawn()) return
	local target = phoenix.social.Interface.focusTarget()
	if (target >= 0) phoenix.social.Model.send("interact", { targetId = target })
	try { cancelEvent() } catch (e2) {}
}

addEventHandler("onKeyDown", phoenixSocialOnKeyDown)
addEventHandler("onFocus", phoenixSocialOnFocus)
try { phoenix.ui.ActiveGui.register("social", phoenix.social.Interface.forceClose) } catch (e) {}
