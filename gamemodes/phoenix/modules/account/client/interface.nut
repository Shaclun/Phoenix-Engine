phoenix.account.Interface <- {
	function showLogin() {
		try { phoenix.camera.Structure.destroyCamera() } catch (e) {}
		try { phoenix.player.Controls.dettach() } catch (e) {}
		try {
			phoenix.player.Lobby.pickSpot()
			phoenix.player.Lobby.applyLobbyCamera()
		} catch (e) {}
		phoenix.web.Manager.show("auth")
		phoenix.web.Manager.emit("phoenix:account:authMode", { mode = "login" })
		try { phoenix.ui.ActiveGui.set("auth") } catch (e) {}
	}

	function showRegister() {
		try { phoenix.camera.Structure.destroyCamera() } catch (e) {}
		try { phoenix.player.Controls.dettach() } catch (e) {}
		try {
			phoenix.player.Lobby.pickSpot()
			phoenix.player.Lobby.applyLobbyCamera()
		} catch (e) {}
		phoenix.web.Manager.show("auth")
		phoenix.web.Manager.emit("phoenix:account:authMode", { mode = "register" })
		try { phoenix.ui.ActiveGui.set("auth") } catch (e) {}
	}
}
