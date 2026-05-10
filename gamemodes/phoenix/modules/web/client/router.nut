phoenix.web.Router <- {
	routes = {}

	function on(channel, handler) {
		if (!(channel in routes)) routes[channel] <- []
		routes[channel].push(handler)
	}

	function dispatch(channel, payload) {
		if (!(channel in routes)) return
		foreach (handler in routes[channel]) handler(payload)
	}

	function handleRaw(raw) {
		if (raw == null) return
		try {
			local parsed = phoenix.web.Json.parse(raw)
			if (parsed == null) return
			dispatch(parsed.channel, "payload" in parsed ? parsed.payload : null)
		} catch (e) {}
	}
}
