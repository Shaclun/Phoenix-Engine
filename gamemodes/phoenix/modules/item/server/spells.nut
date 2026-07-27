phoenix.item.Spells <- {
	registry = {}
	cooldown = {}
	pendingCast = {}
	pendingScroll = {}

	maxLevel = 60
	xpFromScroll = 1
	xpFromRune   = 5

	function xpToNext(level) {
		if (level >= phoenix.item.Spells.maxLevel) return 0
		return 20 + level * level * 3
	}

	function circleForLevel(level) {
		if (level <= 0) return 0
		local c = (level / 10).tointeger()
		if (c < 1) return 0
		if (c > 6) return 6
		return c
	}

	function levelForCircle(circle) {
		if (circle <= 0) return 0
		if (circle > 6) circle = 6
		return circle * 10
	}

	function _addXp(playerId, amount) {
		if (!phoenix.features.Settings.isEnabled("progression.magicExperience")) return
		if (amount == null || amount <= 0) return
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		if (!("magicLevel" in record) || record.magicLevel == null) record.magicLevel <- 0
		if (!("magicXp" in record) || record.magicXp == null) record.magicXp <- 0
		if (record.magicLevel >= phoenix.item.Spells.maxLevel) return
		record.magicXp += amount
		local leveledUp = false
		while (record.magicLevel < phoenix.item.Spells.maxLevel) {
			local needed = phoenix.item.Spells.xpToNext(record.magicLevel)
			if (needed <= 0) break
			if (record.magicXp < needed) break
			record.magicXp -= needed
			record.magicLevel += 1
			leveledUp = true
		}
		if (leveledUp) {
			local previousManaMax = record.manaMax
			try { phoenix.player.Progression.normalizeRecordStats(record) } catch (eN) {}
			if (record.manaMax > previousManaMax) {
				phoenix.player.Resources.syncMaximums(playerId, record)
				phoenix.player.Resources.set(playerId, record, "mana", phoenix.player.Resources.max(record, "mana", playerId), true)
			}
			try {
				local sql2 = "UPDATE `phoenix_characters` SET `manaMax` = " + record.manaMax + ", `mana` = " + record.mana + " WHERE `id` = " + record.id
				ORM.engine.executeAsync(sql2, function (_) {})
			} catch (e2) {}
		}
		try {
			local sql = "UPDATE `phoenix_characters` SET `magicLevel` = " + record.magicLevel + ", `magicXp` = " + record.magicXp + " WHERE `id` = " + record.id
			ORM.engine.executeAsync(sql, function (_) {})
		} catch (e) {}
		try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e2) {}
		try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e3) {}
		if (leveledUp) {
			try { phoenix.player.Combat.emitText(playerId, 0, "levelup") } catch (e4) {}
			try { phoenix.notification.notify(playerId, "success", "Magia", "Poziom magii: " + record.magicLevel + " (krag " + phoenix.item.Spells.circleForLevel(record.magicLevel) + ")", 3500) } catch (e5) {}
		}
	}

	function getMagicLevel(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return 0
		if (!("magicLevel" in record) || record.magicLevel == null) return 0
		return record.magicLevel
	}

	function register(key, def) {
		if (key == null || key == "") return
		local up = key.tostring().toupper()
		phoenix.item.Spells.registry[up] <- def
	}

	function find(key) {
		if (key == null) return null
		local up = key.tostring().toupper()
		if (up in phoenix.item.Spells.registry) return phoenix.item.Spells.registry[up]
		return null
	}

	function findByInstance(instanceId) {
		if (instanceId == null) return null
		local up = instanceId.tostring().toupper()
		local key = ""
		if (up.find("ITRU_") == 0) key = up.slice(5)
		else if (up.find("ITSC_") == 0) key = up.slice(5)
		else return null
		return phoenix.item.Spells.find(key)
	}

	function _now() { return getTickCount() }

	function _onCooldown(playerId, spellKey, cooldownMs) {
		if (cooldownMs == null || cooldownMs <= 0) return false
		local now = phoenix.item.Spells._now()
		if (!(playerId in phoenix.item.Spells.cooldown)) phoenix.item.Spells.cooldown[playerId] <- {}
		local map = phoenix.item.Spells.cooldown[playerId]
		if (spellKey in map && now - map[spellKey] < cooldownMs) return true
		return false
	}

	function _markCooldown(playerId, spellKey, cooldownMs) {
		if (cooldownMs == null || cooldownMs <= 0) return
		if (!(playerId in phoenix.item.Spells.cooldown)) phoenix.item.Spells.cooldown[playerId] <- {}
		phoenix.item.Spells.cooldown[playerId][spellKey] <- phoenix.item.Spells._now()
	}

	function _checkMana(playerId, manaCost) {
		if (manaCost == null || manaCost <= 0) return true
		local mana = 0
		try { mana = getPlayerMana(playerId) } catch (e) { return true }
		return mana >= manaCost
	}

	function _consumeMana(playerId, manaCost) {
		if (manaCost == null || manaCost <= 0) return
		local mana = 0
		try { mana = getPlayerMana(playerId) } catch (e) { return }
		local newMana = mana - manaCost
		if (newMana < 0) newMana = 0
		try { setPlayerMana(playerId, newMana) } catch (e) {}
	}


	function tryCast(casterId, spellKey, scheme) {
		if (!phoenix.features.Settings.isEnabled("items.spells")) return { ok = false, reason = "featureDisabled" }
		if (spellKey == null || spellKey == "") return { ok = false, reason = "noSpell" }
		local spell = phoenix.item.Spells.find(spellKey)
		if (spell == null) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Czar nieznany: " + spellKey, 1800) } catch (e) {}
			return { ok = false, reason = "unknownSpell" }
		}
		local circle = ("circle" in spell) ? spell.circle.tointeger() : 1
		if (circle < 1) circle = 1
		local fromScroll = false
		try { if (scheme != null && scheme.category == PhoenixItemCategory.Scroll) fromScroll = true } catch (eC) {}
		if (!fromScroll) {
			local requiredLevel = phoenix.item.Spells.levelForCircle(circle)
			local currentLevel = phoenix.item.Spells.getMagicLevel(casterId)
			if (currentLevel < requiredLevel) {
				try { phoenix.notification.notify(casterId, "warn", "Magia", "Wymagany poziom magii " + requiredLevel + " (krag " + circle + ")", 2400) } catch (e) {}
				return { ok = false, reason = "lowLevel" }
			}
		}
		local manaCost = ("manaCost" in spell) ? spell.manaCost.tointeger() : 0
		if (fromScroll) {
			local discounted = (manaCost / 3).tointeger()
			if (discounted < 5) discounted = 5
			if (discounted > manaCost && manaCost > 0) discounted = manaCost
			manaCost = discounted
		}
		if (!phoenix.item.Spells._checkMana(casterId, manaCost)) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Brak many (" + manaCost + ")", 2200) } catch (e) {}
			return { ok = false, reason = "noMana" }
		}
		local cd = ("cooldownMs" in spell) ? spell.cooldownMs.tointeger() : 0
		if (phoenix.item.Spells._onCooldown(casterId, spellKey, cd)) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Zaklecie nie ostyglo", 1500) } catch (e) {}
			return { ok = false, reason = "cooldown" }
		}
		phoenix.item.Spells.pendingCast[casterId] <- {
			spellKey = spellKey,
			manaCost = manaCost,
			circle   = circle,
			fromScroll = fromScroll,
			scheme = scheme,
			expires = phoenix.item.Spells._now() + 8000
		}
		phoenix.item.Spells._markCooldown(casterId, spellKey, cd)
		return { ok = true, manaCost = manaCost }
	}


	function _consumePending(casterId) {
		if (!(casterId in phoenix.item.Spells.pendingCast)) return null
		local entry = phoenix.item.Spells.pendingCast[casterId]
		phoenix.item.Spells.pendingCast.rawdelete(casterId)
		if (entry.expires < phoenix.item.Spells._now()) return null
		return entry
	}

	function _findSlotIndex(playerId, instanceId) {
		if (instanceId == null) return -1
		local target = instanceId.tostring().toupper()
		for (local i = 0; i <= 6; i++) {
			try {
				local s = getPlayerSpell(playerId, i)
				if (s != null && s.tostring().toupper() == target) return i
			} catch (e) {}
		}
		return -1
	}

	function castFromInventory(playerId, characterId, rec, scheme) {
		if (!phoenix.features.Settings.isEnabled("items.spells")) return
		if (rec == null || scheme == null) return
		local instance = rec.instanceId
		if (instance == null || instance == "") return
		local instUp = instance.tostring().toupper()
		local spell = phoenix.item.Spells.findByInstance(instance)
		if (spell == null) {
			try { phoenix.notification.notify(playerId, "warn", "Magia", "Nieznany czar", 1800) } catch (eN) {}
			return
		}
		local fromScroll = (scheme.category == PhoenixItemCategory.Scroll)
		local circle = ("circle" in spell) ? spell.circle.tointeger() : 1
		if (circle < 1) circle = 1
		if (!fromScroll) {
			local requiredLevel = phoenix.item.Spells.levelForCircle(circle)
			local currentLevel = phoenix.item.Spells.getMagicLevel(playerId)
			if (currentLevel < requiredLevel) {
				try { phoenix.notification.notify(playerId, "warn", "Magia", "Wymagany poziom magii " + requiredLevel + " (krag " + circle + ")", 2400) } catch (e) {}
				return
			}
		}
		local manaCost = ("manaCost" in spell) ? spell.manaCost.tointeger() : 0
		if (fromScroll && manaCost > 0) {
			local d = (manaCost / 3).tointeger()
			if (d < 5) d = 5
			if (d > manaCost) d = manaCost
			manaCost = d
		}
		local mana = 0
		try { mana = getPlayerMana(playerId) } catch (e) {}
		if (manaCost > 0 && mana < manaCost) {
			try { phoenix.notification.notify(playerId, "warn", "Magia", "Brak many (" + manaCost + ")", 2200) } catch (e) {}
			return
		}
		local cd = ("cooldownMs" in spell) ? spell.cooldownMs.tointeger() : 0
		local spellKey = ""
		if (instUp.find("ITRU_") == 0 || instUp.find("ITSC_") == 0) spellKey = instUp.slice(5)
		else spellKey = instUp
		if (phoenix.item.Spells._onCooldown(playerId, spellKey, cd)) {
			try { phoenix.notification.notify(playerId, "warn", "Magia", "Zaklecie nie ostyglo", 1500) } catch (e) {}
			return
		}

		local alreadyEquipped = (rec.equipped == 1)
		if (!alreadyEquipped) {
			try { ::giveItem(playerId, instance, 1) } catch (e) {}
			try { ::equipItem(playerId, instance) } catch (e2) {}
		}

		local capturedPid = playerId
		local capturedInst = instance
		local capturedManaCost = manaCost
		local capturedRecId = rec.id
		local capturedCharId = characterId
		local capturedConsume = fromScroll
		local capturedDelay = alreadyEquipped ? 50 : 200

		if (capturedConsume) {
			phoenix.item.Spells.pendingScroll[capturedPid] <- {
				instance = capturedInst,
				recordId = capturedRecId,
				charId   = capturedCharId,
				temporary = !alreadyEquipped,
				expires  = phoenix.item.Spells._now() + 12000
			}
		}

		setTimer(function() {
			if (!phoenix.features.Settings.isEnabled("items.spells")) return
			try { setPlayerWeaponMode(capturedPid, WEAPONMODE_MAG) } catch (e) {}
			local slotIdx = phoenix.item.Spells._findSlotIndex(capturedPid, capturedInst)
			if (slotIdx < 0) slotIdx = 0
			try { readySpell(capturedPid, slotIdx, capturedManaCost) } catch (e2) {}
		}, capturedDelay, 1)
	}
}


