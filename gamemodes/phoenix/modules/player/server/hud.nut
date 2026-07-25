phoenix.player.Hud <- {
	staminaState = {}
	sittingState = {}
	staminaTickInterval = 250

	function pushSnapshot(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		phoenix.player.Progression.normalizeRecordStats(record)
		local hpMax = phoenix.player.Resources.max(record, "hp", playerId)
		local hp = phoenix.player.Resources.current(playerId, record, "hp")
		local manaMax = phoenix.player.Resources.max(record, "mana", playerId)
		local mana = phoenix.player.Resources.current(playerId, record, "mana")

		local stamina = phoenix.player.Hud._getStamina(playerId, record)
		local staminaMax = record.staminaMax > 0 ? record.staminaMax : 100

		local msg = phoenix.player.Message.HudSnapshot()
		msg.name = record.name
		msg.level = record.level
		msg.experience = record.experience
		msg.experienceNext = record.experienceNext > 0 ? record.experienceNext : phoenix.player.Progression.expForLevel(record.level + 1)
		msg.hp = hp
		msg.hpMax = hpMax
		msg.mana = mana
		msg.manaMax = manaMax
		msg.stamina = stamina
		msg.staminaMax = staminaMax
		try { msg.magicLevel = ("magicLevel" in record && record.magicLevel != null) ? record.magicLevel : 0 } catch (eMl) { msg.magicLevel = 0 }
		try { msg.magicXp    = ("magicXp"    in record && record.magicXp    != null) ? record.magicXp    : 0 } catch (eMx) { msg.magicXp = 0 }
		try { msg.magicXpNext = phoenix.item.Spells != null ? phoenix.item.Spells.xpToNext(msg.magicLevel) : 0 } catch (eMxn) { msg.magicXpNext = 20 + msg.magicLevel * msg.magicLevel * 3 }
		try { msg.weaponProgress = phoenix.player.WeaponProgression.progressString(playerId) } catch (e) { msg.weaponProgress = "" }
		try { msg.headModel = (record.headModel != null) ? record.headModel.tostring() : "" } catch (eHm) { msg.headModel = "" }
		try { msg.bodyModel = (record.bodyModel != null) ? record.bodyModel.tostring() : "" } catch (eBm) { msg.bodyModel = "" }
		try { msg.bodyTexIndex = (record.bodyTexIndex != null) ? record.bodyTexIndex.tointeger() : 0 } catch (eBti) { msg.bodyTexIndex = 0 }
		try { msg.face = (record.face != null) ? record.face.tointeger() : 0 } catch (eFc) { msg.face = 0 }
		try { msg.gender = (record.gender != null) ? record.gender.tointeger() : 1 } catch (eGn) { msg.gender = 1 }
		msg.serialize().send(playerId, RELIABLE_ORDERED)
	}

	function _getStamina(playerId, record) {
		if (!(playerId in phoenix.player.Hud.staminaState)) {
			local current = (record.stamina != null && record.stamina >= 0) ? record.stamina.tofloat() : (record.staminaMax > 0 ? record.staminaMax.tofloat() : 100.0)
			local maxV = record.staminaMax > 0 ? record.staminaMax.tofloat() : 100.0
			if (current < 0.0) current = 0.0
			if (current > maxV) current = maxV
			phoenix.player.Hud.staminaState[playerId] <- {
				value = current
				last = getTickCount()
				lastX = null
				lastY = null
				lastZ = null
			}
		}
		return phoenix.player.Hud.staminaState[playerId].value.tointeger()
	}

	function _setStamina(playerId, record, value) {
		local maxV = record.staminaMax > 0 ? record.staminaMax.tofloat() : 100.0
		if (value < 0) value = 0
		if (value > maxV) value = maxV
		if (!(playerId in phoenix.player.Hud.staminaState)) {
			phoenix.player.Hud.staminaState[playerId] <- { value = value, last = getTickCount(), lastX = null, lastY = null, lastZ = null }
		} else {
			phoenix.player.Hud.staminaState[playerId].value = value
		}
		record.stamina = value.tointeger()
	}

	function consumeStamina(playerId, amount) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return false
		local cur = phoenix.player.Hud._getStamina(playerId, record).tofloat()
		if (cur < amount) return false
		phoenix.player.Hud._setStamina(playerId, record, cur - amount)
		try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e) {}
		return true
	}

	function tickAll() {
		local now = getTickCount()
		for (local pid = 0; pid < getMaxSlots(); pid += 1) {
			if (!isPlayerConnected(pid)) continue
			local record = phoenix.character.Structure.getActive(pid)
			if (record == null) continue

			local maxV = record.staminaMax > 0 ? record.staminaMax.tofloat() : 100.0
			if (!(pid in phoenix.player.Hud.staminaState)) {
				local current = (record.stamina != null && record.stamina >= 0) ? record.stamina.tofloat() : maxV
				if (current < 0.0) current = 0.0
				if (current > maxV) current = maxV
				phoenix.player.Hud.staminaState[pid] <- {
					value = current
					last = now
					lastX = null
					lastY = null
					lastZ = null
				}
			}
			local state = phoenix.player.Hud.staminaState[pid]
			local dt = (now - state.last) / 1000.0
			if (dt < 0.0) dt = 0.0
			if (dt > 2.0) dt = 2.0
			state.last = now

			local sitting = pid in phoenix.player.Hud.sittingState
			try {
				local pos = getPlayerPosition(pid)
				if (pos != null) {
					if (sitting && state.lastX != null && state.lastZ != null) {
						local dx = pos.x - state.lastX
						local dz = pos.z - state.lastZ
						local moved = sqrt(dx * dx + dz * dz)
						if (moved > 30.0) {
							phoenix.player.Hud.setSitting(pid, false)
							sitting = false
						}
					}
					state.lastX = pos.x
					state.lastY = pos.y
					state.lastZ = pos.z
				}
			} catch (epos) {}

			if (sitting && state.value < maxV) {
				state.value += 4.0 * dt
				if (state.value > maxV) state.value = maxV
			}
			if (state.value < 0.0) state.value = 0.0

			record.stamina = state.value.tointeger()
			local staminaRatio = maxV > 0.0 ? (state.value / maxV) : 0.0
			if (staminaRatio >= 0.20) {
				local factor = (staminaRatio - 0.20) / 0.80
				if (factor > 1.0) factor = 1.0
				local inCombat = phoenix.player.Hud._inCombat(pid)
				local hpRate = 0.0
				local manaRate = 0.0
				if (inCombat) {
					hpRate = 0.2 + 0.4 * factor
					manaRate = 0.1 + 0.2 * factor
				} else if (sitting) {
					hpRate = 4.0 + 4.0 * factor
					manaRate = 2.5 + 3.0 * factor
				} else {
					hpRate = 0.8 + 1.2 * factor
					manaRate = 0.4 + 0.8 * factor
				}
				local hpMax = record.hpMax > 0 ? record.hpMax : 100
				local manaMax = record.manaMax > 0 ? record.manaMax : 0
				local rtHpMax = 0
				local rtManaMax = 0
				try { rtHpMax = getPlayerMaxHealth(pid) } catch (erhm) {}
				try { rtManaMax = getPlayerMaxMana(pid) } catch (ermm) {}
				local trustedHp = (rtHpMax > 0) && !(rtHpMax < record.hpMax)
				local trustedMana = (rtManaMax > 0) && !(rtManaMax < record.manaMax)
				local hp = record.hp
				local mana = record.mana
				if (trustedHp) { try { hp = getPlayerHealth(pid) } catch (eh) {} }
				if (trustedMana) { try { mana = getPlayerMana(pid) } catch (em) {} }
				if (trustedHp && hp > 0 && hp < hpMax) {
					hp += hpRate * dt
					phoenix.player.Resources.set(pid, record, "hp", hp, true)
				}
				if (trustedMana && manaMax > 0 && mana >= 0 && mana < manaMax) {
					mana += manaRate * dt
					phoenix.player.Resources.set(pid, record, "mana", mana, true)
				}
			}
			phoenix.player.Hud.pushSnapshot(pid)
		}
	}

	function setSitting(playerId, value) {
		if (value) {
			if (!isPlayerConnected(playerId)) return
			phoenix.player.Hud.sittingState[playerId] <- true
			try { setPlayerWeaponMode(playerId, 0) } catch (e) {}
			try { playAni(playerId, "T_STAND_2_SIT") } catch (e) {}
		} else {
			if (playerId in phoenix.player.Hud.sittingState) phoenix.player.Hud.sittingState.rawdelete(playerId)
			try { stopAni(playerId, "T_STAND_2_SIT") } catch (e) {}
			try { stopAni(playerId, "S_SIT") } catch (e) {}
		}
	}

	function _inCombat(playerId) {
		try {
			if (!(playerId in phoenix.social.Structure.recentCombat)) return false
			return (getTickCount() - phoenix.social.Structure.recentCombat[playerId]) < 5000
		} catch (e) {}
		return false
	}

	function isSitting(playerId) {
		return playerId in phoenix.player.Hud.sittingState
	}

	function onSitToggle(playerId, message) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		local current = playerId in phoenix.player.Hud.sittingState
		local desired = (message != null && "sitting" in message) ? message.sitting : !current
		if (desired == current) return
		phoenix.player.Hud.setSitting(playerId, desired)
		try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e) {}
	}

	function clear(playerId) {
		if (playerId in phoenix.player.Hud.staminaState) phoenix.player.Hud.staminaState.rawdelete(playerId)
		if (playerId in phoenix.player.Hud.sittingState) phoenix.player.Hud.sittingState.rawdelete(playerId)
	}

	function start() {
		setTimer(phoenix.player.Hud.tickAll, phoenix.player.Hud.staminaTickInterval, 0)
	}
}

addEventHandler("onInit", function () {
	setTimer(function () {
		try { phoenix.player.Hud.start() } catch (e) {}
	}, 5000, 1)
})

addEventHandler("phoenix.character.OnSelected", function (playerId, _characterId) {
	setTimer(function () {
		try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e) {}
	}, 800, 1)
})

addEventHandler("onPlayerDisconnect", function (playerId, _reason) {
	phoenix.player.Hud.clear(playerId)
})

phoenix.player.Message.Sit.bind(phoenix.player.Hud.onSitToggle)
