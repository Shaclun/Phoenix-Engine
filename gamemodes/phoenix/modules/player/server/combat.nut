phoenix.player.Combat <- {
	MIN_DAMAGE = 1
	MAX_PROTECTION = 85.0

	function _roll(chance) {
		if (chance <= 0.0) return false
		local limited = chance
		if (limited > 95.0) limited = 95.0
		local value = (rand() % 10000) / 100.0
		return value < limited
	}

	function _activeRecord(playerId) {
		try { return phoenix.character.Structure.getActive(playerId) } catch (e) {}
		return null
	}

	function _npcEntry(playerId) {
		try { return phoenix.npc.Spawn._liveByNpcId(playerId) } catch (e) {}
		return null
	}

	function _weaponKeyFromMode(mode) {
		try { return phoenix.player.WeaponProgression.keyFromMode(mode) } catch (e) {}
		return null
	}

	function _weaponSlotFromMode(mode) {
		try { if (mode == WEAPONMODE_BOW || mode == WEAPONMODE_CBOW) return PhoenixItemSlot.Ranged } catch (e) {}
		return PhoenixItemSlot.MainHand
	}

	function _equipped(playerId, slot) {
		local record = phoenix.player.Combat._activeRecord(playerId)
		if (record == null) return null
		local inv = null
		try { inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, record.id) } catch (e) { inv = null }
		if (inv == null) return null
		foreach (rec in inv.items) {
			if (rec.equipped != 1 || rec.slot != slot) continue
			local scheme = phoenix.item.Structure.schemeOf(rec)
			if (scheme == null) continue
			return { record = rec, scheme = scheme, stats = phoenix.item.computeStats(scheme, rec.quality, rec.upgrade) }
		}
		return null
	}

	function _damageKey(damageType) {
		switch (damageType) {
			case PhoenixDamageType.Blunt: return "blunt"
			case PhoenixDamageType.Point: return "point"
			case PhoenixDamageType.Fire: return "fire"
			case PhoenixDamageType.Magic: return "magic"
		}
		return "edge"
	}

	function _protection(playerId, damageType) {
		local item = phoenix.player.Combat._equipped(playerId, PhoenixItemSlot.Armor)
		if (item == null || item.stats == null || item.stats.protection == null) return 0.0
		local key = phoenix.player.Combat._damageKey(damageType)
		local value = 0.0
		try { if (key in item.stats.protection) value = item.stats.protection[key].tofloat() } catch (e) { value = 0.0 }
		if (value < 0.0) value = 0.0
		if (value > phoenix.player.Combat.MAX_PROTECTION) value = phoenix.player.Combat.MAX_PROTECTION
		return value
	}

	function _baseDamageFromDescription(desc) {
		local dmg = 0.0
		try { if (desc != null && "damage" in desc) dmg = desc.damage.tofloat() } catch (e) {}
		try { if (dmg <= 0.0 && desc != null && "rawDamage" in desc) dmg = desc.rawDamage.tofloat() } catch (e2) {}
		try {
			if (dmg <= 0.0 && desc != null && "damageByType" in desc && desc.damageByType != null) {
				foreach (_type, value in desc.damageByType) dmg += value.tofloat()
			}
		} catch (e3) {}
		return dmg
	}

	function _skill(attackerId, key) {
		if (key == null) return 0
		try {
			if (attackerId in phoenix.player.WeaponProgression.byPlayer) return phoenix.player.WeaponProgression.byPlayer[attackerId][key].level
		} catch (e) {}
		local record = phoenix.player.Combat._activeRecord(attackerId)
		if (record == null) return 0
		try { return phoenix.player.WeaponProgression._readRecordValue(record, key) } catch (e2) {}
		return 0
	}

	function _attribute(attackerId, key) {
		local value = 10
		if (key == "bow") { try { value = getPlayerDexterity(attackerId) } catch (e) {} }
		else { try { value = getPlayerStrength(attackerId) } catch (e2) {} }
		if (value < 0) value = 0
		return value
	}

	function _defenderDexterity(defenderId) {
		local value = 10
		try { value = getPlayerDexterity(defenderId) } catch (e) {}
		if (value < 0) value = 0
		return value
	}

	function _weaponDamage(attackerId, mode, fallback) {
		local item = phoenix.player.Combat._equipped(attackerId, phoenix.player.Combat._weaponSlotFromMode(mode))
		if (item != null && item.stats != null && item.stats.damage > 0) {
			return { damage = item.stats.damage.tofloat(), type = item.scheme.damageType, item = item.record }
		}
		local value = fallback
		if (value <= 0.0) {
			try { value = getPlayerStrength(attackerId).tofloat() } catch (e) { value = 10.0 }
		}
		if (value <= 0.0) value = 10.0
		return { damage = value, type = PhoenixDamageType.Edge, item = null }
	}

	function _npcDamage(attackerId, fallback) {
		local entry = phoenix.player.Combat._npcEntry(attackerId)
		if (entry != null && entry.row != null) {
			local dmg = 0.0
			try { dmg = entry.row.attackDamage.tofloat() } catch (e) { dmg = 0.0 }
			if (dmg > 0.0) return { damage = dmg, type = PhoenixDamageType.Edge, item = null }
		}
		if (fallback > 0.0) return { damage = fallback, type = PhoenixDamageType.Edge, item = null }
		return { damage = 10.0, type = PhoenixDamageType.Edge, item = null }
	}

	function calculate(attackerId, victimId, desc = null, fallbackDamage = 0) {
		local summary = { finalDamage = 0, rawDamage = 0, protection = 0, miss = false, dodged = false, critical = false, skill = 0, attribute = 0, weaponKey = null, damageType = PhoenixDamageType.Edge }
		if (attackerId == null || attackerId < 0) return summary
		local fallback = fallbackDamage == null ? 0.0 : fallbackDamage.tofloat()
		if (fallback <= 0.0) fallback = phoenix.player.Combat._baseDamageFromDescription(desc)
		local mode = 0
		try { mode = getPlayerWeaponMode(attackerId) } catch (e) { mode = 0 }
		local key = phoenix.player.Combat._weaponKeyFromMode(mode)
		local data = null
		if (phoenix.player.Combat._activeRecord(attackerId) != null) data = phoenix.player.Combat._weaponDamage(attackerId, mode, fallback)
		else data = phoenix.player.Combat._npcDamage(attackerId, fallback)
		local skill = phoenix.player.Combat._skill(attackerId, key)
		local attribute = phoenix.player.Combat._attribute(attackerId, key)
		local defenderDex = phoenix.player.Combat._defenderDexterity(victimId)
		local missChance = 18.0 - skill * 0.12 - attribute * 0.025
		if (missChance < 3.0) missChance = 3.0
		if (missChance > 28.0) missChance = 28.0
		if (phoenix.player.Combat._roll(missChance)) { summary.miss = true; return summary }
		local dodgeChance = defenderDex * 0.035 - skill * 0.025
		if (dodgeChance < 0.0) dodgeChance = 0.0
		if (dodgeChance > 18.0) dodgeChance = 18.0
		if (phoenix.player.Combat._roll(dodgeChance)) { summary.dodged = true; return summary }
		local critChance = 5.0 + skill * 0.18
		if (critChance > 28.0) critChance = 28.0
		local critical = phoenix.player.Combat._roll(critChance)
		local protection = phoenix.player.Combat._protection(victimId, data.type)
		local protectedDamage = data.damage * (1.0 - protection / 100.0)
		local skillMultiplier = 0.75 + skill * 0.0055
		local attributeMultiplier = 1.0 + attribute * 0.0045
		local criticalMultiplier = critical ? 1.6 : 1.0
		local total = protectedDamage * skillMultiplier * attributeMultiplier * criticalMultiplier + attribute * 0.12
		if (total < phoenix.player.Combat.MIN_DAMAGE) total = phoenix.player.Combat.MIN_DAMAGE
		summary.finalDamage = total.tointeger()
		summary.rawDamage = data.damage.tointeger()
		summary.protection = protection.tointeger()
		summary.critical = critical
		summary.skill = skill
		summary.attribute = attribute
		summary.weaponKey = key
		summary.damageType = data.type
		return summary
	},

	function emitText(targetId, amount, kind) {
		if (!phoenix.features.Settings.isEnabled("player.combatText")) return
		if (targetId == null || targetId < 0) return
		local value = 0
		try { value = amount.tointeger() } catch (e) { value = 0 }
		local label = "damage"
		try { label = kind.tostring() } catch (e2) { label = "damage" }
		if (label != "damage" && label != "crit" && label != "miss" && label != "dodge" && label != "levelup") label = "damage"
		local maxSlots = getMaxSlots()
		for (local playerId = 0; playerId < maxSlots; playerId++) {
			try {
				if (!isPlayerConnected(playerId)) continue
				local msg = phoenix.player.Message.CombatText()
				msg.targetId = targetId
				msg.amount = value
				msg.kind = label
				msg.serialize().send(playerId, RELIABLE_ORDERED)
			} catch (e3) {}
		}
	}
}