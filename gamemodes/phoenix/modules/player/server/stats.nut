phoenix.player.Stats <- {

	// Stat caps + base costs (in learn points). Trainer NPCs may grant cheaper rates.
	caps = {
		strength = 200, dexterity = 200,
		hpMax = 1000, manaMax = 500
	}
	cost = {
		strength = 1, dexterity = 1,
		hpMax = 1, manaMax = 1
	}
	hpPerPoint = 5
	manaPerPoint = 5

	function _u16(value) {
		local out = 0
		try { out = value.tointeger() } catch (e) {}
		if (out < 0) return 0
		if (out > 65535) return 65535
		return out
	}

	function pushSnapshot(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		phoenix.player.Progression.normalizeRecordStats(record)
		local hp = phoenix.player.Resources.current(playerId, record, "hp")
		local mana = phoenix.player.Resources.current(playerId, record, "mana")
		local m = phoenix.player.Message.StatsSnapshot()
		m.level = phoenix.player.Stats._u16(record.level)
		m.experience = record.experience
		m.experienceNext = record.experienceNext > 0 ? record.experienceNext : phoenix.player.Progression.expForLevel(record.level + 1)
		m.learnPoints = phoenix.player.Stats._u16(record.learnPoints)
		m.hp = phoenix.player.Stats._u16(hp)
		m.hpMax = phoenix.player.Stats._u16(phoenix.player.Resources.max(record, "hp", playerId))
		m.mana = phoenix.player.Stats._u16(mana)
		m.manaMax = phoenix.player.Stats._u16(phoenix.player.Resources.max(record, "mana", playerId))
		m.stamina = phoenix.player.Stats._u16(record.stamina)
		m.staminaMax = phoenix.player.Stats._u16(record.staminaMax)
		m.strength = phoenix.player.Stats._u16(record.strength + phoenix.item.Effects.modifier(playerId, "strength"))
		m.dexterity = phoenix.player.Stats._u16(record.dexterity + phoenix.item.Effects.modifier(playerId, "dexterity"))
		m.oneHand = phoenix.player.Stats._u16(record.oneHand)
		m.twoHand = phoenix.player.Stats._u16(record.twoHand)
		m.bow = phoenix.player.Stats._u16(record.bow)
		m.crossbow = phoenix.player.Stats._u16(record.crossbow)
		try { m.magicLevel = phoenix.player.Stats._u16(("magicLevel" in record && record.magicLevel != null) ? record.magicLevel : 0) } catch (e) { m.magicLevel = 0 }
		try { m.magicXp    = ("magicXp"    in record && record.magicXp    != null) ? record.magicXp    : 0 } catch (e) { m.magicXp = 0 }
		try { m.magicXpNext = phoenix.item.Spells != null ? phoenix.item.Spells.xpToNext(m.magicLevel) : 0 } catch (e) { m.magicXpNext = 20 + m.magicLevel * m.magicLevel * 3 }
		m.gold = phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, record.id, "ITMI_GOLD")
		try { m.weaponProgress = phoenix.player.WeaponProgression.progressString(playerId) } catch (e) { m.weaponProgress = "" }
		m.serialize().send(playerId, RELIABLE_ORDERED)
	}

	function reply(playerId, ok, err) {
		local r = phoenix.player.Message.StatsResult()
		r.success = ok
		r.error = err == null ? "" : err
		r.serialize().send(playerId, RELIABLE_ORDERED)
	}

	function _statValue(record, stat) {
		switch (stat) {
			case "strength": return record.strength
			case "dexterity": return record.dexterity
			case "hpMax": return record.hpMax
			case "manaMax": return record.manaMax
		}
		return -1
	}

	function _setStatValue(record, stat, value) {
		switch (stat) {
			case "strength": record.strength = value; return
			case "dexterity": record.dexterity = value; return
			case "hpMax": record.hpMax = value; return
			case "manaMax": record.manaMax = value; return
		}
	}

	function persistRecord(record) {
		if (record == null || record.id <= 0) return
		phoenix.player.Progression.normalizeRecordStats(record)
		local sql = "UPDATE `phoenix_characters` SET `learnPoints` = " + record.learnPoints + ", `strength` = " + record.strength + ", `dexterity` = " + record.dexterity + ", `hpMax` = " + record.hpMax + ", `hp` = " + record.hp + ", `manaMax` = " + record.manaMax + ", `mana` = " + record.mana + " WHERE `id` = " + record.id
		try { ORM.engine.executeAsync(sql, function(_) {}) } catch (e) {}
	}

	// Spend learn points to raise a stat. amount: how many points to spend (each grants +1 stat * unitFor(stat)).
	// Returns null on success, error key on failure.
	function spend(playerId, stat, amount) {
		if (!phoenix.features.Settings.isEnabled("progression.statsSpending")) return "featureDisabled"
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return "noCharacter"
		phoenix.player.Progression.normalizeRecordStats(record)
		if (!(stat in phoenix.player.Stats.cost)) return "unknownStat"
		if (amount <= 0) return "unknownStat"
		local cost = phoenix.player.Stats.cost[stat] * amount
		if (record.learnPoints < cost) return "noLearnPoints"
		local cap = phoenix.player.Stats.caps[stat]
		local cur = phoenix.player.Stats._statValue(record, stat)
		local unit = (stat == "hpMax") ? phoenix.player.Stats.hpPerPoint : ((stat == "manaMax") ? phoenix.player.Stats.manaPerPoint : 1)
		local newVal = cur + amount * unit
		if (newVal > cap) return "atCap"
		phoenix.player.Stats._setStatValue(record, stat, newVal)
		record.learnPoints -= cost
		// Apply derived effects.
		if (stat == "hpMax") {
			record.hp = record.hpMax
			phoenix.player.Resources.syncMaximums(playerId, record)
			phoenix.player.Resources.set(playerId, record, "hp", record.hpMax, true)
		} else if (stat == "manaMax") {
			record.mana = record.manaMax
			phoenix.player.Resources.syncMaximums(playerId, record)
			phoenix.player.Resources.set(playerId, record, "mana", record.manaMax, true)
		} else if (stat == "strength") {
			try { setPlayerStrength(playerId, record.strength) } catch (e) {}
		} else if (stat == "dexterity") {
			try { setPlayerDexterity(playerId, record.dexterity) } catch (e) {}
		}
		phoenix.player.Stats.persistRecord(record)
		try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e) {}
		return null
	}

	function onRequest(playerId, _message) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		try {
			phoenix.player.WeaponProgression.load(playerId, record.id, function(_) {
				try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e2) {}
			})
		} catch (e) { try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e3) {} }
	}

	function onSpend(playerId, message) {
		if (!phoenix.features.Settings.isEnabled("progression.statsSpending")) return
		local stat = message.stat
		local amount = message.amount.tointeger()
		if (amount > 50) amount = 50
		local err = phoenix.player.Stats.spend(playerId, stat, amount)
		phoenix.player.Stats.reply(playerId, err == null, err)
		if (err == null) phoenix.player.Stats.pushSnapshot(playerId)
	}
}

phoenix.player.Message.StatsRequest.bind(phoenix.player.Stats.onRequest)
phoenix.player.Message.StatsSpend.bind(phoenix.player.Stats.onSpend)
