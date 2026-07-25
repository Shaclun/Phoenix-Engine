phoenix.player.Resources <- {
	function max(record, kind, playerId = -1) {
		if (record == null) return 0
		local value = 0
		if (kind == "hp") value = record.hpMax
		else if (kind == "mana") value = record.manaMax
		else if (kind == "stamina") value = record.staminaMax
		if (playerId >= 0) {
			try { value += phoenix.item.Effects.modifier(playerId, kind + "Max") } catch (e) {}
		}
		return value > 0 ? value.tointeger() : 0
	}

	function clamp(record, kind, value, playerId = -1) {
		local maximum = phoenix.player.Resources.max(record, kind, playerId)
		local out = value.tofloat()
		if (out < 0.0) out = 0.0
		if (out > maximum) out = maximum.tofloat()
		return out
	}

	function current(playerId, record, kind) {
		local value = 0
		try {
			if (kind == "hp") value = getPlayerHealth(playerId)
			else if (kind == "mana") value = getPlayerMana(playerId)
			else if (kind == "stamina") return phoenix.player.Hud._getStamina(playerId, record)
		} catch (e) {
			if (kind == "hp") value = record.hp
			else if (kind == "mana") value = record.mana
			else value = record.stamina
		}
		return phoenix.player.Resources.clamp(record, kind, value, playerId).tointeger()
	}
	function set(playerId, record, kind, value, syncRuntime = true) {
		if (record == null) return 0
		local out = phoenix.player.Resources.clamp(record, kind, value, playerId)
		local integerValue = out.tointeger()
		if (kind == "hp") record.hp = integerValue
		else if (kind == "mana") record.mana = integerValue
		else if (kind == "stamina") {
			record.stamina = integerValue
			try { phoenix.player.Hud._setStamina(playerId, record, out) } catch (e) {}
		}
		if (syncRuntime) {
			try {
				if (kind == "hp") setPlayerHealth(playerId, integerValue)
				else if (kind == "mana") setPlayerMana(playerId, integerValue)
			} catch (e) {}
		}
		return integerValue
	}

	function add(playerId, record, kind, amount) {
		local current = phoenix.player.Resources.current(playerId, record, kind)
		return phoenix.player.Resources.set(playerId, record, kind, current.tofloat() + amount.tofloat(), true)
	}

	function syncMaximums(playerId, record) {
		if (record == null) return
		local hpMax = phoenix.player.Resources.max(record, "hp", playerId)
		local manaMax = phoenix.player.Resources.max(record, "mana", playerId)
		try { setPlayerMaxHealth(playerId, hpMax) } catch (e) {}
		try { setPlayerMaxMana(playerId, manaMax) } catch (e) {}
		phoenix.player.Resources.set(playerId, record, "hp", phoenix.player.Resources.current(playerId, record, "hp"), true)
		phoenix.player.Resources.set(playerId, record, "mana", phoenix.player.Resources.current(playerId, record, "mana"), true)
	}
}