phoenix.item.Spells.register("LIGHT",            { circle = 1, manaCost = 5,   cooldownMs = 1500, label = "Swiatlo" })
phoenix.item.Spells.register("PALLIGHT",         { circle = 1, manaCost = 5,   cooldownMs = 1500, label = "Swiatlo Paladyna" })
phoenix.item.Spells.register("LIGHTHEAL",        { circle = 1, manaCost = 10,  cooldownMs = 2500, label = "Male leczenie" })
phoenix.item.Spells.register("PALLIGHTHEAL",     { circle = 1, manaCost = 12,  cooldownMs = 2500, label = "Swiete leczenie" })
phoenix.item.Spells.register("MEDIUMHEAL",       { circle = 3, manaCost = 30,  cooldownMs = 4000, label = "Srednie leczenie" })
phoenix.item.Spells.register("PALMEDIUMHEAL",    { circle = 3, manaCost = 35,  cooldownMs = 4000, label = "Srednie swiete leczenie" })
phoenix.item.Spells.register("FULLHEAL",         { circle = 5, manaCost = 80,  cooldownMs = 6000, label = "Pelne leczenie" })
phoenix.item.Spells.register("PALFULLHEAL",      { circle = 5, manaCost = 90,  cooldownMs = 6000, label = "Pelne swiete leczenie" })

