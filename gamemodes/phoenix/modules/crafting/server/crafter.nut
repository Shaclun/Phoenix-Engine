phoenix.crafting.Crafter <- {

	activeByPlayer = {}
	locks = {}

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

	function _normalizeWorld(value) {
		try { return phoenix.vob.Structure.normalizeWorld(value) } catch (e) {}
		if (value == null || value == "") return "NEWWORLD"
		local world = value.tostring()
		local separator = -1
		for (local i = world.len() - 1; i >= 0; i -= 1) {
			local ch = world[i]
			if (ch == '\\' || ch == '/') { separator = i; break }
		}
		if (separator >= 0) world = world.slice(separator + 1)
		world = world.toupper()
		local zenAt = world.find(".ZEN")
		if (zenAt != null) world = world.slice(0, zenAt)
		return world
	}

	function _stationValid(playerId, vobId) {
		try {
			local station = null
			foreach (vid, entry in phoenix.vob.Structure.entries) if (vid == vobId) { station = entry; break }
			if (station == null) return false
			local playerWorld = getPlayerWorld(playerId)
			if ("world" in station && station.world != null && station.world != "" && phoenix.crafting.Crafter._normalizeWorld(playerWorld) != phoenix.crafting.Crafter._normalizeWorld(station.world)) return false
			if (!("x" in station) || !("y" in station) || !("z" in station)) return true
			local pos = getPlayerPosition(playerId)
			if (pos == null) return false
			local dx = pos.x - station.x; local dy = pos.y - station.y; local dz = pos.z - station.z
			return sqrt(dx * dx + dy * dy + dz * dz) <= 550.0
		} catch (e) {}
		return false
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
		if (playerId in phoenix.crafting.Crafter.locks) {
			phoenix.crafting.Crafter._reply(playerId, false, "busy", "", 0)
			return
		}
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
		if (!phoenix.crafting.Crafter._stationValid(playerId, vobId)) {
			phoenix.crafting.Crafter.close(playerId)
			phoenix.crafting.Crafter._reply(playerId, false, "tooFar", "", 0)
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
		if (recipe.resultAmount <= 0) {
			phoenix.crafting.Crafter._reply(playerId, false, "outputFailed", "", 0)
			return
		}
		if (phoenix.item.find(recipe.resultInstance) == null) {
			phoenix.crafting.Crafter._reply(playerId, false, "noResultScheme", recipe.resultInstance, 0)
			return
		}
		local extras = ("outputs" in recipe) ? recipe.outputs : []
		foreach (output in extras) {
			if (output.amount <= 0 || phoenix.item.find(output.instance) == null) {
				phoenix.crafting.Crafter._reply(playerId, false, "noOutputScheme:" + output.instance, "", 0)
				return
			}
		}
		local required = {}; local consume = {}
		foreach (ing in recipe.ingredients) {
			local instance = ing.instance != null ? ing.instance.tostring().toupper() : ""
			if (instance == "" || ing.amount <= 0 || phoenix.item.find(instance) == null) {
				phoenix.crafting.Crafter._reply(playerId, false, "badIngredient:" + instance, "", 0)
				return
			}
			if (!(instance in required)) required[instance] <- 0
			required[instance] += ing.amount
			if (ing.role == "consume") {
				if (!(instance in consume)) consume[instance] <- 0
				consume[instance] += ing.amount
			}
		}
		foreach (instance, amount in required) {
			local have = phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, character.id, instance)
			if (have < amount) {
				phoenix.crafting.Crafter._reply(playerId, false, "missing:" + instance, "", 0)
				return
			}
		}
		local consumeQueue = phoenix.crafting.Crafter._buildConsumePlan(character.id, consume)
		if (consumeQueue == null) {
			phoenix.crafting.Crafter._reply(playerId, false, "consumeFailed", "", 0)
			return
		}
		phoenix.crafting.Crafter.locks[playerId] <- true
		phoenix.crafting.Crafter._consumeAll(character.id, playerId, consumeQueue, function (okAll, consumeRollbackOk) {
			if (!okAll) {
				if (playerId in phoenix.crafting.Crafter.locks) phoenix.crafting.Crafter.locks.rawdelete(playerId)
				phoenix.crafting.Crafter._reply(playerId, false, consumeRollbackOk == false ? "rollbackFailed" : "consumeFailed", "", 0)
				return
			}
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, character.id, recipe.resultInstance, {
				amount = recipe.resultAmount, quality = PhoenixItemQuality.Common, upgrade = 0, source = "craft"
			}, function (rec) {
				if (rec == null) {
					phoenix.crafting.Crafter._restoreConsumed(character.id, consumeQueue, function(restored) {
						if (playerId in phoenix.crafting.Crafter.locks) phoenix.crafting.Crafter.locks.rawdelete(playerId)
						try { phoenix.item.Structure.sendInventorySnapshot(playerId, character.id) } catch (eSn) {}
						phoenix.crafting.Crafter._reply(playerId, false, restored ? "noResultScheme" : "rollbackFailed", recipe.resultInstance, 0)
					})
					return
				}
				local granted = [{ itemId = rec.id, amount = recipe.resultAmount }]
				phoenix.crafting.Crafter._giveExtras(character.id, extras, granted, function (extrasOk, allGranted) {
					if (!extrasOk) {
						phoenix.crafting.Crafter._rollbackGranted(character.id, allGranted, function(outputsRolledBack) {
							if (!outputsRolledBack) {
								if (playerId in phoenix.crafting.Crafter.locks) phoenix.crafting.Crafter.locks.rawdelete(playerId)
								try { phoenix.item.Structure.sendInventorySnapshot(playerId, character.id) } catch (eSn) {}
								phoenix.crafting.Crafter._reply(playerId, false, "rollbackFailed", "", 0)
								return
							}
							phoenix.crafting.Crafter._restoreConsumed(character.id, consumeQueue, function(restored) {
								if (playerId in phoenix.crafting.Crafter.locks) phoenix.crafting.Crafter.locks.rawdelete(playerId)
								try { phoenix.item.Structure.sendInventorySnapshot(playerId, character.id) } catch (eSn) {}
								phoenix.crafting.Crafter._reply(playerId, false, restored ? "outputFailed" : "rollbackFailed", "", 0)
							})
						})
						return
					}
					if (playerId in phoenix.crafting.Crafter.locks) phoenix.crafting.Crafter.locks.rawdelete(playerId)
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

	function _giveExtras(characterId, extras, granted, callback) {
		if (granted == null) granted = []
		if (extras == null || extras.len() == 0) { if (callback != null) callback(true, granted); return }
		local first = extras[0]
		local rest = extras.slice(1)
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, characterId, first.instance, {
			amount = first.amount, quality = PhoenixItemQuality.Common, upgrade = 0, source = "craft"
		}, function (record) {
			if (record == null) { if (callback != null) callback(false, granted); return }
			granted.append({ itemId = record.id, amount = first.amount })
			phoenix.crafting.Crafter._giveExtras(characterId, rest, granted, callback)
		})
	}

	function _buildConsumePlan(characterId, consume) {
		local inventory = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, characterId)
		if (inventory == null) return null
		local queue = []
		foreach (instance, amount in consume) {
			local remaining = amount
			foreach (record in inventory.items) {
				if (remaining <= 0) break
				local recordInstance = record.instanceId != null ? record.instanceId.toupper() : ""
				if (recordInstance != instance || record.equipped != 0) continue
				local take = remaining < record.amount ? remaining : record.amount
				queue.append({ itemId = record.id, instance = recordInstance, amount = take, quality = record.quality, upgrade = record.upgrade })
				remaining -= take
			}
			if (remaining > 0) return null
		}
		return queue
	}

	function _rollbackGranted(characterId, granted, callback, success = true) {
		if (granted == null || granted.len() == 0) { if (callback != null) callback(success); return }
		local lastIndex = granted.len() - 1
		local issued = granted[lastIndex]
		local rest = granted.slice(0, lastIndex)
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, characterId, issued.itemId, issued.amount, function(ok) {
			phoenix.crafting.Crafter._rollbackGranted(characterId, rest, callback, success && ok)
		})
	}

	function _restoreConsumed(characterId, queue, callback, success = true) {
		if (queue == null || queue.len() == 0) { if (callback != null) callback(success); return }
		local first = queue[0]
		local rest = queue.slice(1)
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, characterId, first.instance, {
			amount = first.amount, quality = first.quality, upgrade = first.upgrade, source = "craft-rollback"
		}, function(record) {
			phoenix.crafting.Crafter._restoreConsumed(characterId, rest, callback, success && record != null)
		})
	}

	function _consumeAll(characterId, playerId, queue, callback, consumed = null) {
		if (consumed == null) consumed = []
		if (queue.len() == 0) { if (callback != null) callback(true, true); return }
		local first = queue[0]
		local rest = queue.slice(1)
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, characterId, first.itemId, first.amount, function (ok) {
			if (!ok) {
				phoenix.crafting.Crafter._restoreConsumed(characterId, consumed, function(restored) { if (callback != null) callback(false, restored) })
				return
			}
			consumed.append(first)
			try { phoenix.item.Structure.sendInventorySnapshot(playerId, characterId) } catch (eSn) {}
			phoenix.crafting.Crafter._consumeAll(characterId, playerId, rest, callback, consumed)
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

addEventHandler("onPlayerDisconnect", function(playerId, _reason) {
	if (playerId in phoenix.crafting.Crafter.locks) phoenix.crafting.Crafter.locks.rawdelete(playerId)
	phoenix.crafting.Crafter.close(playerId)
})
