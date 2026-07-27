phoenix.notification.Client <- {
	function onShow(message) {
		if (!phoenix.features.Client.effectiveEnabled("notifications.enabled")) return
		try {
			phoenix.web.Manager.emit("phoenix:notification:show", {
				kind = message.kind,
				title = message.title,
				text = message.text,
				durationMs = message.durationMs
			})
		} catch (e) {}
	}
}

phoenix.notification.Message.Show.bind(phoenix.notification.Client.onShow)
