phoenix.quest.DialogClient <- {
	active = false,

	function begin(payload) {
		phoenix.quest.DialogClient.active = true
		phoenix.quest.Interface.visible = true
		try {
			phoenix.npc.Interaction.visible = true
			phoenix.npc.Interaction.currentNpcId = payload.npcId
			phoenix.npc.Interaction.currentIdleAnimation = ("idleAnimation" in payload) ? payload.idleAnimation : "S_STAND"
		} catch (e) {}
		phoenix.web.Manager.show("quests")
		phoenix.ui.ActiveGui.set("quests")
	}

	function end() {
		if (!phoenix.quest.DialogClient.active) return
		try { phoenix.npc.Interaction.restoreAfterDialog() } catch (e) {}
		try {
			phoenix.npc.Interaction.visible = false
			phoenix.npc.Interaction.currentNpcId = -1
			phoenix.npc.Interaction.currentIdleAnimation = ""
		} catch (e2) {}
		phoenix.quest.DialogClient.active = false
	}

	function onMessage(message) {
		phoenix.quest.Model.dialog = {
			sessionId = message.sessionId,
			action = message.action,
			payload = message.payload
		}
		if (message.action == "open") phoenix.quest.DialogClient.begin(message.payload)
		else if (message.action == "close") {
			phoenix.quest.DialogClient.end()
			phoenix.quest.Interface.close()
		}
		phoenix.web.Manager.emit("phoenix:quest:dialog", phoenix.quest.Model.dialog)
	}
}

phoenix.quest.Message.Dialog.bind(phoenix.quest.DialogClient.onMessage)