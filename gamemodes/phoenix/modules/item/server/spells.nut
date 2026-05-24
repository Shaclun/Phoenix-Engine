phoenix.item.Spells <- {
	registry = {}
	cooldown = {}

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
		try {
			local sql = "UPDATE `phoenix_characters` SET `magicLevel` = " + record.magicLevel + ", `magicXp` = " + record.magicXp + " WHERE `id` = " + record.id
			ORM.engine.executeAsync(sql, function (_) {})
		} catch (e) {}
		try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e2) {}
		if (leveledUp) {
			try { phoenix.player.Combat.emitText(playerId, 0, "levelup") } catch (e3) {}
			try { phoenix.notification.notify(playerId, "success", "Magia", "Poziom magii: " + record.magicLevel + " (krag " + phoenix.item.Spells.circleForLevel(record.magicLevel) + ")", 3500) } catch (e4) {}
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

	function _now() { return getTickCount() }

	function _onCooldown(playerId, spellKey, cooldownMs) {
		if (cooldownMs == null || cooldownMs <= 0) return false
		local now = phoenix.item.Spells._now()
		if (!(playerId in phoenix.item.Spells.cooldown)) phoenix.item.Spells.cooldown[playerId] <- {}
		local map = phoenix.item.Spells.cooldown[playerId]
		local key = "_global"
		if (cooldownMs > 0) key = spellKey
		if (key in map && now - map[key] < cooldownMs) return true
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

	function _heal(playerId, amount) {
		if (amount == null || amount <= 0) return 0
		local hp = 0
		local hpMax = 0
		try { hp = getPlayerHealth(playerId) } catch (e) { return 0 }
		try { hpMax = getPlayerMaxHealth(playerId) } catch (e2) { hpMax = hp + amount }
		local newHp = hp + amount
		if (hpMax > 0 && newHp > hpMax) newHp = hpMax
		try { setPlayerHealth(playerId, newHp) } catch (e3) {}
		try { phoenix.player.Combat.emitText(playerId, newHp - hp, "heal") } catch (e4) {}
		return newHp - hp
	}

	function _dist(ax, ay, az, bx, by, bz) {
		local dx = ax - bx
		local dy = ay - by
		local dz = az - bz
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function _world(playerId) {
		try { return getPlayerWorld(playerId) } catch (e) { return "" }
	}

	function _findTargets(casterId, range, requiresFront) {
		local out = []
		local cp = null
		try { cp = getPlayerPosition(casterId) } catch (e) { return out }
		if (cp == null) return out
		local cw = phoenix.item.Spells._world(casterId)
		local angle = 0.0
		try { angle = getPlayerAngle(casterId) } catch (e) { angle = 0.0 }
		local rad = angle * 3.1415926 / 180.0
		local fx = sin(rad)
		local fz = cos(rad)


		try {
			foreach (sid, entry in phoenix.npc.Spawn.live) {
				if (entry == null || !entry.alive) continue
				local nid = entry.npcId
				if (nid == null || nid < 0) continue
				local hp = 0
				try { hp = getPlayerHealth(nid) } catch (e) { continue }
				if (hp <= 0) continue
				local np = null
				try { np = getPlayerPosition(nid) } catch (e) { continue }
				if (np == null) continue
				local nw = ""
				try { nw = getPlayerWorld(nid) } catch (e) {}
				if (cw != "" && nw != "" && cw != nw) continue
				local d = phoenix.item.Spells._dist(cp.x, cp.y, cp.z, np.x, np.y, np.z)
				if (d > range) continue
				if (requiresFront) {
					local dx = np.x - cp.x
					local dz = np.z - cp.z
					local dot = dx * fx + dz * fz
					if (dot <= 0) continue
				}
				out.append({ id = nid, kind = "npc", entry = entry, pos = np, distance = d })
			}
		} catch (eIter) {}


		try {
			local maxSlots = getMaxSlots()
			for (local pid = 0; pid < maxSlots; pid += 1) {
				if (pid == casterId) continue
				try { if (!isPlayerConnected(pid)) continue } catch (e) { continue }
				try { if (phoenix.npc.Spawn._liveByNpcId(pid) != null) continue } catch (e) {}
				local hp = 0
				try { hp = getPlayerHealth(pid) } catch (e) { continue }
				if (hp <= 0) continue
				local pp = null
				try { pp = getPlayerPosition(pid) } catch (e) { continue }
				if (pp == null) continue
				local pw = ""
				try { pw = getPlayerWorld(pid) } catch (e) {}
				if (cw != "" && pw != "" && cw != pw) continue
				local d = phoenix.item.Spells._dist(cp.x, cp.y, cp.z, pp.x, pp.y, pp.z)
				if (d > range) continue
				if (requiresFront) {
					local dx = pp.x - cp.x
					local dz = pp.z - cp.z
					local dot = dx * fx + dz * fz
					if (dot <= 0) continue
				}
				out.append({ id = pid, kind = "player", entry = null, pos = pp, distance = d })
			}
		} catch (eP) {}

		out.sort(function (a, b) {
			if (a.distance < b.distance) return -1
			if (a.distance > b.distance) return 1
			return 0
		})
		return out
	}

	function _damageTarget(casterId, target, amount, damageType) {
		if (target == null || amount <= 0) return false
		try {
			if (target.kind == "npc") {
				local entry = target.entry
				if (entry == null) return false
				if (("unconscious" in entry.ai) && entry.ai.unconscious == true) return false
				local hp = 0
				try { hp = getPlayerHealth(target.id) } catch (e) {}
				if (hp <= 0) return false
				local newHp = hp - amount
				if (newHp < 0) newHp = 0
				local lethal = newHp <= 0
				try { setPlayerHealth(target.id, newHp) } catch (e) {}
				try { phoenix.player.Combat.emitText(target.id, amount, "damage") } catch (e2) {}
				try { phoenix.npc.Spawn._retaliate(entry, casterId) } catch (e3) {}
				try { phoenix.npc.Spawn.broadcastNameplates() } catch (e4) {}
				if (lethal) try { phoenix.npc.Spawn.onNpcKilled(target.id, casterId) } catch (e5) {}
				return true
			}
			if (target.kind == "player") {
				phoenix.player.Gate.applyDamage(target.id, amount, casterId, true)
				try { phoenix.player.Combat.emitText(target.id, amount, "damage") } catch (e) {}
				return true
			}
		} catch (eDmg) {}
		return false
	}

	function _playCastAnim(casterId, anim) {
		if (anim == null || anim == "") return
		try { playAni(casterId, anim) } catch (e) {}
	}

	function cast(casterId, spell, scheme) {
		if (spell == null) return { ok = false, reason = "noSpell" }
		local circle = ("circle" in spell) ? spell.circle.tointeger() : 1
		if (circle < 1) circle = 1
		local requiredLevel = phoenix.item.Spells.levelForCircle(circle)
		local currentLevel = phoenix.item.Spells.getMagicLevel(casterId)
		if (currentLevel < requiredLevel) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Wymagany poziom magii " + requiredLevel + " (krag " + circle + ")", 2400) } catch (e) {}
			return { ok = false, reason = "lowLevel" }
		}
		local manaCost = ("manaCost" in spell) ? spell.manaCost.tointeger() : 0
		if (!phoenix.item.Spells._checkMana(casterId, manaCost)) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Brak many (" + manaCost + ")", 2200) } catch (e) {}
			return { ok = false, reason = "noMana" }
		}
		local cd = ("cooldownMs" in spell) ? spell.cooldownMs.tointeger() : 0
		local key = ("key" in spell) ? spell.key.tostring() : "spell"
		if (phoenix.item.Spells._onCooldown(casterId, key, cd)) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Zaklecie nie ostyglo", 1500) } catch (e) {}
			return { ok = false, reason = "cooldown" }
		}
		local kind = ("kind" in spell) ? spell.kind.tostring() : "damage"
		local handler = phoenix.item.Spells.handlers
		if (!(kind in handler)) {
			try { phoenix.notification.notify(casterId, "info", "Magia", "Czar bez efektu", 2000) } catch (e) {}
			return { ok = false, reason = "noKind" }
		}
		local result = handler[kind].call(phoenix.item.Spells, casterId, spell, scheme)
		if (result == null) result = { ok = true }
		if (result.ok) {
			phoenix.item.Spells._consumeMana(casterId, manaCost)
			phoenix.item.Spells._markCooldown(casterId, key, cd)
			phoenix.item.Spells._playCastAnim(casterId, ("anim" in spell) ? spell.anim : "T_MAGRUN_2_HEASHOOT")
			local label = ("label" in spell) ? spell.label.tostring() : key
			try { phoenix.notification.notify(casterId, "info", "Czar", label, 1800) } catch (e) {}

			local xp = phoenix.item.Spells.xpFromScroll
			if (scheme != null) {
				try { if (scheme.category == PhoenixItemCategory.Rune) xp = phoenix.item.Spells.xpFromRune } catch (e) {}
			}
			xp = xp + circle
			phoenix.item.Spells._addXp(casterId, xp)
		}
		return result
	}

	handlers = null
}

