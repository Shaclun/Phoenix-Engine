phoenix.player.Development <- {
	ready = false
	revision = 0
	schemaVersion = 1
	updatedBy = 0
	updatedAt = 0
	config = null

	function _skill(unit, cap, maxPurchase, costs, animation = null) {
		return {
			enabled = true,
			unit = unit,
			cap = cap,
			maxPurchase = maxPurchase,
			direct = true,
			teacher = true,
			teacherMultiplier = 1.0,
			costs = costs,
			animation = animation == null ? [] : animation
		}
	}

	function defaultConfig() {
		local weaponCosts = [{ from = 0, cost = 1 }, { from = 30, cost = 2 }, { from = 60, cost = 3 }]
		local animation = [{ at = 0, talent = 0 }, { at = 30, talent = 30 }, { at = 60, talent = 60 }]
		return {
			dailyGrant = 5,
			accumulationCap = 100,
			maxCatchupDays = 3,
			resetTimezone = "UTC",
			resetOffsetMinutes = 0,
			resetHour = 0,
			channels = { direct = true, teacher = true },
			skills = {
				strength = _skill(1, 200, 10, [{ from = 0, cost = 1 }, { from = 50, cost = 2 }, { from = 100, cost = 3 }, { from = 150, cost = 5 }]),
				dexterity = _skill(1, 200, 10, [{ from = 0, cost = 1 }, { from = 50, cost = 2 }, { from = 100, cost = 3 }, { from = 150, cost = 5 }]),
				hpMax = _skill(5, 1000, 10, [{ from = 0, cost = 1 }, { from = 300, cost = 2 }, { from = 600, cost = 4 }]),
				manaMax = _skill(5, 500, 10, [{ from = 0, cost = 1 }, { from = 150, cost = 2 }, { from = 300, cost = 4 }]),
				staminaMax = _skill(5, 500, 10, [{ from = 0, cost = 1 }, { from = 200, cost = 2 }, { from = 350, cost = 4 }]),
				oneHand = _skill(1, 100, 10, weaponCosts, animation),
				twoHand = _skill(1, 100, 10, weaponCosts, animation),
				bow = _skill(1, 100, 10, weaponCosts, animation),
				crossbow = _skill(1, 100, 10, weaponCosts, animation),
				magicLevel = _skill(1, 60, 5, [{ from = 0, cost = 2 }, { from = 20, cost = 3 }, { from = 40, cost = 5 }])
			}
		}
	}


	function escape(value) {
		if (value == null) return ""
		local source = value.tostring()
		local out = ""
		for (local i = 0; i < source.len(); i++) {
			local c = source[i]
			if (c == '\\') out += "\\\\"
			else if (c == '\'') out += "\\'"
			else if (c == 0) out += "\\0"
			else if (c == 10) out += "\\n"
			else if (c == 13) out += "\\r"
			else if (c == 26) out += "\\Z"
			else out += source.slice(i, i + 1)
		}
		return out
	}

	function _int(value, fallback, minimum, maximum) {
		local out = fallback
		local kind = typeof value
		try {
			if (kind == "integer" || kind == "float") out = value.tointeger()
			else return fallback
		} catch (e) { return fallback }
		if (out < minimum) out = minimum
		if (out > maximum) out = maximum
		return out
	}

	function _number(value, fallback, minimum, maximum) {
		local out = fallback.tofloat()
		local kind = typeof value
		try {
			if (kind == "integer" || kind == "float") out = value.tofloat()
			else return fallback
		} catch (e) { return fallback }
		if (out < minimum) out = minimum
		if (out > maximum) out = maximum
		return out
	}

	function _validateSteps(source, valueKey, maxValue) {
		if (typeof source != "array" || source.len() == 0 || source.len() > 16) return null
		local out = []
		local previous = -1
		foreach (entry in source) {
			if (typeof entry != "table" || !("from" in entry) || !(valueKey in entry)) return null
			if ((typeof entry.from != "integer" && typeof entry.from != "float") || (typeof entry[valueKey] != "integer" && typeof entry[valueKey] != "float")) return null
			local from = entry.from.tointeger()
			local value = entry[valueKey].tointeger()
			if (from.tofloat() != entry.from.tofloat() || value.tofloat() != entry[valueKey].tofloat()) return null
			if (from < 0 || from > maxValue || value < 0 || value > 100000 || from <= previous) return null
			local next = { from = from }
			next[valueKey] <- value
			out.push(next)
			previous = from
		}
		if (out[0].from != 0) return null
		return out
	}

	function validateConfig(source) {
		if (typeof source != "table") return { ok = false, error = "invalidConfig" }
		local limits = { dailyGrant = [0, 10000], accumulationCap = [0, 1000000], maxCatchupDays = [0, 365], resetOffsetMinutes = [-720, 840], resetHour = [0, 23] }
		local values = {}
		foreach (field, range in limits) {
			if (!(field in source) || (typeof source[field] != "integer" && typeof source[field] != "float")) return { ok = false, error = "missingField:" + field }
			local parsedValue = source[field].tointeger()
			if (parsedValue.tofloat() != source[field].tofloat() || parsedValue < range[0] || parsedValue > range[1]) return { ok = false, error = "invalidField:" + field }
			values[field] <- parsedValue
		}
		local defaults = defaultConfig()
		local out = {
			dailyGrant = values.dailyGrant,
			accumulationCap = values.accumulationCap,
			maxCatchupDays = values.maxCatchupDays,
			resetTimezone = ("resetTimezone" in source && typeof source.resetTimezone == "string") ? source.resetTimezone : "",
			resetOffsetMinutes = values.resetOffsetMinutes,
			resetHour = values.resetHour,
			channels = {},
			skills = {}
		}
		if (out.accumulationCap < out.dailyGrant) return { ok = false, error = "invalidLimits" }
		if (out.resetTimezone.len() < 1 || out.resetTimezone.len() > 32) return { ok = false, error = "invalidTimezone" }
		if (!("channels" in source) || typeof source.channels != "table") return { ok = false, error = "invalidChannels" }
		foreach (channel in ["direct", "teacher"]) {
			if (!(channel in source.channels) || typeof source.channels[channel] != "bool") return { ok = false, error = "invalidChannel:" + channel }
			out.channels[channel] <- source.channels[channel]
		}
		if (!("skills" in source) || typeof source.skills != "table") return { ok = false, error = "invalidSkills" }

		foreach (key, fallback in defaults.skills) {
			if (!(key in source.skills) || typeof source.skills[key] != "table") return { ok = false, error = "missingSkill:" + key }
			local raw = source.skills[key]
			foreach (field in ["enabled", "direct", "teacher"]) if (!(field in raw) || typeof raw[field] != "bool") return { ok = false, error = "invalidSkill:" + key }
			foreach (field in ["unit", "cap", "maxPurchase", "teacherMultiplier"]) if (!(field in raw) || (typeof raw[field] != "integer" && typeof raw[field] != "float")) return { ok = false, error = "invalidSkillLimits:" + key }
			local unit = raw.unit.tointeger()
			local cap = raw.cap.tointeger()
			local maxPurchase = raw.maxPurchase.tointeger()
			local multiplier = raw.teacherMultiplier.tofloat()
			if (unit.tofloat() != raw.unit.tofloat() || cap.tofloat() != raw.cap.tofloat() || maxPurchase.tofloat() != raw.maxPurchase.tofloat()) return { ok = false, error = "invalidSkillLimits:" + key }
			if (unit <= 0 || unit > 100 || cap <= 0 || cap > 100000 || maxPurchase <= 0 || maxPurchase > 100 || multiplier < 0.1 || multiplier > 10.0) return { ok = false, error = "invalidSkillLimits:" + key }
			local minimumCaps = { strength = 10, dexterity = 10, hpMax = 100, manaMax = 50, staminaMax = 100 }
			if (key in minimumCaps && cap < minimumCaps[key]) return { ok = false, error = "invalidSkillLimits:" + key }
			if (phoenix.player.WeaponProgression.isWeaponKey(key) && cap > 100) return { ok = false, error = "invalidSkillLimits:" + key }
			if (key == "magicLevel" && cap > phoenix.item.Spells.maxLevel) return { ok = false, error = "invalidSkillLimits:" + key }
			local costs = _validateSteps(("costs" in raw) ? raw.costs : null, "cost", cap)
			if (costs == null) return { ok = false, error = "invalidCosts:" + key }
			local animation = []
			if (phoenix.player.WeaponProgression.isWeaponKey(key)) {
				if (!("animation" in raw) || typeof raw.animation != "array" || raw.animation.len() == 0 || raw.animation.len() > 16) return { ok = false, error = "invalidAnimation:" + key }
				local previousAt = -1
				foreach (entry in raw.animation) {
					if (typeof entry != "table" || !("at" in entry) || !("talent" in entry)) return { ok = false, error = "invalidAnimation:" + key }
					if ((typeof entry.at != "integer" && typeof entry.at != "float") || (typeof entry.talent != "integer" && typeof entry.talent != "float")) return { ok = false, error = "invalidAnimation:" + key }
					local at = entry.at.tointeger()
					local talent = entry.talent.tointeger()
					if (at.tofloat() != entry.at.tofloat() || talent.tofloat() != entry.talent.tofloat() || at < 0 || at > cap || talent < 0 || talent > 100 || at <= previousAt) return { ok = false, error = "invalidAnimation:" + key }
					animation.push({ at = at, talent = talent })
					previousAt = at
				}
				if (animation[0].at != 0) return { ok = false, error = "invalidAnimation:" + key }
			}
			out.skills[key] <- {
				enabled = raw.enabled,
				unit = unit,
				cap = cap,
				maxPurchase = maxPurchase,
				direct = raw.direct,
				teacher = raw.teacher,
				teacherMultiplier = multiplier,
				costs = costs,
				animation = animation
			}
		}
		foreach (key, _value in source.skills) if (!(key in defaults.skills)) return { ok = false, error = "unknownSkill:" + key }
		return { ok = true, config = out }
	}

	function snapshot() {
		return {
			config = config,
			revision = revision,
			schemaVersion = schemaVersion,
			updatedBy = updatedBy,
			updatedAt = updatedAt,
			ready = ready
		}
	}

	function _applyRow(row) {
		if (row == null) return false
		local decoded = null
		try { decoded = phoenix.web.Json.parse(row.configJson.tostring()) } catch (e) {}
		local validated = validateConfig(decoded)
		if (!validated.ok) return false
		config = validated.config
		try { revision = row.revision.tointeger() } catch (e) { revision = 0 }
		try { schemaVersion = row.schemaVersion.tointeger() } catch (e) { schemaVersion = 1 }
		try { updatedBy = row.updatedBy == null ? 0 : row.updatedBy.tointeger() } catch (e) { updatedBy = 0 }
		try { updatedAt = row.updatedAt == null ? 0 : row.updatedAt.tointeger() } catch (e) { updatedAt = 0 }
		return true
	}

	function load() {
		try {
			local rows = ORM.engine.execute("SELECT `configJson`,`schemaVersion`,`revision`,`updatedBy`,UNIX_TIMESTAMP(`updatedAt`) AS `updatedAt` FROM `phoenix_progression_settings` WHERE `id`=1 LIMIT 1")
			if (rows != null && rows.len() > 0 && _applyRow(rows[0])) { ready = true; return }
			local encoded = phoenix.web.Json.encode(defaultConfig())
			ORM.engine.execute("INSERT INTO `phoenix_progression_settings` (`id`,`configJson`,`schemaVersion`,`revision`) VALUES (1,'" + escape(encoded) + "',1,1) ON DUPLICATE KEY UPDATE `configJson`=VALUES(`configJson`),`schemaVersion`=VALUES(`schemaVersion`),`revision`=`revision`+1,`updatedAt`=UTC_TIMESTAMP()")
			rows = ORM.engine.execute("SELECT `configJson`,`schemaVersion`,`revision`,`updatedBy`,UNIX_TIMESTAMP(`updatedAt`) AS `updatedAt` FROM `phoenix_progression_settings` WHERE `id`=1 LIMIT 1")
			if (rows != null && rows.len() > 0) _applyRow(rows[0])
		} catch (e) { print("[development] config load failed: " + e + "\n") }
		if (config == null) config = defaultConfig()
		ready = true
	}


	function updateConfig(payload, actorAccountId) {
		if (payload == null || typeof payload != "table" || !("expectedRevision" in payload) || !("config" in payload)) return { ok = false, error = "invalidPayload", snapshot = snapshot() }
		local expected = -1
		try { expected = payload.expectedRevision.tointeger() } catch (e) {}
		if (expected < 0 || expected != revision) return { ok = false, error = "conflict", snapshot = snapshot() }
		local validated = validateConfig(payload.config)
		if (!validated.ok) return { ok = false, error = validated.error, snapshot = snapshot() }
		local beforeJson = phoenix.web.Json.encode(config)
		local afterJson = phoenix.web.Json.encode(validated.config)
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT `revision` FROM `phoenix_progression_settings` WHERE `id`=1 FOR UPDATE")
			if (rows == null || rows.len() == 0 || rows[0].revision.tointeger() != expected) throw "CONFLICT"
			local nextRevision = expected + 1
			local actorSql = actorAccountId > 0 ? actorAccountId.tostring() : "NULL"
			ORM.engine.execute("UPDATE `phoenix_progression_settings` SET `configJson`='" + escape(afterJson) + "',`schemaVersion`=1,`revision`=" + nextRevision + ",`updatedBy`=" + actorSql + " WHERE `id`=1 AND `revision`=" + expected)
			ORM.engine.execute("INSERT INTO `phoenix_progression_settings_audit` (`revision`,`actorAccountId`,`beforeJson`,`afterJson`) VALUES (" + nextRevision + "," + actorSql + ",'" + escape(beforeJson) + "','" + escape(afterJson) + "')")
			ORM.engine.execute("COMMIT")
			config = validated.config
			revision = nextRevision
			updatedBy = actorAccountId
			try { callEvent("phoenix.player.Development.OnConfigChanged", snapshot()) } catch (e) {}
			for (local playerId = 0; playerId < getMaxSlots(); playerId += 1) {
				try {
					if (!isPlayerConnected(playerId) || phoenix.character.Structure.getActive(playerId) == null) continue
					syncConfiguredTalents(playerId)
					phoenix.player.Stats.pushSnapshot(playerId)
				} catch (e) {}
			}
			return { ok = true, error = "", snapshot = snapshot() }
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			if (error.tostring() == "CONFLICT") { try { load() } catch (e) {}; return { ok = false, error = "conflict", snapshot = snapshot() } }
			print("[development] config update failed: " + error + "\n")
			return { ok = false, error = "database", snapshot = snapshot() }
		}
	}

	function enabled() {
		return ready && config != null && phoenix.features.Settings.isEnabled("progression.dailyLp")
	}

	function _dayInfo() {
		local offset = config.resetOffsetMinutes
		local hour = config.resetHour
		local sql = "SELECT DATE(DATE_SUB(DATE_ADD(UTC_TIMESTAMP(), INTERVAL " + offset + " MINUTE), INTERVAL " + hour + " HOUR)) AS `dayKey`,UNIX_TIMESTAMP(DATE_SUB(DATE_ADD(DATE_ADD(DATE(DATE_SUB(DATE_ADD(UTC_TIMESTAMP(), INTERVAL " + offset + " MINUTE), INTERVAL " + hour + " HOUR)), INTERVAL 1 DAY), INTERVAL " + hour + " HOUR), INTERVAL " + offset + " MINUTE)) AS `nextGrantAt`"
		local rows = ORM.engine.execute(sql)
		return { dayKey = rows[0].dayKey.tostring(), nextGrantAt = rows[0].nextGrantAt.tointeger() }
	}

	function _activeRecordByCharacter(characterId) {
		foreach (_playerId, record in phoenix.character.Structure.active) if (record != null && record.id == characterId) return record
		return null
	}

	function _syncBalance(characterId, balance) {
		local record = _activeRecordByCharacter(characterId)
		if (record != null) record.learnPoints = balance
	}

	function ensureDaily(playerId) {
		if (!enabled()) return { ok = false, error = "featureDisabled", granted = 0 }
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return { ok = false, error = "noCharacter", granted = 0 }
		local day = _dayInfo()
		local granted = 0
		local balance = record.learnPoints
		try {
			ORM.engine.execute("START TRANSACTION")
			local charRows = ORM.engine.execute("SELECT `learnPoints` FROM `phoenix_characters` WHERE `id`=" + record.id + " FOR UPDATE")
			if (charRows == null || charRows.len() == 0) throw "NO_CHARACTER"
			balance = charRows[0].learnPoints.tointeger()
			ORM.engine.execute("INSERT INTO `phoenix_character_daily_lp` (`characterId`,`lastGrantDay`,`revision`) VALUES (" + record.id + ",NULL,0) ON DUPLICATE KEY UPDATE `characterId`=`characterId`")
			local stateRows = ORM.engine.execute("SELECT `lastGrantDay`,`revision`,DATEDIFF('" + day.dayKey + "',`lastGrantDay`) AS `elapsed` FROM `phoenix_character_daily_lp` WHERE `characterId`=" + record.id + " FOR UPDATE")
			local lastDay = stateRows[0].lastGrantDay
			local days = 0
			if (lastDay == null) days = 1
			else {
				days = stateRows[0].elapsed.tointeger()
				if (days < 0) days = 0
				local grantDayLimit = config.maxCatchupDays
				if (grantDayLimit < 1) grantDayLimit = 1
				if (days > grantDayLimit) days = grantDayLimit
			}
			if (days > 0) {
				granted = config.dailyGrant * days
				local room = config.accumulationCap - balance
				if (room < 0) room = 0
				if (granted > room) granted = room
				if (granted > 0) {
					balance += granted
					ORM.engine.execute("UPDATE `phoenix_characters` SET `learnPoints`=" + balance + " WHERE `id`=" + record.id)
					local sourceKey = "daily:" + day.dayKey
					ORM.engine.execute("INSERT INTO `phoenix_character_lp_ledger` (`characterId`,`dayKey`,`delta`,`balanceAfter`,`reason`,`channel`,`skillKey`,`amount`,`sourceKey`,`metadataJson`) VALUES (" + record.id + ",'" + day.dayKey + "'," + granted + "," + balance + ",'dailyGrant','system',NULL," + days + ",'" + sourceKey + "','{\"days\":" + days + "}')")
				}
				ORM.engine.execute("UPDATE `phoenix_character_daily_lp` SET `lastGrantDay`='" + day.dayKey + "',`lastGrantAt`=UTC_TIMESTAMP(),`revision`=`revision`+1 WHERE `characterId`=" + record.id)
			}
			ORM.engine.execute("COMMIT")
			_syncBalance(record.id, balance)
			return { ok = true, error = "", granted = granted, balance = balance, day = day }
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			print("[development] daily grant failed character=" + record.id + ": " + error + "\n")
			return { ok = false, error = "database", granted = 0 }
		}
	}


	function _rowValue(row, skill) {
		try { if (skill in row && row[skill] != null) return row[skill].tointeger() } catch (e) {}
		return 0
	}

	function _recordValue(record, skill) {
		try { if (skill in record && record[skill] != null) return record[skill].tointeger() } catch (e) {}
		return 0
	}

	function _costAt(definition, value) {
		local result = 0
		foreach (step in definition.costs) {
			if (value < step.from) break
			result = step.cost
		}
		return result
	}

	function _skillFeatureAvailable(skill) {
		if (skill == "staminaMax") return phoenix.features.Settings.isEnabled("player.stamina")
		if (skill == "magicLevel") return phoenix.features.Settings.isEnabled("items.spells")
		if (phoenix.player.WeaponProgression.isWeaponKey(skill)) return phoenix.features.Settings.isEnabled("items.equipment")
		return true
	}

	function quoteValue(skill, current, amount, channel) {
		if (!enabled()) return { ok = false, error = "featureDisabled" }
		if (!(skill in config.skills)) return { ok = false, error = "unknownStat" }
		if (!_skillFeatureAvailable(skill)) return { ok = false, error = "skillUnavailable" }
		if (channel != "direct" && channel != "teacher") return { ok = false, error = "invalidChannel" }
		if (!config.channels[channel]) return { ok = false, error = "channelDisabled" }
		local definition = config.skills[skill]
		if (!definition.enabled || !definition[channel]) return { ok = false, error = "skillUnavailable" }
		if (amount <= 0 || amount > definition.maxPurchase) return { ok = false, error = "invalidAmount" }
		if (current + amount * definition.unit > definition.cap) return { ok = false, error = "atCap" }
		local cost = 0
		for (local index = 0; index < amount; index += 1) cost += _costAt(definition, current + index * definition.unit)
		if (channel == "teacher") {
			local scaled = cost.tofloat() * definition.teacherMultiplier
			cost = scaled.tointeger()
			if (cost.tofloat() < scaled) cost += 1
		}
		return { ok = true, error = "", cost = cost, current = current, next = current + amount * definition.unit, definition = definition }
	}

	function quote(playerId, skill, amount, channel) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return { ok = false, error = "noCharacter" }
		local result = quoteValue(skill, _recordValue(record, skill), amount, channel)
		if (result.ok && record.learnPoints < result.cost) return { ok = false, error = "noLearnPoints", cost = result.cost }
		return result
	}

	function _safeRequestId(value) {
		if (value == null) return ""
		local source = value.tostring()
		if (source.len() < 1 || source.len() > 80) return ""
		for (local i = 0; i < source.len(); i++) {
			local c = source[i]
			local valid = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == ':'
			if (!valid) return ""
		}
		return source
	}

	function talentValue(skill, value) {
		if (!enabled() || config == null || !(skill in config.skills)) return value
		local definition = config.skills[skill]
		if (!("animation" in definition) || definition.animation.len() == 0) return value
		local talent = 0
		foreach (step in definition.animation) {
			if (value < step.at) break
			talent = step.talent
		}
		return talent
	}

	function _runtimeApply(playerId, record, skill, value) {
		record[skill] = value
		if (skill == "strength") {
			local bonus = 0
			try { bonus = phoenix.item.Effects.modifier(playerId, "strength") } catch (e) {}
			try { setPlayerStrength(playerId, value + bonus) } catch (e) {}
		}
		else if (skill == "dexterity") {
			local bonus = 0
			try { bonus = phoenix.item.Effects.modifier(playerId, "dexterity") } catch (e) {}
			try { setPlayerDexterity(playerId, value + bonus) } catch (e) {}
		}
		else if (skill == "hpMax") { record.hp = value; phoenix.player.Resources.syncMaximums(playerId, record); phoenix.player.Resources.set(playerId, record, "hp", value, true) }
		else if (skill == "manaMax") { record.mana = value; phoenix.player.Resources.syncMaximums(playerId, record); phoenix.player.Resources.set(playerId, record, "mana", value, true) }
		else if (skill == "staminaMax") { record.stamina = value; phoenix.player.Resources.set(playerId, record, "stamina", value, true) }
		else if (phoenix.player.WeaponProgression.isWeaponKey(skill)) {
			if (!(playerId in phoenix.player.WeaponProgression.byPlayer)) phoenix.player.WeaponProgression.byPlayer[playerId] <- phoenix.player.WeaponProgression._stateFromRecord(record)
			local entry = phoenix.player.WeaponProgression.byPlayer[playerId][skill]
			entry.level = value
			entry.xp = 0
			entry.cap = config.skills[skill].cap
			phoenix.player.WeaponProgression.byPlayer[playerId][skill] <- entry
			local weaponType = phoenix.player.WeaponProgression._weaponConst(skill)
			local runtimeTalent = talentValue(skill, value)
			try { setPlayerSkillWeapon(playerId, weaponType, runtimeTalent) } catch (e) {}
		}
	}


	function purchase(playerId, skill, amount, channel, requestId) {
		if (!enabled()) return "featureDisabled"
		if (!phoenix.features.Settings.isEnabled("progression.statsSpending")) return "featureDisabled"
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return "noCharacter"
		local safeId = _safeRequestId(requestId)
		if (safeId == "") return "invalidRequest"
		local sourceKey = "purchase:" + channel + ":" + safeId
		local nextValue = 0
		local nextBalance = 0
		try {
			ORM.engine.execute("START TRANSACTION")
			local charRows = ORM.engine.execute("SELECT `learnPoints`,`strength`,`dexterity`,`hpMax`,`manaMax`,`staminaMax`,`oneHand`,`twoHand`,`bow`,`crossbow`,`magicLevel` FROM `phoenix_characters` WHERE `id`=" + record.id + " FOR UPDATE")
			if (charRows == null || charRows.len() == 0) throw "NO_CHARACTER"
			local duplicateRows = ORM.engine.execute("SELECT `id`,`balanceAfter`,`skillKey`,`amount` FROM `phoenix_character_lp_ledger` WHERE `characterId`=" + record.id + " AND `sourceKey`='" + escape(sourceKey) + "' LIMIT 1")
			if (duplicateRows != null && duplicateRows.len() > 0) {
				if (duplicateRows[0].skillKey.tostring() != skill || duplicateRows[0].amount.tointeger() != amount) throw "RULE:invalidRequest"
				ORM.engine.execute("COMMIT")
				_syncBalance(record.id, duplicateRows[0].balanceAfter.tointeger())
				return null
			}
			local current = _rowValue(charRows[0], skill)
			local quoted = quoteValue(skill, current, amount, channel)
			if (!quoted.ok) throw "RULE:" + quoted.error
			local balance = charRows[0].learnPoints.tointeger()
			if (balance < quoted.cost) throw "RULE:noLearnPoints"
			nextValue = quoted.next
			nextBalance = balance - quoted.cost
			local assignments = "`learnPoints`=" + nextBalance + ",`" + skill + "`=" + nextValue
			if (skill == "hpMax") assignments += ",`hp`=" + nextValue
			else if (skill == "manaMax") assignments += ",`mana`=" + nextValue
			else if (skill == "staminaMax") assignments += ",`stamina`=" + nextValue
			else if (skill == "magicLevel") assignments += ",`magicXp`=0"
			ORM.engine.execute("UPDATE `phoenix_characters` SET " + assignments + " WHERE `id`=" + record.id)
			if (phoenix.player.WeaponProgression.isWeaponKey(skill)) {
				ORM.engine.execute("INSERT INTO `phoenix_character_weapon_progress` (`characterId`,`skillKey`,`level`,`xp`,`cap`) VALUES (" + record.id + ",'" + skill + "'," + nextValue + ",0," + quoted.definition.cap + ") ON DUPLICATE KEY UPDATE `level`=VALUES(`level`),`xp`=0,`cap`=VALUES(`cap`)")
			}
			local accountId = 0
			try { local session = phoenix.account.Structure.get(playerId); if (session != null) accountId = session.id() } catch (e) {}
			local accountSql = accountId > 0 ? accountId.tostring() : "NULL"
			local metadata = phoenix.web.Json.encode({ unit = quoted.definition.unit, valueBefore = current, valueAfter = nextValue, configRevision = revision })
			ORM.engine.execute("INSERT INTO `phoenix_character_lp_ledger` (`characterId`,`delta`,`balanceAfter`,`reason`,`channel`,`skillKey`,`amount`,`sourceKey`,`actorAccountId`,`metadataJson`) VALUES (" + record.id + "," + (-quoted.cost) + "," + nextBalance + ",'skillPurchase','" + channel + "','" + skill + "'," + amount + ",'" + escape(sourceKey) + "'," + accountSql + ",'" + escape(metadata) + "')")
			ORM.engine.execute("COMMIT")
			record.learnPoints = nextBalance
			_runtimeApply(playerId, record, skill, nextValue)
			if (skill == "magicLevel") record.magicXp = 0
			try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e) {}
			return null
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			local text = error.tostring()
			if (text.len() > 5 && text.slice(0, 5) == "RULE:") return text.slice(5)
			if (text == "NO_CHARACTER") return "noCharacter"
			print("[development] purchase failed character=" + record.id + " skill=" + skill + ": " + text + "\n")
			return "database"
		}
	}

	function _skillSnapshot(playerId, record, channel) {
		local out = {}
		foreach (key, definition in config.skills) {
			local current = _recordValue(record, key)
			local maxAmount = ((definition.cap - current) / definition.unit).tointeger()
			if (maxAmount > definition.maxPurchase) maxAmount = definition.maxPurchase
			if (maxAmount < 0) maxAmount = 0
			local quoted = maxAmount > 0 ? quoteValue(key, current, 1, channel) : { ok = false, error = "atCap", cost = 0 }
			local batchAmount = 0
			local batchCost = 0
			for (local candidate = 1; candidate <= maxAmount; candidate += 1) {
				local batchQuote = quoteValue(key, current, candidate, channel)
				if (!batchQuote.ok || batchQuote.cost > record.learnPoints) break
				batchAmount = candidate
				batchCost = batchQuote.cost
			}
			local definitionEnabled = ("enabled" in definition) && definition.enabled == true
			local channelEnabled = (channel in config.channels) && config.channels[channel] == true
			local skillChannelEnabled = (channel in definition) && definition[channel] == true
			out[key] <- {
				enabled = definitionEnabled && channelEnabled && skillChannelEnabled && _skillFeatureAvailable(key),
				current = current,
				unit = definition.unit,
				cap = definition.cap,
				cost = ("cost" in quoted) ? quoted.cost : 0,
				maxPurchase = maxAmount,
				batchAmount = batchAmount,
				batchCost = batchCost,
				available = quoted.ok && record.learnPoints >= quoted.cost,
				error = quoted.ok ? "" : quoted.error,
				animation = ("animation" in definition && typeof definition.animation == "array") ? definition.animation : []
			}
		}
		return out
	}

	function playerSnapshot(playerId, channel = "direct") {
		if (!ready || config == null || typeof config != "table" || !("skills" in config) || !("channels" in config)) {
			return { enabled = false, error = "notReady", skills = {} }
		}
		if (!(channel in config.channels)) return { enabled = false, error = "invalidChannel", skills = {} }
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return { enabled = false, error = "noCharacter", skills = {} }
		local grant = { granted = 0 }
		if (enabled()) grant = ensureDaily(playerId)
		local day = null
		try { day = _dayInfo() } catch (e) { day = { dayKey = "", nextGrantAt = 0 } }
		return {
			enabled = enabled(),
			balance = record.learnPoints,
			dailyGrant = config.dailyGrant,
			accumulationCap = config.accumulationCap,
			maxCatchupDays = config.maxCatchupDays,
			resetTimezone = config.resetTimezone,
			resetOffsetMinutes = config.resetOffsetMinutes,
			resetHour = config.resetHour,
			dayKey = day.dayKey,
			nextGrantAt = day.nextGrantAt,
			grantedNow = ("granted" in grant) ? grant.granted : 0,
			channel = channel,
			configRevision = revision,
			skills = _skillSnapshot(playerId, record, channel)
		}
	}

	function playerSnapshotJson(playerId, channel = "direct") {
		try { return phoenix.web.Json.encode(playerSnapshot(playerId, channel)) } catch (e) { return "{}" }
	}

	function syncConfiguredTalents(playerId) {
		if (!phoenix.player.Development.enabled()) return
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		foreach (key in phoenix.player.WeaponProgression.skills) {
			local level = phoenix.player.Development._recordValue(record, key)
			local weaponType = phoenix.player.WeaponProgression._weaponConst(key)
			local runtimeTalent = phoenix.player.Development.talentValue(key, level)
			try { setPlayerSkillWeapon(playerId, weaponType, runtimeTalent) } catch (e) {}
			try {
				if (playerId in phoenix.player.WeaponProgression.byPlayer && key in phoenix.player.WeaponProgression.byPlayer[playerId]) phoenix.player.WeaponProgression.byPlayer[playerId][key].cap = phoenix.player.Development.config.skills[key].cap
			} catch (e) {}
		}
	}

	function onCharacterSelected(playerId, _characterId) {
		if (!phoenix.player.Development.enabled()) return
		local result = phoenix.player.Development.ensureDaily(playerId)
		if (result.ok && result.granted > 0) {
			try { phoenix.notification.notify(playerId, "success", "Punkty nauki", "+" + result.granted + " LP", 3200) } catch (e) {}
		}
		try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e) {}
		try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e) {}
	}
}

