phoenix.player.Progression <- {
	maxLevel = 60

	function _persistRecord(record) {
		if (record == null || record.id <= 0) return
		local sql = "UPDATE `phoenix_characters` SET `level` = " + record.level + ", `experience` = " + record.experience + ", `experienceNext` = " + record.experienceNext + ", `learnPoints` = " + record.learnPoints + ", `hpMax` = " + record.hpMax + ", `hp` = " + record.hp + ", `manaMax` = " + record.manaMax + ", `mana` = " + record.mana + ", `staminaMax` = " + record.staminaMax + ", `stamina` = " + record.stamina + " WHERE `id` = " + record.id
		try { ORM.engine.executeAsync(sql, function(_) {}) } catch (e) {}
	}

	function expForLevel(level) {
		if (level <= 1) return 0
		// quadratic curve: total exp to reach level L
		// L2: 500, L10: ~5000, L30: ~45000, L60: ~180000
		local L = level - 1
		return (50 * L * L + 450 * L)
	}

	function expToNext(level) {
		if (level >= phoenix.player.Progression.maxLevel) return 0
		return phoenix.player.Progression.expForLevel(level + 1) - phoenix.player.Progression.expForLevel(level)
	}

	function _baseManaMax(record) {
		return record != null && ("klass" in record) && record.klass == 1 ? 50 : 10
	}

	manaPerMagicLevel = 10

	function _magicLevel(record) {
		try { if (record != null && "magicLevel" in record && record.magicLevel != null) return record.magicLevel.tointeger() } catch (e) {}
		return 0
	}

	function expectedMaxStats(record) {
		local level = 1
		try { level = record.level.tointeger() } catch (e) { level = 1 }
		if (level < 1) level = 1
		local gained = level - 1
		local magicBonus = phoenix.player.Progression._magicLevel(record) * phoenix.player.Progression.manaPerMagicLevel
		return {
			hpMax = 100 + gained * 10,
			manaMax = phoenix.player.Progression._baseManaMax(record) + gained * ((record != null && ("klass" in record) && record.klass == 1) ? 8 : 2) + magicBonus,
			staminaMax = 100 + gained * 5
		}
	}

	function normalizeRecordStats(record) {
		if (record == null) return false
		local expected = phoenix.player.Progression.expectedMaxStats(record)
		local changed = false
		if (record.hpMax == null) { record.hpMax = 0; changed = true }
		if (record.hp == null) { record.hp = 0; changed = true }
		if (record.manaMax == null) { record.manaMax = 0; changed = true }
		if (record.mana == null) { record.mana = 0; changed = true }
		if (record.staminaMax == null) { record.staminaMax = 0; changed = true }
		if (record.stamina == null) { record.stamina = 0; changed = true }
		local oldHpMax = (record.hpMax != null && record.hpMax > 0) ? record.hpMax : 100
		local oldManaMax = (record.manaMax != null && record.manaMax > 0) ? record.manaMax : phoenix.player.Progression._baseManaMax(record)
		local oldStaminaMax = (record.staminaMax != null && record.staminaMax > 0) ? record.staminaMax : 100
		if (record.hpMax < expected.hpMax) {
			record.hpMax = expected.hpMax
			if (record.hp <= 0 || record.hp >= oldHpMax) record.hp = record.hpMax
			changed = true
		}
		if (record.manaMax < expected.manaMax) {
			record.manaMax = expected.manaMax
			if (record.mana < 0 || record.mana >= oldManaMax) record.mana = record.manaMax
			changed = true
		}
		if (record.staminaMax < expected.staminaMax) {
			record.staminaMax = expected.staminaMax
			if (record.stamina <= 0 || record.stamina >= oldStaminaMax) record.stamina = record.staminaMax
			changed = true
		}
		if (record.hp > record.hpMax) { record.hp = record.hpMax; changed = true }
		if (record.mana > record.manaMax) { record.mana = record.manaMax; changed = true }
		if (record.stamina > record.staminaMax) { record.stamina = record.staminaMax; changed = true }
		return changed
	}

	function awardExperience(playerId, amount) {
		if (amount <= 0) return
		try {
			if ("social" in phoenix && phoenix.social != null && "Structure" in phoenix.social && phoenix.social.Structure != null) {
				if (!phoenix.social.Structure._awardingParty && phoenix.social.Structure.distributeExperience(playerId, amount)) return
			}
		} catch (eParty) {}
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		phoenix.player.Progression.normalizeRecordStats(record)
		if (record.level >= phoenix.player.Progression.maxLevel) return

		record.experience += amount
		local levelsGained = 0
		while (record.level < phoenix.player.Progression.maxLevel) {
			local needed = phoenix.player.Progression.expForLevel(record.level + 1)
			if (record.experience < needed) break
			record.level += 1
			levelsGained += 1
			phoenix.player.Progression._applyLevelUpStats(playerId, record)
		}
		record.experienceNext = phoenix.player.Progression.expForLevel(record.level + 1)
		if (record.level >= phoenix.player.Progression.maxLevel) record.experience = phoenix.player.Progression.expForLevel(phoenix.player.Progression.maxLevel)
		phoenix.player.Progression._persistRecord(record)

		phoenix.player.Hud.pushSnapshot(playerId)
	}

	function _applyLevelUpStats(playerId, record) {
		record.hpMax += 10
		record.staminaMax += 5
		if (record.klass == 1) record.manaMax += 8
		else record.manaMax += 2
		record.learnPoints += 10
		try { setPlayerMaxHealth(playerId, record.hpMax) } catch (e) {}
		try { setPlayerHealth(playerId, record.hpMax) } catch (e) {}
		try { setPlayerMaxMana(playerId, record.manaMax) } catch (e) {}
		try { setPlayerMana(playerId, record.manaMax) } catch (e) {}
		record.hp = record.hpMax
		record.mana = record.manaMax
		record.stamina = record.staminaMax
		try { phoenix.player.Combat.emitText(playerId, 0, "levelup") } catch (e) {}
	}
}
