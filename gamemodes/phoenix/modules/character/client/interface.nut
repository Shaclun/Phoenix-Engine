phoenix.character.Interface <- {
	function showSelection() {
		try { phoenix.camera.Structure.destroyCamera() } catch (e) {}
		try { phoenix.player.Controls.dettach() } catch (e) {}
		try { setHudMode(HUD_ALL, HUD_MODE_HIDDEN) } catch (e) {}
		try { phoenix.chat.Client.closeInputLocal(false) } catch (e) {}
		try { phoenix.chat.Client.hide() } catch (e) { try { phoenix.web.Manager.emit("phoenix:chat:hide", null) } catch (e2) {} }
		try {
			phoenix.player.Lobby.pickSpot()
			phoenix.player.Lobby.applyLobbyCamera()
		} catch (e) {}
		phoenix.web.Manager.show("character")
		phoenix.character.Model.requestList()
		try { phoenix.ui.ActiveGui.set("character") } catch (e) {}
	}

	function hide() {
		phoenix.web.Manager.hide()
		try {
			if (phoenix.ui.ActiveGui.is("character")) phoenix.ui.ActiveGui.clear()
		} catch (e) {}
	}
}

local phoenixCharacterAuthEvent = "phoenix.account." + "OnAuthenticated"
addEventHandler(phoenixCharacterAuthEvent, function() {
	phoenix.character.Interface.showSelection()
})
