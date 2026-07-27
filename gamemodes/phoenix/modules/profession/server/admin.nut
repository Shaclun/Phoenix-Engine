phoenix.profession.Admin <- {
	function list(playerId, _payload) {
		try {
			phoenix.admin.Server.reply(playerId, "professionList", true, "", { entries = phoenix.profession.Structure.adminDefinitions() })
		} catch (e) { phoenix.admin.Server.reply(playerId, "professionList", false, "exception", null) }
	}

	function save(playerId, payload) {
		phoenix.profession.Structure.saveDefinition(payload, function(ok, error, id) {
			if (ok) phoenix.admin.Server.audit(playerId, "professionSave", "profession", null, id, payload.code)
			phoenix.admin.Server.reply(playerId, "professionSave", ok, error, { id = id })
		})
	}

	function remove(playerId, payload) {
		local id = 0
		try { if (payload != null && "id" in payload) id = payload.id.tointeger() } catch (e) {}
		phoenix.profession.Structure.deleteDefinition(id, function(ok, error) {
			if (ok) phoenix.admin.Server.audit(playerId, "professionDelete", "profession", null, id, "")
			phoenix.admin.Server.reply(playerId, "professionDelete", ok, error, { id = id })
		})
	}
}

addEventHandler("onInit", function() {
	try {
		phoenix.admin.Server.dispatchers.professionList <- phoenix.profession.Admin.list
		phoenix.admin.Server.dispatchers.professionSave <- phoenix.profession.Admin.save
		phoenix.admin.Server.dispatchers.professionDelete <- phoenix.profession.Admin.remove
	} catch (e) {
		try { print("Profession admin dispatchers registration failed: " + e) } catch (printError) {}
	}
})
