phoenix.crafting.Client <- {
	visible = false
	vobId = ""
	stationVisuals = {}

	function init() {
		try { phoenix.web.Router.on("phoenix:crafting:craft", phoenix.crafting.Client.onCraft) } catch (e) {}
		try { phoenix.web.Router.on("phoenix:crafting:cancel", phoenix.crafting.Client.onCancel) } catch (e) {}
		try { phoenix.web.Router.on("phoenix:crafting:close", phoenix.crafting.Client.forceClose) } catch (e) {}
		try { phoenix.ui.ActiveGui.register("crafting", phoenix.crafting.Client.forceClose) } catch (e) {}
	}

	function stationVisualKeys(visual) {
		local out = []
		if (visual == null) return out
		local key = strip(visual.tostring()).toupper()
		if (key == "") return out
		out.append(key)
		if (key.len() > 4) {
			local extension = key.slice(key.len() - 4)
			local visualBase = key.slice(0, key.len() - 4)
			if (extension == ".3DS") out.append(visualBase + ".MRM")
			else if (extension == ".MRM") out.append(visualBase + ".3DS")
		}
		return out
	}

	function isStationVisual(visual) {
		foreach (key in phoenix.crafting.Client.stationVisualKeys(visual)) {
			if (key in phoenix.crafting.Client.stationVisuals) return true
		}
		return false
	}

	function onStations(message) {
		phoenix.crafting.Client.stationVisuals = {}
		try {
			local raw = message.visuals != null ? message.visuals.tostring() : ""
			if (raw == "") return
			local lines = split(raw, "\n")
			foreach (line in lines) {
				foreach (key in phoenix.crafting.Client.stationVisualKeys(line)) phoenix.crafting.Client.stationVisuals[key] <- true
			}
		} catch (e) {}
		try { phoenix.crafting.Client.refreshVobInteractive() } catch (e2) {}
	}

	function refreshVobInteractive() {
		if (!("vob" in phoenix) || !("Ground" in phoenix.vob)) return
		foreach (vobId, entry in phoenix.vob.Ground.entries) {
			try {
				local v = entry.visual != null ? entry.visual.tostring() : ""
				if (phoenix.crafting.Client.isStationVisual(v)) entry.interactive = true
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
				outputs = extras,
				professionId = parts.len() >= 12 ? parts[11].tointeger() : 0,
				professionCode = parts.len() >= 13 ? parts[12] : "",
				professionName = parts.len() >= 14 ? parts[13] : "",
				requiredProfessionTier = parts.len() >= 15 ? parts[14].tointeger() : 0,
				baseStamina = parts.len() >= 16 ? parts[15].tointeger() : 0,
				professionXp = parts.len() >= 17 ? parts[16].tointeger() : 0,
				playerProfessionLevel = parts.len() >= 18 ? parts[17].tointeger() : 0,
				playerProfessionTier = parts.len() >= 19 ? parts[18].tointeger() : 0,
				effectiveStaminaCost = parts.len() >= 20 ? parts[19].tointeger() : 0
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
			playerStamina = message.playerStamina,
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
			requestId = message.requestId != null ? message.requestId.tostring() : "",
			resultInstance = message.resultInstance != null ? message.resultInstance.tostring() : "",
			resultAmount = message.resultAmount,
			playerStamina = message.playerStamina,
			items = phoenix.crafting.Client.parseItems(message.playerItems)
		}
		try { phoenix.web.Manager.emit("phoenix:crafting:result", payload) } catch (e) {}
	}

	function onProgress(message) {
		local payload = {
			requestId = message.requestId != null ? message.requestId.tostring() : "",
			recipeId = message.recipeId,
			quantity = message.quantity,
			elapsedMs = message.elapsedMs,
			totalMs = message.totalMs,
			progress = message.progress,
			state = message.state != null ? message.state.tostring() : "crafting"
		}
		try { phoenix.web.Manager.emit("phoenix:crafting:progress", payload) } catch (e) {}
	}

	function onCraft(payload) {
		if (payload == null || !("recipeId" in payload)) return
		local msg = phoenix.crafting.Message.Craft()
		msg.vobId = phoenix.crafting.Client.vobId
		msg.recipeId = payload.recipeId.tointeger()
		try { if ("quantity" in payload) msg.quantity = payload.quantity.tointeger() } catch (eQ) { msg.quantity = 1 }
		try { if ("requestId" in payload && payload.requestId != null) msg.requestId = payload.requestId.tostring() } catch (eR) {}
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onCancel(payload) {
		local msg = phoenix.crafting.Message.Cancel()
		try { if (payload != null && "requestId" in payload && payload.requestId != null) msg.requestId = payload.requestId.tostring() } catch (e) {}
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e2) {}
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
phoenix.crafting.Message.Progress.bind(phoenix.crafting.Client.onProgress)
phoenix.crafting.Message.Result.bind(phoenix.crafting.Client.onResult)
phoenix.crafting.Message.Stations.bind(phoenix.crafting.Client.onStations)
phoenix.crafting.Client.init()