local phoenixDevelopmentDatabaseReadyEvent = "phoenix.database." + "OnReady"
local phoenixDevelopmentSelectedEvent = "phoenix.character." + "OnSelected"
local phoenixDevelopmentFeatureEvent = "phoenix.features." + "OnChanged"
addEventHandler(phoenixDevelopmentDatabaseReadyEvent, function() { phoenix.player.Development.load() })
addEventHandler(phoenixDevelopmentSelectedEvent, function(playerId, characterId) { phoenix.player.Development.onCharacterSelected(playerId, characterId) })

addEventHandler(phoenixDevelopmentFeatureEvent, function(key, enabled) {
	if (key != "progression.dailyLp") return
	for (local playerId = 0; playerId < getMaxSlots(); playerId += 1) {
		try {
			if (!isPlayerConnected(playerId) || phoenix.character.Structure.getActive(playerId) == null) continue
			if (enabled) {
				phoenix.player.Development.ensureDaily(playerId)
				phoenix.player.Development.syncConfiguredTalents(playerId)
			} else {
				local record = phoenix.character.Structure.getActive(playerId)
				foreach (weaponKey in phoenix.player.WeaponProgression.skills) {
					local weaponType = phoenix.player.WeaponProgression._weaponConst(weaponKey)
					local level = phoenix.player.Development._recordValue(record, weaponKey)
					try { setPlayerSkillWeapon(playerId, weaponType, level) } catch (e) {}
					try {
						if (playerId in phoenix.player.WeaponProgression.byPlayer && weaponKey in phoenix.player.WeaponProgression.byPlayer[playerId]) {
							local entry = phoenix.player.WeaponProgression.byPlayer[playerId][weaponKey]
							entry.cap = phoenix.player.WeaponProgression._capForLevel(level)
							local sql = "UPDATE `phoenix_character_weapon_progress` SET `cap`=" + entry.cap + " WHERE `characterId`=" + record.id + " AND `skillKey`='" + weaponKey + "'"
							ORM.engine.executeAsync(sql, function(_) {})
						}
					} catch (e) {}
				}
			}
			phoenix.player.Stats.pushSnapshot(playerId)
		} catch (e) {}
	}
})