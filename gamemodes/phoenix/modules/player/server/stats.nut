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

	function pushSnapshot(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		phoenix.player.Progression.normalizeRecordStats(record)
		local hp = record.hp
		try { hp = getPlayerHealth(playerId) } catch (e) {}
		local mana = record.mana
		try { mana = getPlayerMana(playerId) } catch (e) {}
		local m = phoenix.player.Message.StatsSnapshot()
		m.level = record.level
		m.experience = record.experience
		m.experienceNext = record.experienceNext > 0 ? record.experienceNext : phoenix.player.Progression.expForLevel(record.level + 1)
		m.learnPoints = record.learnPoints
		m.hp = hp < 0 ? 0 : hp
		m.hpMax = record.hpMax
		m.mana = mana < 0 ? 0 : mana
		m.manaMax = record.manaMax
		m.stamina = record.stamina
		m.staminaMax = record.staminaMax
		m.strength = record.strength
		m.dexterity = record.dexterity
		m.oneHand = record.oneHand
		m.twoHand = record.twoHand
		m.bow = record.bow
		m.crossbow = record.crossbow
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
			try { setPlayerMaxHealth(playerId, record.hpMax) } catch (e) {}
			record.hp = record.hpMax
			try { setPlayerHealth(playerId, record.hpMax) } catch (e) {}
		} else if (stat == "manaMax") {
			try { setPlayerMaxMana(playerId, record.manaMax) } catch (e) {}
			record.mana = record.manaMax
			try { setPlayerMana(playerId, record.manaMax) } catch (e) {}
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