phoenix.item.Spells.handlers = {

	heal = function (casterId, spell, _scheme) {
		local amount = ("hp" in spell) ? spell.hp.tointeger() : 50
		phoenix.item.Spells._heal(casterId, amount)
		return { ok = true }
	},


	damage = function (casterId, spell, _scheme) {
		local range = ("range" in spell) ? spell.range.tofloat() : 1500.0
		local damage = ("damage" in spell) ? spell.damage.tointeger() : 30
		local damageType = ("damageType" in spell) ? spell.damageType.tointeger() : PhoenixDamageType.Magic
		local targets = phoenix.item.Spells._findTargets(casterId, range, true)
		if (targets.len() == 0) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Brak celu", 1500) } catch (e) {}
			return { ok = false, reason = "noTarget" }
		}
		phoenix.item.Spells._damageTarget(casterId, targets[0], damage, damageType)
		return { ok = true }
	},


	aoe = function (casterId, spell, _scheme) {
		local radius = ("radius" in spell) ? spell.radius.tofloat() : 800.0
		local damage = ("damage" in spell) ? spell.damage.tointeger() : 40
		local damageType = ("damageType" in spell) ? spell.damageType.tointeger() : PhoenixDamageType.Magic
		local targets = phoenix.item.Spells._findTargets(casterId, radius, false)
		if (targets.len() == 0) {
			try { phoenix.notification.notify(casterId, "warn", "Magia", "Brak celow", 1500) } catch (e) {}
			return { ok = false, reason = "noTarget" }
		}
		local maxTargets = ("maxTargets" in spell) ? spell.maxTargets.tointeger() : 10
		local hits = 0
		foreach (target in targets) {
			if (hits >= maxTargets) break
			if (phoenix.item.Spells._damageTarget(casterId, target, damage, damageType)) hits += 1
		}
		return { ok = hits > 0, hits = hits }
	},


	teleport = function (casterId, spell, _scheme) {
		if (!("dest" in spell) || spell.dest == null) return { ok = false, reason = "noDest" }
		local dest = spell.dest
		local x = ("x" in dest) ? dest.x.tofloat() : 0.0
		local y = ("y" in dest) ? dest.y.tofloat() : 0.0
		local z = ("z" in dest) ? dest.z.tofloat() : 0.0
		local world = ("world" in dest) ? dest.world.tostring() : ""
		try {
			if (world != "") setPlayerWorld(casterId, world)
		} catch (e) {}
		try { setPlayerPosition(casterId, x, y, z) } catch (e2) {}
		return { ok = true }
	},


	light = function (casterId, _spell, _scheme) {
		try { phoenix.notification.notify(casterId, "info", "Magia", "Swiatlo otacza dlon", 2200) } catch (e) {}
		return { ok = true }
	},


	summon = function (casterId, spell, _scheme) {
		try { phoenix.notification.notify(casterId, "info", "Magia", "Przywolanie nieaktywne (planowane)", 2400) } catch (e) {}
		return { ok = true }
	}
}


