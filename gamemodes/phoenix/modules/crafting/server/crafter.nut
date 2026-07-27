phoenix.crafting.Crafter <- {
	MAX_BATCH = 100
	TICK_MS = 250
	activeByPlayer = {}
	jobs = {}

	function enabled() {
		return phoenix.features.Settings.isEnabled("crafting.enabled")
	}

	function disableAll() {
		local playerIds = {}
		foreach (playerId, _ in phoenix.crafting.Crafter.activeByPlayer) playerIds[playerId] <- true
		foreach (playerId, _ in phoenix.crafting.Crafter.jobs) playerIds[playerId] <- true
		foreach (playerId, _ in playerIds) phoenix.crafting.Crafter.close(playerId, "featureDisabled")
	}

	function playerInventoryString(playerId) {
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return ""
		local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
		if (inv == null) return ""
		local payload = ""; local first = true
		foreach (rec in inv.items) {
			local inst = rec.instanceId != null ? rec.instanceId.toupper() : ""
			if (inst == "") continue
			local visual = ""
			try { local found = phoenix.item.lookupVisual(inst); if (found != null) visual = found } catch (e) {}
			local line = inst + "|" + rec.amount + "|" + (rec.equipped == 1 ? 1 : 0) + "|" + rec.quality + "|" + rec.upgrade + "|" + visual
			if (first) { payload = line; first = false } else payload += "\n" + line
		}
		return payload
	}

	function recipesString(playerId, recipes) {
		local payload = ""; local first = true
		local character = phoenix.character.Structure.getActive(playerId)
		foreach (rec in recipes) {
			local ingredients = ""; local ingredientFirst = true
			foreach (ing in rec.ingredients) {
				local visual = ""
				try { local found = phoenix.item.lookupVisual(ing.instance); if (found != null) visual = found } catch (e) {}
				local part = ing.role + "," + ing.instance + "," + ing.amount + "," + visual
				if (ingredientFirst) { ingredients = part; ingredientFirst = false } else ingredients += ";" + part
			}
			local outputs = ""; local outputFirst = true
			foreach (output in (("outputs" in rec) ? rec.outputs : [])) {
				local visual = ""
				try { local found = phoenix.item.lookupVisual(output.instance); if (found != null) visual = found } catch (e) {}
				local part = output.instance + "," + output.amount + "," + visual
				if (outputFirst) { outputs = part; outputFirst = false } else outputs += ";" + part
			}
			local resultVisual = ""
			try { local found = phoenix.item.lookupVisual(rec.resultInstance); if (found != null) resultVisual = found } catch (e) {}
			local professionCode = ""; local professionName = ""; local professionLevel = 0; local professionTier = 0
			if (rec.professionId > 0) {
				local definition = phoenix.profession.Structure.definition(rec.professionId)
				if (definition != null) { professionCode = definition.code; professionName = definition.namePl }
				if (character != null) {
					local progress = phoenix.profession.Structure.progressFor(character.id, rec.professionId)
					professionLevel = progress.level
					professionTier = phoenix.profession.Structure.tierForLevel(progress.level)
				}
			}
			local effectiveStamina = phoenix.profession.Structure.staminaCostForLevel(professionLevel, rec.requiredProfessionTier, rec.baseStamina)
			local line = rec.id + "|" + _escape(rec.name) + "|" + rec.resultInstance + "|" + rec.resultAmount + "|" +
				rec.category + "|" + rec.craftTimeMs + "|" + rec.requiredLevel + "|" + _escape(rec.description) + "|" + ingredients + "|" + resultVisual + "|" + outputs + "|" +
				rec.professionId + "|" + _escape(professionCode) + "|" + _escape(professionName) + "|" + rec.requiredProfessionTier + "|" + rec.baseStamina + "|" + rec.professionXp + "|" + professionLevel + "|" + professionTier + "|" + effectiveStamina
			if (first) { payload = line; first = false } else payload += "\n" + line
		}
		return payload
	}

	function _escape(text) {
		if (text == null) return ""
		local out = ""; local source = text.tostring()
		for (local i = 0; i < source.len(); i += 1) {
			local c = source[i]
			if (c == '\n' || c == '|' || c == ';') out += " "
			else out += source.slice(i, i + 1)
		}
		return out
	}

	function _vobEntry(vobId) {
		try { if (vobId in phoenix.vob.Structure.entries) return phoenix.vob.Structure.entries[vobId] } catch (e) {}
		return null
	}

	function _vobVisualAndLabel(vobId) {
		local entry = _vobEntry(vobId)
		if (entry == null) return { visual = "", label = vobId }
		local visual = ("visual" in entry && entry.visual != null) ? entry.visual.tostring() : ""
		local label = ("name" in entry && entry.name != null && entry.name != "") ? entry.name.tostring() : visual
		return { visual = visual, label = label }
	}

	function _normalizeWorld(value) {
		try { return phoenix.vob.Structure.normalizeWorld(value) } catch (e) {}
		if (value == null || value == "") return "NEWWORLD"
		local world = value.tostring(); local separator = -1
		for (local i = world.len() - 1; i >= 0; i -= 1) {
			local ch = world[i]
			if (ch == '\\' || ch == '/') { separator = i; break }
		}
		if (separator >= 0) world = world.slice(separator + 1)
		world = world.toupper(); local zenAt = world.find(".ZEN")
		if (zenAt != null) world = world.slice(0, zenAt)
		return world
	}
	function _stationValid(playerId, vobId) {
		try {
			local station = _vobEntry(vobId)
			if (station == null || !("x" in station) || !("y" in station) || !("z" in station)) return false
			if (station.x == null || station.y == null || station.z == null) return false
			local playerWorld = getPlayerWorld(playerId)
			if ("world" in station && station.world != null && station.world != "" && _normalizeWorld(playerWorld) != _normalizeWorld(station.world)) return false
			local pos = getPlayerPosition(playerId)
			if (pos == null) return false
			local dx = pos.x - station.x.tofloat(); local dy = pos.y - station.y.tofloat(); local dz = pos.z - station.z.tofloat()
			return sqrt(dx * dx + dy * dy + dz * dz) <= 550.0
		} catch (e) {}
		return false
	}

	function _recipeAllowed(visual, recipeId) {
		return phoenix.crafting.Structure.recipeAllowedForVisual(visual, recipeId)
	}

	function _openFailure(playerId, error, vobId, visual = "") {
		_reply(playerId, false, error, "", "", 0)
		local text = "Nie mozna otworzyc stanowiska rzemieslniczego."
		if (error == "tooFar") text = "Podejdz blizej do stanowiska."
		else if (error == "notStation") text = "Ten obiekt nie jest stanowiskiem rzemieslniczym."
		else if (error == "noRecipe") text = "To stanowisko nie ma przypisanych receptur."
		try { phoenix.notification.notify(playerId, "error", "Crafting", text, 3500) } catch (eN) {}
		try { print("[crafting] open rejected player=" + playerId + " vob=" + vobId + " visual=" + visual + " reason=" + error + "\n") } catch (eL) {}
	}

	function open(playerId, vobId) {
		if (!phoenix.crafting.Crafter.enabled()) { phoenix.crafting.Crafter.close(playerId, "featureDisabled"); return }
		if (vobId == null || vobId == "") return
		local activeCharacter = phoenix.character.Structure.getActive(playerId)
		if (activeCharacter == null) return
		if (!_stationValid(playerId, vobId)) {
			_openFailure(playerId, "tooFar", vobId)
			return
		}
		local info = _vobVisualAndLabel(vobId)
		if (info.visual == "") { _openFailure(playerId, "notStation", vobId); return }
		local recipes = phoenix.crafting.Structure.recipesForVisual(info.visual)
		if (recipes.len() == 0) { _openFailure(playerId, "noRecipe", vobId, info.visual); return }
		phoenix.crafting.Crafter.activeByPlayer[playerId] <- { vobId = vobId, visual = phoenix.crafting.Structure.normalizeStationVisual(info.visual) }
		local msg = phoenix.crafting.Message.Open()
		msg.vobId = vobId; msg.stationName = info.label; msg.recipes = recipesString(playerId, recipes)
		msg.playerItems = playerInventoryString(playerId)
		local level = 1
		try { level = getPlayerLevel(playerId) } catch (e) {}
		msg.playerLevel = level > 0 ? level : 1
		try { msg.playerStamina = phoenix.player.Resources.current(playerId, activeCharacter, "stamina").tointeger() } catch (eStamina) { msg.playerStamina = 0 }
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function close(playerId, reason = "cancelled") {
		if (playerId in phoenix.crafting.Crafter.jobs) _abortJob(playerId, reason, true)
		if (playerId in phoenix.crafting.Crafter.activeByPlayer) phoenix.crafting.Crafter.activeByPlayer.rawdelete(playerId)
	}
	function _counts(characterId, instance) {
		local loose = phoenix.item.Structure.countRequiredInstance(PhoenixInventoryOwner.Player, characterId, instance, false)
		local all = phoenix.item.Structure.countRequiredInstance(PhoenixInventoryOwner.Player, characterId, instance, true)
		return { loose = loose, equipped = all - loose, all = all }
	}

	function _requirements(recipe) {
		local consume = {}; local tools = {}
		foreach (ing in recipe.ingredients) {
			local role = ing.role != null ? ing.role.tostring().tolower() : ""
			local instance = ing.instance != null ? ing.instance.tostring().toupper() : ""
			if ((role != "consume" && role != "tool") || instance == "" || ing.amount <= 0 || phoenix.item.find(instance) == null)
				return { ok = false, error = "badIngredient:" + instance }
			local target = role == "consume" ? consume : tools
			if (!(instance in target)) target[instance] <- 0
			target[instance] += ing.amount
		}
		return { ok = true, consume = consume, tools = tools }
	}

	function _validate(playerId, vobId, recipeId, quantity) {
		if (!phoenix.crafting.Structure.loaded) return { ok = false, error = "loading" }
		local session = (playerId in activeByPlayer) ? activeByPlayer[playerId] : null
		if (session == null || session.vobId != vobId) return { ok = false, error = "notActive" }
		if (!_stationValid(playerId, vobId)) return { ok = false, error = "tooFar" }
		local character = phoenix.character.Structure.getActive(playerId)
		if (character == null) return { ok = false, error = "noCharacter" }
		local recipe = phoenix.crafting.Structure.recipeById(recipeId)
		if (recipe == null) return { ok = false, error = "noRecipe" }
		if (!_recipeAllowed(session.visual, recipeId)) return { ok = false, error = "notAllowed" }
		local level = 1
		try { level = getPlayerLevel(playerId) } catch (e) {}
		if (level < recipe.requiredLevel) return { ok = false, error = "lowLevel" }
		local professionCheck = phoenix.profession.Structure.check(playerId, recipe.professionId, recipe.requiredProfessionTier, recipe.baseStamina, quantity)
		if (!professionCheck.ok) return professionCheck
		if (recipe.resultAmount <= 0 || phoenix.item.find(recipe.resultInstance) == null) return { ok = false, error = "noResultScheme:" + recipe.resultInstance }
		foreach (output in recipe.outputs) {
			if (output.amount <= 0 || phoenix.item.find(output.instance) == null) return { ok = false, error = "noOutputScheme:" + output.instance }
		}
		local requirements = _requirements(recipe)
		if (!requirements.ok) return requirements
		local instances = {}
		foreach (instance, _ in requirements.consume) instances[instance] <- true
		foreach (instance, _ in requirements.tools) instances[instance] <- true
		local maxCraftable = phoenix.crafting.Crafter.MAX_BATCH
		foreach (instance, _ in instances) {
			local counts = _counts(character.id, instance)
			local toolNeed = (instance in requirements.tools) ? requirements.tools[instance] : 0
			if (counts.all < toolNeed) return { ok = false, error = "missingTool:" + instance, maxCraftable = 0 }
			local reserveLoose = toolNeed - counts.equipped
			if (reserveLoose < 0) reserveLoose = 0
			local available = counts.loose - reserveLoose
			local perCraft = (instance in requirements.consume) ? requirements.consume[instance] : 0
			if (perCraft > 0) {
				local possible = available >= 0 ? (available / perCraft).tointeger() : 0
				if (possible < maxCraftable) maxCraftable = possible
			}
		}
		if (maxCraftable < 0) maxCraftable = 0
		if (quantity > maxCraftable) return { ok = false, error = "quantityTooHigh:" + maxCraftable, maxCraftable = maxCraftable }
		return { ok = true, character = character, recipe = recipe, consume = requirements.consume, tools = requirements.tools,
			maxCraftable = maxCraftable, professionCheck = professionCheck }
	}
	function onRequestOpen(playerId, message) {
		if (!phoenix.crafting.Crafter.enabled()) { phoenix.crafting.Crafter.close(playerId, "featureDisabled"); return }
		if (message != null && message.vobId != null) open(playerId, message.vobId.tostring())
	}

	function onClose(playerId, _message) { close(playerId, "cancelled") }

	function onCancel(playerId, message) {
		if (!(playerId in jobs)) return
		local requestId = message != null && message.requestId != null ? message.requestId.tostring() : ""
		if (requestId != "" && jobs[playerId].requestId != requestId) return
		_abortJob(playerId, "cancelled", true)
	}

	function onCraftRequest(playerId, message) {
		if (!phoenix.crafting.Crafter.enabled()) {
			local hadJob = playerId in phoenix.crafting.Crafter.jobs
			phoenix.crafting.Crafter.close(playerId, "featureDisabled")
			if (!hadJob) phoenix.crafting.Crafter._reply(playerId, false, "featureDisabled", message != null && message.requestId != null ? message.requestId.tostring() : "", "", 0)
			return
		}
		if (message == null) return
		local requestId = message.requestId != null ? message.requestId.tostring() : ""
		if (requestId == "") requestId = playerId + "-" + getTickCount()
		if (playerId in jobs) { _reply(playerId, false, "busy", requestId, "", 0); return }
		local otherActivity = false
		try { otherActivity = (playerId in phoenix.herb.Structure.active) } catch (eHerb) {}
		try { if (playerId in phoenix.profession.Hunting.jobs) otherActivity = true } catch (eHunting) {}
		if (otherActivity) { _reply(playerId, false, "busy", requestId, "", 0); return }
		local vobId = message.vobId != null ? message.vobId.tostring() : ""
		local recipeId = message.recipeId.tointeger(); local quantity = message.quantity.tointeger()
		if (quantity < 1) quantity = 1
		if (quantity > phoenix.crafting.Crafter.MAX_BATCH) quantity = phoenix.crafting.Crafter.MAX_BATCH
		if (vobId == "" || recipeId <= 0) { _reply(playerId, false, "invalid", requestId, "", 0); return }
		local checked = _validate(playerId, vobId, recipeId, quantity)
		if (!checked.ok) { _reply(playerId, false, checked.error, requestId, "", 0); return }
		local now = getTickCount(); local totalMs = checked.recipe.craftTimeMs * quantity
		if (totalMs < 100) totalMs = 100
		jobs[playerId] <- {
			requestId = requestId, playerId = playerId, characterId = checked.character.id,
			vobId = vobId, visual = activeByPlayer[playerId].visual, recipeId = recipeId,
			quantity = quantity, startedAt = now, finishAt = now + totalMs, totalMs = totalMs,
			professionId = checked.recipe.professionId, contentTier = checked.recipe.requiredProfessionTier,
			professionXp = checked.recipe.professionXp, staminaCost = checked.professionCheck.staminaCost,
			staminaConsumed = false, lastProgressAt = 0, state = "crafting", aborted = false, abortError = "cancelled"
		}
		try { playAni(playerId, "T_REPAIR_S0_2_S1") } catch (e) {}
		_sendProgress(playerId, jobs[playerId], 0, "crafting")
	}

	function tick() {
		if (!phoenix.crafting.Crafter.enabled()) { phoenix.crafting.Crafter.disableAll(); return }
		local now = getTickCount(); local playerIds = []
		foreach (playerId, _ in phoenix.crafting.Crafter.jobs) playerIds.append(playerId)
		foreach (playerId in playerIds) {
			if (!(playerId in phoenix.crafting.Crafter.jobs)) continue
			local job = phoenix.crafting.Crafter.jobs[playerId]
			if (job.state != "crafting") continue
			local activeCharacter = phoenix.character.Structure.getActive(playerId)
			if (activeCharacter == null || activeCharacter.id != job.characterId) { phoenix.crafting.Crafter._abortJob(playerId, "characterChanged", true); continue }
			if (!phoenix.crafting.Crafter._stationValid(playerId, job.vobId)) { phoenix.crafting.Crafter._abortJob(playerId, "moved", true); continue }
			if (now - job.lastProgressAt >= 500) {
				local elapsed = now - job.startedAt
				if (elapsed < 0) elapsed = 0
				if (elapsed > job.totalMs) elapsed = job.totalMs
				phoenix.crafting.Crafter._sendProgress(playerId, job, elapsed, "crafting")
				job.lastProgressAt = now
			}
			if (now >= job.finishAt) phoenix.crafting.Crafter._beginFinalize(playerId, job.requestId)
		}
	}
	function _sendProgress(playerId, job, elapsed, state) {
		local progress = job.totalMs > 0 ? ((elapsed.tofloat() / job.totalMs.tofloat()) * 1000.0).tointeger() : 1000
		if (progress < 0) progress = 0
		if (progress > 1000) progress = 1000
		local msg = phoenix.crafting.Message.Progress()
		msg.requestId = job.requestId; msg.recipeId = job.recipeId; msg.quantity = job.quantity
		msg.elapsedMs = elapsed; msg.totalMs = job.totalMs; msg.progress = progress; msg.state = state
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function _abortJob(playerId, error, notify) {
		if (!(playerId in phoenix.crafting.Crafter.jobs)) return
		local job = phoenix.crafting.Crafter.jobs[playerId]
		job.aborted = true; job.abortError = error
		if (job.state == "finalizing") return
		phoenix.crafting.Crafter.jobs.rawdelete(playerId)
		if (notify) phoenix.crafting.Crafter._reply(playerId, false, error, job.requestId, "", 0)
	}

	function _currentJob(playerId, requestId) {
		if (!(playerId in phoenix.crafting.Crafter.jobs)) return null
		local job = phoenix.crafting.Crafter.jobs[playerId]
		return job.requestId == requestId ? job : null
	}

	function _refundJobStamina(playerId, job) {
		if (job == null || !("staminaConsumed" in job) || !job.staminaConsumed) return
		job.staminaConsumed = false
		phoenix.profession.Structure.refundStaminaForCharacter(playerId, job.characterId, job.staminaCost)
	}

	function _beginFinalize(playerId, requestId) {
		if (!phoenix.crafting.Crafter.enabled()) { phoenix.crafting.Crafter.close(playerId, "featureDisabled"); return }
		local job = phoenix.crafting.Crafter._currentJob(playerId, requestId)
		if (job == null || job.state != "crafting") return
		local checked = phoenix.crafting.Crafter._validate(playerId, job.vobId, job.recipeId, job.quantity)
		if (!checked.ok) {
			phoenix.crafting.Crafter.jobs.rawdelete(playerId)
			phoenix.crafting.Crafter._reply(playerId, false, checked.error, requestId, "", 0)
			return
		}
		job.state = "finalizing"
		job.staminaCost = checked.professionCheck.staminaCost
		if (!phoenix.profession.Structure.consumeStamina(playerId, job.staminaCost)) {
			phoenix.crafting.Crafter.jobs.rawdelete(playerId)
			phoenix.crafting.Crafter._reply(playerId, false, "noStamina:" + job.staminaCost, requestId, "", 0)
			return
		}
		job.staminaConsumed = job.staminaCost > 0
		phoenix.crafting.Crafter._sendProgress(playerId, job, job.totalMs, "finalizing")
		local consume = {}
		foreach (instance, amount in checked.consume) consume[instance] <- amount * job.quantity
		local plan = phoenix.crafting.Crafter._buildConsumePlan(job.characterId, consume)
		if (plan == null) {
			phoenix.crafting.Crafter._refundJobStamina(playerId, job)
			phoenix.crafting.Crafter.jobs.rawdelete(playerId)
			phoenix.crafting.Crafter._reply(playerId, false, "consumeFailed", requestId, "", 0)
			return
		}
		phoenix.crafting.Crafter._consumeAll(job.characterId, playerId, plan, function(ok, rollbackOk, consumed) {
			local current = phoenix.crafting.Crafter._currentJob(playerId, requestId)
			if (!phoenix.crafting.Crafter.enabled() && current != null) phoenix.crafting.Crafter._abortJob(playerId, "featureDisabled", true)
			if (!ok) {
				phoenix.crafting.Crafter._refundJobStamina(playerId, job)
				if (current != null) phoenix.crafting.Crafter.jobs.rawdelete(playerId)
				phoenix.crafting.Crafter._reply(playerId, false, rollbackOk ? "consumeFailed" : "rollbackFailed", requestId, "", 0)
				return
			}
			if (current == null || current.aborted) {
				phoenix.crafting.Crafter._restoreConsumed(job.characterId, consumed, function(restored) {
					phoenix.crafting.Crafter._refundJobStamina(playerId, job)
					if (current != null) phoenix.crafting.Crafter.jobs.rawdelete(playerId)
					if (current != null) phoenix.crafting.Crafter._reply(playerId, false, restored ? current.abortError : "rollbackFailed", requestId, "", 0)
				})
				return
			}
			phoenix.crafting.Crafter._giveOutputs(playerId, current, checked.recipe, consumed)
		})
	}

	function _giveOutputs(playerId, job, recipe, consumed) {
		if (!phoenix.crafting.Crafter.enabled()) {
			phoenix.crafting.Crafter._abortJob(playerId, "featureDisabled", false)
			phoenix.crafting.Crafter._restoreConsumed(job.characterId, consumed, function(restored) {
				phoenix.crafting.Crafter._refundJobStamina(playerId, job)
				if (phoenix.crafting.Crafter._currentJob(playerId, job.requestId) != null) phoenix.crafting.Crafter.jobs.rawdelete(playerId)
				phoenix.crafting.Crafter._reply(playerId, false, restored ? "featureDisabled" : "rollbackFailed", job.requestId, "", 0)
			})
			return
		}
		local mainAmount = recipe.resultAmount * job.quantity
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, job.characterId, recipe.resultInstance, {
			amount = mainAmount, quality = PhoenixItemQuality.Common, upgrade = 0, source = "craft", suppressQuest = true
		}, function(record) {
			local current = phoenix.crafting.Crafter._currentJob(playerId, job.requestId)
			if (!phoenix.crafting.Crafter.enabled() && current != null) phoenix.crafting.Crafter._abortJob(playerId, "featureDisabled", false)
			if (record == null) { phoenix.crafting.Crafter._restoreAfterOutputFailure(playerId, job, consumed, [], "outputFailed"); return }
			local granted = [{ itemId = record.id, instance = recipe.resultInstance, amount = mainAmount }]
			if (current == null || current.aborted) {
				phoenix.crafting.Crafter._restoreAfterOutputFailure(playerId, job, consumed, granted, current != null ? current.abortError : "cancelled")
				return
			}
			local extras = []
			foreach (output in recipe.outputs) extras.append({ instance = output.instance, amount = output.amount * job.quantity })
			phoenix.crafting.Crafter._giveExtras(job.characterId, extras, granted, function(ok, allGranted) {
				local latest = phoenix.crafting.Crafter._currentJob(playerId, job.requestId)
				if (!phoenix.crafting.Crafter.enabled() && latest != null) phoenix.crafting.Crafter._abortJob(playerId, "featureDisabled", false)
				if (!ok || latest == null || latest.aborted) {
					local reason = !ok ? "outputFailed" : (latest != null ? latest.abortError : "cancelled")
					phoenix.crafting.Crafter._restoreAfterOutputFailure(playerId, job, consumed, allGranted, reason)
					return
				}
				phoenix.crafting.Crafter._emitCraftEvents(job.characterId, allGranted)
				if (job.professionId > 0 && job.professionXp > 0)
					phoenix.profession.Structure.awardForCharacter(playerId, job.characterId, job.professionId, job.professionXp * job.quantity, job.contentTier)
				job.staminaConsumed = false
				phoenix.crafting.Crafter.jobs.rawdelete(playerId)
				try { phoenix.item.Structure.sendInventorySnapshot(playerId, job.characterId) } catch (e) {}
				phoenix.crafting.Crafter._reply(playerId, true, "", job.requestId, recipe.resultInstance, mainAmount)
			})
		})
	}
	function _restoreAfterOutputFailure(playerId, job, consumed, granted, reason) {
		phoenix.crafting.Crafter._rollbackGranted(job.characterId, granted, function(outputsRolledBack) {
			if (!outputsRolledBack) {
				job.staminaConsumed = false
				if (phoenix.crafting.Crafter._currentJob(playerId, job.requestId) != null) phoenix.crafting.Crafter.jobs.rawdelete(playerId)
				phoenix.crafting.Crafter._reply(playerId, false, "rollbackFailed", job.requestId, "", 0)
				return
			}
			phoenix.crafting.Crafter._restoreConsumed(job.characterId, consumed, function(restored) {
				phoenix.crafting.Crafter._refundJobStamina(playerId, job)
				if (phoenix.crafting.Crafter._currentJob(playerId, job.requestId) != null) phoenix.crafting.Crafter.jobs.rawdelete(playerId)
				try { phoenix.item.Structure.sendInventorySnapshot(playerId, job.characterId) } catch (e) {}
				phoenix.crafting.Crafter._reply(playerId, false, restored ? reason : "rollbackFailed", job.requestId, "", 0)
			})
		})
	}

	function _emitCraftEvents(characterId, granted) {
		foreach (entry in granted) {
			try { phoenix.quest.Events.itemGranted(PhoenixInventoryOwner.Player, characterId, entry.instance, entry.amount, "craft", entry.itemId) } catch (e) {}
		}
	}

	function _giveExtras(characterId, extras, granted, callback) {
		if (!phoenix.crafting.Crafter.enabled()) { callback(false, granted); return }
		if (extras == null || extras.len() == 0) { callback(true, granted); return }
		local first = extras[0]; local rest = extras.slice(1)
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, characterId, first.instance, {
			amount = first.amount, quality = PhoenixItemQuality.Common, upgrade = 0, source = "craft", suppressQuest = true
		}, function(record) {
			if (record == null) { callback(false, granted); return }
			granted.append({ itemId = record.id, instance = first.instance, amount = first.amount })
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

	function _consumeAll(characterId, playerId, queue, callback, consumed = null) {
		if (consumed == null) consumed = []
		if (!phoenix.crafting.Crafter.enabled()) {
			phoenix.crafting.Crafter._restoreConsumed(characterId, consumed, function(restored) { callback(false, restored, []) })
			return
		}
		if (queue.len() == 0) { callback(true, true, consumed); return }
		local first = queue[0]; local rest = queue.slice(1)
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, characterId, first.itemId, first.amount, function(ok) {
			if (!ok) {
				phoenix.crafting.Crafter._restoreConsumed(characterId, consumed, function(restored) { callback(false, restored, []) })
				return
			}
			consumed.append(first)
			phoenix.crafting.Crafter._consumeAll(characterId, playerId, rest, callback, consumed)
		})
	}
	function _rollbackGranted(characterId, granted, callback, success = true) {
		if (granted == null || granted.len() == 0) { callback(success); return }
		local lastIndex = granted.len() - 1; local issued = granted[lastIndex]; local rest = granted.slice(0, lastIndex)
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, characterId, issued.itemId, issued.amount, function(ok) {
			phoenix.crafting.Crafter._rollbackGranted(characterId, rest, callback, success && ok)
		})
	}

	function _restoreConsumed(characterId, queue, callback, success = true) {
		if (queue == null || queue.len() == 0) { callback(success); return }
		local first = queue[0]; local rest = queue.slice(1)
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, characterId, first.instance, {
			amount = first.amount, quality = first.quality, upgrade = first.upgrade, source = "craft-rollback", suppressQuest = true
		}, function(record) {
			phoenix.crafting.Crafter._restoreConsumed(characterId, rest, callback, success && record != null)
		})
	}

	function _reply(playerId, success, error, requestId, resultInstance, resultAmount) {
		local msg = phoenix.crafting.Message.Result()
		msg.success = success; msg.error = error != null ? error.tostring() : ""; msg.requestId = requestId != null ? requestId.tostring() : ""
		msg.resultInstance = resultInstance != null ? resultInstance.tostring() : ""; msg.resultAmount = resultAmount.tointeger()
		msg.playerItems = phoenix.crafting.Crafter.playerInventoryString(playerId)
		local activeCharacter = phoenix.character.Structure.getActive(playerId)
		try { if (activeCharacter != null) msg.playerStamina = phoenix.player.Resources.current(playerId, activeCharacter, "stamina").tointeger() } catch (eStamina) {}
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}
}

