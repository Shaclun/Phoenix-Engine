phoenix.admin.Server <- {
	flyStates = {}
	godmodeStates = {}
	mapPlayerPollAt = {}

	function findPlayerByCharacterId(characterId) {
		local maxSlots = getMaxSlots()
		for (local i = 0; i < maxSlots; i += 1) {
			try {
				if (!isPlayerConnected(i)) continue
				local rec = phoenix.character.Structure.getActive(i)
				if (rec != null && rec.id == characterId) return i
			} catch (e) {}
		}
		return -1
	}

	function findPlayerByAccountId(accountId) {
		local maxSlots = getMaxSlots()
		for (local i = 0; i < maxSlots; i += 1) {
			try {
				if (!isPlayerConnected(i)) continue
				local s = phoenix.account.Structure.get(i)
				if (s != null && s.id() == accountId) return i
			} catch (e) {}
		}
		return -1
	}

	function reply(playerId, action, success, error, payload) {
		local m = phoenix.admin.Message.Response()
		m.action = action
		m.success = success
		m.error = error
		m.payload = payload
		try { m.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) { print("[admin] Response '" + action + "' failed: " + e + "\n") }
	}

	function dispatchListPlayers(playerId, _payload) {
		local rows = []
		local maxSlots = getMaxSlots()
		for (local i = 0; i < maxSlots; i += 1) {
			try {
				if (!isPlayerConnected(i)) continue
				local entry = {
					playerId = i,
					name = "",
					accountId = 0,
					accountName = "",
					characterId = 0,
					characterName = "",
					role = 0,
					ip = "",
					serial = "",
					world = "",
					level = 0,
					experience = 0,
					experienceNext = 0,
					learnPoints = 0,
					hp = 0,
					hpMax = 0,
					mana = 0,
					manaMax = 0,
					stamina = 0,
					staminaMax = 0,
					strength = 0,
					dexterity = 0,
					oneHand = 0,
					twoHand = 0,
					bow = 0,
					crossbow = 0,
					magicLevel = 0,
					magicXp = 0,
					posX = 0.0, posY = 0.0, posZ = 0.0,
					gold = 0,
					itemCount = 0,
					ping = 0,
					vanished = false
				}
				try { entry.name = getPlayerName(i) } catch (e) {}
				try { entry.ip = getPlayerIP(i) } catch (e) {}
				try { entry.serial = getPlayerSerial(i) } catch (e) {}
				try { entry.world = getPlayerWorld(i) } catch (e) {}
				try { entry.ping = getPlayerPing(i) } catch (e) {}
				try {
					local p = getPlayerPosition(i)
					if (p != null) { entry.posX = p.x; entry.posY = p.y; entry.posZ = p.z }
				} catch (e) {}
				try { entry.hp = getPlayerHealth(i) } catch (e) {}
				local s = phoenix.account.Structure.get(i)
				if (s != null) {
					entry.accountId = s.id()
					entry.accountName = s.username()
					try { entry.role = s.record.role } catch (e) {}
					try { entry.vanished = s.vanished == true } catch (e) {}
				}
				local rec = phoenix.character.Structure.getActive(i)
				if (rec != null) {
					entry.characterId = rec.id
					try { entry.characterName = rec.name } catch (e) {}
					try { entry.level = rec.level } catch (e) {}
					try { entry.experience = rec.experience; entry.experienceNext = rec.experienceNext; entry.learnPoints = rec.learnPoints } catch (e) {}
					try { entry.hp = phoenix.player.Resources.current(i, rec, "hp"); entry.hpMax = rec.hpMax; entry.mana = phoenix.player.Resources.current(i, rec, "mana"); entry.manaMax = rec.manaMax } catch (e) {}
					try { entry.stamina = phoenix.player.Resources.current(i, rec, "stamina"); entry.staminaMax = rec.staminaMax } catch (e) {}
					try { entry.strength = rec.strength; entry.dexterity = rec.dexterity; entry.oneHand = rec.oneHand; entry.twoHand = rec.twoHand; entry.bow = rec.bow; entry.crossbow = rec.crossbow } catch (e) {}
					try { entry.magicLevel = rec.magicLevel; entry.magicXp = rec.magicXp } catch (e) {}
					try {
						local cacheKey = phoenix.item.Structure.key(PhoenixInventoryOwner.Player, rec.id)
						if (cacheKey in phoenix.item.Structure.cache) {
							local e2 = phoenix.item.Structure.cache[cacheKey]
							if ("gold" in e2) entry.gold = e2.gold
							if ("items" in e2) entry.itemCount = e2.items.len()
						}
					} catch (e) {}
				}
				rows.append(entry)
			} catch (e) {}
		}
		phoenix.admin.Server.reply(playerId, "players", true, "", { players = rows })
	}

	function dispatchSetPlayerStats(playerId, payload) {
		if (payload == null || !("playerId" in payload) || !("stats" in payload)) return phoenix.admin.Server.reply(playerId, "setPlayerStats", false, "payload", null)
		local targetPid = payload.playerId.tointeger()
		if (targetPid < 0 || !isPlayerConnected(targetPid)) return phoenix.admin.Server.reply(playerId, "setPlayerStats", false, "offline", null)
		local record = phoenix.character.Structure.getActive(targetPid)
		if (record == null) return phoenix.admin.Server.reply(playerId, "setPlayerStats", false, "noCharacter", null)
		local stats = payload.stats
		local readInt = function(key, fallback, minimum, maximum) {
			local value = fallback
			try { if (key in stats && stats[key] != null) value = stats[key].tointeger() } catch (e) {}
			if (value < minimum) value = minimum
			if (value > maximum) value = maximum
			return value
		}
		record.level = readInt("level", record.level, 1, phoenix.player.Progression.maxLevel)
		record.experience = readInt("experience", record.experience, 0, phoenix.player.Progression.expForLevel(phoenix.player.Progression.maxLevel))
		record.experienceNext = phoenix.player.Progression.expForLevel(record.level + 1)
		record.learnPoints = readInt("learnPoints", record.learnPoints, 0, 100000)
		record.hpMax = readInt("hpMax", record.hpMax, 1, 100000)
		record.manaMax = readInt("manaMax", record.manaMax, 0, 100000)
		record.staminaMax = readInt("staminaMax", record.staminaMax, 1, 100000)
		record.strength = readInt("strength", record.strength, 0, 10000)
		record.dexterity = readInt("dexterity", record.dexterity, 0, 10000)
		record.oneHand = readInt("oneHand", record.oneHand, 0, 100)
		record.twoHand = readInt("twoHand", record.twoHand, 0, 100)
		record.bow = readInt("bow", record.bow, 0, 100)
		record.crossbow = readInt("crossbow", record.crossbow, 0, 100)
		record.magicLevel = readInt("magicLevel", record.magicLevel, 0, 20)
		record.magicXp = readInt("magicXp", record.magicXp, 0, 100000000)
		phoenix.player.Progression.normalizeRecordStats(record)
		phoenix.player.Resources.syncMaximums(targetPid, record)
		phoenix.player.Resources.set(targetPid, record, "hp", readInt("hp", record.hp, 0, record.hpMax), true)
		phoenix.player.Resources.set(targetPid, record, "mana", readInt("mana", record.mana, 0, record.manaMax), true)
		phoenix.player.Resources.set(targetPid, record, "stamina", readInt("stamina", record.stamina, 0, record.staminaMax), true)
		local strengthBonus = 0; local dexterityBonus = 0
		try { strengthBonus = phoenix.item.Effects.modifier(targetPid, "strength") } catch (e) {}
		try { dexterityBonus = phoenix.item.Effects.modifier(targetPid, "dexterity") } catch (e) {}
		try { setPlayerStrength(targetPid, record.strength + strengthBonus) } catch (e) {}
		try { setPlayerDexterity(targetPid, record.dexterity + dexterityBonus) } catch (e) {}
		try { setPlayerSkillWeapon(targetPid, WEAPON_1H, record.oneHand); setPlayerSkillWeapon(targetPid, WEAPON_2H, record.twoHand); setPlayerSkillWeapon(targetPid, WEAPON_BOW, record.bow); setPlayerSkillWeapon(targetPid, WEAPON_CBOW, record.crossbow) } catch (e) {}
		try {
			if (!(targetPid in phoenix.player.WeaponProgression.byPlayer)) phoenix.player.WeaponProgression.byPlayer[targetPid] <- phoenix.player.WeaponProgression._stateFromRecord(record)
			foreach (key in phoenix.player.WeaponProgression.skills) {
				local entry = phoenix.player.WeaponProgression.byPlayer[targetPid][key]
				entry.level = phoenix.player.WeaponProgression._readRecordValue(record, key)
				entry.cap = phoenix.player.WeaponProgression._capForLevel(entry.level)
			}
			phoenix.player.WeaponProgression.saveAll(targetPid)
		} catch (eWp) {}
		local sql = "UPDATE `phoenix_characters` SET `level`=" + record.level + ",`experience`=" + record.experience + ",`experienceNext`=" + record.experienceNext + ",`learnPoints`=" + record.learnPoints + ",`hp`=" + record.hp + ",`hpMax`=" + record.hpMax + ",`mana`=" + record.mana + ",`manaMax`=" + record.manaMax + ",`stamina`=" + record.stamina + ",`staminaMax`=" + record.staminaMax + ",`strength`=" + record.strength + ",`dexterity`=" + record.dexterity + ",`oneHand`=" + record.oneHand + ",`twoHand`=" + record.twoHand + ",`bow`=" + record.bow + ",`crossbow`=" + record.crossbow + ",`magicLevel`=" + record.magicLevel + ",`magicXp`=" + record.magicXp + " WHERE `id`=" + record.id
		ORM.engine.executeAsync(sql, function(_) {
			try { phoenix.player.Hud.pushSnapshot(targetPid); phoenix.player.Stats.pushSnapshot(targetPid) } catch (e) {}
			phoenix.admin.Server.audit(playerId, "setPlayerStats", "character", record.id, record.name, "level=" + record.level + " hp=" + record.hp + "/" + record.hpMax)
			phoenix.admin.Server.reply(playerId, "setPlayerStats", true, "", { playerId = targetPid, characterId = record.id })
		})
	}

	function dispatchListSchemes(playerId, _payload) {
		local rows = []
		try {
			foreach (instanceId, scheme in phoenix.item.Schemes.byInstance) {
				local entry = {
					instance = instanceId,
					name = instanceId,
					description = "",
					category = 0,
					slot = 0,
					value = 0,
					weight = 0.0,
					damage = 0,
					visual = ""
				}
				try { if ("name" in scheme && scheme.name != null && scheme.name != "") entry.name = scheme.name } catch (e) {}
				try { if ("description" in scheme && scheme.description != null) entry.description = scheme.description } catch (e) {}
				try { entry.category = ("category" in scheme) ? scheme.category : 0 } catch (e) {}
				try { entry.slot = ("slot" in scheme) ? scheme.slot : 0 } catch (e) {}
				try { entry.value = ("value" in scheme) ? scheme.value : 0 } catch (e) {}
				try { entry.weight = ("weight" in scheme) ? scheme.weight.tofloat() : 0.0 } catch (e) {}
				try { entry.damage = ("damage" in scheme) ? scheme.damage : 0 } catch (e) {}
				try {
					local v = null
					try { v = phoenix.item.lookupVisual(instanceId) } catch (e) {}
					if (v == null || v == "") v = ("visual" in scheme) ? scheme.visual : null
					if (v != null && v != "") {
						local up = v.toupper()
						if (up.find(".3DS") != null) v = v.slice(0, v.len() - 4) + ".MRM"
						entry.visual = v
					}
				} catch (e) {}
				rows.append(entry)
			}
		} catch (e) {}
		local total = rows.len()
		local chunkSize = 200
		local chunkCount = (total <= 0) ? 1 : (((total - 1) / chunkSize) + 1)
		if (total == 0) {
			phoenix.admin.Server.reply(playerId, "schemes", true, "", { schemes = [], chunkIndex = 0, chunkCount = 1 })
			return
		}
		for (local ci = 0; ci < chunkCount; ci += 1) {
			local start = ci * chunkSize
			local end = start + chunkSize
			if (end > total) end = total
			local chunk = []
			for (local i = start; i < end; i += 1) chunk.append(rows[i])
			phoenix.admin.Server.reply(playerId, "schemes", true, "", { schemes = chunk, chunkIndex = ci, chunkCount = chunkCount })
		}
	}

	function dispatchSchemeDetails(playerId, payload) {
		if (payload == null || !("instance" in payload)) return phoenix.admin.Server.reply(playerId, "schemeDetails", false, "payload", null)
		local inst = payload.instance.tostring()
		if (!phoenix.item.has(inst)) return phoenix.admin.Server.reply(playerId, "schemeDetails", false, "unknown", null)
		local s = phoenix.item.find(inst)
		local protection = { edge = 0, blunt = 0, point = 0, fire = 0, magic = 0 }
		try {
			if ("protection" in s && s.protection != null) {
				foreach (k, v in s.protection) protection[k] <- v
			}
		} catch (e) {}
		local visual = ""
		try {
			local v = ("visual" in s) ? s.visual : null
			if (v == null || v == "") { try { v = phoenix.item.lookupVisual(inst) } catch (e) {} }
			if (v != null) visual = v
		} catch (e) {}
		local out = {
			instance = inst,
			name = ("name" in s) ? s.name : inst,
			description = ("description" in s && s.description != null) ? s.description : "",
			category = ("category" in s) ? s.category : 0,
			slot = ("slot" in s) ? s.slot : 0,
			value = ("value" in s) ? s.value : 0,
			weight = ("weight" in s) ? s.weight.tofloat() : 0.0,
			damage = ("damage" in s) ? s.damage : 0,
			damageType = ("damageType" in s) ? s.damageType : 0,
			stackMax = ("stackMax" in s) ? s.stackMax : 1,
			flags = ("flags" in s) ? s.flags : 0,
			visual = visual,
			protection = protection
		}
		phoenix.admin.Server.reply(playerId, "schemeDetails", true, "", out)
	}

	function dispatchGiveItem(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "giveItem", false, "payload", null)
		local targetCharId = ("characterId" in payload) ? payload.characterId : 0
		local instance     = ("instance" in payload) ? payload.instance.tostring() : ""
		local amount       = ("amount" in payload) ? payload.amount : 1
		local quality      = ("quality" in payload) ? payload.quality : 0
		local upgrade      = ("upgrade" in payload) ? payload.upgrade : 0
		if (instance == "") return phoenix.admin.Server.reply(playerId, "giveItem", false, "instance", null)
		if (targetCharId <= 0) return phoenix.admin.Server.reply(playerId, "giveItem", false, "badTarget", null)
		if (!phoenix.item.has(instance))
			return phoenix.admin.Server.reply(playerId, "giveItem", false, "unknownInstance", null)
		local recipientPid = phoenix.admin.Server.findPlayerByCharacterId(targetCharId)
		local cacheKey = phoenix.item.Structure.key(PhoenixInventoryOwner.Player, targetCharId)
		local function doGive() {
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, targetCharId, instance, {
			amount = amount, quality = quality, upgrade = upgrade, source = "admin-panel"
		}, function(rec) {
			if (recipientPid >= 0)
				try { phoenix.item.Structure.sendInventorySnapshot(recipientPid, targetCharId) } catch (e) {}
			try { phoenix.admin.Server.audit(playerId, "giveItem", "character", targetCharId, instance, "x" + amount + " q" + quality + " +" + upgrade) } catch (e) {}
			phoenix.admin.Server.reply(playerId, "giveItem", true, "", { instance = instance, amount = amount })
		})
		}
		if (!(cacheKey in phoenix.item.Structure.cache)) {
			try { phoenix.item.Structure.loadOwner(PhoenixInventoryOwner.Player, targetCharId, function (_) { doGive() }); return } catch (e) {}
		}
		doGive()
	}

	function dispatchTeleportTo(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "tpTo", false, "payload", null)
		local targetPid = ("playerId" in payload) ? payload.playerId : -1
		if (targetPid < 0 || !isPlayerConnected(targetPid))
			return phoenix.admin.Server.reply(playerId, "tpTo", false, "offline", null)
		local targetName = ""
		try { targetName = getPlayerName(targetPid) } catch (e) {}
		try {
			local p = getPlayerPosition(targetPid)
			if (p != null) setPlayerPosition(playerId, p.x, p.y + 50, p.z)
		} catch (e) {}
		phoenix.admin.Server.audit(playerId, "tpTo", "player", targetPid, targetName, "")
		phoenix.admin.Server.reply(playerId, "tpTo", true, "", null)
	}

	function dispatchTeleportHere(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "tpHere", false, "payload", null)
		local targetPid = ("playerId" in payload) ? payload.playerId : -1
		if (targetPid < 0 || !isPlayerConnected(targetPid))
			return phoenix.admin.Server.reply(playerId, "tpHere", false, "offline", null)
		local targetName = ""
		try { targetName = getPlayerName(targetPid) } catch (e) {}
		try {
			local p = getPlayerPosition(playerId)
			if (p != null) setPlayerPosition(targetPid, p.x, p.y + 50, p.z)
		} catch (e) {}
		phoenix.admin.Server.audit(playerId, "tpHere", "player", targetPid, targetName, "")
		phoenix.admin.Server.reply(playerId, "tpHere", true, "", null)
	}

	function dispatchAdminMapPlayers(playerId, payload) {
		if (!phoenix.account.Auth.isAdmin(playerId)) return phoenix.admin.Server.reply(playerId, "adminMapPlayers", false, "denied", null)
		local mapKey = "newworld"
		local requestId = 0
		try {
			if (payload != null && "map" in payload) mapKey = payload.map.tostring()
			if (payload != null && "requestId" in payload) requestId = payload.requestId.tointeger()
		} catch (e) { return phoenix.admin.Server.reply(playerId, "adminMapPlayers", false, "payload", { map = mapKey, requestId = requestId, players = [] }) }
		local bounds = null
		if (mapKey == "newworld") bounds = { minX = -28000.0, maxX = 95500.0, minZ = -42500.0, maxZ = 50500.0 }
		else if (mapKey == "city") bounds = { minX = -6900.0, maxX = 21600.0, minZ = -9400.0, maxZ = 11800.0 }
		if (bounds == null) return phoenix.admin.Server.reply(playerId, "adminMapPlayers", false, "map", { map = mapKey, requestId = requestId, players = [] })
		local now = getTickCount()
		if (playerId in phoenix.admin.Server.mapPlayerPollAt) {
			local elapsed = now - phoenix.admin.Server.mapPlayerPollAt[playerId]
			if (elapsed >= 0 && elapsed < 750) return phoenix.admin.Server.reply(playerId, "adminMapPlayers", false, "rateLimited", { map = mapKey, requestId = requestId, players = [] })
		}
		if (playerId in phoenix.admin.Server.mapPlayerPollAt) phoenix.admin.Server.mapPlayerPollAt[playerId] = now
		else phoenix.admin.Server.mapPlayerPollAt[playerId] <- now
		local requesterWorld = ""
		local requesterVirtualWorld = 0
		try { requesterWorld = getPlayerWorld(playerId).tostring().toupper() } catch (e) {}
		try { requesterVirtualWorld = getPlayerVirtualWorld(playerId) } catch (e) {}
		local rows = []
		for (local i = 0; i < getMaxSlots() && rows.len() < 64; i += 1) {
			if (i == playerId) continue
			try {
				if (!isPlayerConnected(i)) continue
				local record = phoenix.character.Structure.getActive(i)
				if (record == null) continue
				local targetWorld = getPlayerWorld(i).tostring().toupper()
				if (targetWorld != requesterWorld || getPlayerVirtualWorld(i) != requesterVirtualWorld) continue
				local position = getPlayerPosition(i)
				if (position == null) continue
				if (position.x < bounds.minX || position.x > bounds.maxX || position.z < bounds.minZ || position.z > bounds.maxZ) continue
				local name = ""
				try { name = record.name } catch (e) { try { name = getPlayerName(i) } catch (en) {} }
				local angle = 0.0
				try { angle = getPlayerAngle(i) } catch (e) {}
				rows.append({ playerId = i, characterId = record.id, name = name, x = position.x, y = position.y, z = position.z, angle = angle })
			} catch (e) {}
		}
		phoenix.admin.Server.reply(playerId, "adminMapPlayers", true, "", { map = mapKey, requestId = requestId, players = rows })
	}

	function dispatchAdminMapTeleport(playerId, payload) {
		if (!phoenix.account.Auth.isAdmin(playerId)) return phoenix.admin.Server.reply(playerId, "adminMapTeleport", false, "denied", null)
		if (payload == null || !("x" in payload) || !("y" in payload) || !("z" in payload) || !("map" in payload)) return phoenix.admin.Server.reply(playerId, "adminMapTeleport", false, "payload", null)
		local xType = typeof payload.x
		local yType = typeof payload.y
		local zType = typeof payload.z
		if ((xType != "integer" && xType != "float") || (yType != "integer" && yType != "float") || (zType != "integer" && zType != "float")) return phoenix.admin.Server.reply(playerId, "adminMapTeleport", false, "position", null)
		local mapKey = payload.map.tostring()
		local bounds = null
		if (mapKey == "newworld") bounds = { minX = -28000.0, maxX = 95500.0, minZ = -42500.0, maxZ = 50500.0 }
		else if (mapKey == "city") bounds = { minX = -6900.0, maxX = 21600.0, minZ = -9400.0, maxZ = 11800.0 }
		if (bounds == null) return phoenix.admin.Server.reply(playerId, "adminMapTeleport", false, "map", null)
		local x = payload.x.tofloat()
		local y = payload.y.tofloat()
		local z = payload.z.tofloat()
		if (!(x >= bounds.minX && x <= bounds.maxX && y >= -20000.0 && y <= 100000.0 && z >= bounds.minZ && z <= bounds.maxZ)) return phoenix.admin.Server.reply(playerId, "adminMapTeleport", false, "position", null)
		try { setPlayerPosition(playerId, x, y, z) } catch (e) { return phoenix.admin.Server.reply(playerId, "adminMapTeleport", false, "teleport", null) }
		phoenix.admin.Server.audit(playerId, "adminMapTeleport", "self", null, "", "map=" + mapKey + " x=" + x + " y=" + y + " z=" + z)
		phoenix.admin.Server.reply(playerId, "adminMapTeleport", true, "", { x = x, y = y, z = z })
	}

	function disableFly(playerId) {
		local wasEnabled = playerId in phoenix.admin.Server.flyStates
		if (wasEnabled) phoenix.admin.Server.flyStates.rawdelete(playerId)
		try { setPlayerCollision(playerId, true) } catch (e) {}
		if (wasEnabled) phoenix.admin.Server.reply(playerId, "adminFly", true, "", { enabled = false })
		return wasEnabled
	}

	function dispatchAdminFly(playerId, payload) {
		if (!phoenix.account.Auth.isAdmin(playerId)) return phoenix.admin.Server.reply(playerId, "adminFly", false, "denied", null)
		local enabled = !(playerId in phoenix.admin.Server.flyStates)
		if (payload != null && "enabled" in payload) enabled = payload.enabled == true || payload.enabled == 1
		if (enabled) phoenix.admin.Server.flyStates[playerId] <- true
		else if (playerId in phoenix.admin.Server.flyStates) phoenix.admin.Server.flyStates.rawdelete(playerId)
		try { setPlayerCollision(playerId, !enabled) } catch (e) {}
		phoenix.admin.Server.audit(playerId, "adminFly", "self", null, "", enabled ? "on" : "off")
		phoenix.admin.Server.reply(playerId, "adminFly", true, "", { enabled = enabled })
	}

	function dispatchAdminGodmode(playerId, payload) {
		if (!phoenix.account.Auth.isAdmin(playerId)) return phoenix.admin.Server.reply(playerId, "adminGodmode", false, "denied", null)
		local enabled = !(playerId in phoenix.admin.Server.godmodeStates)
		if (payload != null && "enabled" in payload) enabled = payload.enabled == true || payload.enabled == 1
		if (enabled) phoenix.admin.Server.godmodeStates[playerId] <- true
		else if (playerId in phoenix.admin.Server.godmodeStates) phoenix.admin.Server.godmodeStates.rawdelete(playerId)
		phoenix.admin.Server.audit(playerId, "adminGodmode", "self", null, "", enabled ? "on" : "off")
		phoenix.admin.Server.reply(playerId, "adminGodmode", true, "", { enabled = enabled })
	}

	function dispatchKick(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "kick", false, "payload", null)
		local targetPid = ("playerId" in payload) ? payload.playerId : -1
		local reason    = ("reason" in payload) ? payload.reason.tostring() : "Kicked by admin"
		if (targetPid < 0 || !isPlayerConnected(targetPid))
			return phoenix.admin.Server.reply(playerId, "kick", false, "offline", null)
		local targetName = ""
		try { targetName = getPlayerName(targetPid) } catch (e) {}
		try { kick(targetPid, reason) } catch (e) {}
		phoenix.admin.Server.audit(playerId, "kick", "player", targetPid, targetName, reason)
		phoenix.admin.Server.reply(playerId, "kick", true, "", null)
	}

	function dispatchVanish(playerId, payload) {
		local forced = null
		if (payload != null && ("vanished" in payload)) forced = payload.vanished == true
		try {
			phoenix.chat.Server.toggleVanish(playerId, forced)
			local s = phoenix.account.Structure.get(playerId)
			local v = (s != null && s.vanished == true) ? "on" : "off"
			phoenix.admin.Server.audit(playerId, "vanish", "self", null, "", v)
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "vanish", false, "exception", null)
		}
	}

	function dispatchBan(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "ban", false, "payload", null)
		local targetPid    = ("playerId" in payload) ? payload.playerId : -1
		local accountId    = ("accountId" in payload) ? payload.accountId : 0
		local characterId  = ("characterId" in payload) ? payload.characterId : 0
		local scope        = ("scope" in payload) ? payload.scope : PhoenixBanScope.Account
		local minutes      = ("minutes" in payload) ? payload.minutes : 0
		local reason       = ("reason" in payload) ? payload.reason.tostring() : ""
		local banIp        = ("banIp" in payload) ? payload.banIp : false
		local banSerial    = ("banSerial" in payload) ? payload.banSerial : false

		local ip = ""
		local serial = ""
		if (targetPid >= 0 && isPlayerConnected(targetPid)) {
			try { ip = getPlayerIP(targetPid) } catch (e) {}
			try { serial = getPlayerSerial(targetPid) } catch (e) {}
			local s = phoenix.account.Structure.get(targetPid)
			if (s != null && accountId == 0) accountId = s.id()
			local rec = phoenix.character.Structure.getActive(targetPid)
			if (rec != null && characterId == 0) characterId = rec.id
		}

		local issuer = phoenix.account.Structure.get(playerId)
		local issuerId = (issuer != null) ? issuer.id() : null
		local issuerSql = (issuerId != null) ? issuerId.tostring() : "NULL"
		local accSql = (accountId != 0) ? accountId.tostring() : "NULL"
		local charSql = (characterId != 0) ? characterId.tostring() : "NULL"
		local expiresSql = (minutes > 0)
			? "DATE_ADD(NOW(), INTERVAL " + minutes + " MINUTE)"
			: "NULL"
		local reasonEsc = reason
		try { reasonEsc = ORM.engine.escape(reason) } catch (e) {}

		local function insertBan(ipAddr, ser, sc) {
			local ipEsc = ipAddr; local serEsc = ser
			try { ipEsc = ORM.engine.escape(ipAddr) } catch (e) {}
			try { serEsc = ORM.engine.escape(ser) } catch (e) {}
			local sql = "INSERT INTO `phoenix_bans` " +
				"(`scope`,`accountId`,`characterId`,`ipAddress`,`serial`,`reason`,`issuedBy`,`expiresAt`,`active`) VALUES (" +
				sc + "," + accSql + "," + charSql + ",'" + ipEsc + "','" + serEsc + "','" + reasonEsc + "'," + issuerSql + "," + expiresSql + ",1)"
			ORM.engine.executeAsync(sql, function(_){})
		}

		if (scope == PhoenixBanScope.Account || scope == PhoenixBanScope.Character) {
			insertBan("", "", scope)
		}
		if (banIp && ip != "") insertBan(ip, "", PhoenixBanScope.Ip)
		if (banSerial && serial != "") insertBan("", serial, PhoenixBanScope.Serial)

		if (targetPid >= 0 && isPlayerConnected(targetPid))
			try { kick(targetPid, "Banned: " + reason) } catch (e) {}

		phoenix.admin.Server.audit(playerId, "ban", "account", accountId, "", "scope=" + scope + " min=" + minutes + " ip=" + (banIp ? "1" : "0") + " sr=" + (banSerial ? "1" : "0") + " reason=" + reason)
		phoenix.admin.Server.reply(playerId, "ban", true, "", null)
	}

	function dispatchUnban(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "unban", false, "payload", null)
		local banId = ("banId" in payload) ? payload.banId : 0
		if (banId <= 0) return phoenix.admin.Server.reply(playerId, "unban", false, "id", null)
		local sql = "UPDATE `phoenix_bans` SET `active` = 0 WHERE `id` = " + banId
		ORM.engine.executeAsync(sql, function(_) {
			phoenix.admin.Server.audit(playerId, "unban", "ban", banId, "", "")
			phoenix.admin.Server.reply(playerId, "unban", true, "", { banId = banId })
		})
	}

	function dispatchListBans(playerId, payload) {
		local accountId = (payload != null && "accountId" in payload) ? payload.accountId : 0
		local sql = ""
		if (accountId > 0) {
			sql = "SELECT `id`,`scope`,`accountId`,`characterId`,`ipAddress`,`serial`,`reason`,`issuedBy`," +
				"UNIX_TIMESTAMP(`issuedAt`) AS issuedAt, UNIX_TIMESTAMP(`expiresAt`) AS expiresAt, `active` " +
				"FROM `phoenix_bans` WHERE `accountId` = " + accountId + " ORDER BY `id` DESC LIMIT 200"
		} else {
			sql = "SELECT `id`,`scope`,`accountId`,`characterId`,`ipAddress`,`serial`,`reason`,`issuedBy`," +
				"UNIX_TIMESTAMP(`issuedAt`) AS issuedAt, UNIX_TIMESTAMP(`expiresAt`) AS expiresAt, `active` " +
				"FROM `phoenix_bans` WHERE `active` = 1 ORDER BY `id` DESC LIMIT 200"
		}
		ORM.engine.executeAsync(sql, function(rows) {
			local out = []
			foreach (r in rows) out.append(r)
			phoenix.admin.Server.reply(playerId, "bans", true, "", { bans = out })
		})
	}

	function dispatchInspectInventory(playerId, payload) {
		local characterId = (payload != null && "characterId" in payload) ? payload.characterId : 0
		if (characterId <= 0) return phoenix.admin.Server.reply(playerId, "inv", false, "id", null)

		local function send(items, gold) {
			local rows = []
			foreach (it in items) {
				rows.append({
					id = ("id" in it) ? it.id : 0,
					instance = ("instanceId" in it) ? it.instanceId : "",
					amount = ("amount" in it) ? it.amount : 1,
					quality = ("quality" in it) ? it.quality : 0,
					upgrade = ("upgrade" in it) ? it.upgrade : 0,
					slot = ("slot" in it) ? it.slot : 0
				})
			}
			phoenix.admin.Server.reply(playerId, "inv", true, "", {
				characterId = characterId, items = rows, gold = gold
			})
		}

		local cacheKey = phoenix.item.Structure.key(PhoenixInventoryOwner.Player, characterId)
		if (cacheKey in phoenix.item.Structure.cache) {
			local entry = phoenix.item.Structure.cache[cacheKey]
			local gold = ("gold" in entry) ? entry.gold : 0
			local items = ("items" in entry) ? entry.items : []
			return send(items, gold)
		}
		try {
			phoenix.item.Structure.loadOwner(PhoenixInventoryOwner.Player, characterId, function(_) {
				local entry2 = (cacheKey in phoenix.item.Structure.cache)
					? phoenix.item.Structure.cache[cacheKey]
					: { items = [], gold = 0 }
				send(("items" in entry2) ? entry2.items : [], ("gold" in entry2) ? entry2.gold : 0)
			})
		} catch (e) {
			send([], 0)
		}
	}

	function audit(adminPid, action, targetType, targetId, targetName, details) {
		local s = phoenix.account.Structure.get(adminPid)
		local adminId = (s != null) ? s.id() : 0
		local adminName = (s != null) ? s.username() : ""
		local adminSql = (adminId > 0) ? adminId.tostring() : "NULL"
		local targetSql = (targetId != null && targetId > 0) ? targetId.tostring() : "NULL"
		local nameEsc = adminName; try { nameEsc = ORM.engine.escape(adminName) } catch (e) {}
		local targetTypeEsc = (targetType == null) ? "" : targetType
		try { targetTypeEsc = ORM.engine.escape(targetTypeEsc) } catch (e) {}
		local targetNameEsc = (targetName == null) ? "" : targetName.tostring()
		try { targetNameEsc = ORM.engine.escape(targetNameEsc) } catch (e) {}
		local detailsEsc = (details == null) ? "" : details.tostring()
		try { detailsEsc = ORM.engine.escape(detailsEsc) } catch (e) {}
		local actionEsc = action; try { actionEsc = ORM.engine.escape(action) } catch (e) {}
		local sql = "INSERT INTO `phoenix_admin_log` (`adminId`,`adminName`,`action`,`targetType`,`targetId`,`targetName`,`details`) VALUES (" +
			adminSql + ",'" + nameEsc + "','" + actionEsc + "','" + targetTypeEsc + "'," + targetSql + ",'" + targetNameEsc + "','" + detailsEsc + "')"
		try { ORM.engine.executeAsync(sql, function(_){}) } catch (e) {}
	}

	function dispatchServerFeaturesGet(playerId, _payload) {
		if (!phoenix.account.Auth.isAdmin(playerId)) {
			phoenix.admin.Server.reply(playerId, "serverFeaturesGet", false, "denied", null)
			return
		}
		phoenix.admin.Server.reply(playerId, "serverFeaturesGet", true, "", phoenix.features.Settings.snapshot())
	}

	function dispatchServerFeaturesUpdate(playerId, payload) {
		if (!phoenix.account.Auth.isAdmin(playerId)) {
			phoenix.admin.Server.reply(playerId, "serverFeaturesUpdate", false, "denied", null)
			return
		}
		local session = phoenix.account.Structure.get(playerId)
		local updatedBy = session != null ? session.id() : 0
		phoenix.features.Settings.update(payload, updatedBy, function (success, error, snapshot, changed) {
			if (success) {
				local changedText = ""
				for (local i = 0; i < changed.len(); i += 1) {
					if (i > 0) changedText += ","
					changedText += changed[i]
				}
				local details = "profile=" + snapshot.profile + ", revision=" + snapshot.revision + ", changed=" + changedText
				phoenix.admin.Server.audit(playerId, "serverFeaturesUpdate", "server", null, snapshot.profile, details)
			}
			phoenix.admin.Server.reply(playerId, "serverFeaturesUpdate", success, error, snapshot)
		})
	}

	function dispatchListLog(playerId, payload) {
		local limit = 100
		if (payload != null && "limit" in payload) limit = payload.limit
		if (limit < 1) limit = 100
		if (limit > 500) limit = 500
		local sql = "SELECT `id`,`adminId`,`adminName`,`action`,`targetType`,`targetId`,`targetName`,`details`,UNIX_TIMESTAMP(`createdAt`) AS createdAt " +
			"FROM `phoenix_admin_log` ORDER BY `id` DESC LIMIT " + limit
		phoenix.admin.Server.ensureTables(function () {
			ORM.engine.executeAsync(sql, function(rows) {
				local out = []
				foreach (r in rows) out.append(r)
				phoenix.admin.Server.reply(playerId, "log", true, "", { entries = out })
			})
		})
	}

	function _localizedPayload(payload, key, legacy) {
		local out = { pl = legacy, en = "", de = "", ru = "" }
		try {
			if (key in payload && payload[key] != null) {
				local source = payload[key]
				foreach (lang in ["pl", "en", "de", "ru"]) if (lang in source && source[lang] != null) out[lang] = source[lang].tostring()
			}
		} catch (e) {}
		return out
	}

	function _customData(payload, inst) {
		local name = ("name" in payload) ? payload.name.tostring() : inst
		local description = ("description" in payload) ? payload.description.tostring() : ""
		local labels = phoenix.admin.Server._localizedPayload(payload, "labels", name)
		local descriptions = phoenix.admin.Server._localizedPayload(payload, "descriptions", description)
		local content = phoenix.admin.Server._localizedPayload(payload, "content", "")
		if (labels.pl == "") labels.pl = name
		if (descriptions.pl == "") descriptions.pl = description
		local onUse = ("onUse" in payload && payload.onUse != null) ? payload.onUse.tostring() : ""
		if (onUse != "" && onUse != "consumable" && onUse != "document") onUse = ""
		local effects = []
		try {
			if ("effects" in payload && payload.effects != null) foreach (raw in payload.effects) {
				local effect = phoenix.item.Effects._normalizeEffect(raw)
				if (effect != null) effects.append(effect)
			}
		} catch (e) {}
		local category = ("category" in payload) ? payload.category.tointeger() : PhoenixItemCategory.Misc
		if (category < 0 || category > PhoenixItemCategory.Misc) category = PhoenixItemCategory.Misc
		local slot = ("slot" in payload) ? payload.slot.tointeger() : 0
		if (slot < 0 || slot > PhoenixItemSlot.Spell) slot = 0
		local value = ("value" in payload) ? payload.value.tointeger() : 0; if (value < 0) value = 0
		local weight = ("weight" in payload) ? payload.weight.tofloat() : 0.0; if (weight < 0.0) weight = 0.0
		local stackMax = ("stackMax" in payload) ? payload.stackMax.tointeger() : 1; if (stackMax < 1) stackMax = 1; if (stackMax > 100000) stackMax = 100000
		local damage = ("damage" in payload) ? payload.damage.tointeger() : 0; if (damage < 0) damage = 0
		local damageType = ("damageType" in payload) ? payload.damageType.tointeger() : 0; if (damageType < 0 || damageType > 4) damageType = 0
		local flags = ("flags" in payload) ? payload.flags.tointeger() : 0
		local protection = { edge = 0, blunt = 0, point = 0, fire = 0, magic = 0 }
		try { if ("protection" in payload && payload.protection != null) foreach (key, val in payload.protection) if (key in protection) protection[key] = val.tointeger() } catch (e) {}
		return { category = category, slot = slot, name = labels.pl, description = descriptions.pl, labels = labels, descriptions = descriptions, content = content, onUse = (onUse == "" ? null : onUse), effects = effects, value = value, visual = ("visual" in payload && payload.visual != null && payload.visual != "") ? payload.visual.tostring() : null, weight = weight, stackMax = stackMax, damage = damage, damageType = damageType, flags = flags, protection = protection }
	}

	function dispatchSaveCustomItem(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "saveCustom", false, "payload", null)
		local inst = ("instance" in payload) ? payload.instance.tostring().toupper() : ""
		if (inst == "" || inst.len() > 64) return phoenix.admin.Server.reply(playerId, "saveCustom", false, "badInstance", null)
		local data = null
		try { data = phoenix.admin.Server._customData(payload, inst) } catch (error) { return phoenix.admin.Server.reply(playerId, "saveCustom", false, "validation", null) }
		local session = phoenix.account.Structure.get(playerId)
		local adminId = session != null ? session.id() : 0
		local adminSql = adminId > 0 ? adminId.tostring() : "NULL"
		local esc = function(value) { try { return ORM.engine.escape(value == null ? "" : value.tostring()) } catch (e) { return "" } }
		local visual = data.visual != null ? data.visual : ""
		local onUse = data.onUse != null ? data.onUse : ""
		local sql = "INSERT INTO `phoenix_custom_items` (`instance`,`category`,`slot`,`name`,`description`,`visual`,`value`,`weight`,`stackMax`,`damage`,`damageType`,`protEdge`,`protBlunt`,`protPoint`,`protFire`,`protMagic`,`flags`,`onUse`,`effectJson`,`labelsJson`,`descriptionsJson`,`contentJson`,`createdBy`) VALUES ('" + esc(inst) + "'," + data.category + "," + data.slot + ",'" + esc(data.name) + "','" + esc(data.description) + "','" + esc(visual) + "'," + data.value + "," + data.weight + "," + data.stackMax + "," + data.damage + "," + data.damageType + "," + data.protection.edge + "," + data.protection.blunt + "," + data.protection.point + "," + data.protection.fire + "," + data.protection.magic + "," + data.flags + ",'" + esc(onUse) + "','" + esc(phoenix.web.Json.encode(data.effects)) + "','" + esc(phoenix.web.Json.encode(data.labels)) + "','" + esc(phoenix.web.Json.encode(data.descriptions)) + "','" + esc(phoenix.web.Json.encode(data.content)) + "'," + adminSql + ") ON DUPLICATE KEY UPDATE `category`=VALUES(`category`),`slot`=VALUES(`slot`),`name`=VALUES(`name`),`description`=VALUES(`description`),`visual`=VALUES(`visual`),`value`=VALUES(`value`),`weight`=VALUES(`weight`),`stackMax`=VALUES(`stackMax`),`damage`=VALUES(`damage`),`damageType`=VALUES(`damageType`),`protEdge`=VALUES(`protEdge`),`protBlunt`=VALUES(`protBlunt`),`protPoint`=VALUES(`protPoint`),`protFire`=VALUES(`protFire`),`protMagic`=VALUES(`protMagic`),`flags`=VALUES(`flags`),`onUse`=VALUES(`onUse`),`effectJson`=VALUES(`effectJson`),`labelsJson`=VALUES(`labelsJson`),`descriptionsJson`=VALUES(`descriptionsJson`),`contentJson`=VALUES(`contentJson`)"
		try {
			ORM.engine.execute("START TRANSACTION")
			ORM.engine.execute(sql)
			ORM.engine.execute("COMMIT")
			phoenix.item.register(inst, data)
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			return phoenix.admin.Server.reply(playerId, "saveCustom", false, "database", null)
		}
		phoenix.admin.Server.audit(playerId, "saveCustom", "item", null, inst, data.name)
		phoenix.admin.Server.reply(playerId, "saveCustom", true, "", { instance = inst })
	}

	function loadCustomItems() {
		try {
			phoenix.admin.Server.ensureTables(function () {
				ORM.engine.executeAsync("SELECT * FROM `phoenix_custom_items`", function(rows) {
					if (rows == null) return
					foreach (r in rows) try {
						local labels = phoenix.web.Json.parse(r.labelsJson); local descriptions = phoenix.web.Json.parse(r.descriptionsJson); local content = phoenix.web.Json.parse(r.contentJson); local effects = phoenix.web.Json.parse(r.effectJson)
						phoenix.item.register(r.instance, { category = r.category, slot = r.slot, name = r.name, description = r.description, labels = labels, descriptions = descriptions, content = content, onUse = (r.onUse != null && r.onUse != "") ? r.onUse : null, effects = effects != null ? effects : [], value = r.value, visual = (r.visual != "" ? r.visual : null), weight = r.weight.tofloat(), stackMax = r.stackMax, damage = r.damage, damageType = r.damageType, flags = r.flags, protection = { edge = r.protEdge, blunt = r.protBlunt, point = r.protPoint, fire = r.protFire, magic = r.protMagic } })
					} catch (e) {}
				})
			})
		} catch (e) {}
	}

	function ensureTables(callback) {
		local sqlLog = "CREATE TABLE IF NOT EXISTS `phoenix_admin_log` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,`adminId` INT NULL,`adminName` VARCHAR(64) DEFAULT '',`action` VARCHAR(48) NOT NULL,`targetType` VARCHAR(24) DEFAULT '',`targetId` INT NULL,`targetName` VARCHAR(64) DEFAULT '',`details` TEXT NULL,`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,KEY `idx_log_admin` (`adminId`),KEY `idx_log_action` (`action`),KEY `idx_log_created` (`createdAt`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		local sqlItems = "CREATE TABLE IF NOT EXISTS `phoenix_custom_items` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,`instance` VARCHAR(64) NOT NULL UNIQUE,`category` TINYINT NOT NULL DEFAULT 0,`slot` TINYINT NOT NULL DEFAULT 0,`name` VARCHAR(96) DEFAULT '',`description` VARCHAR(512) DEFAULT '',`visual` VARCHAR(96) DEFAULT '',`value` INT DEFAULT 0,`weight` FLOAT DEFAULT 0,`stackMax` INT DEFAULT 1,`damage` INT DEFAULT 0,`damageType` TINYINT DEFAULT 0,`protEdge` INT DEFAULT 0,`protBlunt` INT DEFAULT 0,`protPoint` INT DEFAULT 0,`protFire` INT DEFAULT 0,`protMagic` INT DEFAULT 0,`flags` INT DEFAULT 0,`onUse` VARCHAR(24) NOT NULL DEFAULT '',`effectJson` MEDIUMTEXT NULL,`labelsJson` MEDIUMTEXT NULL,`descriptionsJson` MEDIUMTEXT NULL,`contentJson` MEDIUMTEXT NULL,`createdBy` INT NULL,`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,KEY `idx_custom_category` (`category`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try { ORM.engine.executeAsync(sqlLog, function (_) { ORM.engine.executeAsync(sqlItems, function (_) { if (callback != null) callback() }) }) } catch (e) { if (callback != null) callback() }
	}

	function dispatchNpcCatalog(playerId, _payload) {
		phoenix.admin.Server.reply(playerId, "npcCatalog", true, "", { entries = phoenix.npc.Catalog })
	}

	function dispatchNpcCatalogSave(playerId, payload) {
		if (payload == null || !("instance" in payload)) { phoenix.admin.Server.reply(playerId, "npcCatalogSave", false, "badPayload", null); return }
		local instance = payload.instance.tostring().toupper()
		local row = phoenix.npc.findCatalog(instance)
		if (row == null) { phoenix.admin.Server.reply(playerId, "npcCatalogSave", false, "unknown", null); return }
		local label = ("label" in payload) ? payload.label.tostring() : row.label
		local category = ("category" in payload) ? payload.category.tostring() : row.category
		local tier = ("tier" in payload) ? payload.tier.tointeger() : row.tier
		local hostile = ("defaultHostile" in payload) ? payload.defaultHostile.tointeger() : row.defaultHostile
		local baseExperience = ("baseExperience" in payload) ? payload.baseExperience.tointeger() : row.baseExperience
		if (tier < 1) tier = 1
		if (hostile != 0) hostile = 1
		if (baseExperience < 0) baseExperience = 0
		row.label = label
		row.category = category
		row.tier = tier
		row.defaultHostile = hostile
		row.baseExperience = baseExperience
		local esc = phoenix.npc.Spawn._esc
		local tableSql = "CREATE TABLE IF NOT EXISTS `phoenix_npc_catalog_overrides` (`instance` VARCHAR(64) NOT NULL,`label` VARCHAR(128) NOT NULL DEFAULT '',`category` VARCHAR(32) NOT NULL DEFAULT 'monster',`tier` INT NOT NULL DEFAULT 1,`defaultHostile` TINYINT NOT NULL DEFAULT 1,`baseExperience` INT NOT NULL DEFAULT 0,`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY (`instance`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try {
			ORM.engine.executeAsync(tableSql, function (_) {
				local saveSql = "INSERT INTO `phoenix_npc_catalog_overrides` (`instance`,`label`,`category`,`tier`,`defaultHostile`,`baseExperience`) VALUES ('" + esc(instance) + "','" + esc(label) + "','" + esc(category) + "'," + tier + "," + hostile + "," + baseExperience + ") ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`category`=VALUES(`category`),`tier`=VALUES(`tier`),`defaultHostile`=VALUES(`defaultHostile`),`baseExperience`=VALUES(`baseExperience`)"
				ORM.engine.executeAsync(saveSql, function (_) {
					phoenix.admin.Server.audit(playerId, "npcCatalogSave", "npcCatalog", null, instance, "xp=" + baseExperience)
					phoenix.admin.Server.reply(playerId, "npcCatalogSave", true, "", row)
				})
			})
		} catch (e) { phoenix.admin.Server.reply(playerId, "npcCatalogSave", false, "exception", null) }
	}

	function dispatchNpcList(playerId, _payload) {
		try {
			local list = phoenix.npc.Spawn.listAll()
			phoenix.admin.Server.reply(playerId, "npcList", true, "", { spawns = list })
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcList", false, "exception", null)
		}
	}

	function dispatchNpcSpawn(playerId, payload) {
		if (payload == null) {
			phoenix.admin.Server.reply(playerId, "npcSpawn", false, "badPayload", null); return
		}
		local hasInstance = ("instance" in payload) && payload.instance != ""
		local hasPreset = ("presetId" in payload) && payload.presetId > 0
		if (!hasInstance && !hasPreset) {
			phoenix.admin.Server.reply(playerId, "npcSpawn", false, "badInstance", null); return
		}
		try {
			phoenix.npc.spawnAtAdmin(playerId, payload, function (newId) {
				if (newId == null || newId < 0) {
					phoenix.admin.Server.reply(playerId, "npcSpawn", false, "createFail", null); return
				}
				local label = hasInstance ? payload.instance : ("preset#" + payload.presetId)
				phoenix.admin.Server.audit(playerId, "npcSpawn", "npc", null, label, "id=" + newId)
				phoenix.admin.Server.reply(playerId, "npcSpawn", true, "", { id = newId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcSpawn", false, "exception", null)
		}
	}

	function dispatchSpawnTestPlayerNpc(playerId, _payload) {
		local payload = {
			instance = "PC_HERO",
			name = "Testowy gracz",
			tag = "test-player",
			kind = "npc",
			hostile = 0,
			respawnSec = 0,
			bodyModel = "HUM_BODY_NAKED0",
			bodyTex = 1,
			headModel = "HUM_HEAD_PONY",
			headTex = 0,
			fatness = 0.0,
			voice = 0,
			hp = 100,
			level = 1,
			strength = 10,
			dexterity = 10,
			idleAnimation = "S_STAND",
			aggroRadius = 0,
			baseExperience = 0,
			metadata = "{\"testPlayer\":1}"
		}
		try {
			phoenix.npc.spawnAtAdmin(playerId, payload, function(newId) {
				if (newId == null || newId < 0) { phoenix.admin.Server.reply(playerId, "spawnTestPlayerNpc", false, "createFail", null); return }
				phoenix.admin.Server.audit(playerId, "spawnTestPlayerNpc", "npc", null, "Testowy gracz", "id=" + newId)
				phoenix.admin.Server.reply(playerId, "spawnTestPlayerNpc", true, "", { id = newId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "spawnTestPlayerNpc", false, "exception", null)
		}
	}

	function dispatchNpcPreviewRestore(playerId, payload) {
		try {
			phoenix.player.Gate.restoreVisual(playerId)
			local record = null
			try { record = phoenix.character.Structure.getActive(playerId) } catch (er) {}
			if (record != null) {
				try { phoenix.player.Gate.applyEquipment(playerId, record) } catch (ea) {}
				try { phoenix.player.Gate.restoreEquipment(playerId, record) } catch (eb) {}
			}
			phoenix.admin.Server.reply(playerId, "npcPreviewRestore", true, "", null)
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcPreviewRestore", false, "exception", null)
		}
	}

	function dispatchHerbCatalog(playerId, _payload) {
		local out = []
		try {
			foreach (instance, row in phoenix.herb.Catalog) {
				local visual = ""
				try { local v = phoenix.item.lookupVisual(instance); if (v != null) visual = v } catch (e) {}
				out.append({
					instance = instance,
					name = row.pl,
					labelPl = row.pl,
					labelEn = row.en,
					labelDe = row.de,
					labelRu = row.ru,
					rarity = row.rarity,
					gatherMs = row.gatherMs,
					cooldownSec = row.cooldownSec,
					successChance = row.successChance,
					visual = visual
				})
			}
		} catch (e) {}
		phoenix.admin.Server.reply(playerId, "herbCatalog", true, "", { entries = out })
	}

	function dispatchHerbList(playerId, _payload) {
		try {
			phoenix.herb.Structure.loadDbSpots(function() {
				phoenix.admin.Server.reply(playerId, "herbList", true, "", { spots = phoenix.herb.Structure.listSpots() })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "herbList", false, "exception", null)
		}
	}

	function dispatchHerbSave(playerId, payload) {
		try {
			phoenix.herb.Structure.saveSpotFromAdmin(playerId, payload, function(ok, err, spot) {
				if (ok) phoenix.admin.Server.audit(playerId, "herbSave", "herb", null, spot.id, spot.instance)
				phoenix.admin.Server.reply(playerId, "herbSave", ok, err, spot)
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "herbSave", false, "exception", null)
		}
	}

	function dispatchHerbDelete(playerId, payload) {
		if (payload == null || !("plantId" in payload)) {
			phoenix.admin.Server.reply(playerId, "herbDelete", false, "badId", null); return
		}
		local plantId = payload.plantId.tostring()
		try {
			phoenix.herb.Structure.deleteSpot(plantId, function(ok) {
				if (ok) phoenix.admin.Server.audit(playerId, "herbDelete", "herb", null, plantId, "")
				phoenix.admin.Server.reply(playerId, "herbDelete", ok, ok ? "" : "fail", { plantId = plantId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "herbDelete", false, "exception", null)
		}
	}

	function dispatchVobCatalog(playerId, payload) {
		try {
			phoenix.admin.Server.reply(playerId, "vobCatalog", true, "", phoenix.vob.Structure.filteredCatalog(payload))
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "vobCatalog", false, "exception", null)
		}
	}

	function dispatchVobList(playerId, _payload) {
		try {
			phoenix.vob.Structure.listAll(function(entries) {
				phoenix.admin.Server.reply(playerId, "vobList", true, "", { vobs = entries })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "vobList", false, "exception", null)
		}
	}

	function dispatchVobSave(playerId, payload) {
		try {
			phoenix.vob.Structure.saveFromAdmin(playerId, payload, function(ok, err, entry) {
				if (ok) phoenix.admin.Server.audit(playerId, "vobSave", "vob", null, entry.vobId, entry.visual)
				phoenix.admin.Server.reply(playerId, "vobSave", ok, err, entry)
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "vobSave", false, "exception", null)
		}
	}

	function dispatchVobDelete(playerId, payload) {
		if (payload == null || !("vobId" in payload)) {
			phoenix.admin.Server.reply(playerId, "vobDelete", false, "badId", null); return
		}
		local vobId = payload.vobId.tostring()
		try {
			phoenix.vob.Structure.deleteById(vobId, function(ok) {
				if (ok) phoenix.admin.Server.audit(playerId, "vobDelete", "vob", null, vobId, "")
				phoenix.admin.Server.reply(playerId, "vobDelete", ok, ok ? "" : "fail", { vobId = vobId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "vobDelete", false, "exception", null)
		}
	}

	function dispatchHouseList(playerId, _payload) {
		try {
			phoenix.house.Structure.listAll(function(rows) {
				phoenix.admin.Server.reply(playerId, "houseList", true, "", { houses = rows })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "houseList", false, "exception", null)
		}
	}

	function dispatchHouseSave(playerId, payload) {
		try {
			phoenix.house.Structure.saveFromAdmin(playerId, payload, function(ok, err, house) {
				if (ok) phoenix.admin.Server.audit(playerId, "houseSave", "house", house.id, house.name, house.slug)
				phoenix.admin.Server.reply(playerId, "houseSave", ok, err, house)
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "houseSave", false, "exception", null)
		}
	}

	function dispatchHouseDelete(playerId, payload) {
		if (payload == null || !("id" in payload)) {
			phoenix.admin.Server.reply(playerId, "houseDelete", false, "badId", null); return
		}
		local houseId = payload.id.tointeger()
		try {
			phoenix.house.Structure.deleteById(houseId, function(ok) {
				if (ok) phoenix.admin.Server.audit(playerId, "houseDelete", "house", houseId, "", "")
				phoenix.admin.Server.reply(playerId, "houseDelete", ok, ok ? "" : "fail", { id = houseId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "houseDelete", false, "exception", null)
		}
	}

	function dispatchAdminHouseCapture(playerId, payload) {
		local pos = null
		local world = ""
		local angle = 0.0
		try { pos = getPlayerPosition(playerId) } catch (e) { pos = null }
		if (pos == null) {
			phoenix.admin.Server.reply(playerId, "adminHouseCapture", false, "position", null); return
		}
		try { world = getPlayerWorld(playerId) } catch (e) {}
		try { angle = getPlayerAngle(playerId).tofloat() } catch (e2) {}
		local slot = "point"
		local index = -1
		if (payload != null && "slot" in payload && payload.slot != null) slot = payload.slot.tostring()
		if (payload != null && "index" in payload && payload.index != null) {
			try { index = payload.index.tointeger() } catch (e3) { index = -1 }
		}
		phoenix.admin.Server.reply(playerId, "adminHouseCapture", true, "", {
			slot = slot,
			index = index,
			world = world,
			posX = pos.x,
			posY = pos.y,
			posZ = pos.z,
			angle = angle
		})
	}

	function dispatchRevive(playerId, payload) {
		local target = playerId
		if (payload != null && "target" in payload) {
			try { target = payload.target.tointeger() } catch (e) { target = playerId }
		}
		try {
			if (!isPlayerConnected(target)) {
				phoenix.admin.Server.reply(playerId, "revive", false, "offline", null); return
			}
			local ok = phoenix.player.Gate.revive(target)
			phoenix.admin.Server.audit(playerId, "revive", "player", target, "", "")
			phoenix.admin.Server.reply(playerId, "revive", ok, ok ? "" : "noRecord", { target = target })
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "revive", false, "exception", null)
		}
	}

	function dispatchNpcDelete(playerId, payload) {
		if (payload == null || !("id" in payload)) {
			phoenix.admin.Server.reply(playerId, "npcDelete", false, "badId", null); return
		}
		local sid = payload.id
		try {
			phoenix.npc.Spawn.remove(sid, function (ok) {
				phoenix.admin.Server.audit(playerId, "npcDelete", "npc", null, "id=" + sid, "")
				phoenix.admin.Server.reply(playerId, "npcDelete", true, "", { id = sid })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcDelete", false, "exception", null)
		}
	}

	function dispatchNpcUpdate(playerId, payload) {
		if (payload == null || !("id" in payload) || !("fields" in payload)) {
			phoenix.admin.Server.reply(playerId, "npcUpdate", false, "badPayload", null); return
		}
		try {
			phoenix.npc.Spawn.update(payload.id, payload.fields, function (ok) {
				phoenix.admin.Server.audit(playerId, "npcUpdate", "npc", null, "id=" + payload.id, "")
				phoenix.admin.Server.reply(playerId, "npcUpdate", ok, ok ? "" : "fail", { id = payload.id })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcUpdate", false, "exception", null)
		}
	}

	function dispatchBestiary(playerId, payload) {
		local cid = (payload != null && "characterId" in payload) ? payload.characterId : 0
		if (cid <= 0) { phoenix.admin.Server.reply(playerId, "bestiary", false, "badCharacter", null); return }
		try {
			phoenix.npc.Bestiary.loadFor(cid, function (rows) {
				phoenix.admin.Server.reply(playerId, "bestiary", true, "", { characterId = cid, entries = rows })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "bestiary", false, "exception", null)
		}
	}

	function dispatchNpcPresetList(playerId, _payload) {
		try {
			phoenix.npc.Preset.loadAll(function (list) {
				phoenix.admin.Server.reply(playerId, "npcPresetList", true, "", { presets = list })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcPresetList", false, "exception", null)
		}
	}

	function dispatchNpcPresetSave(playerId, payload) {
		if (payload == null) { phoenix.admin.Server.reply(playerId, "npcPresetSave", false, "empty", null); return }
		payload.createdBy <- playerId
		try {
			phoenix.npc.Preset.save(payload, function (id) {
				if (id <= 0) {
					phoenix.admin.Server.reply(playerId, "npcPresetSave", false, "saveFail", null); return
				}
				phoenix.admin.Server.audit(playerId, "npcPresetSave", "npcPreset", null,
					("code" in payload) ? payload.code : "", ("label" in payload) ? payload.label : "")
				phoenix.admin.Server.reply(playerId, "npcPresetSave", true, "", { id = id })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcPresetSave", false, "exception", null)
		}
	}

	function dispatchNpcPresetDelete(playerId, payload) {
		if (payload == null || !("id" in payload)) {
			phoenix.admin.Server.reply(playerId, "npcPresetDelete", false, "badId", null); return
		}
		try {
			phoenix.npc.Preset.remove(payload.id, function (_) {
				phoenix.admin.Server.audit(playerId, "npcPresetDelete", "npcPreset", null, "id=" + payload.id, "")
				phoenix.admin.Server.reply(playerId, "npcPresetDelete", true, "", { id = payload.id })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcPresetDelete", false, "exception", null)
		}
	}

	function dispatchNpcRoutineGet(playerId, payload) {
		if (payload == null || !("spawnId" in payload)) {
			phoenix.admin.Server.reply(playerId, "npcRoutineGet", false, "badSpawn", null); return
		}
		try {
			local r = phoenix.npc.Routines.getBySpawnId(payload.spawnId)
			local out = r != null ? r : { spawnId = payload.spawnId, enabled = 1, loop = 1, nodes = [] }
			phoenix.admin.Server.reply(playerId, "npcRoutineGet", true, "", { spawnId = payload.spawnId, routine = out })
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcRoutineGet", false, "exception", null)
		}
	}

	function dispatchNpcRoutineSave(playerId, payload) {
		if (payload == null || !("spawnId" in payload)) {
			phoenix.admin.Server.reply(playerId, "npcRoutineSave", false, "badPayload", null); return
		}
		try {
			local session = phoenix.account.Structure.get(playerId)
			local input = {
				enabled = ("enabled" in payload) ? payload.enabled : 1,
				loop = ("loop" in payload) ? payload.loop : 1,
				nodes = ("nodes" in payload) ? payload.nodes : [],
				createdBy = session != null ? session.id() : 0
			}
			phoenix.npc.Routines.save(payload.spawnId, input, function (ok) {
				phoenix.admin.Server.audit(playerId, "npcRoutineSave", "npcRoutine", null, "spawn=" + payload.spawnId, "nodes=" + input.nodes.len())
				phoenix.admin.Server.reply(playerId, "npcRoutineSave", ok, ok ? "" : "saveFail", { spawnId = payload.spawnId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcRoutineSave", false, "exception", null)
		}
	}

	function dispatchNpcRoutineDelete(playerId, payload) {
		if (payload == null || !("spawnId" in payload)) {
			phoenix.admin.Server.reply(playerId, "npcRoutineDelete", false, "badSpawn", null); return
		}
		try {
			phoenix.npc.Routines.remove(payload.spawnId, function (_) {
				phoenix.admin.Server.audit(playerId, "npcRoutineDelete", "npcRoutine", null, "spawn=" + payload.spawnId, "")
				phoenix.admin.Server.reply(playerId, "npcRoutineDelete", true, "", { spawnId = payload.spawnId })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcRoutineDelete", false, "exception", null)
		}
	}

	function dispatchNpcRoutineCapturePos(playerId, _payload) {
		try {
			local p = getPlayerPosition(playerId)
			local a = getPlayerAngle(playerId)
			if (p == null) { phoenix.admin.Server.reply(playerId, "npcRoutineCapturePos", false, "noPos", null); return }
			phoenix.admin.Server.reply(playerId, "npcRoutineCapturePos", true, "", { x = p.x, y = p.y, z = p.z, angle = a })
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "npcRoutineCapturePos", false, "exception", null)
		}
	}

	function _dbSafeIdent(name) {
		if (name == null) return null
		local s = name.tostring()
		if (s.len() == 0 || s.len() > 64) return null
		for (local i = 0; i < s.len(); i += 1) {
			local c = s[i]
			local ok = (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_'
			if (!ok) return null
		}
		return s
	}

	function _dbIsManagedTable(table) {
		if (table == null) return false
		local s = table.tostring()
		if (s.len() < 8) return false
		return s.slice(0, 8) == "phoenix_"
	}

	function _dbEscape(v) {
		if (v == null) return "NULL"
		if (typeof v == "string") {
			try { return "'" + ORM.engine.escape(v) + "'" } catch (e) { return "'" + v + "'" }
		}
		if (typeof v == "integer" || typeof v == "float" || typeof v == "bool") {
			return v.tostring()
		}
		try { return "'" + ORM.engine.escape(v.tostring()) + "'" } catch (e) { return "'" + v.tostring() + "'" }
	}

	function dispatchDbTables(playerId, _payload) {
		local sql = "SELECT TABLE_NAME AS `name`, TABLE_ROWS AS `rowCount`, ENGINE AS `engine` FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME"
		try {
			ORM.engine.executeAsync(sql, function (rows) {
				local out = []
				if (rows != null) foreach (r in rows) out.append(r)
				phoenix.admin.Server.reply(playerId, "dbTables", true, "", { tables = out })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "dbTables", false, "exception", null)
		}
	}

	function dispatchDbTableSchema(playerId, payload) {
		local table = (payload != null && "table" in payload) ? phoenix.admin.Server._dbSafeIdent(payload.table) : null
		if (table == null) { phoenix.admin.Server.reply(playerId, "dbTableSchema", false, "badTable", null); return }
		local sql = "SELECT COLUMN_NAME AS name, COLUMN_TYPE AS type, IS_NULLABLE AS nullable, COLUMN_KEY AS keyType, COLUMN_DEFAULT AS defaultValue, EXTRA AS extra " +
			"FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '" + table + "' ORDER BY ORDINAL_POSITION"
		try {
			ORM.engine.executeAsync(sql, function (rows) {
				local out = []
				if (rows != null) foreach (r in rows) out.append(r)
				phoenix.admin.Server.reply(playerId, "dbTableSchema", true, "", { table = table, columns = out })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "dbTableSchema", false, "exception", null)
		}
	}

	function dispatchDbRows(playerId, payload) {
		local table = (payload != null && "table" in payload) ? phoenix.admin.Server._dbSafeIdent(payload.table) : null
		if (table == null) { phoenix.admin.Server.reply(playerId, "dbRows", false, "badTable", null); return }
		local limit = 100
		if (payload != null && "limit" in payload) limit = payload.limit.tointeger()
		if (limit < 1) limit = 1
		if (limit > 500) limit = 500
		local offset = 0
		if (payload != null && "offset" in payload) offset = payload.offset.tointeger()
		if (offset < 0) offset = 0
		local order = (payload != null && "orderBy" in payload) ? phoenix.admin.Server._dbSafeIdent(payload.orderBy) : null
		local dir = (payload != null && "orderDir" in payload && payload.orderDir.tostring().toupper() == "ASC") ? "ASC" : "DESC"
		local where = ""
		if (payload != null && "filterColumn" in payload && "filterValue" in payload) {
			local col = phoenix.admin.Server._dbSafeIdent(payload.filterColumn)
			if (col != null) {
				where = " WHERE `" + col + "` = " + phoenix.admin.Server._dbEscape(payload.filterValue)
			}
		}
		local sql = "SELECT * FROM `" + table + "`" + where
		if (order != null) sql += " ORDER BY `" + order + "` " + dir
		sql += " LIMIT " + limit + " OFFSET " + offset
		local countSql = "SELECT COUNT(*) AS total FROM `" + table + "`" + where
		try {
			ORM.engine.executeAsync(countSql, function (countRows) {
				local total = 0
				if (countRows != null && countRows.len() > 0 && "total" in countRows[0]) total = countRows[0].total
				ORM.engine.executeAsync(sql, function (rows) {
					local out = []
					if (rows != null) foreach (r in rows) out.append(r)
					phoenix.admin.Server.reply(playerId, "dbRows", true, "", { table = table, rows = out, total = total, offset = offset, limit = limit })
				})
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "dbRows", false, "exception", null)
		}
	}

	function _dbReloadAfterEdit(table, pkCol, pkValue) {
		if (table == null || table == "") return
		if (table == "phoenix_characters" && pkCol == "id") {
			local characterId = -1
			try { characterId = pkValue.tointeger() } catch (e) {}
			if (characterId > 0) {
				try { phoenix.character.Structure.reloadByCharacterId(characterId) } catch (eR) {}
			}
		}
	}

	function dispatchDbRowUpdate(playerId, payload) {
		local table = (payload != null && "table" in payload) ? phoenix.admin.Server._dbSafeIdent(payload.table) : null
		if (table == null) { phoenix.admin.Server.reply(playerId, "dbRowUpdate", false, "badTable", null); return }
		if (!phoenix.admin.Server._dbIsManagedTable(table)) { phoenix.admin.Server.reply(playerId, "dbRowUpdate", false, "tableNotEditable", null); return }
		if (payload == null || !("pkColumn" in payload) || !("pkValue" in payload) || !("changes" in payload)) {
			phoenix.admin.Server.reply(playerId, "dbRowUpdate", false, "badPayload", null); return
		}
		local pkCol = phoenix.admin.Server._dbSafeIdent(payload.pkColumn)
		if (pkCol == null) { phoenix.admin.Server.reply(playerId, "dbRowUpdate", false, "badPk", null); return }
		local sets = []
		foreach (k, v in payload.changes) {
			local colName = phoenix.admin.Server._dbSafeIdent(k)
			if (colName == null) continue
			sets.append("`" + colName + "` = " + phoenix.admin.Server._dbEscape(v))
		}
		if (sets.len() == 0) { phoenix.admin.Server.reply(playerId, "dbRowUpdate", false, "noChanges", null); return }
		local setSql = sets.reduce(function (a, b) { return a + ", " + b })
		local sql = "UPDATE `" + table + "` SET " + setSql + " WHERE `" + pkCol + "` = " + phoenix.admin.Server._dbEscape(payload.pkValue) + " LIMIT 1"
		try {
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.admin.Server.audit(playerId, "dbRowUpdate", "db:" + table, null, pkCol + "=" + payload.pkValue, setSql)
				phoenix.admin.Server.reply(playerId, "dbRowUpdate", true, "", { table = table })
				try { phoenix.admin.Server._dbReloadAfterEdit(table, pkCol, payload.pkValue) } catch (eRel) {}
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "dbRowUpdate", false, "exception", null)
		}
	}

	function dispatchDbRowInsert(playerId, payload) {
		local table = (payload != null && "table" in payload) ? phoenix.admin.Server._dbSafeIdent(payload.table) : null
		if (table == null) { phoenix.admin.Server.reply(playerId, "dbRowInsert", false, "badTable", null); return }
		if (!phoenix.admin.Server._dbIsManagedTable(table)) { phoenix.admin.Server.reply(playerId, "dbRowInsert", false, "tableNotEditable", null); return }
		if (payload == null || !("values" in payload)) { phoenix.admin.Server.reply(playerId, "dbRowInsert", false, "badPayload", null); return }
		local cols = []
		local vals = []
		foreach (k, v in payload.values) {
			local colName = phoenix.admin.Server._dbSafeIdent(k)
			if (colName == null) continue
			cols.append("`" + colName + "`")
			vals.append(phoenix.admin.Server._dbEscape(v))
		}
		if (cols.len() == 0) { phoenix.admin.Server.reply(playerId, "dbRowInsert", false, "noValues", null); return }
		local sql = "INSERT INTO `" + table + "` (" + cols.reduce(function (a, b) { return a + "," + b }) + ") VALUES (" + vals.reduce(function (a, b) { return a + "," + b }) + ")"
		try {
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.admin.Server.audit(playerId, "dbRowInsert", "db:" + table, null, "", "")
				phoenix.admin.Server.reply(playerId, "dbRowInsert", true, "", { table = table })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "dbRowInsert", false, "exception", null)
		}
	}

	function dispatchDbRowDelete(playerId, payload) {
		local table = (payload != null && "table" in payload) ? phoenix.admin.Server._dbSafeIdent(payload.table) : null
		if (table == null) { phoenix.admin.Server.reply(playerId, "dbRowDelete", false, "badTable", null); return }
		if (!phoenix.admin.Server._dbIsManagedTable(table)) { phoenix.admin.Server.reply(playerId, "dbRowDelete", false, "tableNotEditable", null); return }
		if (payload == null || !("pkColumn" in payload) || !("pkValue" in payload)) {
			phoenix.admin.Server.reply(playerId, "dbRowDelete", false, "badPayload", null); return
		}
		local pkCol = phoenix.admin.Server._dbSafeIdent(payload.pkColumn)
		if (pkCol == null) { phoenix.admin.Server.reply(playerId, "dbRowDelete", false, "badPk", null); return }
		local sql = "DELETE FROM `" + table + "` WHERE `" + pkCol + "` = " + phoenix.admin.Server._dbEscape(payload.pkValue) + " LIMIT 1"
		try {
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.admin.Server.audit(playerId, "dbRowDelete", "db:" + table, null, pkCol + "=" + payload.pkValue, "")
				phoenix.admin.Server.reply(playerId, "dbRowDelete", true, "", { table = table })
			})
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "dbRowDelete", false, "exception", null)
		}
	}

	function _ensureSpawnConfigTable(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_admin_config` (" +
			"`id` INT UNSIGNED NOT NULL AUTO_INCREMENT," +
			"`configKey` VARCHAR(64) NOT NULL," +
			"`payload` TEXT NOT NULL," +
			"`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"PRIMARY KEY (`id`),UNIQUE KEY `idx_config_key` (`configKey`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback() }) }
		catch (e) { if (callback != null) callback() }
	}

	function dispatchSpawnConfigGet(playerId, _payload) {
		phoenix.admin.Server._ensureSpawnConfigTable(function () {
			local sql = "SELECT `configKey`, `payload` FROM `phoenix_admin_config` WHERE `configKey` IN ('lobbyCameras','characterDefaultSpawn','characterScenarios','characterCreateCamera','characterSelectCamera','hudPortrait')"
			ORM.engine.executeAsync(sql, function (rows) {
				local out = { lobbyCameras = "", characterDefaultSpawn = "", characterScenarios = "", characterCreateCamera = "", characterSelectCamera = "", hudPortrait = "" }
				if (rows != null) foreach (r in rows) {
					if (!("configKey" in r)) continue
					local key = r.configKey.tostring()
					local val = ("payload" in r) ? r.payload.tostring() : ""
					if (key in out) out[key] = val
				}
				phoenix.admin.Server.reply(playerId, "spawnConfigGet", true, "", out)
			})
		})
	}

	function dispatchSpawnConfigSave(playerId, payload) {
		if (payload == null || !("configKey" in payload) || !("payload" in payload)) {
			phoenix.admin.Server.reply(playerId, "spawnConfigSave", false, "badPayload", null); return
		}
		local key = payload.configKey.tostring()
		if (key != "lobbyCameras" && key != "characterDefaultSpawn" && key != "characterScenarios" &&
			key != "characterCreateCamera" && key != "characterSelectCamera" && key != "hudPortrait") {
			phoenix.admin.Server.reply(playerId, "spawnConfigSave", false, "badKey", null); return
		}
		local raw = payload.payload.tostring()
		local keyEsc = key
		try { keyEsc = ORM.engine.escape(key) } catch (e) {}
		local valEsc = raw
		try { valEsc = ORM.engine.escape(raw) } catch (e) {}
		phoenix.admin.Server._ensureSpawnConfigTable(function () {
			local sql = "INSERT INTO `phoenix_admin_config` (`configKey`,`payload`) VALUES ('" + keyEsc + "','" + valEsc + "') " +
				"ON DUPLICATE KEY UPDATE `payload`=VALUES(`payload`)"
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.admin.Server.audit(playerId, "spawnConfigSave", "config", null, key, "")
				try { phoenix.player.LobbyConfig.broadcast() } catch (e) {}
				phoenix.admin.Server.reply(playerId, "spawnConfigSave", true, "", { configKey = key })
			})
		})
	}

	function dispatchSpawnConfigCapture(playerId, payload) {
		try {
			local p = getPlayerPosition(playerId)
			local a = getPlayerAngle(playerId)
			local w = ""; try { w = getPlayerWorld(playerId) } catch (e) {}
			if (p == null) { phoenix.admin.Server.reply(playerId, "spawnConfigCapture", false, "noPos", null); return }
			local purpose = (payload != null && "purpose" in payload) ? payload.purpose.tostring() : ""
			phoenix.admin.Server.reply(playerId, "spawnConfigCapture", true, "", { x = p.x, y = p.y, z = p.z, angle = a, world = w, purpose = purpose })
		} catch (e) {
			phoenix.admin.Server.reply(playerId, "spawnConfigCapture", false, "exception", null)
		}
	}

	function _ensureBestiaryRenderTable(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_bestiary_render` (" +
			"`instance` VARCHAR(64) NOT NULL," +
			"`rotX` FLOAT NOT NULL DEFAULT 0.158," +
			"`rotY` FLOAT NOT NULL DEFAULT -0.853," +
			"`rotZ` FLOAT NOT NULL DEFAULT 0," +
			"`scaleValue` FLOAT NOT NULL DEFAULT 1.5," +
			"`lightIntensity` FLOAT NOT NULL DEFAULT 2.3," +
			"`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"PRIMARY KEY (`instance`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback() }) }
		catch (e) { if (callback != null) callback() }
	}

	function dispatchBestiaryRenderList(playerId, _payload) {
		phoenix.admin.Server._ensureBestiaryRenderTable(function () {
			ORM.engine.executeAsync("SELECT `instance`,`rotX`,`rotY`,`rotZ`,`scaleValue`,`lightIntensity` FROM `phoenix_bestiary_render`", function (rows) {
				local out = []
				if (rows != null) foreach (r in rows) out.append(r)
				phoenix.admin.Server.reply(playerId, "bestiaryRenderList", true, "", { entries = out })
			})
		})
	}

	function dispatchBestiaryRenderSave(playerId, payload) {
		if (payload == null || !("instance" in payload)) {
			phoenix.admin.Server.reply(playerId, "bestiaryRenderSave", false, "badPayload", null); return
		}
		local instance = payload.instance.tostring().toupper()
		local function cleanFloat(key, fallback) {
			if (!(key in payload)) return fallback
			try { return payload[key].tofloat() } catch (e) { return fallback }
		}
		local rotX = cleanFloat("rotX", 0.158)
		local rotY = cleanFloat("rotY", -0.853)
		local rotZ = cleanFloat("rotZ", 0.0)
		local scaleValue = cleanFloat("scaleValue", 1.5)
		local lightIntensity = cleanFloat("lightIntensity", 2.3)
		local instEsc = instance
		try { instEsc = ORM.engine.escape(instance) } catch (e) {}
		phoenix.admin.Server._ensureBestiaryRenderTable(function () {
			local sql = "INSERT INTO `phoenix_bestiary_render` (`instance`,`rotX`,`rotY`,`rotZ`,`scaleValue`,`lightIntensity`) VALUES ('" + instEsc + "'," + rotX + "," + rotY + "," + rotZ + "," + scaleValue + "," + lightIntensity + ") ON DUPLICATE KEY UPDATE `rotX`=VALUES(`rotX`),`rotY`=VALUES(`rotY`),`rotZ`=VALUES(`rotZ`),`scaleValue`=VALUES(`scaleValue`),`lightIntensity`=VALUES(`lightIntensity`)"
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.admin.Server.audit(playerId, "bestiaryRenderSave", "bestiary", null, instance, "rotX=" + rotX + " rotY=" + rotY + " scale=" + scaleValue)
				try { phoenix.npc.BestiaryRender.broadcast() } catch (eB) {}
				phoenix.admin.Server.reply(playerId, "bestiaryRenderSave", true, "", { instance = instance, rotX = rotX, rotY = rotY, rotZ = rotZ, scaleValue = scaleValue, lightIntensity = lightIntensity })
			})
		})
	}

	function _ensureItemRenderTable(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_item_render` (" +
			"`instance` VARCHAR(64) NOT NULL," +
			"`rotX` FLOAT NOT NULL DEFAULT 1.584," +
			"`rotY` FLOAT NOT NULL DEFAULT -1.662," +
			"`rotZ` FLOAT NOT NULL DEFAULT -0.488," +
			"`scaleValue` FLOAT NOT NULL DEFAULT 1.4," +
			"`lightIntensity` FLOAT NOT NULL DEFAULT 2.85," +
			"`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"PRIMARY KEY (`instance`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback() }) }
		catch (e) { if (callback != null) callback() }
	}

	function dispatchItemRenderList(playerId, _payload) {
		phoenix.admin.Server._ensureItemRenderTable(function () {
			ORM.engine.executeAsync("SELECT `instance`,`rotX`,`rotY`,`rotZ`,`scaleValue`,`lightIntensity` FROM `phoenix_item_render`", function (rows) {
				local out = []
				if (rows != null) foreach (r in rows) out.append(r)
				phoenix.admin.Server.reply(playerId, "itemRenderList", true, "", { entries = out })
			})
		})
	}

	function dispatchItemRenderSave(playerId, payload) {
		if (payload == null || !("instance" in payload)) {
			phoenix.admin.Server.reply(playerId, "itemRenderSave", false, "badPayload", null); return
		}
		local instance = payload.instance.tostring().toupper()
		local function cleanFloat(key, fallback) {
			if (!(key in payload)) return fallback
			try { return payload[key].tofloat() } catch (e) { return fallback }
		}
		local rotX = cleanFloat("rotX", 1.584)
		local rotY = cleanFloat("rotY", -1.662)
		local rotZ = cleanFloat("rotZ", -0.488)
		local scaleValue = cleanFloat("scaleValue", 1.4)
		local lightIntensity = cleanFloat("lightIntensity", 2.85)
		local instEsc = instance
		try { instEsc = ORM.engine.escape(instance) } catch (e) {}
		phoenix.admin.Server._ensureItemRenderTable(function () {
			local sql = "INSERT INTO `phoenix_item_render` (`instance`,`rotX`,`rotY`,`rotZ`,`scaleValue`,`lightIntensity`) VALUES ('" + instEsc + "'," + rotX + "," + rotY + "," + rotZ + "," + scaleValue + "," + lightIntensity + ") ON DUPLICATE KEY UPDATE `rotX`=VALUES(`rotX`),`rotY`=VALUES(`rotY`),`rotZ`=VALUES(`rotZ`),`scaleValue`=VALUES(`scaleValue`),`lightIntensity`=VALUES(`lightIntensity`)"
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.admin.Server.audit(playerId, "itemRenderSave", "item", null, instance, "rotX=" + rotX + " rotY=" + rotY + " scale=" + scaleValue)
				try { phoenix.item.RenderConfig.broadcast() } catch (eB) {}
				phoenix.admin.Server.reply(playerId, "itemRenderSave", true, "", { instance = instance, rotX = rotX, rotY = rotY, rotZ = rotZ, scaleValue = scaleValue, lightIntensity = lightIntensity })
			})
		})
	}

	function dispatchItemRenderDelete(playerId, payload) {
		if (payload == null || !("instance" in payload)) {
			phoenix.admin.Server.reply(playerId, "itemRenderDelete", false, "badPayload", null); return
		}
		local instance = payload.instance.tostring().toupper()
		local instEsc = instance
		try { instEsc = ORM.engine.escape(instance) } catch (e) {}
		phoenix.admin.Server._ensureItemRenderTable(function () {
			ORM.engine.executeAsync("DELETE FROM `phoenix_item_render` WHERE `instance` = '" + instEsc + "'", function (_) {
				phoenix.admin.Server.audit(playerId, "itemRenderDelete", "item", null, instance, "")
				try { phoenix.item.RenderConfig.broadcast() } catch (eB) {}
				phoenix.admin.Server.reply(playerId, "itemRenderDelete", true, "", { instance = instance })
			})
		})
	}

	dispatchers = null

	function contentEditorAction(action) {
		local value = action != null ? action.tostring().tolower() : ""
		local exact = {
			schemes = true,
			schemedetails = true,
			savecustom = true,
			adminhousecapture = true,
			spawntestplayernpc = true,
			dbrowupdate = true,
			dbrowinsert = true,
			dbrowdelete = true
		}
		if (value in exact) return true
		local prefixes = ["item", "custom", "npc", "herb", "vob", "quest", "crafting", "profession", "house", "worldclock", "weather", "config", "spawnconfig", "bestiaryrender"]
		foreach (prefix in prefixes) if (value.len() >= prefix.len() && value.slice(0, prefix.len()) == prefix) return true
		return false
	}

	function onRequest(playerId, message) {
		local action = message.action
		local authorized = phoenix.account.Auth.isAdmin(playerId)
		if (!authorized) {
			try { authorized = phoenix.quest.Admin.authorized(playerId, action) } catch (error) { authorized = false }
		}
		if (!authorized) {
			phoenix.admin.Server.reply(playerId, action, false, "denied", null)
			return
		}
		if (!(action in phoenix.admin.Server.dispatchers)) {
			phoenix.admin.Server.reply(playerId, action, false, "unknownAction", null)
			return
		}
		if (phoenix.admin.Server.contentEditorAction(action) && !phoenix.features.Settings.isEnabled("admin.contentEditors")) {
			phoenix.admin.Server.reply(playerId, action, false, "featureDisabled", null)
			return
		}
		try {
			phoenix.admin.Server.dispatchers[action].call(phoenix.admin.Server, playerId, message.payload)
		} catch (e) {
			phoenix.admin.Server.reply(playerId, action, false, "exception", null)
		}
	}
}

phoenix.admin.Server.dispatchers = {
	players = phoenix.admin.Server.dispatchListPlayers,
	serverFeaturesGet = phoenix.admin.Server.dispatchServerFeaturesGet,
	serverFeaturesUpdate = phoenix.admin.Server.dispatchServerFeaturesUpdate,
	setPlayerStats = phoenix.admin.Server.dispatchSetPlayerStats,
	schemes = phoenix.admin.Server.dispatchListSchemes,
	schemeDetails = phoenix.admin.Server.dispatchSchemeDetails,
	giveItem = phoenix.admin.Server.dispatchGiveItem,
	tpTo = phoenix.admin.Server.dispatchTeleportTo,
	tpHere = phoenix.admin.Server.dispatchTeleportHere,
	adminMapPlayers = phoenix.admin.Server.dispatchAdminMapPlayers,
	adminMapTeleport = phoenix.admin.Server.dispatchAdminMapTeleport,
	adminFly = phoenix.admin.Server.dispatchAdminFly,
	adminGodmode = phoenix.admin.Server.dispatchAdminGodmode,
	kick = phoenix.admin.Server.dispatchKick,
	ban = phoenix.admin.Server.dispatchBan,
	unban = phoenix.admin.Server.dispatchUnban,
	bans = phoenix.admin.Server.dispatchListBans,
	inv = phoenix.admin.Server.dispatchInspectInventory,
	vanish = phoenix.admin.Server.dispatchVanish,
	log = phoenix.admin.Server.dispatchListLog,
	saveCustom = phoenix.admin.Server.dispatchSaveCustomItem,
	npcCatalog = phoenix.admin.Server.dispatchNpcCatalog,
	npcCatalogSave = phoenix.admin.Server.dispatchNpcCatalogSave,
	npcList = phoenix.admin.Server.dispatchNpcList,
	npcSpawn = phoenix.admin.Server.dispatchNpcSpawn,
	spawnTestPlayerNpc = phoenix.admin.Server.dispatchSpawnTestPlayerNpc,
	npcPreviewRestore = phoenix.admin.Server.dispatchNpcPreviewRestore,
	revive = phoenix.admin.Server.dispatchRevive,
	npcDelete = phoenix.admin.Server.dispatchNpcDelete,
	npcUpdate = phoenix.admin.Server.dispatchNpcUpdate,
	npcPresetList = phoenix.admin.Server.dispatchNpcPresetList,
	npcPresetSave = phoenix.admin.Server.dispatchNpcPresetSave,
	npcPresetDelete = phoenix.admin.Server.dispatchNpcPresetDelete,
	npcRoutineGet = phoenix.admin.Server.dispatchNpcRoutineGet,
	npcRoutineSave = phoenix.admin.Server.dispatchNpcRoutineSave,
	npcRoutineDelete = phoenix.admin.Server.dispatchNpcRoutineDelete,
	npcRoutineCapturePos = phoenix.admin.Server.dispatchNpcRoutineCapturePos,
	herbCatalog = phoenix.admin.Server.dispatchHerbCatalog,
	herbList = phoenix.admin.Server.dispatchHerbList,
	herbSave = phoenix.admin.Server.dispatchHerbSave,
	herbDelete = phoenix.admin.Server.dispatchHerbDelete,
	vobCatalog = phoenix.admin.Server.dispatchVobCatalog,
	vobList = phoenix.admin.Server.dispatchVobList,
	vobSave = phoenix.admin.Server.dispatchVobSave,
	vobDelete = phoenix.admin.Server.dispatchVobDelete,
	houseList = phoenix.admin.Server.dispatchHouseList,
	houseSave = phoenix.admin.Server.dispatchHouseSave,
	houseDelete = phoenix.admin.Server.dispatchHouseDelete,
	adminHouseCapture = phoenix.admin.Server.dispatchAdminHouseCapture,
	bestiary = phoenix.admin.Server.dispatchBestiary,
	dbTables = phoenix.admin.Server.dispatchDbTables,
	dbTableSchema = phoenix.admin.Server.dispatchDbTableSchema,
	dbRows = phoenix.admin.Server.dispatchDbRows,
	dbRowUpdate = phoenix.admin.Server.dispatchDbRowUpdate,
	dbRowInsert = phoenix.admin.Server.dispatchDbRowInsert,
	dbRowDelete = phoenix.admin.Server.dispatchDbRowDelete,
	spawnConfigGet = phoenix.admin.Server.dispatchSpawnConfigGet,
	spawnConfigSave = phoenix.admin.Server.dispatchSpawnConfigSave,
	spawnConfigCapture = phoenix.admin.Server.dispatchSpawnConfigCapture,
	bestiaryRenderList = phoenix.admin.Server.dispatchBestiaryRenderList,
	bestiaryRenderSave = phoenix.admin.Server.dispatchBestiaryRenderSave,
	itemRenderList = phoenix.admin.Server.dispatchItemRenderList,
	itemRenderSave = phoenix.admin.Server.dispatchItemRenderSave,
	itemRenderDelete = phoenix.admin.Server.dispatchItemRenderDelete,
	questList = phoenix.quest.Admin.list,
	questGet = phoenix.quest.Admin.get,
	questSave = phoenix.quest.Admin.save,
	questClone = phoenix.quest.Admin.cloneQuest,
	questValidate = phoenix.quest.Admin.validate,
	questPublish = phoenix.quest.Admin.publish,
	questArchive = phoenix.quest.Admin.archive,
	questDelete = phoenix.quest.Admin.deleteDefinition,
	questForceDelete = phoenix.quest.Admin.forceDeleteDefinition,
	questCatalog = phoenix.quest.Admin.catalog,
	questLegacyReport = phoenix.quest.Admin.legacyReport,
	questLegacyConvert = phoenix.quest.Admin.legacyConvert
}

phoenix.admin.Message.Request.bind(phoenix.admin.Server.onRequest)

addEventHandler("phoenix.database.OnReady", function () {
	try { phoenix.admin.Server.loadCustomItems() } catch (e) {}
})

addEventHandler("onPlayerDisconnect", function (playerId, _reason) {
	if (playerId in phoenix.admin.Server.flyStates) phoenix.admin.Server.flyStates.rawdelete(playerId)
	if (playerId in phoenix.admin.Server.godmodeStates) phoenix.admin.Server.godmodeStates.rawdelete(playerId)
	if (playerId in phoenix.admin.Server.mapPlayerPollAt) phoenix.admin.Server.mapPlayerPollAt.rawdelete(playerId)
})

addEventHandler("phoenix.character.OnSelected", function (playerId, _characterId) {
	if (playerId in phoenix.admin.Server.mapPlayerPollAt) phoenix.admin.Server.mapPlayerPollAt.rawdelete(playerId)
	phoenix.admin.Server.disableFly(playerId)
	if (playerId in phoenix.admin.Server.godmodeStates) {
		phoenix.admin.Server.godmodeStates.rawdelete(playerId)
		phoenix.admin.Server.reply(playerId, "adminGodmode", true, "", { enabled = false })
	}
})

try {
	ORM.engine.executeAsync("CREATE TABLE IF NOT EXISTS `phoenix_npc_catalog_overrides` (`instance` VARCHAR(64) NOT NULL,`label` VARCHAR(128) NOT NULL DEFAULT '',`category` VARCHAR(32) NOT NULL DEFAULT 'monster',`tier` INT NOT NULL DEFAULT 1,`defaultHostile` TINYINT NOT NULL DEFAULT 1,`baseExperience` INT NOT NULL DEFAULT 0,`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY (`instance`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", function (_) {
		ORM.engine.executeAsync("SELECT * FROM `phoenix_npc_catalog_overrides`", function (rows) {
			if (rows == null) return
			foreach (r in rows) {
				local instance = phoenix.npc.Spawn._readStr(r, "instance", "")
				local row = phoenix.npc.findCatalog(instance)
				if (row == null) continue
				row.label = phoenix.npc.Spawn._readStr(r, "label", row.label)
				row.category = phoenix.npc.Spawn._readStr(r, "category", row.category)
				row.tier = phoenix.npc.Spawn._readInt(r, "tier", row.tier)
				row.defaultHostile = phoenix.npc.Spawn._readInt(r, "defaultHostile", row.defaultHostile)
				row.baseExperience = phoenix.npc.Spawn._readInt(r, "baseExperience", row.baseExperience)
			}
		})
	})
} catch (e) {}
