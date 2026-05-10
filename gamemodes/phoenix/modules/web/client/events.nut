addEventHandler("onInit", function() {
	phoenix.web.Manager.create()
})

phoenix.web.Router.on("phoenix:web:ready", function(_payload) {
	phoenix.web.Manager.markReady()
})

phoenix.web.Router.on("phoenix:app:exit", function(_payload) {
	try { exitGame() } catch (e) {}
})

phoenix.web.Storage <- {
	prefix = "phoenix:store:"

	function read(key) {
		try { return LocalStorage.getItem(prefix + key) } catch (e) { return null }
	}

	function write(key, value) {
		try { LocalStorage.setItem(prefix + key, value) } catch (e) {}
	}
}

phoenix.web.Router.on("phoenix:storage:set", function(payload) {
	if (payload == null || !("key" in payload)) return
	phoenix.web.Storage.write(payload.key, ("value" in payload) ? payload.value : null)
})

phoenix.web.Router.on("phoenix:storage:get", function(payload) {
	if (payload == null || !("key" in payload)) return
	local value = phoenix.web.Storage.read(payload.key)
	phoenix.web.Manager.emit("phoenix:storage:value", {
		key = payload.key
		value = value
	})
})

::phoenixWebSend <- function(jsonString) {
	phoenix.web.Router.handleRaw(jsonString)
}
