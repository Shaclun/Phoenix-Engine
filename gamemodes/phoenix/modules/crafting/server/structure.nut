phoenix.crafting.Structure <- {

	recipes = {}
	ingredients = {}
	outputs = {}
	stationByVisual = {}
	loaded = false
	loading = false

	function normalizeStationVisual(visual) {
		if (visual == null) return ""
		return strip(visual.tostring()).toupper()
	}

	function stationVisualKeys(visual) {
		local out = []
		local key = phoenix.crafting.Structure.normalizeStationVisual(visual)
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

	function _appendStationRecipe(cache, visual, recipeId) {
		local key = phoenix.crafting.Structure.normalizeStationVisual(visual)
		if (key == "") return
		if (!(key in cache)) cache[key] <- []
		local target = recipeId.tointeger()
		foreach (existing in cache[key]) if (existing == target) return
		cache[key].append(target)
	}

	function isStationVisual(visual) {
		foreach (key in phoenix.crafting.Structure.stationVisualKeys(visual)) {
			if (key in phoenix.crafting.Structure.stationByVisual && phoenix.crafting.Structure.stationByVisual[key].len() > 0) return true
		}
		return false
	}

	function recipeAllowedForVisual(visual, recipeId) {
		local target = recipeId.tointeger()
		foreach (key in phoenix.crafting.Structure.stationVisualKeys(visual)) {
			if (!(key in phoenix.crafting.Structure.stationByVisual)) continue
			foreach (id in phoenix.crafting.Structure.stationByVisual[key]) if (id == target) return true
		}
		return false
	}

	function stationVisualsWithAliases() {
		local out = []
		local seen = {}
		foreach (visual, _ in phoenix.crafting.Structure.stationByVisual) {
			foreach (key in phoenix.crafting.Structure.stationVisualKeys(visual)) {
				if (key in seen) continue
				seen[key] <- true
				out.append(key)
			}
		}
		return out
	}

	function loadAll(callback = null) {
		if (phoenix.crafting.Structure.loading) {
			setTimer(function () {
				try { phoenix.crafting.Structure.loadAll(callback) } catch (e) {}
			}, 250, 1)
			return
		}
		phoenix.crafting.Structure.loading = true
		local nextRecipes = {}
		local nextIngredients = {}
		local nextOutputs = {}
		local nextStations = {}
		try {
			CraftingRecipeModel.findAsync(@(q) q, function (recipes) {
				foreach (r in recipes) {
					local id = r.id.tointeger()
					nextRecipes[id] <- {
						id = id,
						name = r.name != null ? r.name.tostring() : "",
						resultInstance = r.resultInstance != null ? r.resultInstance.tostring() : "",
						resultAmount = r.resultAmount.tointeger(),
						category = r.category != null ? r.category.tostring() : "misc",
						craftTimeMs = r.craftTimeMs.tointeger(),
						requiredLevel = r.requiredLevel.tointeger(),
						professionId = r.professionId != null ? r.professionId.tointeger() : 0,
						requiredProfessionTier = r.requiredProfessionTier.tointeger(),
						baseStamina = r.baseStamina.tointeger(),
						professionXp = r.professionXp.tointeger(),
						description = r.description != null ? r.description.tostring() : ""
					}
				}
				CraftingIngredientModel.findAsync(@(q) q, function (ings) {
					foreach (ing in ings) {
						local rid = ing.recipeId.tointeger()
						if (!(rid in nextIngredients)) nextIngredients[rid] <- []
						nextIngredients[rid].append({
							role = ing.role != null ? ing.role.tostring() : "consume",
							instance = ing.itemInstance != null ? ing.itemInstance.tostring() : "",
							amount = ing.amount.tointeger(),
							position = ing.position.tointeger()
						})
					}
					foreach (rid, list in nextIngredients) list.sort(function (a, b) { return a.position <=> b.position })
					CraftingOutputModel.findAsync(@(q) q, function (outs) {
						foreach (o in outs) {
							local rid2 = o.recipeId.tointeger()
							if (!(rid2 in nextOutputs)) nextOutputs[rid2] <- []
							nextOutputs[rid2].append({
								instance = o.itemInstance != null ? o.itemInstance.tostring() : "",
								amount = o.amount.tointeger(),
								position = o.position.tointeger()
							})
						}
						foreach (rid2, list in nextOutputs) list.sort(function (a, b) { return a.position <=> b.position })
						CraftingStationModel.findAsync(@(q) q, function (stations) {
							foreach (s in stations) phoenix.crafting.Structure._appendStationRecipe(nextStations, s.visual, s.recipeId)
							phoenix.crafting.Structure.recipes = nextRecipes
							phoenix.crafting.Structure.ingredients = nextIngredients
							phoenix.crafting.Structure.outputs = nextOutputs
							phoenix.crafting.Structure.stationByVisual = nextStations
							phoenix.crafting.Structure.loaded = true
							phoenix.crafting.Structure.loading = false
							local recCount = 0
							foreach (_k, _v in nextRecipes) recCount += 1
							print("[crafting] loaded " + recCount + " recipes, " + nextStations.len() + " station visuals\n")
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
			professionId = rec.professionId, requiredProfessionTier = rec.requiredProfessionTier,
			baseStamina = rec.baseStamina, professionXp = rec.professionXp,
			description = rec.description, ingredients = ings, outputs = outs
		}
	}

	function recipesForVisual(visual) {
		local out = []
		local seen = {}
		foreach (key in phoenix.crafting.Structure.stationVisualKeys(visual)) {
			if (!(key in phoenix.crafting.Structure.stationByVisual)) continue
			foreach (rid in phoenix.crafting.Structure.stationByVisual[key]) {
				if (rid in seen) continue
				local rec = phoenix.crafting.Structure.recipeById(rid)
				if (rec == null) continue
				seen[rid] <- true
				out.append(rec)
			}
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

	function _sql(value) {
		if (value == null) return ""
		local source = value.tostring()
		local out = ""
		for (local i = 0; i < source.len(); i += 1) {
			local c = source[i]
			if (c == '\\') out += "\\\\"
			else if (c == '\'') out += "\\'"
			else out += source.slice(i, i + 1)
		}
		return out
	}

	function _normalizeRecipe(data) {
		if (data == null) return { ok = false, error = "empty" }
		local categories = { misc = true, weapon = true, armor = true, food = true, potion = true, alchemy = true, smithing = true }
		local id = 0; local name = ""; local resultInstance = ""; local resultAmount = 1
		local category = "misc"; local craftTimeMs = 1500; local requiredLevel = 0; local description = ""
		local professionId = 0; local requiredProfessionTier = 0; local baseStamina = 0; local professionXp = 0
		try { if ("id" in data && data.id != null) id = data.id.tointeger() } catch (e0) {}
		try { if ("name" in data && data.name != null) name = strip(data.name.tostring()) } catch (e1) {}
		try { if ("resultInstance" in data && data.resultInstance != null) resultInstance = strip(data.resultInstance.tostring()).toupper() } catch (e2) {}
		try { if ("resultAmount" in data) resultAmount = data.resultAmount.tointeger() } catch (e3) {}
		try { if ("category" in data && data.category != null) category = data.category.tostring().tolower() } catch (e4) {}
		try { if ("craftTimeMs" in data) craftTimeMs = data.craftTimeMs.tointeger() } catch (e5) {}
		try { if ("requiredLevel" in data) requiredLevel = data.requiredLevel.tointeger() } catch (e6) {}
		try { if ("description" in data && data.description != null) description = data.description.tostring() } catch (e7) {}
		try { if ("professionId" in data && data.professionId != null) professionId = data.professionId.tointeger() } catch (eP1) {}
		try { if ("requiredProfessionTier" in data) requiredProfessionTier = data.requiredProfessionTier.tointeger() } catch (eP2) {}
		try { if ("baseStamina" in data) baseStamina = data.baseStamina.tointeger() } catch (eP3) {}
		try { if ("professionXp" in data) professionXp = data.professionXp.tointeger() } catch (eP4) {}
		if (resultInstance == "" || resultInstance.len() > 64) return { ok = false, error = "noResult" }
		if (phoenix.item.find(resultInstance) == null) return { ok = false, error = "noResultScheme" }
		if (name == "") name = resultInstance
		if (name.len() > 96 || description.len() > 4000) return { ok = false, error = "textTooLong" }
		if (!(category in categories)) return { ok = false, error = "badCategory" }
		if (resultAmount < 1 || resultAmount > 100000) return { ok = false, error = "badAmount" }
		if (craftTimeMs < 100 || craftTimeMs > 600000) return { ok = false, error = "badTime" }
		if (requiredLevel < 0 || requiredLevel > 1000) return { ok = false, error = "badLevel" }
		if (professionId < 0 || (professionId > 0 && phoenix.profession.Structure.definition(professionId) == null)) return { ok = false, error = "badProfession" }
		if (requiredProfessionTier < 0 || requiredProfessionTier > 100) return { ok = false, error = "badProfessionTier" }
		if (baseStamina < 0 || baseStamina > 10000) return { ok = false, error = "badStamina" }
		if (professionXp < 0 || professionXp > 1000000) return { ok = false, error = "badProfessionXp" }
		if (professionId == 0 && (requiredProfessionTier > 0 || professionXp > 0)) return { ok = false, error = "badProfession" }

		local rawIngredients = []; local rawOutputs = []; local rawVisuals = []
		try { if ("ingredients" in data && data.ingredients != null) rawIngredients = data.ingredients } catch (e8) {}
		try { if ("outputs" in data && data.outputs != null) rawOutputs = data.outputs } catch (e9) {}
		try { if ("visuals" in data && data.visuals != null) rawVisuals = data.visuals } catch (e10) {}
		if (rawIngredients.len() > 64 || rawOutputs.len() > 32 || rawVisuals.len() > 32) return { ok = false, error = "tooManyEntries" }

		local ingredients = []; local ingredientAt = {}
		foreach (entry in rawIngredients) {
			local role = "consume"; local instance = ""; local amount = 1
			try { if ("role" in entry && entry.role != null) role = entry.role.tostring().tolower() } catch (e11) {}
			try { if ("instance" in entry && entry.instance != null) instance = strip(entry.instance.tostring()).toupper() } catch (e12) {}
			try { if ("amount" in entry) amount = entry.amount.tointeger() } catch (e13) {}
			if (role != "consume" && role != "tool") return { ok = false, error = "badRole" }
			if (instance == "" || instance.len() > 64 || phoenix.item.find(instance) == null) return { ok = false, error = "badIngredient:" + instance }
			if (amount < 1 || amount > 100000) return { ok = false, error = "badAmount" }
			local key = role + ":" + instance
			if (key in ingredientAt) {
				local idx = ingredientAt[key]
				if (ingredients[idx].amount + amount > 100000) return { ok = false, error = "badAmount" }
				ingredients[idx].amount += amount
			} else {
				ingredientAt[key] <- ingredients.len()
				ingredients.append({ role = role, instance = instance, amount = amount })
			}
		}

		local outputs = []; local outputAt = {}
		foreach (entry in rawOutputs) {
			local instance = ""; local amount = 1
			try { if ("instance" in entry && entry.instance != null) instance = strip(entry.instance.tostring()).toupper() } catch (e14) {}
			try { if ("amount" in entry) amount = entry.amount.tointeger() } catch (e15) {}
			if (instance == "" || instance.len() > 64 || phoenix.item.find(instance) == null) return { ok = false, error = "noOutputScheme:" + instance }
			if (amount < 1 || amount > 100000) return { ok = false, error = "badAmount" }
			if (instance in outputAt) {
				local idx = outputAt[instance]
				if (outputs[idx].amount + amount > 100000) return { ok = false, error = "badAmount" }
				outputs[idx].amount += amount
			} else {
				outputAt[instance] <- outputs.len()
				outputs.append({ instance = instance, amount = amount })
			}
		}

		local visuals = []; local visualSeen = {}
		foreach (entry in rawVisuals) {
			local visual = ""
			try { if (entry != null) visual = phoenix.crafting.Structure.normalizeStationVisual(entry) } catch (e16) {}
			if (visual == "" || visual.len() > 96) return { ok = false, error = "badStation" }
			if (!(visual in visualSeen)) { visualSeen[visual] <- true; visuals.append(visual) }
		}
		if (visuals.len() == 0) return { ok = false, error = "noStation" }
		return { ok = true, value = { id = id, name = name, resultInstance = resultInstance, resultAmount = resultAmount,
			category = category, craftTimeMs = craftTimeMs, requiredLevel = requiredLevel, description = description,
			professionId = professionId, requiredProfessionTier = requiredProfessionTier, baseStamina = baseStamina, professionXp = professionXp,
			ingredients = ingredients, outputs = outputs, visuals = visuals } }
	}

	function saveRecipe(data, callback) {
		local normalized = phoenix.crafting.Structure._normalizeRecipe(data)
		if (!normalized.ok) { if (callback != null) callback(false, normalized.error, 0); return }
		local recipe = normalized.value
		local id = recipe.id
		try {
			ORM.engine.execute("START TRANSACTION")
			if (id > 0) {
				local rows = ORM.engine.execute("SELECT `id` FROM `phoenix_crafting_recipes` WHERE `id`=" + id + " FOR UPDATE")
				if (rows == null || rows.len() == 0) throw "recipeNotFound"
				ORM.engine.execute("UPDATE `phoenix_crafting_recipes` SET `name`='" + _sql(recipe.name) + "',`resultInstance`='" + _sql(recipe.resultInstance) + "',`resultAmount`=" + recipe.resultAmount + ",`category`='" + _sql(recipe.category) + "',`craftTimeMs`=" + recipe.craftTimeMs + ",`requiredLevel`=" + recipe.requiredLevel + ",`professionId`=" + (recipe.professionId > 0 ? recipe.professionId.tostring() : "NULL") + ",`requiredProfessionTier`=" + recipe.requiredProfessionTier + ",`baseStamina`=" + recipe.baseStamina + ",`professionXp`=" + recipe.professionXp + ",`description`='" + _sql(recipe.description) + "',`updatedAt`=NOW() WHERE `id`=" + id)
			} else {
				ORM.engine.execute("INSERT INTO `phoenix_crafting_recipes` (`name`,`resultInstance`,`resultAmount`,`category`,`craftTimeMs`,`requiredLevel`,`professionId`,`requiredProfessionTier`,`baseStamina`,`professionXp`,`description`,`updatedAt`) VALUES ('" + _sql(recipe.name) + "','" + _sql(recipe.resultInstance) + "'," + recipe.resultAmount + ",'" + _sql(recipe.category) + "'," + recipe.craftTimeMs + "," + recipe.requiredLevel + "," + (recipe.professionId > 0 ? recipe.professionId.tostring() : "NULL") + "," + recipe.requiredProfessionTier + "," + recipe.baseStamina + "," + recipe.professionXp + ",'" + _sql(recipe.description) + "',NOW())")
				local idRows = ORM.engine.execute("SELECT LAST_INSERT_ID() AS `id`")
				if (idRows == null || idRows.len() == 0) throw "insertFailed"
				id = idRows[0].id.tointeger()
			}
			ORM.engine.execute("DELETE FROM `phoenix_crafting_ingredients` WHERE `recipeId`=" + id)
			ORM.engine.execute("DELETE FROM `phoenix_crafting_outputs` WHERE `recipeId`=" + id)
			ORM.engine.execute("DELETE FROM `phoenix_crafting_stations` WHERE `recipeId`=" + id)
			for (local i = 0; i < recipe.ingredients.len(); i += 1) {
				local ing = recipe.ingredients[i]
				ORM.engine.execute("INSERT INTO `phoenix_crafting_ingredients` (`recipeId`,`role`,`itemInstance`,`amount`,`position`) VALUES (" + id + ",'" + _sql(ing.role) + "','" + _sql(ing.instance) + "'," + ing.amount + "," + i + ")")
			}
			for (local o = 0; o < recipe.outputs.len(); o += 1) {
				local output = recipe.outputs[o]
				ORM.engine.execute("INSERT INTO `phoenix_crafting_outputs` (`recipeId`,`itemInstance`,`amount`,`position`) VALUES (" + id + ",'" + _sql(output.instance) + "'," + output.amount + "," + o + ")")
			}
			for (local s = 0; s < recipe.visuals.len(); s += 1)
				ORM.engine.execute("INSERT INTO `phoenix_crafting_stations` (`visual`,`recipeId`,`position`) VALUES ('" + _sql(recipe.visuals[s]) + "'," + id + "," + s + ")")
			ORM.engine.execute("COMMIT")
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			local code = error.tostring() == "recipeNotFound" ? "recipeNotFound" : "database"
			print("[crafting] recipe save failed: " + error + "\n")
			if (callback != null) callback(false, code, 0)
			return
		}
		phoenix.crafting.Structure.loadAll(function () { if (callback != null) callback(true, "", id) })
	}

	function deleteRecipe(id, callback) {
		local rid = id.tointeger()
		if (rid <= 0) { if (callback != null) callback(false); return }
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT `id` FROM `phoenix_crafting_recipes` WHERE `id`=" + rid + " FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "recipeNotFound"
			ORM.engine.execute("DELETE FROM `phoenix_crafting_ingredients` WHERE `recipeId`=" + rid)
			ORM.engine.execute("DELETE FROM `phoenix_crafting_outputs` WHERE `recipeId`=" + rid)
			ORM.engine.execute("DELETE FROM `phoenix_crafting_stations` WHERE `recipeId`=" + rid)
			ORM.engine.execute("DELETE FROM `phoenix_crafting_recipes` WHERE `id`=" + rid)
			ORM.engine.execute("COMMIT")
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			print("[crafting] recipe delete failed: " + error + "\n")
			if (callback != null) callback(false)
			return
		}
		phoenix.crafting.Structure.loadAll(function () {
			try { phoenix.crafting.Structure.broadcastStations() } catch (eB) {}
			try { phoenix.vob.Structure.broadcastSnapshot() } catch (eS) {}
			if (callback != null) callback(true)
		})
	}

	function stationsPayload() {
		local payload = ""
		local first = true
		foreach (key in phoenix.crafting.Structure.stationVisualsWithAliases()) {
			if (first) { payload = key; first = false } else payload += "\n" + key
		}
		return payload
	}

	function broadcastStations() {
		local payload = phoenix.crafting.Structure.stationsPayload()
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
		try {
			local msg = phoenix.crafting.Message.Stations()
			msg.visuals = phoenix.crafting.Structure.stationsPayload()
			msg.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}
}

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