phoenix.item.Spells.register("ZAP",              { circle = 1, manaCost = 5,   cooldownMs = 1200, label = "Iskra" })
phoenix.item.Spells.register("FIREBOLT",         { circle = 1, manaCost = 12,  cooldownMs = 1500, label = "Pocisk Ognia" })
phoenix.item.Spells.register("PALHOLYBOLT",      { circle = 1, manaCost = 14,  cooldownMs = 1700, label = "Swiety Pocisk" })
phoenix.item.Spells.register("ICEBOLT",          { circle = 2, manaCost = 14,  cooldownMs = 1700, label = "Pocisk Lodu" })
phoenix.item.Spells.register("INSTANTFIREBALL",  { circle = 2, manaCost = 25,  cooldownMs = 2200, label = "Kula Ognia" })
phoenix.item.Spells.register("THUNDERBALL",      { circle = 3, manaCost = 30,  cooldownMs = 2500, label = "Kula Blyskawic" })
phoenix.item.Spells.register("HARMUNDEAD",       { circle = 4, manaCost = 35,  cooldownMs = 2500, label = "Razenie Nieumarych" })
phoenix.item.Spells.register("PALREPELEVIL",     { circle = 3, manaCost = 35,  cooldownMs = 2500, label = "Odpedzenie Zla" })
phoenix.item.Spells.register("CHARGEFIREBALL",   { circle = 4, manaCost = 45,  cooldownMs = 3000, label = "Naladowana Kula Ognia" })
phoenix.item.Spells.register("LIGHTNINGFLASH",   { circle = 4, manaCost = 60,  cooldownMs = 3500, label = "Blyskawica" })
phoenix.item.Spells.register("PALDESTROYEVIL",   { circle = 6, manaCost = 70,  cooldownMs = 4000, label = "Niszcz Zlo" })

