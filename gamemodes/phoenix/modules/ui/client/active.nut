phoenix.ui.ActiveGui <- {
	current = null
	previous = null
	transitioning = false
	knockedDown = false
	closing = false
	closeHandlers = {}
	cameraHadOrbital = false

	function register(name, handler) {
		if (name == null || handler == null) return
		phoenix.ui.ActiveGui.closeHandlers[name.tostring()] <- handler
	}

	function _captureCameraState() {
		phoenix.ui.ActiveGui.cameraHadOrbital = false
		try { phoenix.ui.ActiveGui.cameraHadOrbital = phoenix.camera.Structure.orbitalCamera != null } catch (e) {}
	}

	function _restoreCameraState() {
		if (phoenix.ui.ActiveGui.cameraHadOrbital) {
			try { if (phoenix.camera.Structure.orbitalCamera != null) phoenix.camera.Structure.orbitalCamera.setEnabled(true) } catch (e) {}
			try { Camera.movementEnabled = false } catch (e) {}
			try { Camera.modeChangeEnabled = false } catch (e) {}
			return
		}
		try { Camera.movementEnabled = true } catch (e) {}
		try { Camera.modeChangeEnabled = true } catch (e) {}
	}

	function _closeRegistered(name) {
		if (name == null) return
		if (phoenix.ui.ActiveGui.closing) return
		if (!(name in phoenix.ui.ActiveGui.closeHandlers)) return
		phoenix.ui.ActiveGui.closing = true
		try { phoenix.ui.ActiveGui.closeHandlers[name]() } catch (e) {}
		phoenix.ui.ActiveGui.closing = false
	}

	function _applyOpenSideEffects() {
		try { setCursorVisible(true) } catch (e) {}
		try { disableControls(true) } catch (e) {}
		try { setFreeze(true) } catch (e) {}
		try { Camera.movementEnabled = false } catch (e) {}
		try { Camera.modeChangeEnabled = false } catch (e) {}
	}

	function _applyCloseSideEffects() {
		if (phoenix.ui.ActiveGui.knockedDown) {
			try { setCursorVisible(true) } catch (e) {}
			try { disableControls(true) } catch (e) {}
			try { setFreeze(true) } catch (e) {}
			try { Camera.movementEnabled = false } catch (e) {}
			try { Camera.modeChangeEnabled = false } catch (e) {}
			return
		}
		try { setCursorVisible(false) } catch (e) {}
		try { disableControls(false) } catch (e) {}
		try { setFreeze(false) } catch (e) {}
		phoenix.ui.ActiveGui._restoreCameraState()
	}

	function set(name) {
		local normalized = (name == null || name == "") ? null : name.tostring()
		if (normalized == phoenix.ui.ActiveGui.current) return
		if (normalized != null && phoenix.ui.ActiveGui.current != null) {
			phoenix.ui.ActiveGui._closeRegistered(phoenix.ui.ActiveGui.current)
			if (normalized == phoenix.ui.ActiveGui.current) return
		}
		local old = phoenix.ui.ActiveGui.current
		if (old == null && normalized != null) phoenix.ui.ActiveGui._captureCameraState()
		phoenix.ui.ActiveGui.previous = old
		phoenix.ui.ActiveGui.current = normalized

		if (old != null) {
			try { callEvent("phoenix.ui.OnClose", old) } catch (e) {}
		}
		if (normalized != null) {
			phoenix.ui.ActiveGui.transitioning = (old != null)
			phoenix.ui.ActiveGui._applyOpenSideEffects()
			try { callEvent("phoenix.ui.OnOpen", normalized) } catch (e) {}
		} else {
			phoenix.ui.ActiveGui.transitioning = false
			phoenix.ui.ActiveGui._applyCloseSideEffects()
		}

		try { callEvent("phoenix.ui.OnChange", normalized, old) } catch (e) {}
	}

	function clear() {
		phoenix.ui.ActiveGui.set(null)
	}

	function is(name) {
		if (name == null) return phoenix.ui.ActiveGui.current == null
		return phoenix.ui.ActiveGui.current == name
	}

	function isAnyOpen() {
		return phoenix.ui.ActiveGui.current != null
	}

	function setKnockedDown(value) {
		phoenix.ui.ActiveGui.knockedDown = value == true
	}
}

::setActiveGUI <- function (value) { phoenix.ui.ActiveGui.set(value) }
::isAnyGuiOpen <- function () { return phoenix.ui.ActiveGui.isAnyOpen() }

phoenix.ui.suppressEngineUi <- function () {
	try { Chat.setVisible(false) } catch (e) {}
	try { chatInputSetVisible(false) } catch (e) {}
}

addEventHandler("onRenderFocus", function (_type, _id, _x, _y, _name) {
	try { cancelEvent() } catch (e) {}
})

addEventHandler("onRender", function () {
	phoenix.ui.suppressEngineUi()
})

phoenix.ui.suppressEngineUi()
