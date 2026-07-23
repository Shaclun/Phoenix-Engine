phoenix.web.Router.on("phoenix:quest:request", function(payload) {
	if (payload == null || !("action" in payload)) return
	phoenix.quest.Model.request(payload.action, ("payload" in payload) ? payload.payload : null)
})

phoenix.web.Router.on("phoenix:quest:close", function(payload) {
	try { phoenix.quest.DialogClient.end() } catch (e) {}
	phoenix.quest.Interface.close()
})