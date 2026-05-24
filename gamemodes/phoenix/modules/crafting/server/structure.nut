phoenix.crafting.Structure <- {

	recipes = {}
	ingredients = {}
	outputs = {}
	stationByVisual = {}
	loaded = false
	loading = false

	function cleanupLegacyTables() {
		try {
			local rows = ORM.engine.execute("SHOW COLUMNS FROM `phoenix_crafting_ingredients` LIKE 'instance'")
			if (rows == null || rows.len() == 0) return
			try { ORM.engine.execute("DROP TABLE IF EXISTS `phoenix_crafting_outputs`") } catch (e1) {}
			try { ORM.engine.execute("DROP TABLE IF EXISTS `phoenix_crafting_stations`") } catch (e2) {}
			try { ORM.engine.execute("DROP TABLE IF EXISTS `phoenix_crafting_ingredients`") } catch (e3) {}
			try { ORM.engine.execute("DROP TABLE IF EXISTS `phoenix_crafting_recipes`") } catch (e4) {}
		} catch (e) {}
	}

	function loadAll(callback = null) {
		if (phoenix.crafting.Structure.loading) {
			setTimer(function () {
				try { phoenix.crafting.Structure.loadAll(callback) } catch (e) {}
			}, 250, 1)
			return
		}
		phoenix.crafting.Structure.loading = true
		phoenix.crafting.Structure.recipes = {}
		phoenix.crafting.Structure.ingredients = {}
		phoenix.crafting.Structure.outputs = {}
		phoenix.crafting.Structure.stationByVisual = {}
		try {
			CraftingRecipeModel.findAsync(@(q) q, function (recipes) {
				foreach (r in recipes) {
					local id = r.id.tointeger()
					phoenix.crafting.Structure.recipes[id] <- {
						id = id,
						name = r.name != null ? r.name.tostring() : "",
						resultInstance = r.resultInstance != null ? r.resultInstance.tostring() : "",
						resultAmount = r.resultAmount.tointeger(),
						category = r.category != null ? r.category.tostring() : "misc",
						craftTimeMs = r.craftTimeMs.tointeger(),
						requiredLevel = r.requiredLevel.tointeger(),
						description = r.description != null ? r.description.tostring() : ""
					}
				}
				CraftingIngredientModel.findAsync(@(q) q, function (ings) {
					foreach (ing in ings) {
						local rid = ing.recipeId.tointeger()
						if (!(rid in phoenix.crafting.Structure.ingredients)) phoenix.crafting.Structure.ingredients[rid] <- []
						phoenix.crafting.Structure.ingredients[rid].append({
							role = ing.role != null ? ing.role.tostring() : "consume",
							instance = ing.itemInstance != null ? ing.itemInstance.tostring() : "",
							amount = ing.amount.tointeger(),
							position = ing.position.tointeger()
						})
					}
					foreach (rid, list in phoenix.crafting.Structure.ingredients) {
						list.sort(function (a, b) { return a.position <=> b.position })
					}
					CraftingOutputModel.findAsync(@(q) q, function (outs) {
						foreach (o in outs) {
							local rid2 = o.recipeId.tointeger()
							if (!(rid2 in phoenix.crafting.Structure.outputs)) phoenix.crafting.Structure.outputs[rid2] <- []
							phoenix.crafting.Structure.outputs[rid2].append({
								instance = o.itemInstance != null ? o.itemInstance.tostring() : "",
								amount = o.amount.tointeger(),
								position = o.position.tointeger()
							})
						}
						foreach (rid2, list in phoenix.crafting.Structure.outputs) {
							list.sort(function (a, b) { return a.position <=> b.position })
						}
						CraftingStationModel.findAsync(@(q) q, function (stations) {
							foreach (s in stations) {
								local vis = s.visual != null ? s.visual.tostring().toupper() : ""
								if (vis == "") continue
								if (!(vis in phoenix.crafting.Structure.stationByVisual)) phoenix.crafting.Structure.stationByVisual[vis] <- []
								phoenix.crafting.Structure.stationByVisual[vis].append(s.recipeId.tointeger())
							}
							phoenix.crafting.Structure.loaded = true
							phoenix.crafting.Structure.loading = false
							local recCount = 0
							foreach (_k, _v in phoenix.crafting.Structure.recipes) recCount += 1
							print("[crafting] loaded " + recCount + " recipes, " + phoenix.crafting.Structure.stationByVisual.len() + " station visuals\n")
							if (callback != null) callback()
						})
					})
				})
			})
		} catch (e) {
			phoenix.crafting.Structure.loading = false
			if (callback != null) callback()
		}
	}

	function recipeById(id) {
		local key = id.tointeger()
		if (!(key in phoenix.crafting.Structure.recipes)) return null
		local rec = phoenix.crafting.Structure.recipes[key]
		local ings = (key in phoenix.crafting.Structure.ingredients) ? phoenix.crafting.Structure.ingredients[key] : []
		local outs = (key in phoenix.crafting.Structure.outputs) ? phoenix.crafting.Structure.outputs[key] : []
		return {
			id = rec.id, name = rec.name, resultInstance = rec.resultInstance,
			resultAmount = rec.resultAmount, category = rec.category,
			craftTimeMs = rec.craftTimeMs, requiredLevel = rec.requiredLevel,
			description = rec.description, ingredients = ings, outputs = outs
		}
	}

	function recipesForVisual(visual) {
		local out = []
		if (visual == null || visual == "") return out
		local key = visual.tostring().toupper()
		if (!(key in phoenix.crafting.Structure.stationByVisual)) return out
		foreach (rid in phoenix.crafting.Structure.stationByVisual[key]) {
			local rec = phoenix.crafting.Structure.recipeById(rid)
			if (rec != null) out.append(rec)
		}
		return out
	}

	function visualsForRecipe(recipeId) {
		local out = []
		local target = recipeId.tointeger()
		foreach (visual, rids in phoenix.crafting.Structure.stationByVisual) {
			foreach (rid in rids) if (rid == target) { out.append(visual); break }
		}
		return out
	}

	function allRecipes() {
		local out = []
		foreach (id, _ in phoenix.crafting.Structure.recipes) {
			local rec = phoenix.crafting.Structure.recipeById(id)
			if (rec != null) {
				rec.visuals <- phoenix.crafting.Structure.visualsForRecipe(id)
				out.append(rec)
			}
		}
		return out
	}

	function stationsListing() {
		local out = []
		foreach (vis, rids in phoenix.crafting.Structure.stationByVisual) {
			out.append({ visual = vis, recipeIds = rids })
		}
		return out
	}

	function saveRecipe(data, callback) {
		local id = 0
		try { if ("id" in data && data.id != null) id = data.id.tointeger() } catch (e) {}
		local name = ""
		try { if ("name" in data && data.name != null) name = data.name.tostring() } catch (e) {}
		local resultInstance = ""
		try { if ("resultInstance" in data && data.resultInstance != null) resultInstance = data.resultInstance.tostring().toupper() } catch (e) {}
		local resultAmount = 1
		try { if ("resultAmount" in data) resultAmount = data.resultAmount.tointeger() } catch (e) {}
		local category = "misc"
		try { if ("category" in data && data.category != null) category = data.category.tostring() } catch (e) {}
		local craftTimeMs = 1500
		try { if ("craftTimeMs" in data) craftTimeMs = data.craftTimeMs.tointeger() } catch (e) {}
		local requiredLevel = 0
		try { if ("requiredLevel" in data) requiredLevel = data.requiredLevel.tointeger() } catch (e) {}
		local description = ""
		try { if ("description" in data && data.description != null) description = data.description.tostring() } catch (e) {}
		if (resultAmount < 1) resultAmount = 1
		if (resultInstance == "") {
			if (callback != null) callback(false, "noResult", 0)
			return
		}
		if (name == "") name = resultInstance

		local onPersisted = function (newId) {
			phoenix.crafting.Structure._replaceChildren(newId, data, function () {
				phoenix.crafting.Structure.loadAll(function () {
					if (callback != null) callback(true, "", newId)
				})
			})
		}

		if (id > 0) {
			CraftingRecipeModel.findOneAsync(@(q) q.where("id", "=", id), function (existing) {
				if (existing == null) {
					local model = CraftingRecipeModel()
					model.name = name
					model.resultInstance = resultInstance
					model.resultAmount = resultAmount
					model.category = category
					model.craftTimeMs = craftTimeMs
					model.requiredLevel = requiredLevel
					model.description = description
					model.insertAsync(function (insertedId) {
						local nid = insertedId != null ? insertedId.tointeger() : 0
						onPersisted(nid)
					})
					return
				}
				existing.name = name
				existing.resultInstance = resultInstance
				existing.resultAmount = resultAmount
				existing.category = category
				existing.craftTimeMs = craftTimeMs
				existing.requiredLevel = requiredLevel
				existing.description = description
				existing.saveAsync(function (_) {
					onPersisted(id)
				})
			})
			return
		}

		local model = CraftingRecipeModel()
		model.name = name
		model.resultInstance = resultInstance
		model.resultAmount = resultAmount
		model.category = category
		model.craftTimeMs = craftTimeMs
		model.requiredLevel = requiredLevel
		model.description = description
		model.insertAsync(function (insertedId) {
			local nid = insertedId != null ? insertedId.tointeger() : 0
			onPersisted(nid)
		})
	}

	function _replaceChildren(recipeId, data, callback) {
		phoenix.crafting.Structure._deleteIngredients(recipeId, function () {
			phoenix.crafting.Structure._insertIngredients(recipeId, data, function () {
				phoenix.crafting.Structure._deleteOutputs(recipeId, function () {
					phoenix.crafting.Structure._insertOutputs(recipeId, data, function () {
						phoenix.crafting.Structure._deleteStations(recipeId, function () {
							phoenix.crafting.Structure._insertStations(recipeId, data, function () {
								if (callback != null) callback()
							})
						})
					})
				})
			})
		})
	}

	function _deleteIngredients(recipeId, callback) {
		ORM.engine.executeAsync("DELETE FROM `phoenix_crafting_ingredients` WHERE `recipeId` = " + recipeId, function (_) { if (callback != null) callback() })
	}

	function _deleteOutputs(recipeId, callback) {
		ORM.engine.executeAsync("DELETE FROM `phoenix_crafting_outputs` WHERE `recipeId` = " + recipeId, function (_) { if (callback != null) callback() })
	}

	function _deleteStations(recipeId, callback) {
		ORM.engine.executeAsync("DELETE FROM `phoenix_crafting_stations` WHERE `recipeId` = " + recipeId, function (_) { if (callback != null) callback() })
	}

	function _insertIngredients(recipeId, data, callback) {
		local ings = []
		try { if ("ingredients" in data && data.ingredients != null) ings = data.ingredients } catch (e) {}
		if (ings.len() == 0) { if (callback != null) callback(); return }
		local queue = []
		local pos = 0
		foreach (ing in ings) {
			local instance = ""
			try { if ("instance" in ing && ing.instance != null) instance = ing.instance.tostring().toupper() } catch (e) {}
			if (instance == "") { pos += 1; continue }
			local role = "consume"
			try { if ("role" in ing && ing.role != null) role = ing.role.tostring() } catch (e) {}
			local amount = 1
			try { if ("amount" in ing) amount = ing.amount.tointeger() } catch (e) {}
			if (amount < 1) amount = 1
			queue.append({ role = role, instance = instance, amount = amount, position = pos })
			pos += 1
		}
		phoenix.crafting.Structure._saveIngredientQueue(recipeId, queue, 0, callback)
	}

	function _saveIngredientQueue(recipeId, queue, index, callback) {
		if (index >= queue.len()) { if (callback != null) callback(); return }
		local entry = queue[index]
		local model = CraftingIngredientModel()
		model.recipeId = recipeId
		model.role = entry.role
		model.itemInstance = entry.instance
		model.amount = entry.amount
		model.position = entry.position
		model.insertAsync(function (_) {
			phoenix.crafting.Structure._saveIngredientQueue(recipeId, queue, index + 1, callback)
		})
	}

	function _insertOutputs(recipeId, data, callback) {
		local outs = []
		try { if ("outputs" in data && data.outputs != null) outs = data.outputs } catch (e) {}
		if (outs.len() == 0) { if (callback != null) callback(); return }
		local queue = []
		local pos = 0
		foreach (o in outs) {
			local instance = ""
			try { if ("instance" in o && o.instance != null) instance = o.instance.tostring().toupper() } catch (e) {}
			if (instance == "") { pos += 1; continue }
			local amount = 1
			try { if ("amount" in o) amount = o.amount.tointeger() } catch (e) {}
			if (amount < 1) amount = 1
			queue.append({ instance = instance, amount = amount, position = pos })
			pos += 1
		}
		phoenix.crafting.Structure._saveOutputQueue(recipeId, queue, 0, callback)
	}

	function _saveOutputQueue(recipeId, queue, index, callback) {
		if (index >= queue.len()) { if (callback != null) callback(); return }
		local entry = queue[index]
		local model = CraftingOutputModel()
		model.recipeId = recipeId
		model.itemInstance = entry.instance
		model.amount = entry.amount
		model.position = entry.position
		model.insertAsync(function (_) {
			phoenix.crafting.Structure._saveOutputQueue(recipeId, queue, index + 1, callback)
		})
	}

	function _insertStations(recipeId, data, callback) {
		local visuals = []
		try { if ("visuals" in data && data.visuals != null) visuals = data.visuals } catch (e) {}
		if (visuals.len() == 0) { if (callback != null) callback(); return }
		local seen = {}
		local queue = []
		local pos = 0
		foreach (v in visuals) {
			local visStr = ""
			try { if (v != null) visStr = v.tostring().toupper() } catch (e) {}
			if (visStr == "" || (visStr in seen)) continue
			seen[visStr] <- true
			queue.append({ visual = visStr, position = pos })
			pos += 1
		}
		phoenix.crafting.Structure._saveStationQueue(recipeId, queue, 0, callback)
	}

	function _saveStationQueue(recipeId, queue, index, callback) {
		if (index >= queue.len()) { if (callback != null) callback(); return }
		local entry = queue[index]
		local model = CraftingStationModel()
		model.visual = entry.visual
		model.recipeId = recipeId
		model.position = entry.position
		model.insertAsync(function (_) {
			phoenix.crafting.Structure._saveStationQueue(recipeId, queue, index + 1, callback)
		})
	}

	function deleteRecipe(id, callback) {
		local rid = id.tointeger()
		if (rid <= 0) { if (callback != null) callback(false); return }
		phoenix.crafting.Structure._deleteIngredients(rid, function () {
			phoenix.crafting.Structure._deleteOutputs(rid, function () {
				phoenix.crafting.Structure._deleteStations(rid, function () {
					ORM.engine.executeAsync("DELETE FROM `phoenix_crafting_recipes` WHERE `id` = " + rid, function (_) {
						phoenix.crafting.Structure.loadAll(function () {
							try { phoenix.crafting.Structure.broadcastStations() } catch (eB) {}
							try { phoenix.vob.Structure.broadcastSnapshot() } catch (eS) {}
							if (callback != null) callback(true)
						})
					})
				})
			})
		})
	}

	function broadcastStations() {
		local keys = []
		foreach (vis, _ in phoenix.crafting.Structure.stationByVisual) keys.append(vis)
		local payload = ""
		local first = true
		foreach (k in keys) {
			if (first) { payload = k; first = false } else { payload = payload + "\n" + k }
		}
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try {
				if (!isPlayerConnected(pid)) continue
				local msg = phoenix.crafting.Message.Stations()
				msg.visuals = payload
				msg.serialize().send(pid, RELIABLE_ORDERED)
			} catch (e) {}
		}
	}

	function sendStationsTo(playerId) {
		local keys = []
		foreach (vis, _ in phoenix.crafting.Structure.stationByVisual) keys.append(vis)
		local payload = ""
		local first = true
		foreach (k in keys) {
			if (first) { payload = k; first = false } else { payload = payload + "\n" + k }
		}
		try {
			local msg = phoenix.crafting.Message.Stations()
			msg.visuals = payload
			msg.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}
}

