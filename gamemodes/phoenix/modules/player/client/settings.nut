phoenix.player.SettingsClient <- {
	visible = false

	function init() {
		phoenix.web.Router.on("phoenix:settings:openRequest", phoenix.player.SettingsClient.open)
		phoenix.web.Router.on("phoenix:settings:closeRequest", phoenix.player.SettingsClient.forceClose)
		try { phoenix.ui.ActiveGui.register("settings", phoenix.player.SettingsClient.forceClose) } catch (e) {}
	}

	function open(_payload) {
		if (phoenix.player.SettingsClient.visible) return
		phoenix.player.SettingsClient.visible = true
		try { phoenix.web.Manager.show("settings") } catch (e) {}
		try { phoenix.ui.ActiveGui.set("settings") } catch (e2) {}
	}

	function forceClose(_payload = null) {
		if (!phoenix.player.SettingsClient.visible) return
		phoenix.player.SettingsClient.visible = false
		try { phoenix.web.Manager.hide() } catch (e) {}
		try { if (phoenix.ui.ActiveGui.is("settings")) phoenix.ui.ActiveGui.clear() } catch (e2) {}
	}
}

phoenix.player.SettingsClient.init()
