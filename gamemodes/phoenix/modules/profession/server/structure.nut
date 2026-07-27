phoenix.profession.Structure <- {
	definitions = {}
	byCode = {}
	progressCache = {}
	loaded = false

	function enabled() {
		return phoenix.features.Settings.isEnabled("professions.enabled")
	}

	function _sql(value) {
		if (value == null) return ""
		try { return ORM.engine.escape(value.tostring()) } catch (e) { return value.tostring() }
	}

	function _read(row, key, fallback) {
		try { if (key in row && row[key] != null) return row[key] } catch (e) {}
		return fallback
	}

	function tierForLevel(level) {
		local value = level.tointeger()
		if (value < 0) value = 0
		return (value / 10).tointeger()
	}

	function xpToNext(definition, level) {
		if (definition == null || level >= definition.maxLevel) return 0
		local value = definition.xpBase.tofloat() * pow((level + 1).tofloat(), definition.xpGrowth.tofloat())
		if (value < 1.0) value = 1.0
		if (value > 4294967295.0) value = 4294967295.0
		return value.tointeger()
	}

	function loadDefinitions() {
		local next = {}; local codes = {}
		local rows = ORM.engine.execute("SELECT * FROM `phoenix_professions` ORDER BY `id` ASC")
		if (rows == null) return false
		foreach (row in rows) {
			local id = phoenix.profession.Structure._read(row, "id", 0).tointeger()
			if (id <= 0) continue
			local def = {
				id = id, code = phoenix.profession.Structure._read(row, "code", "").tostring().toupper(),
				namePl = phoenix.profession.Structure._read(row, "namePl", "").tostring(),
				nameEn = phoenix.profession.Structure._read(row, "nameEn", "").tostring(),
				nameDe = phoenix.profession.Structure._read(row, "nameDe", "").tostring(),
				nameRu = phoenix.profession.Structure._read(row, "nameRu", "").tostring(),
				descriptionPl = phoenix.profession.Structure._read(row, "descriptionPl", "").tostring(),
				descriptionEn = phoenix.profession.Structure._read(row, "descriptionEn", "").tostring(),
				descriptionDe = phoenix.profession.Structure._read(row, "descriptionDe", "").tostring(),
				descriptionRu = phoenix.profession.Structure._read(row, "descriptionRu", "").tostring(),
				maxLevel = phoenix.profession.Structure._read(row, "maxLevel", 100).tointeger(),
				xpBase = phoenix.profession.Structure._read(row, "xpBase", 100).tointeger(),
				xpGrowth = phoenix.profession.Structure._read(row, "xpGrowth", 1.35).tofloat(),
				gatherTimeReductionPerTier = phoenix.profession.Structure._read(row, "gatherTimeReductionPerTier", 0.12).tofloat(),
				gatherChancePerTier = phoenix.profession.Structure._read(row, "gatherChancePerTier", 3).tointeger(),
				gatherYieldPerTier = phoenix.profession.Structure._read(row, "gatherYieldPerTier", 1).tointeger(),
				active = phoenix.profession.Structure._read(row, "active", 1).tointeger() == 1
			}
			next[id] <- def; codes[def.code] <- def
		}
		phoenix.profession.Structure.definitions = next
		phoenix.profession.Structure.byCode = codes
		phoenix.profession.Structure.loaded = true
		return true
	}

	function ensureLoaded() {
		if (phoenix.profession.Structure.loaded) return true
		try { return phoenix.profession.Structure.loadDefinitions() } catch (e) {}
		return false
	}

	function definition(id) {
		phoenix.profession.Structure.ensureLoaded()
		local key = 0
		try { key = id.tointeger() } catch (e) { key = 0 }
		return key in phoenix.profession.Structure.definitions ? phoenix.profession.Structure.definitions[key] : null
	}

	function definitionByCode(code) {
		phoenix.profession.Structure.ensureLoaded()
		local key = code != null ? code.tostring().toupper() : ""
		return key in phoenix.profession.Structure.byCode ? phoenix.profession.Structure.byCode[key] : null
	}

	function _progress(characterId, professionId) {
		if (!(characterId in phoenix.profession.Structure.progressCache)) phoenix.profession.Structure.progressCache[characterId] <- {}
		local cache = phoenix.profession.Structure.progressCache[characterId]
		if (professionId in cache) return cache[professionId]
		local rows = ORM.engine.execute("SELECT `level`,`xp` FROM `phoenix_character_professions` WHERE `characterId`=" + characterId + " AND `professionId`=" + professionId + " LIMIT 1")
		local progress = { level = 0, xp = 0 }
		if (rows != null && rows.len() > 0) {
			progress.level = phoenix.profession.Structure._read(rows[0], "level", 0).tointeger()
			progress.xp = phoenix.profession.Structure._read(rows[0], "xp", 0).tointeger()
		}
		cache[professionId] <- progress
		return progress
	}

	function progressFor(characterId, professionId) {
		if (characterId <= 0 || professionId <= 0) return { level = 0, xp = 0 }
		try { return phoenix.profession.Structure._progress(characterId, professionId) } catch (e) {}
		return { level = 0, xp = 0 }
	}

	function xpMultiplier(playerTier, contentTier) {
		local delta = playerTier - contentTier
		if (delta >= 2) return 0.0
		if (delta == 1) return 0.5
		return 1.0
	}

	function staminaCostForLevel(level, contentTier, baseStamina) {
		if (!phoenix.features.Settings.effectiveEnabled("player.stamina")) return 0
		local baseCost = baseStamina.tointeger()
		if (baseCost <= 0) return 0
		local playerTier = phoenix.profession.Structure.tierForLevel(level)
		local steps = ((playerTier - contentTier) / 2).tointeger()
		if (steps < 0) steps = 0
		local divisor = 1
		for (local i = 0; i < steps; i += 1) divisor *= 2
		local cost = ((baseCost + divisor - 1) / divisor).tointeger()
		return cost < 1 ? 1 : cost
	}

	function check(playerId, professionId, requiredTier, baseStamina, quantity = 1) {
		if (!phoenix.profession.Structure.enabled()) return { ok = false, error = "featureDisabled" }
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return { ok = false, error = "noCharacter" }
		local pid = professionId != null ? professionId.tointeger() : 0
		local required = requiredTier != null ? requiredTier.tointeger() : 0
		local level = 0; local tier = 0; local def = null
		if (pid > 0) {
			def = phoenix.profession.Structure.definition(pid)
			if (def == null || !def.active) return { ok = false, error = "professionUnavailable" }
			local progress = phoenix.profession.Structure.progressFor(record.id, pid)
			level = progress.level; tier = phoenix.profession.Structure.tierForLevel(level)
			if (tier < required) return { ok = false, error = "lowProfessionTier:" + required }
		} else if (required > 0) return { ok = false, error = "professionUnavailable" }
		local unitCost = phoenix.profession.Structure.staminaCostForLevel(level, required, baseStamina)
		local totalCost = unitCost * (quantity > 0 ? quantity : 1)
		if (totalCost > 0) {
			local current = phoenix.player.Resources.current(playerId, record, "stamina")
			if (current < totalCost) return { ok = false, error = "noStamina:" + totalCost, staminaCost = totalCost, level = level, tier = tier }
		}
		return { ok = true, profession = def, level = level, tier = tier, staminaCost = totalCost }
	}

	function consumeStamina(playerId, amount) {
		if (!phoenix.profession.Structure.enabled()) return false
		if (!phoenix.features.Settings.effectiveEnabled("player.stamina")) return true
		if (amount <= 0) return true
		local ok = phoenix.player.Hud.consumeStamina(playerId, amount)
		if (ok) {
			local record = phoenix.character.Structure.getActive(playerId)
			try { if (record != null) record.saveAsync(function(_) {}) } catch (e) {}
		}
		return ok
	}

	function refundStaminaForCharacter(playerId, characterId, amount) {
		local value = amount.tointeger()
		local cid = characterId.tointeger()
		if (value <= 0 || cid <= 0) return
		local record = phoenix.character.Structure.getActive(playerId)
		if (record != null && record.id == cid) {
			phoenix.player.Resources.add(playerId, record, "stamina", value)
			try { record.saveAsync(function(_) {}) } catch (e) {}
			try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e2) {}
			return
		}
		local sql = "UPDATE `phoenix_characters` SET `stamina`=LEAST(COALESCE(`staminaMax`,100),GREATEST(0,COALESCE(`stamina`,0)+" + value + ")) WHERE `id`=" + cid
		try { ORM.engine.executeAsync(sql, function(_) {}) } catch (e3) {}
	}

	function refundStamina(playerId, amount) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		phoenix.profession.Structure.refundStaminaForCharacter(playerId, record.id, amount)
	}

	function awardForCharacter(playerId, characterId, professionId, baseXp, contentTier) {
		if (!phoenix.profession.Structure.enabled()) return 0
		local amount = baseXp.tointeger()
		local cid = characterId.tointeger()
		if (cid <= 0 || professionId <= 0 || amount <= 0) return 0
		local def = phoenix.profession.Structure.definition(professionId)
		if (def == null || !def.active) return 0
		local progress = phoenix.profession.Structure.progressFor(cid, professionId)
		local multiplier = phoenix.profession.Structure.xpMultiplier(phoenix.profession.Structure.tierForLevel(progress.level), contentTier)
		local awarded = (amount.tofloat() * multiplier).tointeger()
		if (awarded <= 0 || progress.level >= def.maxLevel) return 0
		progress.xp += awarded
		while (progress.level < def.maxLevel) {
			local needed = phoenix.profession.Structure.xpToNext(def, progress.level)
			if (needed <= 0 || progress.xp < needed) break
			progress.xp -= needed; progress.level += 1
		}
		if (progress.level >= def.maxLevel) progress.xp = 0
		local sql = "INSERT INTO `phoenix_character_professions` (`characterId`,`professionId`,`level`,`xp`) VALUES (" + cid + "," + professionId + "," + progress.level + "," + progress.xp + ") ON DUPLICATE KEY UPDATE `level`=VALUES(`level`),`xp`=VALUES(`xp`)"
		try { ORM.engine.executeAsync(sql, function(_) {}) } catch (e) {}
		local active = phoenix.character.Structure.getActive(playerId)
		if (active != null && active.id == cid) {
			phoenix.profession.Structure.sendSnapshot(playerId)
			try { phoenix.notification.notify(playerId, "success", def.namePl, "+" + awarded + " XP profesji · poziom " + progress.level + " · T" + phoenix.profession.Structure.tierForLevel(progress.level), 3000) } catch (e2) {}
		}
		return awarded
	}

	function award(playerId, professionId, baseXp, contentTier) {
		if (!phoenix.profession.Structure.enabled()) return 0
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return 0
		return phoenix.profession.Structure.awardForCharacter(playerId, record.id, professionId, baseXp, contentTier)
	}

	function snapshotEntries(playerId) {
		local out = []
		if (!phoenix.profession.Structure.enabled()) return out
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || !phoenix.profession.Structure.ensureLoaded()) return out
		foreach (id, def in phoenix.profession.Structure.definitions) {
			if (!def.active) continue
			local progress = phoenix.profession.Structure.progressFor(record.id, id)
			local next = phoenix.profession.Structure.xpToNext(def, progress.level)
			local pct = next > 0 ? ((progress.xp.tofloat() / next.tofloat()) * 100.0).tointeger() : 100
			if (pct < 0) pct = 0; if (pct > 100) pct = 100
			out.append({ id = id, code = def.code, name = def.namePl, description = def.descriptionPl,
				namePl = def.namePl, nameEn = def.nameEn, nameDe = def.nameDe, nameRu = def.nameRu,
				descriptionPl = def.descriptionPl, descriptionEn = def.descriptionEn, descriptionDe = def.descriptionDe, descriptionRu = def.descriptionRu,
				level = progress.level, tier = phoenix.profession.Structure.tierForLevel(progress.level), xp = progress.xp, xpNext = next, progressPct = pct })
		}
		out.sort(function(a, b) { return a.name <=> b.name })
		return out
	}

	function sendSnapshot(playerId) {
		local msg = phoenix.profession.Message.Snapshot()
		msg.entries = phoenix.profession.Structure.snapshotEntries(playerId)
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function adminDefinitions() {
		local out = []
		phoenix.profession.Structure.ensureLoaded()
		foreach (_id, def in phoenix.profession.Structure.definitions) out.append(def)
		out.sort(function(a, b) { return a.id <=> b.id })
		return out
	}

	function _validCode(value) {
		if (value == null) return false
		local code = value.tostring().toupper()
		if (code.len() < 2 || code.len() > 48) return false
		for (local i = 0; i < code.len(); i += 1) {
			local c = code[i]
			if (!((c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_')) return false
		}
		return true
	}

	function saveDefinition(data, callback) {
		if (data == null) { callback(false, "empty", 0); return }
		local id = 0; try { id = data.id.tointeger() } catch (e) {}
		local code = ""; local namePl = ""; local nameEn = ""; local nameDe = ""; local nameRu = ""
		local descriptionPl = ""; local descriptionEn = ""; local descriptionDe = ""; local descriptionRu = ""
		try { code = strip(data.code.tostring()).toupper() } catch (e1) {}
		try { namePl = strip(data.namePl.tostring()) } catch (e2) {}
		try { nameEn = strip(data.nameEn.tostring()) } catch (e3) {}
		try { nameDe = strip(data.nameDe.tostring()) } catch (e4) {}
		try { nameRu = strip(data.nameRu.tostring()) } catch (e5) {}
		try { descriptionPl = data.descriptionPl.tostring() } catch (e6) {}
		try { descriptionEn = data.descriptionEn.tostring() } catch (e7) {}
		try { descriptionDe = data.descriptionDe.tostring() } catch (e8) {}
		try { descriptionRu = data.descriptionRu.tostring() } catch (e9) {}
		if (!phoenix.profession.Structure._validCode(code) || namePl == "" || namePl.len() > 96 || nameEn.len() > 96 || nameDe.len() > 96 || nameRu.len() > 96 ||
			descriptionPl.len() > 512 || descriptionEn.len() > 512 || descriptionDe.len() > 512 || descriptionRu.len() > 512) {
			callback(false, "validation", 0); return
		}
		local maxLevel = 100; local xpBase = 100; local xpGrowth = 1.35; local timeReduction = 0.12; local chance = 3; local yieldPerTier = 1; local active = 1
		try { maxLevel = data.maxLevel.tointeger() } catch (e10) {} try { xpBase = data.xpBase.tointeger() } catch (e11) {}
		try { xpGrowth = data.xpGrowth.tofloat() } catch (e12) {} try { timeReduction = data.gatherTimeReductionPerTier.tofloat() } catch (e13) {}
		try { chance = data.gatherChancePerTier.tointeger() } catch (e14) {} try { yieldPerTier = data.gatherYieldPerTier.tointeger() } catch (e15) {}
		try { active = data.active ? 1 : 0 } catch (e16) {}
		if (maxLevel < 10 || maxLevel > 1000 || xpBase < 1 || xpGrowth < 1.0 || xpGrowth > 5.0 || timeReduction < 0.0 || timeReduction > 0.8 || chance < 0 || chance > 100 || yieldPerTier < 0 || yieldPerTier > 100) { callback(false, "validation", 0); return }
		local values = "`code`='" + _sql(code) + "',`namePl`='" + _sql(namePl) + "',`nameEn`='" + _sql(nameEn) + "',`nameDe`='" + _sql(nameDe) + "',`nameRu`='" + _sql(nameRu) + "',`descriptionPl`='" + _sql(descriptionPl) + "',`descriptionEn`='" + _sql(descriptionEn) + "',`descriptionDe`='" + _sql(descriptionDe) + "',`descriptionRu`='" + _sql(descriptionRu) + "',`maxLevel`=" + maxLevel + ",`xpBase`=" + xpBase + ",`xpGrowth`=" + xpGrowth + ",`gatherTimeReductionPerTier`=" + timeReduction + ",`gatherChancePerTier`=" + chance + ",`gatherYieldPerTier`=" + yieldPerTier + ",`active`=" + active
		try {
			ORM.engine.execute("START TRANSACTION")
			if (id > 0) ORM.engine.execute("UPDATE `phoenix_professions` SET " + values + " WHERE `id`=" + id)
			else {
				ORM.engine.execute("INSERT INTO `phoenix_professions` SET " + values)
				local rows = ORM.engine.execute("SELECT LAST_INSERT_ID() AS `id`"); id = rows[0].id.tointeger()
			}
			ORM.engine.execute("COMMIT")
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			callback(false, "database", 0); return
		}
		phoenix.profession.Structure.loadDefinitions(); callback(true, "", id)
	}

	function deleteDefinition(id, callback) {
		local pid = id.tointeger()
		if (pid <= 0) { callback(false, "badId"); return }
		try { ORM.engine.execute("UPDATE `phoenix_professions` SET `active`=0 WHERE `id`=" + pid); phoenix.profession.Structure.loadDefinitions(); callback(true, "") }
		catch (e) { callback(false, "database") }
	}
}

phoenix.profession.Message.Request.bind(function(playerId, _message) { if (phoenix.profession.Structure.enabled()) phoenix.profession.Structure.sendSnapshot(playerId) })
addEventHandler("phoenix.database.OnReady", function() { try { phoenix.profession.Structure.loadDefinitions() } catch (e) {} })
addEventHandler("phoenix.character.OnSelected", function(playerId, _characterId) { try { if (phoenix.profession.Structure.enabled()) phoenix.profession.Structure.sendSnapshot(playerId) } catch (e) {} })
addEventHandler("onPlayerDisconnect", function(playerId, _reason) {
	local record = null; try { record = phoenix.character.Structure.getActive(playerId) } catch (e) {}
	if (record != null && record.id in phoenix.profession.Structure.progressCache) phoenix.profession.Structure.progressCache.rawdelete(record.id)
})