addEventHandler("phoenix.database.OnSyncReady", function () {
	try { phoenix.crafting.Structure.cleanupLegacyTables() } catch (e) {}
})

addEventHandler("phoenix.database.OnReady", function () {
	setTimer(function () {
		try {
			ORM.engine.executeAsync("DELETE FROM `phoenix_crafting_recipes` WHERE `resultInstance` = '' OR `resultInstance` IS NULL", function (_) {
				phoenix.crafting.Structure.loadAll(function () {
					try { phoenix.crafting.Structure.broadcastStations() } catch (e) {}
					try { phoenix.vob.Structure.broadcastSnapshot() } catch (e2) {}
				})
			})
		} catch (e) {
			phoenix.crafting.Structure.loadAll(function () {})
		}
	}, 1500, 1)
})

addEventHandler("onInit", function () {
	setTimer(function () {
		try {
			local ready = false
			try { ready = phoenix.database.ready } catch (eR) {}
			if (!ready) return
			if (phoenix.crafting.Structure.loaded) return
			phoenix.crafting.Structure.loadAll(function () {
				try { phoenix.crafting.Structure.broadcastStations() } catch (e) {}
				try { phoenix.vob.Structure.broadcastSnapshot() } catch (e2) {}
			})
		} catch (e) {}
	}, 3500, 1)
})

addEventHandler("onPlayerJoin", function (playerId) {
	setTimer(function () {
		try { phoenix.crafting.Structure.sendStationsTo(playerId) } catch (e) {}
	}, 3500, 1)
})