phoenix.crafting.Message.RequestOpen.bind(function(playerId, message) {
	phoenix.crafting.Crafter.onRequestOpen(playerId, message)
})
phoenix.crafting.Message.Close.bind(function(playerId, message) {
	phoenix.crafting.Crafter.onClose(playerId, message)
})
phoenix.crafting.Message.Craft.bind(function(playerId, message) {
	phoenix.crafting.Crafter.onCraftRequest(playerId, message)
})
phoenix.crafting.Message.Cancel.bind(function(playerId, message) {
	phoenix.crafting.Crafter.onCancel(playerId, message)
})

addEventHandler("onInit", function() {
	setTimer(function() { phoenix.crafting.Crafter.tick() }, phoenix.crafting.Crafter.TICK_MS, 0)
})
addEventHandler("phoenix.features.OnChanged", function(key, enabled) {
	if (key == "crafting.enabled" && !enabled) phoenix.crafting.Crafter.disableAll()
})
addEventHandler("onPlayerDisconnect", function(playerId, _reason) {
	if (playerId in phoenix.crafting.Crafter.jobs) phoenix.crafting.Crafter._abortJob(playerId, "disconnected", false)
	if (playerId in phoenix.crafting.Crafter.activeByPlayer) phoenix.crafting.Crafter.activeByPlayer.rawdelete(playerId)
})
addEventHandler("phoenix.character.OnSelected", function(playerId, _characterId) {
	if (playerId in phoenix.crafting.Crafter.jobs) phoenix.crafting.Crafter._abortJob(playerId, "characterChanged", true)
	if (playerId in phoenix.crafting.Crafter.activeByPlayer) phoenix.crafting.Crafter.activeByPlayer.rawdelete(playerId)
})
