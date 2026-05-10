phoenix.web.Manager <- {
	instance = null
	ready = false
	currentPage = null
	overlayPersistent = false
	url = "file://C:\\Users\\sudak\\Documents\\GitHub\\Phoenix-Engine\\gamemodes\\phoenix\\web\\index.html"
	pendingCalls = []

	function create() {
		if (instance != null) return

		instance = Browser(0, 0, 8192, 8192, url)
		instance.onLoad = phoenix.web.Manager.onLoad
		instance.visible = false

		setTimer(phoenix.web.Manager.forceReady, 1500, 1)
	}

	function onLoad(code = 0) {
		phoenix.web.Manager.markReady()
	}

	function forceReady() {
		if (ready) return
		markReady()
	}

	function markReady() {
		if (ready) return
		ready = true
		callEvent("phoenix.web.OnReady")

		while (pendingCalls.len() > 0) {
			local job = pendingCalls.remove(0)
			job()
		}
	}

	function activate() {
		if (instance == null) return
		instance.visible = true
		Browser.setActive(instance)
		setCursorVisible(true)
	}

	function deactivate() {
		if (instance == null) return
		local knocked = false
		try { knocked = phoenix.ui.ActiveGui.knockedDown } catch (e) {}
		try { if (!knocked) knocked = phoenix.player.HudClient.knockedDown } catch (e) {}
		if (knocked) {
			instance.visible = true
			try { Browser.setActive(instance) } catch (e) {}
			setCursorVisible(true)
			return
		}

		if (overlayPersistent) {
			try { Browser.setActive(null) } catch (e) {

				instance.visible = false
				instance.visible = true
			}
			setCursorVisible(false)
			return
		}
		instance.visible = false
		setCursorVisible(false)
	}

	function showOverlay() {
		if (instance == null) return
		overlayPersistent = true
		instance.visible = true
		try { Browser.setActive(null) } catch (e) {}
		setCursorVisible(false)
	}

	function hideOverlay() {
		overlayPersistent = false
		if (instance == null) return
		if (currentPage == null) {
			instance.visible = false
			setCursorVisible(false)
		}
	}

	function focusInput() {
		if (instance == null) return
		instance.visible = true
		Browser.setActive(instance)
		setCursorVisible(true)
	}

	function blurInput() {
		if (instance == null) return
		local knocked = false
		try { knocked = phoenix.ui.ActiveGui.knockedDown } catch (e) {}
		try { if (!knocked) knocked = phoenix.player.HudClient.knockedDown } catch (e) {}
		if (knocked) {
			instance.visible = true
			Browser.setActive(instance)
			setCursorVisible(true)
			return
		}
		try { Browser.setActive(null) } catch (e) {}
		if (overlayPersistent && currentPage == null) {
			instance.visible = true
			setCursorVisible(false)
		} else if (currentPage == null) {
			instance.visible = false
			setCursorVisible(false)
		}
	}

	function isUiBlocking() {
		return currentPage != null
	}

	function show(page) {
		try { phoenix.ui.ActiveGui.set(page) } catch (e) {}
		currentPage = page
		activate()
		jsCall1("phoenixShow", page)
	}

	function hide() {
		local page = currentPage
		currentPage = null
		jsCall0("phoenixHide")
		try { if (page != null && phoenix.ui.ActiveGui.is(page)) phoenix.ui.ActiveGui.clear() } catch (e) {}
		deactivate()
	}

	function jsCall0(funcName) {
		local job = function() {
			try { phoenix.web.Manager.instance.call(funcName) }
			catch (err) {}
		}
		if (!ready) { pendingCalls.push(job); return }
		job()
	}

	function jsCall1(funcName, arg1) {
		local job = function() {
			try { phoenix.web.Manager.instance.call(funcName, arg1) }
			catch (err) {}
		}
		if (!ready) { pendingCalls.push(job); return }
		job()
	}

	function jsCall2(funcName, arg1, arg2) {
		local job = function() {
			try { phoenix.web.Manager.instance.call(funcName, arg1, arg2) }
			catch (err) {}
		}
		if (!ready) { pendingCalls.push(job); return }
		job()
	}

	function emit(channel, payload) {
		local json = phoenix.web.Json.encode({ channel = channel, payload = payload })
		jsCall1("phoenixEmit", json)
	}
}
