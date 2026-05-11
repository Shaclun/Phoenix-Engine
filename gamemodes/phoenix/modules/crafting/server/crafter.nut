phoenix.crafting.Crafter <- {

	activeByPlayer = {}

	function playerInventoryString(playerId) {
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return ""
		local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
		if (inv == null) return ""
		local payload = ""
		local first = true
		foreach (rec in inv.items) {
			local inst = rec.instanceId != null ? rec.instanceId.toupper() : ""
			if (inst == "") continue
			local iv = ""
			try { local vs = phoenix.item.lookupVisual(inst); if (vs != null) iv = vs } catch (eL) {}
			local line = inst + "|" + rec.amount + "|" + (rec.equipped == 1 ? 1 : 0) + "|" + rec.quality + "|" + rec.upgrade + "|" + iv
			if (first) { payload = line; first = false } else { payload = payload + "\n" + line }
		}
		return payload
	}

	function recipesString(recipes) {
		local payload = ""
		local first = true
		foreach (rec in recipes) {
			local ings = ""
			local ifirst = true
			foreach (ing in rec.ingredients) {
				local iv = ""
				try { local vs = phoenix.item.lookupVisual(ing.instance); if (vs != null) iv = vs } catch (eL) {}
				local part = ing.role + "," + ing.instance + "," + ing.amount + "," + iv
				if (ifirst) { ings = part; ifirst = false } else { ings = ings + ";" + part }
			}
			local outs = ""
			local ofirst = true
			local outList = ("outputs" in rec) ? rec.outputs : []
			foreach (o in outList) {
				local ov = ""
				try { local vs = phoenix.item.lookupVisual(o.instance); if (vs != null) ov = vs } catch (eL) {}
				local part = o.instance + "," + o.amount + "," + ov
				if (ofirst) { outs = part; ofirst = false } else { outs = outs + ";" + part }
			}
			local description = rec.description != null ? rec.description.tostring() : ""
			description = phoenix.crafting.Crafter._escape(description)
			local name = phoenix.crafting.Crafter._escape(rec.name != null ? rec.name : "")
			local visual = ""
			try { local vv = phoenix.item.lookupVisual(rec.resultInstance); if (vv != null) visual = vv } catch (eV) {}
			local line = rec.id + "|" + name + "|" + rec.resultInstance + "|" + rec.resultAmount + "|" +
				rec.category + "|" + rec.craftTimeMs + "|" + rec.requiredLevel + "|" + description + "|" + ings + "|" + visual + "|" + outs
			if (first) { payload = line; first = false } else { payload = payload + "\n" + line }
		}
		return payload
	}

	function _escape(text) {
		if (text == null) return ""
		local out = ""
		local s = text.tostring()
		for (local i = 0; i < s.len(); i += 1) {
			local c = s[i]
			if (c == '\n' || c == '|' || c == ';') out += " "
			else out += s.slice(i, i + 1)
		}
		return out
	}

	function _vobVisualAndLabel(vobId) {
		local visual = ""
		local label = vobId
		try {
			foreach (vid, entry in phoenix.vob.Structure.entries) {
				if (vid == vobId) {
					visual = ("visual" in entry && entry.visual != null) ? entry.visual.tostring() : ""
					label = ("name" in entry && entry.name != null && entry.name != "") ? entry.name.tostring() : visual
					break
				}
			}
		} catch (e) {}
		return { visual = visual, label = label }
	}

	function open(playerId, vobId) {
		if (vobId == null || vobId == "") return
		local info = phoenix.crafting.Crafter._vobVisualAndLabel(vobId)
		if (info.visual == "") {
			try { phoenix.notification.notify(playerId, "info", "Warsztat", "Ten VOB nie ma modelu.", 2500) } catch (e) {}
			return
		}
		local recipes = phoenix.crafting.Structure.recipesForVisual(info.visual)
		if (recipes.len() == 0) {
			try { phoenix.notification.notify(playerId, "info", "Warsztat", "Brak dostepnych receptur dla: " + info.visual, 2500) } catch (e) {}
			return
		}
		phoenix.crafting.Crafter.activeByPlayer[playerId] <- { vobId = vobId, visual = info.visual.toupper() }
		local msg = phoenix.crafting.Message.Open()
		msg.vobId = vobId
		msg.stationName = info.label
		msg.recipes = phoenix.crafting.Crafter.recipesString(recipes)
		msg.playerItems = phoenix.crafting.Crafter.playerInventoryString(playerId)
		local level = 1
		try { level = getPlayerLevel(playerId) } catch (e) {}
		if (level < 1) level = 1
		msg.playerLevel = level
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (eS) {}
	}

	function close(playerId) {
		if (playerId in phoenix.crafting.Crafter.activeByPlayer) phoenix.crafting.Crafter.activeByPlayer.rawdelete(playerId)
	}

	function onRequestOpen(playerId, message) {
		if (message == null || message.vobId == null) return
		phoenix.crafting.Crafter.open(playerId, message.vobId.tostring())
	}

	function onClose(playerId, _msg) {
		phoenix.crafting.Crafter.close(playerId)
	}

	function onCraftRequest(playerId, message) {
		if (message == null) return
		local vobId = message.vobId != null ? message.vobId.tostring() : ""
		local recipeId = message.recipeId.tointeger()
		if (vobId == "" || recipeId <= 0) {
			phoenix.crafting.Crafter._reply(playerId, false, "invalid", "", 0)
			return
		}
		local active = (playerId in phoenix.crafting.Crafter.activeByPlayer) ? phoenix.crafting.Crafter.activeByPlayer[playerId] : null
		if (active == null || active.vobId != vobId) {
			phoenix.crafting.Crafter._reply(playerId, false, "notActive", "", 0)
			return
		}
		if (!phoenix.crafting.Structure.loaded) {
			phoenix.crafting.Crafter._reply(playerId, false, "loading", "", 0)
			return
		}
		local recipe = phoenix.crafting.Structure.recipeById(recipeId)
		if (recipe == null) {
			phoenix.crafting.Crafter._reply(playerId, false, "noRecipe", "", 0)
			return
		}
		local stations = phoenix.crafting.Structure.stationByVisual
		local visualKey = active.visual
		if (!(visualKey in stations)) {
			phoenix.crafting.Crafter._reply(playerId, false, "notStation", "", 0)
			return
		}
		local found = false
		foreach (rid in stations[visualKey]) { if (rid == recipeId) { found = true; break } }
		if (!found) {
			phoenix.crafting.Crafter._reply(playerId, false, "notAllowed", "", 0)
			return
		}
		local level = 1
		try { level = getPlayerLevel(playerId) } catch (e) {}
		if (level < recipe.requiredLevel) {
			phoenix.crafting.Crafter._reply(playerId, false, "lowLevel", "", 0)
			return
		}
		local character = phoenix.character.Structure.getActive(playerId)
		if (character == null) {
			phoenix.crafting.Crafter._reply(playerId, false, "noCharacter", "", 0)
			return
		}
		foreach (ing in recipe.ingredients) {
			local have = phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, character.id, ing.instance)
			if (ing.role == "tool") {
				if (have < ing.amount) {
					phoenix.crafting.Crafter._reply(playerId, false, "missingTool:" + ing.instance, "", 0)
					return
				}
			} else {
				if (have < ing.amount) {
					phoenix.crafting.Crafter._reply(playerId, false, "missing:" + ing.instance, "", 0)
					return
				}
			}
		}
		local consumeQueue = []
		foreach (ing in recipe.ingredients) {
			if (ing.role == "consume") consumeQueue.append({ instance = ing.instance, amount = ing.amount })
		}
		phoenix.crafting.Crafter._consumeAll(character.id, playerId, consumeQueue, function (okAll) {
			if (!okAll) {
				phoenix.crafting.Crafter._reply(playerId, false, "consumeFailed", "", 0)
				return
			}
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, character.id, recipe.resultInstance, {
				amount = recipe.resultAmount, quality = PhoenixItemQuality.Common, upgrade = 0, source = "craft"
			}, function (rec) {
				if (rec == null) {
					phoenix.crafting.Crafter._reply(playerId, false, "noResultScheme", recipe.resultInstance, 0)
					return
				}
				local extras = ("outputs" in recipe) ? recipe.outputs : []
				phoenix.crafting.Crafter._giveExtras(character.id, extras, function () {
					try {
						phoenix.item.Structure.sendInventorySnapshot(playerId, character.id)
					} catch (eSn) {}
					try { playAni(playerId, "T_REPAIR_S0_2_S1") } catch (eAa) {}
					phoenix.crafting.Crafter._reply(playerId, true, "", recipe.resultInstance, recipe.resultAmount)
					try {
						phoenix.notification.notify(playerId, "success", "Warsztat",
							"Wytworzono: " + recipe.resultInstance + " x" + recipe.resultAmount, 2500)
					} catch (eNot) {}
				})
			})
		})
	}

	function _giveExtras(characterId, extras, callback) {
		if (extras == null || extras.len() == 0) { if (callback != null) callback(); return }
		local first = extras[0]
		local rest = extras.slice(1)
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, characterId, first.instance, {
			amount = first.amount, quality = PhoenixItemQuality.Common, upgrade = 0, source = "craft"
		}, function (_) {
			phoenix.crafting.Crafter._giveExtras(characterId, rest, callback)
		})
	}

	function _consumeAll(characterId, playerId, queue, callback) {
		if (queue.len() == 0) { if (callback != null) callback(true); return }
		local first = queue[0]
		local rest = queue.slice(1)
		phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, characterId, first.instance, first.amount, function (ok) {
			if (!ok) { if (callback != null) callback(false); return }
			try { ::removeItem(playerId, first.instance, first.amount) } catch (e) {}
			phoenix.crafting.Crafter._consumeAll(characterId, playerId, rest, callback)
		})
	}

	function _reply(playerId, success, error, resultInstance, resultAmount) {
		local msg = phoenix.crafting.Message.Result()
		msg.success = success
		msg.error = error != null ? error.tostring() : ""
		msg.resultInstance = resultInstance != null ? resultInstance.tostring() : ""
		msg.resultAmount = resultAmount.tointeger()
		msg.playerItems = phoenix.crafting.Crafter.playerInventoryString(playerId)
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}
}

phoenix.crafting.Message.RequestOpen.bind(phoenix.crafting.Crafter.onRequestOpen)
phoenix.crafting.Message.Close.bind(phoenix.crafting.Crafter.onClose)
phoenix.crafting.Message.Craft.bind(phoenix.crafting.Crafter.onCraftRequest)
