phoenix.quest.Interface <- {
	visible = false,

	function open() {
		if (phoenix.quest.Interface.visible) return
		try { if (phoenix.web.Manager.isUiBlocking()) return } catch (e) {}
		phoenix.quest.Interface.visible = true
		phoenix.web.Manager.show("quests")
		phoenix.ui.ActiveGui.set("quests")
		phoenix.quest.Model.emitState()
		phoenix.quest.Model.request("snapshot", null)
	}

	function close() {
		if (!phoenix.quest.Interface.visible) return
		local closeDialog = false
		local sessionId = ""
		try {
			closeDialog = phoenix.quest.DialogClient.active
			if (closeDialog && phoenix.quest.Model.dialog != null && "sessionId" in phoenix.quest.Model.dialog) sessionId = phoenix.quest.Model.dialog.sessionId
		} catch (eState) {}
		phoenix.quest.Interface.visible = false
		if (closeDialog && sessionId != "") try { phoenix.quest.Model.request("dialogClose", { sessionId = sessionId }) } catch (eRequest) {}
		try { phoenix.quest.DialogClient.end() } catch (eDialog) {}
		try {
			phoenix.npc.Interaction.visible = false
			phoenix.npc.Interaction.currentNpcId = -1
			phoenix.npc.Interaction.currentIdleAnimation = ""
		} catch (eNpc) {}
		try { phoenix.web.Manager.hide() } catch (e) {}
		try { if (phoenix.ui.ActiveGui.is("quests")) phoenix.ui.ActiveGui.clear() } catch (e) {}
	}

	function toggle() {
		if (phoenix.quest.Interface.visible) phoenix.quest.Interface.close()
		else phoenix.quest.Interface.open()
	}

	function forceClose(value = null) {
		phoenix.quest.Interface.close()
	}
}

addEventHandler("onKeyDown", function(key) {
	if (key == KEY_L) phoenix.quest.Interface.toggle()
})

addEventHandler("onFocus", function(newFocus, oldFocus) {
	if (!newFocus) phoenix.quest.Interface.close()
})

phoenix.ui.ActiveGui.register("quests", phoenix.quest.Interface.forceClose)