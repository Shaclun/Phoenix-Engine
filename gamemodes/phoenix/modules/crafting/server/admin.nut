phoenix.crafting.Admin <- {

	function dispatchList(playerId, _payload) {
		try {
			phoenix.crafting.Structure.loadAll(function () {
				local recipes = phoenix.crafting.Structure.allRecipes()
				local stations = phoenix.crafting.Structure.stationsListing()
				phoenix.admin.Server.reply(playerId, "craftingList", true, "", { recipes = recipes, stations = stations })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "craftingList", false, "exception", null)
		}
	}

	function dispatchSave(playerId, payload) {
		if (payload == null) { phoenix.admin.Server.reply(playerId, "craftingSave", false, "empty", null); return }
		try {
		} catch (eD) {}
		try {
			phoenix.crafting.Structure.saveRecipe(payload, function (ok, err, newId) {
				if (!ok) {
					phoenix.admin.Server.reply(playerId, "craftingSave", false, err != "" ? err : "failed", null)
					return
				}
				try { phoenix.crafting.Structure.broadcastStations() } catch (eB) {}
				try { phoenix.vob.Structure.broadcastSnapshot() } catch (eSn) {}
				phoenix.admin.Server.reply(playerId, "craftingSave", true, "", { id = newId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "craftingSave", false, "exception", null)
		}
	}

	function dispatchDelete(playerId, payload) {
		if (payload == null || !("id" in payload)) { phoenix.admin.Server.reply(playerId, "craftingDelete", false, "empty", null); return }
		local id = 0
		try { id = payload.id.tointeger() } catch (e) { id = 0 }
		if (id <= 0) { phoenix.admin.Server.reply(playerId, "craftingDelete", false, "badId", null); return }
		try {
			phoenix.crafting.Structure.deleteRecipe(id, function (ok) {
				phoenix.admin.Server.reply(playerId, "craftingDelete", ok, ok ? "" : "failed", { id = id })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "craftingDelete", false, "exception", null)
		}
	}
}

addEventHandler("onInit", function () {
	setTimer(function () {
		try {
			if ("admin" in phoenix && "Server" in phoenix.admin && "dispatchers" in phoenix.admin.Server) {
				phoenix.admin.Server.dispatchers.craftingList <- phoenix.crafting.Admin.dispatchList
				phoenix.admin.Server.dispatchers.craftingSave <- phoenix.crafting.Admin.dispatchSave
				phoenix.admin.Server.dispatchers.craftingDelete <- phoenix.crafting.Admin.dispatchDelete
			}
		} catch (e) {}
	}, 3000, 1)
})