phoenix.item.Spells.register("WINDFIST",         { circle = 2, manaCost = 18,  cooldownMs = 2200, label = "Piesc Wiatru" })
phoenix.item.Spells.register("ICECUBE",          { circle = 3, manaCost = 22,  cooldownMs = 2400, label = "Szescian Lodu" })
phoenix.item.Spells.register("FIRESTORM",        { circle = 3, manaCost = 38,  cooldownMs = 3000, label = "Burza Ognia" })
phoenix.item.Spells.register("ICEWAVE",          { circle = 5, manaCost = 55,  cooldownMs = 3500, label = "Fala Lodu" })
phoenix.item.Spells.register("PYROKINESIS",      { circle = 5, manaCost = 60,  cooldownMs = 4000, label = "Pirokineza" })
phoenix.item.Spells.register("FIRERAIN",         { circle = 6, manaCost = 90,  cooldownMs = 5000, label = "Deszcz Ognia" })
phoenix.item.Spells.register("BREATHOFDEATH",    { circle = 6, manaCost = 110, cooldownMs = 5500, label = "Oddech Smierci" })
phoenix.item.Spells.register("MASSDEATH",        { circle = 6, manaCost = 140, cooldownMs = 6500, label = "Masowa Smierc" })
phoenix.item.Spells.register("MASTEROFDISASTER", { circle = 6, manaCost = 180, cooldownMs = 7000, label = "Mistrz Zniszczenia" })