phoenix.item.Spells.register("LIGHT",            { kind = "light",     circle = 1, manaCost = 5,   cooldownMs = 1500, label = "Swiatlo",                 anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PALLIGHT",         { kind = "light",     circle = 1, manaCost = 5,   cooldownMs = 1500, label = "Swiatlo Paladyna",        anim = "T_MAGRUN_2_HEASHOOT" })


phoenix.item.Spells.register("LIGHTHEAL",        { kind = "heal",      circle = 1, manaCost = 10,  cooldownMs = 2500, hp = 60,   label = "Male leczenie",     anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PALLIGHTHEAL",     { kind = "heal",      circle = 1, manaCost = 12,  cooldownMs = 2500, hp = 70,   label = "Swiete leczenie",   anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("MEDIUMHEAL",       { kind = "heal",      circle = 3, manaCost = 30,  cooldownMs = 4000, hp = 180,  label = "Srednie leczenie",  anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PALMEDIUMHEAL",    { kind = "heal",      circle = 3, manaCost = 35,  cooldownMs = 4000, hp = 200,  label = "Srednie swiete leczenie", anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("FULLHEAL",         { kind = "heal",      circle = 5, manaCost = 80,  cooldownMs = 6000, hp = 9999, label = "Pelne leczenie",    anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PALFULLHEAL",      { kind = "heal",      circle = 5, manaCost = 90,  cooldownMs = 6000, hp = 9999, label = "Pelne swiete leczenie",    anim = "T_MAGRUN_2_HEASHOOT" })


phoenix.item.Spells.register("ZAP",              { kind = "damage",    circle = 1, manaCost = 5,   cooldownMs = 1200, damage = 25,  range = 1200.0, damageType = PhoenixDamageType.Magic, label = "Iskra",             anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("FIREBOLT",         { kind = "damage",    circle = 1, manaCost = 12,  cooldownMs = 1500, damage = 55,  range = 2200.0, damageType = PhoenixDamageType.Fire,  label = "Pocisk Ognia",      anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PALHOLYBOLT",      { kind = "damage",    circle = 1, manaCost = 14,  cooldownMs = 1700, damage = 70,  range = 2400.0, damageType = PhoenixDamageType.Magic, label = "Swiety Pocisk",     anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("ICEBOLT",          { kind = "damage",    circle = 2, manaCost = 14,  cooldownMs = 1700, damage = 65,  range = 2400.0, damageType = PhoenixDamageType.Magic, label = "Pocisk Lodu",       anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("INSTANTFIREBALL",  { kind = "damage",    circle = 2, manaCost = 25,  cooldownMs = 2200, damage = 110, range = 2200.0, damageType = PhoenixDamageType.Fire,  label = "Kula Ognia",        anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("THUNDERBALL",      { kind = "damage",    circle = 3, manaCost = 30,  cooldownMs = 2500, damage = 130, range = 2200.0, damageType = PhoenixDamageType.Magic, label = "Kula Blyskawic",    anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("HARMUNDEAD",       { kind = "damage",    circle = 4, manaCost = 35,  cooldownMs = 2500, damage = 200, range = 1500.0, damageType = PhoenixDamageType.Magic, label = "Razenie Nieumarych",anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PALREPELEVIL",     { kind = "damage",    circle = 3, manaCost = 35,  cooldownMs = 2500, damage = 220, range = 1500.0, damageType = PhoenixDamageType.Magic, label = "Odpedzenie Zla",    anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("CHARGEFIREBALL",   { kind = "damage",    circle = 4, manaCost = 45,  cooldownMs = 3000, damage = 200, range = 2400.0, damageType = PhoenixDamageType.Fire,  label = "Naladowana Kula Ognia", anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("LIGHTNINGFLASH",   { kind = "damage",    circle = 4, manaCost = 60,  cooldownMs = 3500, damage = 260, range = 2400.0, damageType = PhoenixDamageType.Magic, label = "Blyskawica",        anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PALDESTROYEVIL",   { kind = "damage",    circle = 6, manaCost = 70,  cooldownMs = 4000, damage = 350, range = 1500.0, damageType = PhoenixDamageType.Magic, label = "Niszcz Zlo",        anim = "T_MAGRUN_2_HEASHOOT" })


phoenix.item.Spells.register("WINDFIST",         { kind = "aoe",       circle = 2, manaCost = 18,  cooldownMs = 2200, damage = 50,  radius = 700.0,  damageType = PhoenixDamageType.Magic, label = "Piesc Wiatru",     maxTargets = 4, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("ICECUBE",          { kind = "aoe",       circle = 3, manaCost = 22,  cooldownMs = 2400, damage = 65,  radius = 700.0,  damageType = PhoenixDamageType.Magic, label = "Szescian Lodu",     maxTargets = 4, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("FIRESTORM",        { kind = "aoe",       circle = 3, manaCost = 38,  cooldownMs = 3000, damage = 90,  radius = 900.0,  damageType = PhoenixDamageType.Fire,  label = "Burza Ognia",       maxTargets = 6, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("ICEWAVE",          { kind = "aoe",       circle = 5, manaCost = 55,  cooldownMs = 3500, damage = 130, radius = 1100.0, damageType = PhoenixDamageType.Magic, label = "Fala Lodu",         maxTargets = 8, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("PYROKINESIS",      { kind = "aoe",       circle = 5, manaCost = 60,  cooldownMs = 4000, damage = 150, radius = 1100.0, damageType = PhoenixDamageType.Fire,  label = "Pirokineza",        maxTargets = 10, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("FIRERAIN",         { kind = "aoe",       circle = 6, manaCost = 90,  cooldownMs = 5000, damage = 200, radius = 1500.0, damageType = PhoenixDamageType.Fire,  label = "Deszcz Ognia",      maxTargets = 12, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("BREATHOFDEATH",    { kind = "aoe",       circle = 6, manaCost = 110, cooldownMs = 5500, damage = 240, radius = 1300.0, damageType = PhoenixDamageType.Magic, label = "Oddech Smierci",    maxTargets = 12, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("MASSDEATH",        { kind = "aoe",       circle = 6, manaCost = 140, cooldownMs = 6500, damage = 320, radius = 1500.0, damageType = PhoenixDamageType.Magic, label = "Masowa Smierc",     maxTargets = 16, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("MASTEROFDISASTER", { kind = "aoe",       circle = 6, manaCost = 180, cooldownMs = 7000, damage = 400, radius = 1700.0, damageType = PhoenixDamageType.Fire,  label = "Mistrz Zniszczenia",maxTargets = 16, anim = "T_MAGRUN_2_HEASHOOT" })


phoenix.item.Spells.register("FEAR",             { kind = "aoe",       circle = 3, manaCost = 25,  cooldownMs = 4000, damage = 1,   radius = 700.0, damageType = PhoenixDamageType.Magic, label = "Strach",           maxTargets = 6, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("SLEEP",            { kind = "aoe",       circle = 2, manaCost = 25,  cooldownMs = 4000, damage = 1,   radius = 700.0, damageType = PhoenixDamageType.Magic, label = "Sen",              maxTargets = 6, anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("SHRINK",           { kind = "damage",    circle = 6, manaCost = 30,  cooldownMs = 4000, damage = 1,   range = 1500.0, damageType = PhoenixDamageType.Magic, label = "Pomniejszenie",    anim = "T_MAGRUN_2_HEASHOOT" })


phoenix.item.Spells.register("SUMGOBSKEL",       { kind = "summon",    circle = 1, manaCost = 20,  cooldownMs = 6000, label = "Szkielet Goblina",  anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("SUMWOLF",          { kind = "summon",    circle = 2, manaCost = 30,  cooldownMs = 6000, label = "Wilk",              anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("SUMSKEL",          { kind = "summon",    circle = 3, manaCost = 50,  cooldownMs = 7000, label = "Szkielet",          anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("SUMGOL",           { kind = "summon",    circle = 4, manaCost = 80,  cooldownMs = 8000, label = "Golem",             anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("SUMDEMON",         { kind = "summon",    circle = 5, manaCost = 120, cooldownMs = 9000, label = "Demon",             anim = "T_MAGRUN_2_HEASHOOT" })
phoenix.item.Spells.register("ARMYOFDARKNESS",   { kind = "summon",    circle = 6, manaCost = 150, cooldownMs = 10000, label = "Armia Ciemnosci", anim = "T_MAGRUN_2_HEASHOOT" })


addEventHandler("onPlayerDisconnect", function (playerId, _reason) {
	if (playerId in phoenix.item.Spells.cooldown) phoenix.item.Spells.cooldown.rawdelete(playerId)
})
