phoenix.player.Hotbar <- {
	bySession = {}
	lastActivate = {}

	function pushSnapshot(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		local raw = (record.hotbar != null) ? record.hotbar.tostring() : ""
		phoenix.player.Hotbar.bySession[playerId] <- phoenix.player.Hotbar._parseSlots(raw)
		local m = phoenix.player.Message.HotbarSnapshot()
		m.data = raw
		try { m.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function _parseSlots(raw) {
		local slots = [null, null, null, null, null, null, null, null]
		if (raw == null || raw == "") return slots
		try {
			if (raw.len() > 0 && raw[0] == '[') {
				phoenix.player.Hotbar._parseJsonSlots(raw, slots)
			} else {
				local parts = split(raw, "|")
				for (local i = 0; i < 8 && i < parts.len(); i++) {
					if (parts[i] == null || parts[i] == "") { slots[i] = null; continue }
					slots[i] = { instance = parts[i].tostring() }
				}
			}
		} catch (e) {}
		return slots
	}

	function _parseJsonSlots(raw, slots) {
		local pos = 0
		local slotIdx = 0
		local len = raw.len()
		while (pos < len && slotIdx < 8) {
			while (pos < len && (raw[pos] == ' ' || raw[pos] == ',' || raw[pos] == '[' || raw[pos] == '\t')) pos++
			if (pos >= len || raw[pos] == ']') break
			if (raw[pos] == 'n') {
				slots[slotIdx] = null
				pos += 4
				slotIdx++
				continue
			}
			if (raw[pos] == '{') {
				local end = raw.find("}", pos)
				if (end == null) break
				local obj = raw.slice(pos, end + 1)
				local instStart = obj.find("\"instance\"")
				if (instStart != null) {
					local colon = obj.find(":", instStart)
					if (colon != null) {
						local q1 = obj.find("\"", colon + 1)
						if (q1 != null) {
							local q2 = obj.find("\"", q1 + 1)
							if (q2 != null) {
								local inst = obj.slice(q1 + 1, q2)
								slots[slotIdx] = { instance = inst }
							}
						}
					}
				}
				pos = end + 1
				slotIdx++
				continue
			}
			pos++
		}
	}

	function onUpdate(playerId, message) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		local raw = (message.data != null) ? message.data.tostring() : ""
		if (raw.len() > 4096) raw = raw.slice(0, 4096)
		record.hotbar = raw
		phoenix.player.Hotbar.bySession[playerId] <- phoenix.player.Hotbar._parseSlots(raw)
		try { record.saveAsync(function(_) {}) } catch (e) {}
	}

	function setDefaults(record, weapon1h, ranged) {
		local slots = [null, null, null, null, null, null, null, null]
		if (weapon1h != null && weapon1h != "") {
			slots[0] = { instance = weapon1h, name = "", visual = "", category = 0, onUse = false }
		}
		if (ranged != null && ranged != "") {
			slots[1] = { instance = ranged, name = "", visual = "", category = 0, onUse = false }
		}
		local parts = []
		foreach (s in slots) {
			if (s == null) parts.append("null")
			else {
				local inst = s.instance.tostring()
				parts.append("{\"instance\":\"" + inst + "\",\"name\":\"\",\"visual\":\"\",\"category\":0,\"onUse\":false}")
			}
		}
		local result = ""
		foreach (i, p in parts) {
			if (i > 0) result += ","
			result += p
		}
		record.hotbar = "[" + result + "]"
	}

	function _modeForCategory(category) {
		if (category == PhoenixItemCategory.Weapon2H) return WEAPONMODE_2HS
		if (category == PhoenixItemCategory.Bow) return WEAPONMODE_BOW
		if (category == PhoenixItemCategory.Crossbow) return WEAPONMODE_CBOW
		if (category == PhoenixItemCategory.Weapon1H) return WEAPONMODE_1HS
		return WEAPONMODE_NONE
	}

	function _checkRequirements(playerId, scheme) {
		if (scheme == null || scheme.requirement == null) return true
		foreach (r in scheme.requirement) {
			if (r == null) continue
			local attr = ("attr" in r && r.attr != null) ? r.attr.tostring() : ""
			local val = ("value" in r) ? r.value.tointeger() : 0
			if (attr == "" || val <= 0) continue
			local cur = 0
			try {
				if (attr == "strength") cur = getPlayerStrength(playerId)
				else if (attr == "dexterity") cur = getPlayerDexterity(playerId)
			} catch (e) {}
			if (cur < val) {
				try { phoenix.notification.notify(playerId, "error", "Wymagania", "Brak " + attr + " " + val, 2800) } catch (e2) {}
				return false
			}
		}
		return true
	}

	function onActivate(playerId, message) {
		local slotIdx = message.slot.tointeger()
		if (slotIdx < 0 || slotIdx > 7) return
		local now = getTickCount()
		if (playerId in phoenix.player.Hotbar.lastActivate) {
			if (now - phoenix.player.Hotbar.lastActivate[playerId] < 600) {
				return
			}
		}
		phoenix.player.Hotbar.lastActivate[playerId] <- now
		local slots = (playerId in phoenix.player.Hotbar.bySession)
			? phoenix.player.Hotbar.bySession[playerId]
			: null
		if (slots == null) return
		local entry = slots[slotIdx]
		if (entry == null) return
		local inst = null
		try { if ("instance" in entry) inst = entry.instance } catch (e) {}
		if (inst == null || inst == "") return

		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return
		local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
		if (inv == null) return
		local target = null
		foreach (rec in inv.items) {
			if (rec.instanceId == null) continue
			if (rec.instanceId.toupper() != inst.toupper()) continue
			if (target == null) target = rec
			else if (rec.equipped == 1) target = rec
		}
		if (target == null) return

		local scheme = phoenix.item.find(target.instanceId)
		if (scheme == null) return
		local category = scheme.category
		local mode = phoenix.player.Hotbar._modeForCategory(category)
		local isWeapon = mode != WEAPONMODE_NONE
		local isEquipment = category >= PhoenixItemCategory.Weapon1H && category <= PhoenixItemCategory.Belt

		if (isWeapon) {
			phoenix.player.Hotbar._useWeapon(playerId, active.id, target, scheme, mode)
		} else if (isEquipment) {
			local want = target.equipped == 1 ? false : true
			if (want && !phoenix.player.Hotbar._checkRequirements(playerId, scheme)) return
			local capturedInst = target.instanceId
			phoenix.item.Structure.setEquipped(PhoenixInventoryOwner.Player, active.id, target.id, want, function(ok) {
				if (!ok) return
				if (want) {
					try { ::giveItem(playerId, capturedInst, 1) } catch (e) {}
					try { ::equipItem(playerId, capturedInst) } catch (e) {}
				} else {
					try { ::unequipItem(playerId, capturedInst) } catch (e) {}
					try { ::removeItem(playerId, capturedInst, 1) } catch (e) {}
				}
			})
		} else {
			local useMsg = phoenix.item.Message.UseRequest()
			useMsg.id = target.id
			phoenix.item.Handlers.onUseRequest(playerId, useMsg)
		}
	}

	function _useWeapon(playerId, characterId, target, scheme, mode) {
		local current = WEAPONMODE_NONE
		try { current = getPlayerWeaponMode(playerId) } catch (e) {}
		if (target.equipped == 1) {
			if (current == mode) {
				try { setPlayerWeaponMode(playerId, 0) } catch (e) {}
			} else if (current != WEAPONMODE_NONE) {
				try { setPlayerWeaponMode(playerId, 0) } catch (e) {}
				setTimer(function() {
					try { drawWeapon(playerId, mode) } catch (e) {}
				}, 400, 1)
			} else {
				try { drawWeapon(playerId, mode) } catch (e) {}
			}
			return
		}

		if (!phoenix.player.Hotbar._checkRequirements(playerId, scheme)) return

		local capturedPid = playerId
		local capturedCid = characterId
		local capturedTargetId = target.id
		local capturedInst = target.instanceId
		local capturedScheme = scheme
		local capturedMode = mode

		local needsSheathe = current != WEAPONMODE_NONE
		if (needsSheathe) {
			try { drawWeapon(capturedPid, WEAPONMODE_NONE) } catch (e) {}
		}

		setTimer(function() {
			try { setPlayerWeaponMode(capturedPid, 0) } catch (e) {}
			phoenix.player.Hotbar._swapEquippedWeapon(capturedPid, capturedCid, capturedTargetId, capturedInst, capturedScheme, function(ok) {
				if (!ok) return
				setTimer(function() {
					try { drawWeapon(capturedPid, capturedMode) } catch (e) {}
				}, 250, 1)
			})
		}, needsSheathe ? 900 : 50, 1)
	}

	function _swapEquippedWeapon(playerId, characterId, targetId, targetInst, scheme, callback) {
		local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, characterId)
		if (inv == null) { callback(false); return }

		local toUnequip = []
		foreach (rec in inv.items) {
			if (rec.id == targetId) continue
			if (rec.equipped != 1) continue
			if (rec.slot != scheme.slot) continue
			toUnequip.append({ id = rec.id, instance = rec.instanceId })
		}

		local unequipNext = null
		unequipNext = function(i) {
			if (i >= toUnequip.len()) {
				phoenix.item.Structure.setEquipped(PhoenixInventoryOwner.Player, characterId, targetId, true, function(ok) {
					if (ok) {
						try { ::giveItem(playerId, targetInst, 1) } catch (e) {}
						try { ::equipItem(playerId, targetInst) } catch (e) {}
					}
					callback(ok)
				})
				return
			}
			local entry = toUnequip[i]
			local prevInst = entry.instance
			phoenix.item.Structure.setEquipped(PhoenixInventoryOwner.Player, characterId, entry.id, false, function(_) {
				try { ::unequipItem(playerId, prevInst) } catch (e) {}
				try { ::removeItem(playerId, prevInst, 1) } catch (e) {}
				unequipNext(i + 1)
			})
		}
		unequipNext(0)
	}
}

