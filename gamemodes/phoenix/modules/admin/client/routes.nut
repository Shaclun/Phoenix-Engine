if ("Router" in phoenix.web && phoenix.web.Router != null) {

	phoenix.web.Router.on("phoenix:admin:request", function(payload) {
		if (payload == null || !("action" in payload)) return
		if (phoenix.admin.Model.handleLocal(payload.action, ("payload" in payload) ? payload.payload : null)) return
		phoenix.admin.Model.send(payload.action, ("payload" in payload) ? payload.payload : null)
	})
}
