phoenix.profession.Hunting <- {
	configs = {}
	lootByInstance = {}
	carcasses = {}
	jobs = {}
	timers = {}
	nextJobId = 1
	loaded = false

	function load() {
		local nextConfigs = {}; local nextLoot = {}
		local configs = ORM.engine.execute("SELECT * FROM `phoenix_hunting_carcasses` WHERE `active`=1")
		if (configs != null) foreach (row in configs) {
			local instance = row.npcInstance.tostring().toupper()
			nextConfigs[instance] <- {
				npcInstance = instance, corpseVisual = row.corpseVisual != null ? row.corpseVisual.tostring() : "",
				professionId = row.professionId != null ? row.professionId.tointeger() : 0,
				requiredProfessionTier = row.requiredProfessionTier.tointeger(), baseStamina = row.baseStamina.tointeger(),
				professionXp = row.professionXp.tointeger(), skinTimeMs = row.skinTimeMs.tointeger(), lifetimeSec = row.lifetimeSec.tointeger()
			}
		}
		local loot = ORM.engine.execute("SELECT * FROM `phoenix_hunting_loot` WHERE `active`=1 ORDER BY `id` ASC")
		if (loot != null) foreach (row in loot) {
			local instance = row.npcInstance.tostring().toupper()
			local itemInstance = row.itemInstance.tostring().toupper()
			if (phoenix.item.find(itemInstance) == null) continue
			if (!(instance in nextLoot)) nextLoot[instance] <- []
			nextLoot[instance].append({ itemInstance = itemInstance, baseChance = row.baseChance.tointeger(),
				baseMin = row.baseMin.tointeger(), baseMax = row.baseMax.tointeger(), chancePerTier = row.chancePerTier.tointeger(), amountPerTier = row.amountPerTier.tofloat() })
		}
		phoenix.profession.Hunting.configs = nextConfigs; phoenix.profession.Hunting.lootByInstance = nextLoot; phoenix.profession.Hunting.loaded = true
	}

	function ensureLoaded() {
		if (phoenix.profession.Hunting.loaded) return true
		try { phoenix.profession.Hunting.load(); return true } catch (e) {}
		return false
	}

	function _label(entry) {
		try {
			local label = phoenix.npc.Spawn._catalogLabel(entry.row.instance, "pl")
			if (label != null && label != "" && label != entry.row.instance) return label.tostring()
		} catch (e) {}
		try { if (entry.row.name != null && entry.row.name != "") return entry.row.name.tostring() } catch (e2) {}
		return "zwierzę"
	}

	function spawnCarcass(entry, killerId = -1) {
		if (entry == null || !phoenix.profession.Hunting.ensureLoaded()) return
		local instance = ""; try { instance = entry.row.instance.tostring().toupper() } catch (e) {}
		if (!(instance in phoenix.profession.Hunting.configs) || !(instance in phoenix.profession.Hunting.lootByInstance)) return
		local cfg = phoenix.profession.Hunting.configs[instance]
		local pos = null; try { pos = getPlayerPosition(entry.npcId) } catch (eP) {}
		if (pos == null) pos = { x = entry.row.posX, y = entry.row.posY, z = entry.row.posZ }
		local world = entry.row.world
		try { local current = getPlayerWorld(entry.npcId); if (current != null && current != "") world = current } catch (eW) {}
		local visual = cfg.corpseVisual
		try { local metadataVisual = phoenix.npc.Spawn._metadataValue(entry.row.metadata, "corpseVisual"); if (metadataVisual != "") visual = metadataVisual } catch (eM) {}
		if (visual == "") visual = instance + ".MDS"
		local id = "carcass_" + entry.row.id + "_" + getTickCount() + "_" + (rand() % 10000)
		local carcass = { vobId = id, name = "Oskóruj: " + phoenix.profession.Hunting._label(entry), visual = visual,
			world = phoenix.vob.Structure.normalizeWorld(world), x = pos.x, y = pos.y, z = pos.z, rotX = 0.0, rotY = entry.row.angle, rotZ = 0.0,
			interactive = true, noCollision = true, craftInteraction = false, entryKind = "carcass", itemInstance = "", itemAmount = 0, itemQuality = 0,
			npcInstance = instance, spawnId = entry.row.id, config = cfg, lockedBy = -1, killerId = killerId }
		phoenix.profession.Hunting.carcasses[id] <- carcass; phoenix.vob.Structure.entries[id] <- carcass
		phoenix.vob.Structure.broadcastSnapshot()
		local lifetime = cfg.lifetimeSec > 10 ? cfg.lifetimeSec : 120
		phoenix.profession.Hunting.timers[id] <- setTimer(function() { phoenix.profession.Hunting.removeCarcass(id) }, lifetime * 1000, 1)
	}

	function removeCarcass(vobId) {
		if (vobId in phoenix.profession.Hunting.timers) {
			try { killTimer(phoenix.profession.Hunting.timers[vobId]) } catch (e) {}
			phoenix.profession.Hunting.timers.rawdelete(vobId)
		}
		if (vobId in phoenix.profession.Hunting.carcasses) phoenix.profession.Hunting.carcasses.rawdelete(vobId)
		if (vobId in phoenix.vob.Structure.entries) phoenix.vob.Structure.entries.rawdelete(vobId)
		phoenix.vob.Structure.broadcastSnapshot()
	}

	function removeBySpawn(spawnId) {
		local ids = []
		foreach (id, carcass in phoenix.profession.Hunting.carcasses) if (carcass.spawnId == spawnId) ids.append(id)
		foreach (id in ids) phoenix.profession.Hunting.removeCarcass(id)
	}

	function _result(playerId, vobId, success, error, drops = "", xp = 0) {
		local code = error != null ? error.tostring() : ""
		local separator = code.find(":"); if (separator != null) code = code.slice(0, separator)
		local msg = phoenix.profession.Message.HuntingResult()
		msg.vobId = vobId; msg.success = success; msg.error = code; msg.drops = drops; msg.xp = xp
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function _currentJob(playerId, vobId, jobId) {
		if (!(playerId in phoenix.profession.Hunting.jobs)) return null
		local job = phoenix.profession.Hunting.jobs[playerId]
		if (job.vobId != vobId || job.id != jobId) return null
		return job
	}

	function interact(playerId, vobId) {
		if (!(vobId in phoenix.profession.Hunting.carcasses) || playerId in phoenix.profession.Hunting.jobs) return true
		local otherActivity = false
		try { otherActivity = (playerId in phoenix.herb.Structure.active) } catch (eHerb) {}
		try { if (playerId in phoenix.crafting.Crafter.jobs) otherActivity = true } catch (eCrafting) {}
		if (otherActivity) { phoenix.profession.Hunting._result(playerId, vobId, false, "busy"); return true }
		local carcass = phoenix.profession.Hunting.carcasses[vobId]
		if (carcass.lockedBy >= 0) { phoenix.profession.Hunting._result(playerId, vobId, false, "busy"); return true }
		if (!phoenix.vob.Handlers.isInRange(playerId, carcass, 360.0)) { phoenix.profession.Hunting._result(playerId, vobId, false, "moved"); return true }
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) { phoenix.profession.Hunting._result(playerId, vobId, false, "noCharacter"); return true }
		local checked = phoenix.profession.Structure.check(playerId, carcass.config.professionId, carcass.config.requiredProfessionTier, carcass.config.baseStamina, 1)
		if (!checked.ok) {
			local code = checked.error
			if (code.find(":") != null) code = code.slice(0, code.find(":"))
			phoenix.profession.Hunting._result(playerId, vobId, false, code); return true
		}
		local duration = carcass.config.skinTimeMs
		local reductionPerTier = checked.profession != null ? checked.profession.gatherTimeReductionPerTier : 0.0
		local reduction = checked.tier * reductionPerTier
		if (reduction > 0.75) reduction = 0.75; if (reduction < 0.0) reduction = 0.0
		duration = (duration.tofloat() * (1.0 - reduction)).tointeger()
		if (duration < 1200) duration = 1200
		local jobId = phoenix.profession.Hunting.nextJobId
		phoenix.profession.Hunting.nextJobId += 1
		carcass.lockedBy = playerId
		phoenix.profession.Hunting.jobs[playerId] <- { id = jobId, vobId = vobId, characterId = active.id,
			professionId = carcass.config.professionId, contentTier = carcass.config.requiredProfessionTier, staminaCost = checked.staminaCost,
			professionXp = carcass.config.professionXp, tier = checked.tier, finishAt = getTickCount() + duration,
			state = "gathering", aborted = false, abortError = "cancelled", abortNotify = true, staminaConsumed = false }
		local msg = phoenix.profession.Message.HuntingStarted(); msg.vobId = vobId; msg.label = carcass.name; msg.durationMs = duration
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
		try { playAni(playerId, "T_PLUNDER") } catch (e2) {}
		setTimer(function() { phoenix.profession.Hunting.finish(playerId, vobId, jobId) }, duration, 1)
		return true
	}

	function _rollDrops(instance, tier) {
		local out = []
		if (!(instance in phoenix.profession.Hunting.lootByInstance)) return out
		foreach (loot in phoenix.profession.Hunting.lootByInstance[instance]) {
			if (phoenix.item.find(loot.itemInstance) == null) continue
			local chance = loot.baseChance + loot.chancePerTier * tier
			if (chance > 100) chance = 100; if (chance < 0) chance = 0
			if ((1 + rand() % 100) > chance) continue
			local minAmount = loot.baseMin > 0 ? loot.baseMin : 1
			local maxAmount = loot.baseMax >= minAmount ? loot.baseMax : minAmount
			maxAmount += (loot.amountPerTier * tier).tointeger()
			local amount = minAmount + (maxAmount > minAmount ? rand() % (maxAmount - minAmount + 1) : 0)
			out.append({ instance = loot.itemInstance, amount = amount })
		}
		return out
	}

	function _giveDrops(characterId, queue, labels, granted, callback) {
		if (queue.len() == 0) { callback(true, labels, granted); return }
		local first = queue[0]; local rest = queue.slice(1)
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, characterId, first.instance, { amount = first.amount, source = "hunting", suppressQuest = true }, function(record) {
			if (record == null) { callback(false, labels, granted); return }
			local label = first.instance
			try { local scheme = phoenix.item.find(first.instance); if (scheme != null && scheme.name != null && scheme.name != "") label = scheme.name } catch (e) {}
			labels.append(label + " x" + first.amount)
			granted.append({ itemId = record.id, instance = first.instance, amount = first.amount })
			phoenix.profession.Hunting._giveDrops(characterId, rest, labels, granted, callback)
		})
	}

	function _rollbackDrops(characterId, granted, callback, success = true) {
		if (granted == null || granted.len() == 0) { callback(success); return }
		local last = granted[granted.len() - 1]; local rest = granted.slice(0, granted.len() - 1)
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, characterId, last.itemId, last.amount, function(ok) {
			phoenix.profession.Hunting._rollbackDrops(characterId, rest, callback, success && ok)
		})
	}

	function finish(playerId, vobId, jobId) {
		local job = phoenix.profession.Hunting._currentJob(playerId, vobId, jobId)
		if (job == null || job.state != "gathering") return
		if (!(vobId in phoenix.profession.Hunting.carcasses)) { phoenix.profession.Hunting.cancel(playerId, "cancelled", true); return }
		local carcass = phoenix.profession.Hunting.carcasses[vobId]
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || record.id != job.characterId || !phoenix.vob.Handlers.isInRange(playerId, carcass, 360.0)) { phoenix.profession.Hunting.cancel(playerId, "moved", true); return }
		local checked = phoenix.profession.Structure.check(playerId, job.professionId, job.contentTier, carcass.config.baseStamina, 1)
		if (!checked.ok || !phoenix.profession.Structure.consumeStamina(playerId, checked.staminaCost)) {
			phoenix.profession.Hunting.cancel(playerId, checked.ok ? "noStamina" : checked.error, true); return
		}
		job.state = "finalizing"
		job.staminaCost = checked.staminaCost
		job.staminaConsumed = checked.staminaCost > 0
		local drops = phoenix.profession.Hunting._rollDrops(carcass.npcInstance, checked.tier)
		phoenix.profession.Hunting._giveDrops(record.id, drops, [], [], function(ok, labels, granted) {
			local current = phoenix.profession.Hunting._currentJob(playerId, vobId, jobId)
			local active = phoenix.character.Structure.getActive(playerId)
			local valid = ok && current != null && !current.aborted && active != null && active.id == job.characterId
			valid = valid && vobId in phoenix.profession.Hunting.carcasses && phoenix.profession.Hunting.carcasses[vobId].lockedBy == playerId
			if (!valid) {
				local reason = !ok ? "grantFailed" : (current != null ? current.abortError : "cancelled")
				local shouldNotify = !ok || (current != null && current.abortNotify)
				phoenix.profession.Hunting._rollbackDrops(job.characterId, granted, function(rolledBack) {
					if (rolledBack && job.staminaConsumed) {
						job.staminaConsumed = false
						phoenix.profession.Structure.refundStaminaForCharacter(playerId, job.characterId, job.staminaCost)
					}
					local latest = phoenix.profession.Hunting._currentJob(playerId, vobId, jobId)
					if (latest != null) phoenix.profession.Hunting.jobs.rawdelete(playerId)
					if (vobId in phoenix.profession.Hunting.carcasses && phoenix.profession.Hunting.carcasses[vobId].lockedBy == playerId) {
						if (rolledBack) phoenix.profession.Hunting.carcasses[vobId].lockedBy = -1
						else phoenix.profession.Hunting.removeCarcass(vobId)
					}
					if (shouldNotify) phoenix.profession.Hunting._result(playerId, vobId, false, rolledBack ? reason : "rollbackFailed")
				})
				return
			}
			job.staminaConsumed = false
			phoenix.profession.Hunting.jobs.rawdelete(playerId)
			foreach (entry in granted) {
				try { phoenix.quest.Events.itemGranted(PhoenixInventoryOwner.Player, record.id, entry.instance, entry.amount, "hunting", entry.itemId) } catch (eQuest) {}
			}
			local xp = phoenix.profession.Structure.awardForCharacter(playerId, job.characterId, job.professionId, job.professionXp, job.contentTier)
			local text = labels.len() > 0 ? labels.reduce(function(a, b) { return a + ", " + b }) : "Brak użytecznych części"
			phoenix.profession.Hunting.removeCarcass(vobId)
			phoenix.profession.Hunting._result(playerId, vobId, true, "", text, xp)
		})
	}

	function cancel(playerId, reason, notify) {
		if (!(playerId in phoenix.profession.Hunting.jobs)) return
		local job = phoenix.profession.Hunting.jobs[playerId]
		if (job.state == "finalizing") {
			job.aborted = true
			job.abortError = reason
			job.abortNotify = notify
			return
		}
		phoenix.profession.Hunting.jobs.rawdelete(playerId)
		if (job.vobId in phoenix.profession.Hunting.carcasses && phoenix.profession.Hunting.carcasses[job.vobId].lockedBy == playerId)
			phoenix.profession.Hunting.carcasses[job.vobId].lockedBy = -1
		if (notify) phoenix.profession.Hunting._result(playerId, job.vobId, false, reason)
	}
}

addEventHandler("phoenix.database.OnReady", function() { try { phoenix.profession.Hunting.load() } catch (e) {} })
addEventHandler("onPlayerDisconnect", function(playerId, _reason) { phoenix.profession.Hunting.cancel(playerId, "disconnected", false) })
addEventHandler("phoenix.character.OnSelected", function(playerId, _characterId) { phoenix.profession.Hunting.cancel(playerId, "characterChanged", false) })
