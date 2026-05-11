phoenix.crafting.Client <- {
	visible = false
	vobId = ""
	stationVisuals = {}

	function init() {
		try { phoenix.web.Router.on("phoenix:crafting:craft", phoenix.crafting.Client.onCraft) } catch (e) {}
		try { phoenix.web.Router.on("phoenix:crafting:close", phoenix.crafting.Client.forceClose) } catch (e) {}
		try { phoenix.ui.ActiveGui.register("crafting", phoenix.crafting.Client.forceClose) } catch (e) {}
	}

	function isStationVisual(visual) {
		if (visual == null) return false
		local key = visual.tostring().toupper()
		return key in phoenix.crafting.Client.stationVisuals
	}

	function onStations(message) {
		phoenix.crafting.Client.stationVisuals = {}
		try {
			local raw = message.visuals != null ? message.visuals.tostring() : ""
			if (raw == "") return
			local lines = split(raw, "\n")
			foreach (line in lines) {
				if (line == "") continue
				phoenix.crafting.Client.stationVisuals[line.toupper()] <- true
			}
		} catch (e) {}
		try { phoenix.crafting.Client.refreshVobInteractive() } catch (e2) {}
	}

	function refreshVobInteractive() {
		if (!("vob" in phoenix) || !("Ground" in phoenix.vob)) return
		foreach (vobId, entry in phoenix.vob.Ground.entries) {
			try {
				local v = entry.visual != null ? entry.visual.tostring().toupper() : ""
				if (v != "" && (v in phoenix.crafting.Client.stationVisuals)) {
					entry.interactive = true
				}
			} catch (e) {}
		}
	}

	function parseRecipes(raw) {
		local recipes = []
		if (raw == null || raw == "") return recipes
		local lines = split(raw.tostring(), "\n")
		foreach (line in lines) {
			if (line == "") continue
			local parts = split(line, "|")
			if (parts.len() < 9) continue
			local ings = []
			if (parts[8] != "") {
				local chunks = split(parts[8], ";")
				foreach (c in chunks) {
					local cp = split(c, ",")
					if (cp.len() < 3) continue
					local visual = cp.len() >= 4 ? cp[3] : ""
					ings.append({ role = cp[0], instance = cp[1], amount = cp[2].tointeger(), visual = visual })
				}
			}
			local resultVisual = parts.len() >= 10 ? parts[9] : ""
			local extras = []
			if (parts.len() >= 11 && parts[10] != "") {
				local chunks = split(parts[10], ";")
				foreach (c in chunks) {
					local cp = split(c, ",")
					if (cp.len() < 2) continue
					local visual = cp.len() >= 3 ? cp[2] : ""
					extras.append({ instance = cp[0], amount = cp[1].tointeger(), visual = visual })
				}
			}
			recipes.append({
				id = parts[0].tointeger(),
				name = parts[1],
				resultInstance = parts[2],
				resultAmount = parts[3].tointeger(),
				category = parts[4],
				craftTimeMs = parts[5].tointeger(),
				requiredLevel = parts[6].tointeger(),
				description = parts[7],
				ingredients = ings,
				visual = resultVisual,
				outputs = extras
			})
		}
		return recipes
	}

	function parseItems(raw) {
		local items = []
		if (raw == null || raw == "") return items
		local lines = split(raw.tostring(), "\n")
		foreach (line in lines) {
			if (line == "") continue
			local parts = split(line, "|")
			if (parts.len() < 5) continue
			local visual = parts.len() >= 6 ? parts[5] : ""
			items.append({
				instance = parts[0],
				amount = parts[1].tointeger(),
				equipped = parts[2].tointeger() == 1,
				quality = parts[3].tointeger(),
				upgrade = parts[4].tointeger(),
				visual = visual
			})
		}
		return items
	}

	function onOpen(message) {
		phoenix.crafting.Client.vobId = message.vobId != null ? message.vobId.tostring() : ""
		phoenix.crafting.Client.visible = true
		local payload = {
			vobId = phoenix.crafting.Client.vobId,
			stationName = message.stationName != null ? message.stationName.tostring() : "",
			playerLevel = message.playerLevel,
			recipes = phoenix.crafting.Client.parseRecipes(message.recipes),
			items = phoenix.crafting.Client.parseItems(message.playerItems)
		}
		try { phoenix.web.Manager.show("crafting") } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:crafting:open", payload) } catch (e) {}
		try { phoenix.ui.ActiveGui.set("crafting") } catch (e) {}
	}

	function onResult(message) {
		local payload = {
			success = message.success,
			error = message.error != null ? message.error.tostring() : "",
			resultInstance = message.resultInstance != null ? message.resultInstance.tostring() : "",
			resultAmount = message.resultAmount,
			items = phoenix.crafting.Client.parseItems(message.playerItems)
		}
		try { phoenix.web.Manager.emit("phoenix:crafting:result", payload) } catch (e) {}
	}

	function onCraft(payload) {
		if (payload == null || !("recipeId" in payload)) return
		local msg = phoenix.crafting.Message.Craft()
		msg.vobId = phoenix.crafting.Client.vobId
		msg.recipeId = payload.recipeId.tointeger()
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function forceClose(_a = null) {
		if (!phoenix.crafting.Client.visible) return
		phoenix.crafting.Client.visible = false
		phoenix.crafting.Client.vobId = ""
		try { phoenix.crafting.Message.Close().serialize().send(RELIABLE_ORDERED) } catch (e) {}
		try { phoenix.web.Manager.hide() } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:crafting:hide", null) } catch (e) {}
		try {
			if (phoenix.ui.ActiveGui.is("crafting")) phoenix.ui.ActiveGui.clear()
		} catch (e) {}
	}
}

phoenix.crafting.Message.Open.bind(phoenix.crafting.Client.onOpen)
phoenix.crafting.Message.Result.bind(phoenix.crafting.Client.onResult)
phoenix.crafting.Message.Stations.bind(phoenix.crafting.Client.onStations)
phoenix.crafting.Client.init()
