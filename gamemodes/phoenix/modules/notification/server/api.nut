phoenix.notification.Api <- {
	function notify(playerId, kind, title, text, durationMs) {
		if (!phoenix.features.Settings.isEnabled("notifications.enabled")) return
		if (playerId == null || playerId < 0) return
		local msg = phoenix.notification.Message.Show()
		msg.kind = kind != null ? kind.tostring() : "info"
		msg.title = title != null ? title.tostring() : ""
		msg.text = text != null ? text.tostring() : ""
		msg.durationMs = (durationMs != null && durationMs > 0) ? durationMs.tointeger() : 4000
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function broadcast(kind, title, text, durationMs) {
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try { if (isPlayerConnected(pid)) phoenix.notification.Api.notify(pid, kind, title, text, durationMs) } catch (e) {}
		}
	}
}

phoenix.notification.notify <- phoenix.notification.Api.notify
phoenix.notification.broadcast <- phoenix.notification.Api.broadcast