phoenix.item.Spells.register("FEAR",             { circle = 3, manaCost = 25,  cooldownMs = 4000, label = "Strach" })
phoenix.item.Spells.register("SLEEP",            { circle = 2, manaCost = 25,  cooldownMs = 4000, label = "Sen" })
phoenix.item.Spells.register("SHRINK",           { circle = 6, manaCost = 30,  cooldownMs = 4000, label = "Pomniejszenie" })

phoenix.item.Spells.register("SUMGOBSKEL",       { circle = 1, manaCost = 20,  cooldownMs = 6000, label = "Szkielet Goblina" })
phoenix.item.Spells.register("SUMWOLF",          { circle = 2, manaCost = 30,  cooldownMs = 6000, label = "Wilk" })
phoenix.item.Spells.register("SUMSKEL",          { circle = 3, manaCost = 50,  cooldownMs = 7000, label = "Szkielet" })
phoenix.item.Spells.register("SUMGOL",           { circle = 4, manaCost = 80,  cooldownMs = 8000, label = "Golem" })
phoenix.item.Spells.register("SUMDEMON",         { circle = 5, manaCost = 120, cooldownMs = 9000, label = "Demon" })
phoenix.item.Spells.register("ARMYOFDARKNESS",   { circle = 6, manaCost = 150, cooldownMs = 10000, label = "Armia Ciemnosci" })



addEventHandler("onPlayerSpellSetup", function (playerid, instance) {
	if (!phoenix.features.Settings.isEnabled("items.spells")) {
		try { unreadySpell(playerid) } catch (e) {}
		try { cancelEvent() } catch (e2) {}
		return
	}
	if (instance == null) return
	try {
		local spell = phoenix.item.Spells.findByInstance(instance)
		if (spell == null) return
		local instUp = instance.tostring().toupper()
		local fromScroll = instUp.find("ITSC_") == 0
		if (!fromScroll) {
			local circle = ("circle" in spell) ? spell.circle.tointeger() : 1
			local requiredLevel = phoenix.item.Spells.levelForCircle(circle)
			local currentLevel = phoenix.item.Spells.getMagicLevel(playerid)
			if (currentLevel < requiredLevel) {
				try { phoenix.notification.notify(playerid, "warn", "Magia", "Wymagany poziom magii " + requiredLevel + " (krag " + circle + ")", 2400) } catch (eN) {}
				try { unreadySpell(playerid) } catch (eU) {}
				cancelEvent()
				return
			}
		}
	} catch (e) {}
})


