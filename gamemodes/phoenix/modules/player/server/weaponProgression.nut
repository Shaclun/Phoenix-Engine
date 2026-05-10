phoenix.player.WeaponProgression <- {
	skills = ["oneHand", "twoHand", "bow", "crossbow"]
	names = { oneHand = "Broń jednoręczna", twoHand = "Broń dwuręczna", bow = "Łuk", crossbow = "Kusza" }
	byPlayer = {}
	loaded = {}
	hitTicks = {}

	function ensureTable() {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_character_weapon_progress` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,`characterId` INT NOT NULL,`skillKey` VARCHAR(16) NOT NULL,`level` INT NOT NULL DEFAULT 0,`xp` INT NOT NULL DEFAULT 0,`cap` INT NOT NULL DEFAULT 30,`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,UNIQUE KEY `uq_weapon_progress_character_skill` (`characterId`,`skillKey`),KEY `idx_weapon_progress_character` (`characterId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try { ORM.engine.executeAsync(sql, function(_) {}) } catch (e) {}
	}

	function isWeaponKey(key) {
		return key == "oneHand" || key == "twoHand" || key == "bow" || key == "crossbow"
	}

	function xpToNext(level) {
		if (level >= 100) return 0
		return 20 + level * level * 3
	}

	function _readRecordValue(record, key) {
		switch (key) {
			case "oneHand": return record.oneHand
			case "twoHand": return record.twoHand
			case "bow": return record.bow
			case "crossbow": return record.crossbow
		}
		return 0
	}

	function _writeRecordValue(record, key, value) {
		switch (key) {
			case "oneHand": record.oneHand = value; return
			case "twoHand": record.twoHand = value; return
			case "bow": record.bow = value; return
			case "crossbow": record.crossbow = value; return
		}
	}

	function _weaponConst(key) {
		switch (key) {
			case "oneHand": return WEAPON_1H
			case "twoHand": return WEAPON_2H
			case "bow": return WEAPON_BOW
			case "crossbow": return WEAPON_CBOW
		}
		return WEAPON_1H
	}

	function _capForLevel(level) {
		if (level >= 60) return 100
		if (level >= 30) return 60
		return 30
	}

	function _entry(record, key) {
		local level = phoenix.player.WeaponProgression._readRecordValue(record, key)
		if (level < 0) level = 0
		if (level > 100) level = 100
		return { level = level, xp = 0, cap = phoenix.player.WeaponProgression._capForLevel(level) }
	}

	function _stateFromRecord(record) {
		local state = {}
		foreach (key in phoenix.player.WeaponProgression.skills) state[key] <- phoenix.player.WeaponProgression._entry(record, key)
		return state
	}

	function load(playerId, characterId, callback = null) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) { if (callback != null) callback(null); return }
		local state = phoenix.player.WeaponProgression._stateFromRecord(record)
		phoenix.player.WeaponProgression.loaded[playerId] <- false
		local sql = "SELECT `skillKey`,`level`,`xp`,`cap` FROM `phoenix_character_weapon_progress` WHERE `characterId` = " + characterId
		try {
			ORM.engine.executeAsync(sql, function(rows) {
				if (rows != null) {
					foreach (row in rows) {
						local key = row.skillKey.tostring()
						if (!phoenix.player.WeaponProgression.isWeaponKey(key)) continue
						local level = row.level.tointeger()
						local xp = row.xp.tointeger()
						local cap = row.cap.tointeger()
						if (level < 0) level = 0
						if (level > 100) level = 100
						if (cap != 60 && cap != 100) cap = 30
						if (level > cap) cap = phoenix.player.WeaponProgression._capForLevel(level)
						state[key] <- { level = level, xp = xp, cap = cap }
					}
				}
				phoenix.player.WeaponProgression.byPlayer[playerId] <- state
				phoenix.player.WeaponProgression.loaded[playerId] <- true
				foreach (key, entry in state) phoenix.player.WeaponProgression.sync(playerId, key, entry)
				phoenix.player.WeaponProgression.saveAll(playerId)
				if (callback != null) callback(state)
			})
		} catch (e) {
			phoenix.player.WeaponProgression.byPlayer[playerId] <- state
			phoenix.player.WeaponProgression.loaded[playerId] <- true
			if (callback != null) callback(state)
		}
	}

	function progressString(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return ""
		local state = null
		if (playerId in phoenix.player.WeaponProgression.byPlayer) state = phoenix.player.WeaponProgression.byPlayer[playerId]
		else {
			state = phoenix.player.WeaponProgression._stateFromRecord(record)
			phoenix.player.WeaponProgression.byPlayer[playerId] <- state
		}
		local result = ""
		foreach (key in phoenix.player.WeaponProgression.skills) {
			if (!(key in state)) state[key] <- phoenix.player.WeaponProgression._entry(record, key)
			local entry = state[key]
			if (!("xp" in entry)) entry.xp <- 0
			if (!("cap" in entry)) entry.cap <- phoenix.player.WeaponProgression._capForLevel(entry.level)
			if (result != "") result += ","
			result += key + "|" + entry.level + "|" + entry.xp + "|" + phoenix.player.WeaponProgression.xpToNext(entry.level) + "|" + entry.cap
		}
		return result
	}

	function sync(playerId, key, entry) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		phoenix.player.WeaponProgression._writeRecordValue(record, key, entry.level)
		try { setPlayerSkillWeapon(playerId, phoenix.player.WeaponProgression._weaponConst(key), entry.level) } catch (e) {}
	}

	function saveEntry(characterId, key, entry) {
		local safe = key
		local sql = "INSERT INTO `phoenix_character_weapon_progress` (`characterId`,`skillKey`,`level`,`xp`,`cap`) VALUES (" + characterId + ",'" + safe + "'," + entry.level + "," + entry.xp + "," + entry.cap + ") ON DUPLICATE KEY UPDATE `level`=VALUES(`level`),`xp`=VALUES(`xp`),`cap`=VALUES(`cap`)"
		try { ORM.engine.executeAsync(sql, function(_) {}) } catch (e) {}
	}

	function saveAll(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		if (!(playerId in phoenix.player.WeaponProgression.byPlayer)) return
		foreach (key, entry in phoenix.player.WeaponProgression.byPlayer[playerId]) phoenix.player.WeaponProgression.saveEntry(record.id, key, entry)
		try { record.saveAsync(function(_) {}) } catch (e) {}
	}

	function keyFromMode(mode) {
		try { if (mode == WEAPONMODE_1HS) return "oneHand" } catch (e) {}
		try { if (mode == WEAPONMODE_2HS) return "twoHand" } catch (e2) {}
		try { if (mode == WEAPONMODE_BOW) return "bow" } catch (e3) {}
		try { if (mode == WEAPONMODE_CBOW) return "crossbow" } catch (e4) {}
		return null
	}

	function notify(playerId, kind, title, text) {
		try { phoenix.notification.notify(playerId, kind, title, text, 3200) } catch (e) {}
	}

	function onValidHit(attackerId, victimId, damage, desc = null) {
		if (attackerId == null || attackerId < 0 || attackerId >= getMaxSlots()) return
		if (victimId == attackerId) return
		local record = phoenix.character.Structure.getActive(attackerId)
		if (record == null) return
		if (!(attackerId in phoenix.player.WeaponProgression.loaded) || !phoenix.player.WeaponProgression.loaded[attackerId]) {
			phoenix.player.WeaponProgression.load(attackerId, record.id, function(_) {
				try { phoenix.player.WeaponProgression.onValidHit(attackerId, victimId, damage, desc) } catch (e) {}
			})
			return
		}
		local mode = 0
		try { mode = getPlayerWeaponMode(attackerId) } catch (e) { return }
		local key = phoenix.player.WeaponProgression.keyFromMode(mode)
		if (key == null) return
		local tickKey = attackerId + ":" + key
		local now = getTickCount()
		if (tickKey in phoenix.player.WeaponProgression.hitTicks && now - phoenix.player.WeaponProgression.hitTicks[tickKey] < 850) return
		phoenix.player.WeaponProgression.hitTicks[tickKey] <- now
		local state = phoenix.player.WeaponProgression.byPlayer[attackerId]
		local entry = state[key]
		if (entry.level >= entry.cap || entry.level >= 100) return
		local amount = 5
		try { amount += damage.tointeger() / 12 } catch (e2) {}
		if (amount > 25) amount = 25
		entry.xp += amount
		local leveled = false
		while (entry.level < entry.cap && entry.level < 100) {
			local next = phoenix.player.WeaponProgression.xpToNext(entry.level)
			if (next <= 0 || entry.xp < next) break
			entry.xp -= next
			entry.level += 1
			leveled = true
		}
		if (entry.level >= entry.cap) entry.xp = 0
		state[key] <- entry
		phoenix.player.WeaponProgression.sync(attackerId, key, entry)
		phoenix.player.WeaponProgression.saveEntry(record.id, key, entry)
		try { record.saveAsync(function(_) {}) } catch (e3) {}
		try { phoenix.player.Stats.pushSnapshot(attackerId) } catch (e4) {}
		try { phoenix.player.Hud.pushSnapshot(attackerId) } catch (e5) {}
		if (leveled) {
			local label = phoenix.player.WeaponProgression.names[key]
			phoenix.player.WeaponProgression.notify(attackerId, "success", "Rozwój broni", label + " wzrasta do " + entry.level)
			if (entry.level == entry.cap && entry.cap < 100) phoenix.player.WeaponProgression.notify(attackerId, "info", "Limit umiejętności", "Odwiedź nauczyciela, aby odblokować dalszy trening")
		}
	}

	function unlockCap(playerId, key) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return "noCharacter"
		if (!phoenix.player.WeaponProgression.isWeaponKey(key)) return "unknownStat"
		if (!(playerId in phoenix.player.WeaponProgression.byPlayer)) {
			phoenix.player.WeaponProgression.byPlayer[playerId] <- phoenix.player.WeaponProgression._stateFromRecord(record)
			phoenix.player.WeaponProgression.loaded[playerId] <- true
		}
		local entry = phoenix.player.WeaponProgression.byPlayer[playerId][key]
		if (entry.cap >= 100) return "atCap"
		if (entry.level < entry.cap) return "weaponCapLocked"
		local cost = entry.cap == 30 ? 30 : 60
		local newCap = entry.cap == 30 ? 60 : 100
		if (record.learnPoints < cost) return "noLearnPoints"
		record.learnPoints -= cost
		entry.cap = newCap
		entry.xp = 0
		phoenix.player.WeaponProgression.byPlayer[playerId][key] <- entry
		phoenix.player.WeaponProgression.saveEntry(record.id, key, entry)
		try { record.saveAsync(function(_) {}) } catch (e) {}
		phoenix.player.WeaponProgression.notify(playerId, "success", "Nauczyciel", "Odblokowano limit " + newCap + " dla: " + phoenix.player.WeaponProgression.names[key])
		return null
	}

	function onCharacterSelected(playerId, characterId) {
		phoenix.player.WeaponProgression.load(playerId, characterId, function(_) {
			try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e) {}
			try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e2) {}
		})
	}
}

phoenix.player.WeaponProgression.ensureTable()
addEventHandler("phoenix.character.OnSelected", phoenix.player.WeaponProgression.onCharacterSelected)