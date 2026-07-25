phoenix.player.Gate <- {
	LOBBY_VIRTUAL_WORLD = (("config" in phoenix) && ("GateSpots" in phoenix.config) && ("LOBBY" in phoenix.config.GateSpots) && ("VIRTUAL_WORLD" in phoenix.config.GateSpots.LOBBY)) ? phoenix.config.GateSpots.LOBBY.VIRTUAL_WORLD : 999
	LOBBY_X = (("config" in phoenix) && ("GateSpots" in phoenix.config) && ("LOBBY" in phoenix.config.GateSpots) && ("X" in phoenix.config.GateSpots.LOBBY)) ? phoenix.config.GateSpots.LOBBY.X : 870.118
	LOBBY_Y = (("config" in phoenix) && ("GateSpots" in phoenix.config) && ("LOBBY" in phoenix.config.GateSpots) && ("Y" in phoenix.config.GateSpots.LOBBY)) ? phoenix.config.GateSpots.LOBBY.Y : -96.2501
	LOBBY_Z = (("config" in phoenix) && ("GateSpots" in phoenix.config) && ("LOBBY" in phoenix.config.GateSpots) && ("Z" in phoenix.config.GateSpots.LOBBY)) ? phoenix.config.GateSpots.LOBBY.Z : -1848.33
	LOBBY_ANGLE = (("config" in phoenix) && ("GateSpots" in phoenix.config) && ("LOBBY" in phoenix.config.GateSpots) && ("ANGLE" in phoenix.config.GateSpots.LOBBY)) ? phoenix.config.GateSpots.LOBBY.ANGLE : 65.1225
	DEATH_REVIVE_DELAY_MS = 10000
	DEATH_REVIVE_HP_PERCENT = 0.10
	pending = {}
	reviving = {}
	applying = {}
	appliedAt = {}

	function normalizeWorld(value) {
		if (value == null || value == "") return "NEWWORLD.ZEN"
		local s = value.tostring()
		local sep = -1
		for (local i = s.len() - 1; i >= 0; i -= 1) {
			local ch = s[i]
			if (ch == '\\' || ch == '/') { sep = i; break }
		}
		if (sep >= 0) s = s.slice(sep + 1)
		local upper = s.toupper()
		local zenAt = upper.find(".ZEN")
		if (zenAt == null) return "NEWWORLD.ZEN"
		local stem = s.slice(0, zenAt)
		local n = stem.len()
		if (n > 0 && (n % 2) == 0) {
			local half = n / 2
			if (stem.slice(0, half).toupper() == stem.slice(half).toupper()) {
				stem = stem.slice(half)
			}
		}
		return stem + s.slice(zenAt)
	}

	function visualGender(record, bodyModel) {
		if (record != null && "gender" in record) {
			if (record.gender == PhoenixCharacterGender.Female) return "female"
			if (record.gender == PhoenixCharacterGender.Male) return "male"
		}
		local body = bodyModel == null ? "" : bodyModel.tostring().toupper()
		return body.find("BABE") != null ? "female" : "male"
	}

	function normalizeVisual(record) {
		local body = (record != null && "bodyModel" in record && record.bodyModel != null && record.bodyModel != "") ? record.bodyModel : "Hum_Body_Naked0"
		local head = (record != null && "headModel" in record && record.headModel != null && record.headModel != "") ? record.headModel : "Hum_Head_Pony"
		local bodyTex = (record != null && "bodyTexIndex" in record && record.bodyTexIndex != null) ? record.bodyTexIndex : 1
		local faceTex = (record != null && "face" in record && record.face != null) ? record.face : 0
		local gender = phoenix.player.Gate.visualGender(record, body)

		if (gender == "female") {
			body = "Hum_Body_Babe0"
			local headUpper = head == null ? "" : head.tostring().toupper()
			if (headUpper.find("BABE") == null && headUpper.find("IVY") == null) head = "Hum_Head_Babe"
			if (bodyTex >= 0 && bodyTex <= 3) bodyTex += 4
			if (faceTex < 137 || faceTex > 158) faceTex = 137
		} else {
			body = "Hum_Body_Naked0"
			local headUpper = head == null ? "" : head.tostring().toupper()
			if (headUpper.find("BABE") != null || headUpper.find("IVY") != null) head = "Hum_Head_Pony"
			if (bodyTex >= 4 && bodyTex <= 7) bodyTex -= 4
			if (faceTex >= 137 && faceTex <= 158) faceTex = 0
		}

		return { body = body, head = head, bodyTex = bodyTex, faceTex = faceTex }
	}

	function isLocked(playerId) {
		return playerId in pending
	}

	function lock(playerId) {
		phoenix.player.Gate.pending[playerId] <- true
		try { setPlayerVirtualWorld(playerId, phoenix.player.Gate.LOBBY_VIRTUAL_WORLD) } catch (e) {}
		try { setPlayerInvisible(playerId, true) } catch (e) {}
		try { setPlayerPosition(playerId, phoenix.player.Gate.LOBBY_X, phoenix.player.Gate.LOBBY_Y, phoenix.player.Gate.LOBBY_Z) } catch (e) {}
		try { setPlayerAngle(playerId, phoenix.player.Gate.LOBBY_ANGLE) } catch (e) {}
		try {
			if (!isPlayerSpawned(playerId)) spawnPlayer(playerId)
		} catch (e) {}
	}

	function release(playerId) {
		if (playerId in phoenix.player.Gate.pending) phoenix.player.Gate.pending.rawdelete(playerId)
	}

	function onPlayerJoin(playerId) {
		phoenix.player.Gate.lock(playerId)
	}

	function onPlayerRespawn(playerId) {
		try { cancelEvent() } catch (e) {}
		if (playerId in phoenix.player.Gate.pending) {
			try { setPlayerPosition(playerId, phoenix.player.Gate.LOBBY_X, phoenix.player.Gate.LOBBY_Y, phoenix.player.Gate.LOBBY_Z) } catch (e) {}
			return
		}
		if (playerId in phoenix.player.Gate.applying) return
		if (playerId in phoenix.player.Gate.reviving) {
			local state = phoenix.player.Gate.reviving[playerId]
			try { setPlayerHealth(playerId, 1) } catch (e) {}
			try { setPlayerPosition(playerId, state.x, state.y, state.z) } catch (e) {}
			try { setPlayerAngle(playerId, state.angle) } catch (e) {}
			try { stopAni(playerId) } catch (e) {}
			try { playAni(playerId, "T_DEADB") } catch (e) {}
			return
		}
		setTimer(function () {
			try { phoenix.player.Gate.restoreVisual(playerId) } catch (e) {}
		}, 200, 1)
	}

	function onPlayerDead(playerId, killerId) {
		try { cancelEvent() } catch (e) {}
		if (playerId in phoenix.player.Gate.pending) return
		if (playerId in phoenix.player.Gate.reviving) return
		if (playerId in phoenix.player.Gate.applying) return
		local deathPos = null
		try { deathPos = getPlayerPosition(playerId) } catch (e) {}
		local deathAngle = 0.0
		try { deathAngle = getPlayerAngle(playerId) } catch (e) {}
		phoenix.player.Gate.reviving[playerId] <- {
			ready = false,
			x = deathPos != null ? deathPos.x : 0.0,
			y = deathPos != null ? deathPos.y : 0.0,
			z = deathPos != null ? deathPos.z : 0.0,
			angle = deathAngle
		}
		try { playAni(playerId, "T_DEADB") } catch (e) {}
		local delay = phoenix.player.Gate.DEATH_REVIVE_DELAY_MS
		try {
			local msg = phoenix.player.Message.KnockedDown()
			msg.secondsRemaining = (delay / 1000)
			msg.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
		setTimer(function () {
			try {
				if (playerId in phoenix.player.Gate.reviving) phoenix.player.Gate.reviving[playerId].ready = true
			} catch (e) {}
		}, delay, 1)
	}

	function _scenarioSpawn(record) {
		try {
			if ("LobbyConfig" in phoenix.player) {
				local raw = phoenix.player.LobbyConfig.cache.characterDefaultSpawn
				if (raw != null && raw != "") {
					local x = phoenix.player.Gate._readJsonNumber(raw, "x")
					local y = phoenix.player.Gate._readJsonNumber(raw, "y")
					local z = phoenix.player.Gate._readJsonNumber(raw, "z")
					local a = phoenix.player.Gate._readJsonNumber(raw, "angle")
					if (x != 0.0 || y != 0.0 || z != 0.0) return { x = x, y = y, z = z, angle = a }
				}
			}
		} catch (e) {}
		if (record != null && "positionX" in record &&
			(record.positionX != 0.0 || record.positionY != 0.0 || record.positionZ != 0.0)) {
			return { x = record.positionX, y = record.positionY, z = record.positionZ, angle = record.angle }
		}
		local idx = 0
		try { idx = record.scenario.tointeger() } catch (e) { idx = 0 }
		if (idx < 0 || idx >= phoenix.character.Scenarios.len()) idx = 0
		return phoenix.character.Scenarios[idx]
	}

	function _readJsonNumber(text, key) {
		if (text == null) return 0.0
		local needle = "\"" + key + "\""
		local at = text.find(needle)
		if (at == null) return 0.0
		local rest = text.slice(at + needle.len())
		local started = false
		local n = ""
		for (local i = 0; i < rest.len(); i += 1) {
			local ch = rest[i]
			if (ch == ',' || ch == '}') break
			if ((ch >= '0' && ch <= '9') || ch == '-' || ch == '.' || ch == 'e' || ch == 'E' || ch == '+') { n += ch.tochar(); started = true }
			else if (started) break
		}
		try { return n.tofloat() } catch (e) { return 0.0 }
	}

	function onRespawnChoice(playerId, message) {
		if (!(playerId in phoenix.player.Gate.reviving)) return
		local state = phoenix.player.Gate.reviving[playerId]
		if (!("ready" in state) || !state.ready) return
		local mode = "here"
		try { mode = message.mode.tostring() } catch (e) {}
		if (mode != "spawn") mode = "here"
		try { phoenix.player.Gate.applyKnockdownRevive(playerId, mode) } catch (e) {}
	}

	function applyDamage(playerId, amount, attackerId = -1, calculated = false) {
		try { if (!isPlayerConnected(playerId)) return false } catch (e) { return false }
		if (playerId in phoenix.player.Gate.pending) return false
		if (playerId in phoenix.player.Gate.reviving) return false
		if (playerId in phoenix.player.Gate.applying) return false
		local hp = 0
		try { hp = getPlayerHealth(playerId) } catch (e) { return false }
		local damage = amount == null ? 0 : amount.tointeger()
		if (!calculated && attackerId != null && attackerId >= 0) {
			local summary = phoenix.player.Combat.calculate(attackerId, playerId, null, damage)
			if (summary.miss || summary.dodged || summary.finalDamage <= 0) {
				try { phoenix.player.Combat.emitText(playerId, 0, summary.dodged ? "dodge" : "miss") } catch (ect) {}
				return false
			}
			damage = summary.finalDamage
			try { phoenix.player.WeaponProgression.onValidHit(attackerId, playerId, damage, null) } catch (ewp) {}
			try { phoenix.player.Combat.emitText(playerId, damage, summary.critical ? "crit" : "damage") } catch (ect2) {}
		}
		if (hp <= 0) {
			try { setPlayerHealth(playerId, 1) } catch (e) {}
			phoenix.player.Gate.onPlayerDead(playerId, attackerId)
			return true
		}
		if (damage < 1) damage = 1
		local newHp = hp - damage
		if (newHp <= 0) {
			try { setPlayerHealth(playerId, 1) } catch (e) {}
			phoenix.player.Gate.onPlayerDead(playerId, attackerId)
			return true
		}
		try { setPlayerHealth(playerId, newHp) } catch (e) {}
		return false
	}

	function _damageFromDescription(desc, attackerId) {
		local dmg = 0
		try { if (desc != null && "damage" in desc) dmg = desc.damage.tointeger() } catch (e) {}
		try { if (dmg <= 0 && desc != null && "rawDamage" in desc) dmg = desc.rawDamage.tointeger() } catch (e) {}
		try {
			if (dmg <= 0 && desc != null && "damageByType" in desc && desc.damageByType != null) {
				foreach (_type, value in desc.damageByType) dmg += value.tointeger()
			}
		} catch (e) {}
		if (dmg <= 0) {
			local strength = 10
			try { strength = getPlayerStrength(attackerId) } catch (e) {}
			dmg = strength > 0 ? strength : 10
		}
		if (dmg < 1) dmg = 1
		return dmg
	}

	function applyKnockdownRevive(playerId, mode = "here") {
		local state = null
		if (playerId in phoenix.player.Gate.reviving) state = phoenix.player.Gate.reviving[playerId]
		if (playerId in phoenix.player.Gate.reviving) phoenix.player.Gate.reviving.rawdelete(playerId)
		if (!isPlayerConnected(playerId)) return
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		if (phoenix.player.Progression.normalizeRecordStats(record)) phoenix.player.Progression._persistRecord(record)
		local hpMax = (record.hpMax != null && record.hpMax > 0) ? record.hpMax : 100
		local reviveHp = (hpMax * phoenix.player.Gate.DEATH_REVIVE_HP_PERCENT).tointeger()
		if (reviveHp < 1) reviveHp = 1
		local tx = record.positionX
		local ty = record.positionY
		local tz = record.positionZ
		local tAngle = record.angle
		if (mode != "spawn" && state != null) {
			tx = state.x
			ty = state.y
			tz = state.z
			tAngle = state.angle
		} else {
			local scenario = phoenix.player.Gate._scenarioSpawn(record)
			if (scenario != null) {
				tx = scenario.x
				ty = scenario.y
				tz = scenario.z
				tAngle = scenario.angle
			}
		}
		try { stopAni(playerId, "S_DEADB") } catch (e) {}
		phoenix.player.Gate.applying[playerId] <- true
		local needsSpawn = false
		try { needsSpawn = !isPlayerSpawned(playerId) } catch (e) {}
		if (needsSpawn) {
			try { spawnPlayer(playerId) } catch (e) {}
		}
		if (playerId in phoenix.player.Gate.applying) phoenix.player.Gate.applying.rawdelete(playerId)
		try { setPlayerVirtualWorld(playerId, 0) } catch (e) {}
		try { setPlayerMaxHealth(playerId, hpMax) } catch (e) {}
		try { setPlayerMaxMana(playerId, record.manaMax) } catch (e) {}
		try { setPlayerPosition(playerId, tx, ty, tz) } catch (e) {}
		try { setPlayerAngle(playerId, tAngle) } catch (e) {}
		try { setPlayerHealth(playerId, reviveHp) } catch (e) {}
		try {
			local msg = phoenix.player.Message.Revived()
			msg.hp = reviveHp
			msg.hpMax = hpMax
			msg.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}

	function onCharacterSelected(playerId, characterId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		if (phoenix.player.Progression.normalizeRecordStats(record)) phoenix.player.Progression._persistRecord(record)

		if (playerId in phoenix.player.Gate.reviving) phoenix.player.Gate.reviving.rawdelete(playerId)
		if (playerId in phoenix.player.Gate.applying) phoenix.player.Gate.applying.rawdelete(playerId)
		if (playerId in phoenix.player.Gate.pending) phoenix.player.Gate.pending.rawdelete(playerId)
		try { setPlayerWeaponMode(playerId, 0) } catch (e) {}
		try { stopAni(playerId, "S_DEADB") } catch (e) {}
		try { stopAni(playerId, "T_DEADB") } catch (e) {}
		try { stopAni(playerId, "T_VICTIM") } catch (e) {}
		try {
			local revive = phoenix.player.Message.Revived()
			revive.hp = (record.hp != null && record.hp > 0) ? record.hp : ((record.hpMax != null && record.hpMax > 0) ? record.hpMax : 100)
			revive.hpMax = (record.hpMax != null && record.hpMax > 0) ? record.hpMax : 100
			revive.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}

		local visual = phoenix.player.Gate.normalizeVisual(record)
		local body = visual.body
		local head = visual.head
		local bodyTex = visual.bodyTex
		local faceTex = visual.faceTex

		local hpMax = (record.hpMax != null && record.hpMax > 0) ? record.hpMax : 100
		local hp = (record.hp != null && record.hp > 0) ? record.hp : hpMax
		if (hp > hpMax) hp = hpMax
		local manaMax = (record.manaMax != null && record.manaMax > 0) ? record.manaMax : 10
		local mana = (record.mana != null && record.mana >= 0) ? record.mana : manaMax
		if (mana > manaMax) mana = manaMax

		try { setPlayerVirtualWorld(playerId, 0) } catch (e) {}
		try { setPlayerInvisible(playerId, false) } catch (e) {}
		try { setPlayerInstance(playerId, "PC_HERO") } catch (e) {}
		try { setPlayerVisual(playerId, body, bodyTex, head, faceTex) } catch (e) {}
		if (record.positionX != 0.0 || record.positionY != 0.0 || record.positionZ != 0.0) {
			try { setPlayerPosition(playerId, record.positionX, record.positionY, record.positionZ) } catch (e) {}
		}
		try { setPlayerAngle(playerId, record.angle) } catch (e) {}

		try {
			if (!isPlayerSpawned(playerId)) spawnPlayer(playerId)
		} catch (e) {}

		try { setPlayerMaxHealth(playerId, hpMax) } catch (e) {}
		try { setPlayerHealth(playerId, hp) } catch (e) {}
		try { setPlayerMaxMana(playerId, manaMax) } catch (e) {}
		try { setPlayerMana(playerId, mana) } catch (e) {}
		try { setPlayerStrength(playerId, record.strength) } catch (e) {}
		try { setPlayerDexterity(playerId, record.dexterity) } catch (e) {}
		try { setPlayerSkillWeapon(playerId, WEAPON_1H, record.oneHand) } catch (e) {}
		try { setPlayerSkillWeapon(playerId, WEAPON_2H, record.twoHand) } catch (e) {}
		try { setPlayerSkillWeapon(playerId, WEAPON_BOW, record.bow) } catch (e) {}
		try { setPlayerSkillWeapon(playerId, WEAPON_CBOW, record.crossbow) } catch (e) {}
		record.hp = hp
		record.mana = mana
		try { phoenix.player.Gate.appliedAt[playerId] <- getTickCount() } catch (eat) {}

		phoenix.player.Gate.applyEquipment(playerId, record)
		phoenix.player.Gate.restoreEquipment(playerId, record)

		phoenix.player.Gate.release(playerId)

		callEvent("phoenix.player.OnSpawned", playerId, characterId, record)
	}

	function applyEquipment(playerId, record) {
		if (!("equipment" in record)) return
		local raw = record.equipment
		if (raw == null || raw == "") return

		foreach (entry in split(raw, ",")) {
			local trimmed = strip(entry)
			if (trimmed == "") continue
			local parts = split(trimmed, "|")
			if (parts.len() == 0) continue
			local instance = parts[0]
			local amount = parts.len() > 1 ? parts[1].tointeger() : 1
			try { ::giveItem(playerId, instance, amount) } catch (e) {}
			if (instance != "ITRW_ARROW" && instance != "ITRW_BOLT") {
				try { ::equipItem(playerId, instance) } catch (e) {}
			}
		}
	}

	function restoreEquipment(playerId, record) {
		if (record == null) return
		local characterId = 0
		try { characterId = record.id } catch (e) { characterId = 0 }
		if (characterId <= 0) return
		local apply = function(_) {
			try { phoenix.item.Structure.applyToPlayer(playerId, characterId) } catch (ea) {}
			try { phoenix.item.Structure.sendInventorySnapshot(playerId, characterId) } catch (eb) {}
		}
		local cacheKey = phoenix.item.Structure.key(PhoenixInventoryOwner.Player, characterId)
		if (cacheKey in phoenix.item.Structure.cache) apply(null)
		else phoenix.item.Structure.loadOwner(PhoenixInventoryOwner.Player, characterId, apply)
	}

	function restoreVisual(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return false
		if (phoenix.player.Progression.normalizeRecordStats(record)) phoenix.player.Progression._persistRecord(record)
		local visual = phoenix.player.Gate.normalizeVisual(record)
		local body = visual.body
		local head = visual.head
		local bodyTex = visual.bodyTex
		local faceTex = visual.faceTex
		local hpMax = (record.hpMax != null && record.hpMax > 0) ? record.hpMax : 100
		local hp = (record.hp != null && record.hp > 0) ? record.hp : hpMax
		if (hp > hpMax) hp = hpMax
		local manaMax = (record.manaMax != null && record.manaMax > 0) ? record.manaMax : 10
		local mana = (record.mana != null && record.mana >= 0) ? record.mana : manaMax
		if (mana > manaMax) mana = manaMax
		try { setPlayerInstance(playerId, "PC_HERO") } catch (e) {}
		try { setPlayerVisual(playerId, body, bodyTex, head, faceTex) } catch (e) {}
		try { setPlayerScale(playerId, 1.0, 1.0, 1.0) } catch (e) {}
		try { setPlayerMaxHealth(playerId, hpMax) } catch (e) {}
		try { setPlayerHealth(playerId, hp) } catch (e) {}
		try { setPlayerMaxMana(playerId, manaMax) } catch (e) {}
		try { setPlayerMana(playerId, mana) } catch (e) {}
		try { phoenix.player.Gate.appliedAt[playerId] <- getTickCount() } catch (eat) {}
		try { setPlayerStrength(playerId, record.strength) } catch (e) {}
		try { setPlayerDexterity(playerId, record.dexterity) } catch (e) {}
		record.hp = hp
		record.mana = mana
		return true
	}

	function revive(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return false
		if (phoenix.player.Progression.normalizeRecordStats(record)) phoenix.player.Progression._persistRecord(record)
		phoenix.player.Gate.restoreVisual(playerId)
		local hpMax = (record.hpMax != null && record.hpMax > 0) ? record.hpMax : 100
		local manaMax = (record.manaMax != null && record.manaMax > 0) ? record.manaMax : 10
		try { setPlayerHealth(playerId, hpMax) } catch (e) {}
		try { setPlayerMana(playerId, manaMax) } catch (e) {}
		try {
			if (!isPlayerSpawned(playerId)) spawnPlayer(playerId)
		} catch (e) {}
		return true
	}

	function captureRecord(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return null
		phoenix.player.Progression.normalizeRecordStats(record)
		local now = getTickCount()
		local recentlyApplied = false
		if (playerId in phoenix.player.Gate.appliedAt) {
			local at = phoenix.player.Gate.appliedAt[playerId]
			if (at > 0 && now - at < 12000) recentlyApplied = true
		}
		local recordHpMax = record.hpMax
		local recordManaMax = record.manaMax
		local runtimeHpMax = 0
		local runtimeManaMax = 0
		local hasTemporaryHpMax = false
		local hasTemporaryManaMax = false
		try { hasTemporaryHpMax = phoenix.item.Effects.hasModifier(playerId, "hpMax") } catch (eBuffHp) {}
		try { hasTemporaryManaMax = phoenix.item.Effects.hasModifier(playerId, "manaMax") } catch (eBuffMana) {}
		if (!recentlyApplied) {
			try { if (!hasTemporaryHpMax) runtimeHpMax = getPlayerMaxHealth(playerId) } catch (eMax) { runtimeHpMax = 0 }
			try { if (!hasTemporaryManaMax) runtimeManaMax = getPlayerMaxMana(playerId) } catch (eManaMax) { runtimeManaMax = 0 }
		}
		try { phoenix.character.Structure.bumpPlayTime(playerId, record) } catch (e0) {}
		try {
			local pos = getPlayerPosition(playerId)
			if (pos != null) {
				record.positionX = pos.x
				record.positionY = pos.y
				record.positionZ = pos.z
			}
		} catch (e) {}
		try { record.angle = getPlayerAngle(playerId) } catch (e) {}
		try {
			local w = getPlayerWorld(playerId)
			if (w != null && w != "") record.world = phoenix.player.Gate.normalizeWorld(w)
		} catch (e) {}
		if (!recentlyApplied) {
			try {
				local curHp = getPlayerHealth(playerId)
				local trustedHpRuntime = (runtimeHpMax > 0) && !(runtimeHpMax < recordHpMax)
				if (curHp > 0 && trustedHpRuntime) record.hp = curHp
			} catch (e) {}
			if (runtimeHpMax > 0 && runtimeHpMax > record.hpMax) record.hpMax = runtimeHpMax
			try {
				local curMana = getPlayerMana(playerId)
				local trustedManaRuntime = (runtimeManaMax > 0) && !(runtimeManaMax < recordManaMax)
				if (curMana >= 0 && trustedManaRuntime) record.mana = curMana
			} catch (e) {}
			if (runtimeManaMax > 0 && runtimeManaMax > record.manaMax) record.manaMax = runtimeManaMax
		}
		phoenix.player.Progression.normalizeRecordStats(record)
		local hasStrengthBuff = false; local hasDexterityBuff = false
		try { hasStrengthBuff = phoenix.item.Effects.hasModifier(playerId, "strength") } catch (eBuffStr) {}
		try { hasDexterityBuff = phoenix.item.Effects.hasModifier(playerId, "dexterity") } catch (eBuffDex) {}
		if (!hasStrengthBuff) { try { record.strength = getPlayerStrength(playerId) } catch (e) {} }
		if (!hasDexterityBuff) { try { record.dexterity = getPlayerDexterity(playerId) } catch (e) {} }
		try {
			if (playerId in phoenix.player.WeaponProgression.byPlayer) {
				local wp = phoenix.player.WeaponProgression.byPlayer[playerId]
				record.oneHand = wp.oneHand.level
				record.twoHand = wp.twoHand.level
				record.bow = wp.bow.level
				record.crossbow = wp.crossbow.level
			}
		} catch (e2) {}
		return record
	}

	function persist(playerId) {
		local record = phoenix.player.Gate.captureRecord(playerId)
		if (record == null) return
		try { phoenix.player.Progression._persistRecord(record) } catch (ep) {}
	}

	function consumeRangedAmmo(playerId) {
		local mode = 0
		try { mode = getPlayerWeaponMode(playerId) } catch (e) { mode = 0 }
		local ammo = ""
		try { if (mode == WEAPONMODE_BOW) ammo = "ITRW_ARROW" } catch (e2) {}
		try { if (mode == WEAPONMODE_CBOW) ammo = "ITRW_BOLT" } catch (e3) {}
		if (ammo == "") return
		local record = null
		try { record = phoenix.character.Structure.getActive(playerId) } catch (e4) { record = null }
		if (record == null || record.id <= 0) return
		try {
			phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, record.id, ammo, 1, function(ok) {
				if (ok) {
					try { phoenix.item.Structure.sendInventorySnapshot(playerId, record.id) } catch (es) {}
				}
				else {
					try { phoenix.notification.notify(playerId, "warn", "Amunicja", ammo == "ITRW_ARROW" ? "Brak strzal." : "Brak beltow.", 2500) } catch (en) {}
				}
			})
		} catch (e5) {}
	}

	function onPlayerDisconnect(playerId, _reason) {
		phoenix.player.Gate.persist(playerId)
		phoenix.player.Gate.release(playerId)
		try { if (playerId in phoenix.player.WeaponProgression.byPlayer) phoenix.player.WeaponProgression.byPlayer.rawdelete(playerId) } catch (e) {}
		try { if (playerId in phoenix.player.WeaponProgression.loaded) phoenix.player.WeaponProgression.loaded.rawdelete(playerId) } catch (e2) {}
		if (playerId in phoenix.player.Gate.reviving) phoenix.player.Gate.reviving.rawdelete(playerId)
		if (playerId in phoenix.player.Gate.applying) phoenix.player.Gate.applying.rawdelete(playerId)
		if (playerId in phoenix.player.Gate.appliedAt) phoenix.player.Gate.appliedAt.rawdelete(playerId)
	}

	function onAutoSaveTimer() {
		for (local i = 0; i < getMaxSlots(); i += 1) {
			try {
				if (isPlayerConnected(i)) phoenix.player.Gate.persist(i)
			} catch (e) {}
		}
	}
}

addEventHandler("onPlayerJoin", phoenix.player.Gate.onPlayerJoin)
addEventHandler("onPlayerDamage", function (victimId, attackerId, desc) {
	try {
		if (victimId == null || victimId < 0 || victimId >= getMaxSlots()) return
		try { if (phoenix.npc.Spawn._liveByNpcId(victimId) != null) return } catch (enpc) {}
		if (victimId in phoenix.player.Gate.pending) { cancelEvent(); eventValue(0); return }
		if (victimId in phoenix.player.Gate.reviving) { cancelEvent(); eventValue(0); return }
		if (attackerId == null || attackerId < 0) return
		cancelEvent()
		try {
			if (phoenix.character.Structure.getActive(attackerId) != null) phoenix.player.Hud.consumeStamina(attackerId, 1.0)
		} catch (es) {}
		phoenix.player.Gate.consumeRangedAmmo(attackerId)
		local summary = phoenix.player.Combat.calculate(attackerId, victimId, desc, 0)
		if (summary.miss || summary.dodged || summary.finalDamage <= 0) {
			try { phoenix.player.Combat.emitText(victimId, 0, summary.dodged ? "dodge" : "miss") } catch (ect) {}
			eventValue(0)
			return
		}
		try { phoenix.player.WeaponProgression.onValidHit(attackerId, victimId, summary.finalDamage, desc) } catch (ewp) {}
		try { phoenix.player.Combat.emitText(victimId, summary.finalDamage, summary.critical ? "crit" : "damage") } catch (ect2) {}
		eventValue(summary.finalDamage)
		phoenix.player.Gate.applyDamage(victimId, summary.finalDamage, attackerId, true)
	} catch (e) {}
})
addEventHandler("onPlayerRespawn", phoenix.player.Gate.onPlayerRespawn)
addEventHandler("onPlayerDead", phoenix.player.Gate.onPlayerDead)
addEventHandler("onPlayerDisconnect", phoenix.player.Gate.onPlayerDisconnect)
addEventHandler("phoenix.character.OnSelected", phoenix.player.Gate.onCharacterSelected)
phoenix.player.Message.RespawnChoice.bind(phoenix.player.Gate.onRespawnChoice)

setTimer(phoenix.player.Gate.onAutoSaveTimer, 60000, 0)