addEventHandler("onPlayerSpellCast", function (playerid, instance, spellLevel) {
	if (!phoenix.features.Settings.isEnabled("items.spells")) {
		try { cancelEvent() } catch (e) {}
		return
	}
	if (instance == null) return
	try {
		local spell = phoenix.item.Spells.findByInstance(instance)
		if (spell == null) return
		local instUp = instance.tostring().toupper()
		local fromScroll = instUp.find("ITSC_") == 0
		local circle = ("circle" in spell) ? spell.circle.tointeger() : 1
		if (circle < 1) circle = 1

		if (!fromScroll) {
			local requiredLevel = phoenix.item.Spells.levelForCircle(circle)
			local currentLevel = phoenix.item.Spells.getMagicLevel(playerid)
			if (currentLevel < requiredLevel) {
				try { phoenix.notification.notify(playerid, "warn", "Magia", "Wymagany poziom magii " + requiredLevel + " (krag " + circle + ")", 2400) } catch (eN) {}
				cancelEvent()
				return
			}
		}

		local manaCost = ("manaCost" in spell) ? spell.manaCost.tointeger() : 0
		if (fromScroll) {
			local discounted = (manaCost / 3).tointeger()
			if (discounted < 5) discounted = 5
			if (discounted > manaCost && manaCost > 0) discounted = manaCost
			manaCost = discounted
		}

		local cd = ("cooldownMs" in spell) ? spell.cooldownMs.tointeger() : 0
		local spellKey = ""
		if (instUp.find("ITRU_") == 0 || instUp.find("ITSC_") == 0) spellKey = instUp.slice(5)
		else spellKey = instUp
		if (phoenix.item.Spells._onCooldown(playerid, spellKey, cd)) {
			try { phoenix.notification.notify(playerid, "warn", "Magia", "Zaklecie nie ostyglo", 1500) } catch (e2) {}
			cancelEvent()
			return
		}

		if (manaCost > 0 && !phoenix.item.Spells._checkMana(playerid, manaCost)) {
			try { phoenix.notification.notify(playerid, "warn", "Magia", "Brak many (" + manaCost + ")", 2200) } catch (eM) {}
			cancelEvent()
			return
		}

		phoenix.item.Spells._markCooldown(playerid, spellKey, cd)

		if (fromScroll && playerid in phoenix.item.Spells.pendingScroll) {
			local entry = phoenix.item.Spells.pendingScroll[playerid]
			phoenix.item.Spells.pendingScroll.rawdelete(playerid)
			local capturedPid2 = playerid
			local capturedInst2 = entry.instance
			local capturedRecId2 = entry.recordId
			local capturedCharId2 = entry.charId
			setTimer(function() {
				try { ::removeItem(capturedPid2, capturedInst2, 1) } catch (e) {}
				try {
					local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, capturedCharId2)
					if (inv != null) {
						foreach (it in inv.items) {
							if (it.id == capturedRecId2) {
								phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, capturedCharId2, capturedRecId2, 1)
								break
							}
						}
					}
				} catch (e2) {}
			}, 200, 1)
		}

		local xp = phoenix.item.Spells.xpFromScroll
		if (!fromScroll) xp = phoenix.item.Spells.xpFromRune
		xp = xp + circle
		phoenix.item.Spells._addXp(playerid, xp)
		try { phoenix.player.Hud.pushSnapshot(playerid) } catch (eH) {}
	} catch (e) {}
})


addEventHandler("onPlayerDisconnect", function (playerId, _reason) {
	if (playerId in phoenix.item.Spells.cooldown) phoenix.item.Spells.cooldown.rawdelete(playerId)
	if (playerId in phoenix.item.Spells.pendingCast) phoenix.item.Spells.pendingCast.rawdelete(playerId)
	if (playerId in phoenix.item.Spells.pendingScroll) phoenix.item.Spells.pendingScroll.rawdelete(playerId)
})

addEventHandler("phoenix.features.OnChanged", function(key, enabled) {
	if (key != "items.spells" || enabled) return
	foreach (playerId, entry in phoenix.item.Spells.pendingScroll) {
		if (!("temporary" in entry) || !entry.temporary) continue
		try { ::removeItem(playerId, entry.instance, 1) } catch (e) {}
		try { unreadySpell(playerId) } catch (e2) {}
	}
	phoenix.item.Spells.cooldown = {}
	phoenix.item.Spells.pendingCast = {}
	phoenix.item.Spells.pendingScroll = {}
})