phoenix.player.Hotbar.onDrawWeapon <- function(playerId, message) {
	local mode = message.mode.tointeger()
	local current = 0
	try { current = getPlayerWeaponMode(playerId) } catch (e) {}
	if (current == mode) {
		try { drawWeapon(playerId, WEAPONMODE_NONE) } catch (e) {}
	} else {
		try { drawWeapon(playerId, mode) } catch (e) {}
	}
}

phoenix.player.Message.HotbarUpdate.bind(phoenix.player.Hotbar.onUpdate)
phoenix.player.Message.HotbarActivate.bind(phoenix.player.Hotbar.onActivate)
phoenix.player.Message.DrawWeaponRequest.bind(phoenix.player.Hotbar.onDrawWeapon)

addEventHandler("phoenix.character.OnSelected", function(playerId, _characterId) {
	setTimer(function() {
		try { phoenix.player.Hotbar.pushSnapshot(playerId) } catch (e) {}
	}, 500, 1)
})

addEventHandler("onPlayerDisconnect", function(playerId, _reason) {
	if (playerId in phoenix.player.Hotbar.bySession) phoenix.player.Hotbar.bySession.rawdelete(playerId)
	if (playerId in phoenix.player.Hotbar.lastActivate) phoenix.player.Hotbar.lastActivate.rawdelete(playerId)
})
