phoenix.npc.Spawn <- {

	live = {}
	loaded = false
	loading = false
	bootScheduled = false
	loadAttempts = 0
	lastNameplateBroadcast = 0
	nameplateTimer = null

	function _readFloat(r, key, fallback) {
		if (key in r && r[key] != null) {
			try { return r[key].tofloat() } catch (e) {}
		}
		return fallback
	}

	function _readInt(r, key, fallback) {
		if (key in r && r[key] != null) {
			try { return r[key].tointeger() } catch (e) {}
		}
		return fallback
	}

	function _readStr(r, key, fallback) {
		if (key in r && r[key] != null) {
			try { return r[key].tostring() } catch (e) {}
		}
		return fallback
	}

	function _metadataInt(text, key, fallback) {
		local raw = phoenix.npc.Spawn._metadataValue(text, key)
		if (raw == "") return fallback
		try { return raw.tointeger() } catch (e) {}
		return fallback
	}

	function _esc(v) { try { return ORM.engine.escape(v.tostring()) } catch (e) { return v.tostring() } }

	function _metadataValue(text, key) {
		if (text == null || text == "") return ""
		local needle = "\"" + key + "\":\""
		local start = text.find(needle)
		if (start != null) {
			start += needle.len()
			local rest = text.slice(start)
			local rel = rest.find("\"")
			if (rel == null || rel <= 0) return ""
			local stop = start + rel
			return text.slice(start, stop)
		}
		needle = "\"" + key + "\":"
		start = text.find(needle)
		if (start == null) return ""
		start += needle.len()
		local stop = start
		while (stop < text.len()) {
			local ch = text[stop]
			if (ch == ',' || ch == '}') break
			stop += 1
		}
		local raw = text.slice(start, stop)
		local a = 0
		local b = raw.len()
		while (a < b && raw[a] <= ' ') a += 1
		while (b > a && raw[b - 1] <= ' ') b -= 1
		return b > a ? raw.slice(a, b) : ""
	}

	function _liveByNpcId(npcId) {
		foreach (sid, entry in phoenix.npc.Spawn.live) {
			if (entry.npcId == npcId) return entry
		}
		return null
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

	function _retaliate(entry, attackerId) {
		if (entry == null || attackerId == null || attackerId < 0) return
		try {
			if (!isPlayerConnected(attackerId) && phoenix.npc.Spawn._liveByNpcId(attackerId) == null) return
		} catch (e) {
			if (phoenix.npc.Spawn._liveByNpcId(attackerId) == null) return
		}
		entry.ai.targetPid = attackerId
		entry.ai.lastSeen <- getTickCount()
		entry.ai.warnStart = 0
		entry.ai.state = "combat"
		entry.ai.dialogPartner <- -1
		entry.ai.dialogPaused <- false
	}

	function expForLevel(level) {
		try { return phoenix.player.Progression.expForLevel(level) } catch (e) {}
		if (level <= 1) return 0
		local L = level - 1
		return (50 * L * L + 450 * L)
	}

	function awardNpcExperience(npcId, amount) {
		if (amount <= 0) return
		local entry = phoenix.npc.Spawn._liveByNpcId(npcId)
		if (entry == null || !entry.alive) return
		local row = entry.row
		if (!("experience" in row)) row.experience <- 0
		if (!("level" in row) || row.level <= 0) row.level <- 1
		row.experience += amount
		local leveled = false
		while (row.level < 60) {
			local needed = phoenix.npc.Spawn.expForLevel(row.level + 1)
			if (row.experience < needed) break
			row.level += 1
			row.hp += 10
			row.strength += 2
			row.dexterity += 2
			row.attackDamage += 2
			leveled = true
		}
		if (leveled) {
			try { setPlayerMaxHealth(npcId, row.hp > 0 ? row.hp : 100) } catch (e) {}
			try { setPlayerHealth(npcId, row.hp > 0 ? row.hp : 100) } catch (e2) {}
			try { setPlayerStrength(npcId, row.strength > 0 ? row.strength : 10) } catch (e3) {}
			try { setPlayerDexterity(npcId, row.dexterity > 0 ? row.dexterity : 10) } catch (e4) {}
		}
		try {
			local sql = "UPDATE `phoenix_npc_spawns` SET `experience` = " + row.experience + ", `level` = " + row.level + ", `hp` = " + row.hp + ", `strength` = " + row.strength + ", `dexterity` = " + row.dexterity + ", `attackDamage` = " + row.attackDamage + " WHERE `id` = " + row.id
			ORM.engine.executeAsync(sql, function (_) {})
		} catch (eSave) {}
		try { phoenix.npc.Spawn.broadcastNameplates() } catch (e5) {}
	}

	function rowToObject(r) {
		local metadata = phoenix.npc.Spawn._readStr(r, "metadata", "")
		local weapon = phoenix.npc.Spawn._metadataValue(metadata, "weapon")
		if (weapon == "") weapon = phoenix.npc.Spawn._metadataValue(metadata, "melee")
		local ranged = phoenix.npc.Spawn._metadataValue(metadata, "ranged")
		if (weapon == "") weapon = ranged
		local catalog = phoenix.npc.findCatalog(phoenix.npc.Spawn._readStr(r, "instance", ""))
		local fallbackExperience = catalog != null && "baseExperience" in catalog ? catalog.baseExperience : 0
		local metaExperience = phoenix.npc.Spawn._metadataInt(metadata, "expReward", fallbackExperience)
		return {
			id = r.id,
			instance = phoenix.npc.Spawn._readStr(r, "instance", ""),
			name = phoenix.npc.Spawn._readStr(r, "name", ""),
			world = phoenix.npc.Spawn._readStr(r, "world", ""),
			posX = phoenix.npc.Spawn._readFloat(r, "posX", 0.0),
			posY = phoenix.npc.Spawn._readFloat(r, "posY", 0.0),
			posZ = phoenix.npc.Spawn._readFloat(r, "posZ", 0.0),
			angle = phoenix.npc.Spawn._readFloat(r, "angle", 0.0),
			hostile = phoenix.npc.Spawn._readInt(r, "hostile", 0),
			respawnSec = phoenix.npc.Spawn._readInt(r, "respawnSec", 60),
			tag = phoenix.npc.Spawn._readStr(r, "tag", ""),
			script = phoenix.npc.Spawn._readStr(r, "script", ""),
			metadata = metadata,
			weapon = weapon,
			ranged = ranged,
			presetId = phoenix.npc.Spawn._readInt(r, "presetId", 0),
			kind = phoenix.npc.Spawn._readStr(r, "kind", "monster"),
			scaleX = phoenix.npc.Spawn._readFloat(r, "scaleX", 1.0),
			scaleY = phoenix.npc.Spawn._readFloat(r, "scaleY", 1.0),
			scaleZ = phoenix.npc.Spawn._readFloat(r, "scaleZ", 1.0),
			fatness = phoenix.npc.Spawn._readFloat(r, "fatness", 0.0),
			hp = phoenix.npc.Spawn._readInt(r, "hp", 0),
			level = phoenix.npc.Spawn._readInt(r, "level", 0),
			experience = phoenix.npc.Spawn._readInt(r, "experience", 0),
			strength = phoenix.npc.Spawn._readInt(r, "strength", 0),
			dexterity = phoenix.npc.Spawn._readInt(r, "dexterity", 0),
			bodyModel = phoenix.npc.Spawn._readStr(r, "bodyModel", ""),
			bodyTex = phoenix.npc.Spawn._readInt(r, "bodyTex", -1),
			headModel = phoenix.npc.Spawn._readStr(r, "headModel", ""),
			headTex = phoenix.npc.Spawn._readInt(r, "headTex", -1),
			voice = phoenix.npc.Spawn._readInt(r, "voice", 0),
			idleAnimation = phoenix.npc.Spawn._readStr(r, "idleAnimation", ""),
			aggroRadius = phoenix.npc.Spawn._readInt(r, "aggroRadius", 900),
			attackRange = phoenix.npc.Spawn._readInt(r, "attackRange", 180),
			attackDamage = phoenix.npc.Spawn._readInt(r, "attackDamage", 10),
			walkSpeed = phoenix.npc.Spawn._readInt(r, "walkSpeed", 250),
			baseExperience = phoenix.npc.Spawn._readInt(r, "baseExperience", metaExperience),
			teacherSkills = phoenix.npc.Spawn._readStr(r, "teacherSkills", ""),
			teachCost = phoenix.npc.Spawn._readInt(r, "teachCost", 100)
		}
	}

	function normalizeHumanVisual(row) {
		local bm = row.bodyModel != "" ? row.bodyModel : "HUM_BODY_NAKED0"
		local hm = row.headModel != "" ? row.headModel : "HUM_HEAD_BALD"
		local bt = row.bodyTex >= 0 ? row.bodyTex : 0
		local ht = row.headTex >= 0 ? row.headTex : 0
		local bodyUpper = bm.tostring().toupper()
		local headUpper = hm.tostring().toupper()
		local female = bodyUpper.find("BABE") != null || headUpper.find("BABE") != null || headUpper.find("IVY") != null

		if (female) {
			bm = "HUM_BODY_BABE0"
			if (headUpper.find("BABE") == null && headUpper.find("IVY") == null) hm = "HUM_HEAD_BABE"
			if (bt >= 0 && bt <= 3) bt += 4
			if (ht < 137 || ht > 158) ht = 137
		} else {
			bm = "HUM_BODY_NAKED0"
			if (headUpper.find("BABE") != null || headUpper.find("IVY") != null) hm = "HUM_HEAD_BALD"
			if (bt >= 4 && bt <= 7) bt -= 4
			if (ht >= 137 && ht <= 158) ht = 0
		}

		return { bodyModel = bm, bodyTex = bt, headModel = hm, headTex = ht }
	}

	function applyVisuals(npcId, row) {
		try {
			if (row.bodyModel != "" || row.headModel != "") {
				local visual = phoenix.npc.Spawn.normalizeHumanVisual(row)
				try { setPlayerVisual(npcId, visual.bodyModel, visual.bodyTex, visual.headModel, visual.headTex) } catch (e) {}
			}
			if (row.scaleX != 1.0 || row.scaleY != 1.0 || row.scaleZ != 1.0) {
				try { setPlayerScale(npcId, row.scaleX, row.scaleY, row.scaleZ) } catch (e) {}
			}
			if (row.fatness != 0.0) {
				try { setPlayerFatness(npcId, row.fatness) } catch (e) {}
			}
			local hpVal = row.hp > 0 ? row.hp : 100
			try { setPlayerMaxHealth(npcId, hpVal) } catch (e) {}
			try { setPlayerHealth(npcId, hpVal) } catch (e) {}
			try { setPlayerMaxMana(npcId, 100) } catch (e) {}
			try { setPlayerMana(npcId, 100) } catch (e) {}
			if (row.strength > 0) { try { setPlayerStrength(npcId, row.strength) } catch (e) {} }
			if (row.dexterity > 0) { try { setPlayerDexterity(npcId, row.dexterity) } catch (e) {} }
		} catch (e) {}
	}

	function applyEquipment(npcId, row) {
		foreach (key in ["armor", "weapon", "melee", "ranged", "shield", "helmet"]) {
			local inst = phoenix.npc.Spawn._metadataValue(row.metadata, key)
			if (inst == "") continue
			try { giveItem(npcId, inst, 1) } catch (e) {}
			try { equipItem(npcId, inst) } catch (e) {}
			if (key == "ranged") {
				try { giveItem(npcId, "ITRW_ARROW", 1000) } catch (e) {}
				try { giveItem(npcId, "ITRW_BOLT", 1000) } catch (e) {}
			}
		}
		// G2O may be case-sensitive — try lowercase variant too
		foreach (key in ["armor", "weapon", "melee", "ranged", "shield", "helmet"]) {
			local inst = phoenix.npc.Spawn._metadataValue(row.metadata, key)
			if (inst == "") continue
			try { local lower = inst.tolower(); if (lower != inst) { giveItem(npcId, lower, 1); equipItem(npcId, lower) } } catch (e) {}
		}
	}

	function _autoStats(row) {
		// Auto-adjust NPC strength/dexterity so they can always wield their weapon.
		// Only raises stats, never lowers them — if admin set higher, keep higher.
		local weapon = ("weapon" in row) ? row.weapon : ""
		if (weapon == null || weapon == "") return
		try {
			local scheme = phoenix.item.find(weapon)
			if (scheme == null || scheme.requirement == null) return
			foreach (r in scheme.requirement) {
				if (r == null) continue
				local attr = ("attr" in r) ? r.attr.tostring() : ""
				local val = ("value" in r) ? r.value.tointeger() : 0
				if (val <= 0) continue
				if (attr == "strength") {
					if (!("strength" in row) || row.strength < val) row.strength = val
				} else if (attr == "dexterity") {
					if (!("dexterity" in row) || row.dexterity < val) row.dexterity = val
				}
			}
		} catch (e) {}
	}

	function normalizeEquipmentFields(row) {
		if (!("weapon" in row) || row.weapon == null || row.weapon == "") {
			local weapon = phoenix.npc.Spawn._metadataValue(row.metadata, "weapon")
			if (weapon == "") weapon = phoenix.npc.Spawn._metadataValue(row.metadata, "melee")
			if (weapon == "") weapon = phoenix.npc.Spawn._metadataValue(row.metadata, "ranged")
			if ("weapon" in row) row.weapon = weapon
			else row.weapon <- weapon
		}
		if (!("ranged" in row) || row.ranged == null || row.ranged == "") {
			local ranged = phoenix.npc.Spawn._metadataValue(row.metadata, "ranged")
			if ("ranged" in row) row.ranged = ranged
			else row.ranged <- ranged
		}
	}

	function applySkills(npcId, row) {
		if (row.kind != "humanoid" && row.kind != "npc" && row.kind != "merchant" && row.kind != "guard") return
		local oneh = phoenix.npc.Spawn._metadataInt(row.metadata, "oneh", 80)
		local twoh = phoenix.npc.Spawn._metadataInt(row.metadata, "twoh", 80)
		local bow = phoenix.npc.Spawn._metadataInt(row.metadata, "bow", 80)
		local cbow = phoenix.npc.Spawn._metadataInt(row.metadata, "cbow", 80)
		try { setPlayerSkillWeapon(npcId, WEAPON_1H, oneh) } catch (e) {}
		try { setPlayerSkillWeapon(npcId, WEAPON_2H, twoh) } catch (e) {}
		try { setPlayerSkillWeapon(npcId, WEAPON_BOW, bow) } catch (e) {}
		try { setPlayerSkillWeapon(npcId, WEAPON_CBOW, cbow) } catch (e) {}
	}

	function _resolveDisplayName(row) {
		if (row.name != null && row.name != "") return row.name
		return phoenix.npc.Spawn._catalogLabel(row.instance, "pl")
	}

	function _catalogLabel(instance, lang) {
		try {
			local cat = phoenix.npc.findCatalog(instance)
			if (cat == null) return instance
			if (lang == "en" && "labelEn" in cat && cat.labelEn != "") return cat.labelEn
			if (lang == "de" && "labelDe" in cat && cat.labelDe != "") return cat.labelDe
			if (lang == "ru" && "labelRu" in cat && cat.labelRu != "") return cat.labelRu
			if ("label" in cat && cat.label != "") return cat.label
		} catch (e) {}
		return instance
	}

	function _nameplateHeight(row) {
		local height = 130
		local inst = row.instance
		if (inst == "MEATBUG") height = 35
		else if (inst == "BLOODFLY" || inst == "YBLOODFLY") height = 60
		else if (inst == "WOLF" || inst == "YWOLF" || inst == "KEILER" || inst == "GIANT_RAT" || inst == "GIANT_BUG" || inst == "MOLERAT" || inst == "GOBBO_GREEN" || inst == "GOBBO_BLACK" || inst == "GOBBO_SKELETON") height = 75
		else if (inst == "WARG" || inst == "ICEWOLF" || inst == "BLOODHOUND" || inst == "SCAVENGER" || inst == "WARAN" || inst == "FIREWARAN" || inst == "LURKER" || inst == "SNAPPER" || inst == "ORCBITER") height = 95
		else if (inst == "MINECRAWLER" || inst == "ZOMBIE" || inst == "SWAMPZOMBIE" || inst == "SKELETON" || inst == "LESSER_SKELETON" || inst == "SHADOWBEAST" || inst == "SHADOWBEAST_SKELETON" || inst == "SWAMPSHARK") height = 120
		else if (inst == "TROLL" || inst == "TROLL_BLACK" || inst == "DRAGONSNAPPER") height = 200
		else if (inst == "DRAGON_FIRE" || inst == "DRAGON_ICE" || inst == "DRAGON_ROCK" || inst == "DRAGON_SWAMP" || inst == "DRAGON_UNDEAD") height = 280
		if (row.kind == "npc" || row.kind == "humanoid") height = 130
		try { height = (height.tofloat() * row.scaleY).tointeger() } catch (e) {}
		if (height < 30) height = 30
		return height
	}

	function _makeNameplateList() {
		local out = []
		foreach (sid, entry in phoenix.npc.Spawn.live) {
			if (!entry.alive) continue
			local r = entry.row
			local hp = 0
			local hpMax = r.hp > 0 ? r.hp : 100
			local mana = 0
			local manaMax = 0
			try { hp = getPlayerHealth(entry.npcId) } catch (e) {}
			try { hpMax = getPlayerMaxHealth(entry.npcId) } catch (e) {}
			try { mana = getPlayerMana(entry.npcId) } catch (e) {}
			try { manaMax = getPlayerMaxMana(entry.npcId) } catch (e) {}
			if (hpMax <= 0) hpMax = r.hp > 0 ? r.hp : 100
			if (manaMax <= 0) manaMax = 100
			out.append({
				npcId = entry.npcId,
				spawnId = r.id,
				name = r.name,
				instance = r.instance,
				kind = r.kind,
				height = phoenix.npc.Spawn._nameplateHeight(r),
				level = r.level > 0 ? r.level : 1,
				hp = hp > 0 ? hp : hpMax,
				hpMax = hpMax,
				mana = mana,
				manaMax = manaMax,
				testPlayer = phoenix.npc.Spawn._metadataInt(r.metadata, "testPlayer", 0) > 0,
				labelPl = phoenix.npc.Spawn._catalogLabel(r.instance, "pl"),
				labelEn = phoenix.npc.Spawn._catalogLabel(r.instance, "en"),
				labelDe = phoenix.npc.Spawn._catalogLabel(r.instance, "de"),
				labelRu = phoenix.npc.Spawn._catalogLabel(r.instance, "ru")
			})
		}
		return out
	}

	function broadcastNameplates(targetPid = -1) {
		local msg = phoenix.npc.Message.Nameplates()
		msg.entries = phoenix.npc.Spawn._makeNameplateList()
		local serialized = msg.serialize()
		if (targetPid >= 0) {
			try { serialized.send(targetPid, RELIABLE_ORDERED) } catch (e) {}
			return
		}
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			if (!isPlayerConnected(pid)) continue
			try { serialized.send(pid, RELIABLE_ORDERED) } catch (e) {}
		}
	}

	function ensureNameplateTicker() {
		if (phoenix.npc.Spawn.nameplateTimer != null) return
		phoenix.npc.Spawn.nameplateTimer = setTimer(function () {
			try { phoenix.npc.Spawn.broadcastNameplates() } catch (e) {}
		}, 2000, 0)
	}

	function _normalizeWorld(value) {
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

	function spawnRow(row) {
		try {
			phoenix.npc.Spawn.normalizeEquipmentFields(row)
			local createName = row.instance
			if (row.name != "") createName = row.name
			local npcId = createNpc(createName)
			if (npcId == -1) return -1
			local serverWorld = ""
			try { serverWorld = getServerWorld() } catch (e) {}
			try { setPlayerRespawnTime(npcId, (row.respawnSec > 0 ? row.respawnSec : 60) * 1000) } catch (e) {}
			try { setPlayerInstance(npcId, row.instance.toupper()) } catch (e) { try { setPlayerInstance(npcId, row.instance) } catch (e2) {} }
			// Auto-adjust strength/dexterity to meet weapon requirements
			phoenix.npc.Spawn._autoStats(row)
			// Level → auto HP/Mana (10 HP per level, 5 mana per level, min 100)
			local levelVal = row.level > 0 ? row.level : 1
			local hpVal = row.hp > 0 ? row.hp : (100 + (levelVal - 1) * 10)
			local manaVal = 50 + (levelVal - 1) * 5
			try { setPlayerStrength(npcId, row.strength > 0 ? row.strength : 10) } catch (e) {}
			try { setPlayerDexterity(npcId, row.dexterity > 0 ? row.dexterity : 10) } catch (e) {}
			phoenix.npc.Spawn.applySkills(npcId, row)
			try { setPlayerMaxHealth(npcId, hpVal) } catch (e) {}
			try { setPlayerHealth(npcId, hpVal) } catch (e) {}
			try { setPlayerMaxMana(npcId, manaVal) } catch (e) {}
			try { setPlayerMana(npcId, manaVal) } catch (e) {}
			try { setPlayerPosition(npcId, row.posX, row.posY, row.posZ) } catch (e) {}
			try { setPlayerAngle(npcId, row.angle) } catch (e) {}
			if (serverWorld != "") {
				try { setPlayerWorld(npcId, serverWorld, "") } catch (e) { try { setPlayerWorld(npcId, serverWorld) } catch (e2) {} }
			}
			try { setPlayerVirtualWorld(npcId, 0) } catch (e) {}
			if (row.scaleX != 1.0 || row.scaleY != 1.0 || row.scaleZ != 1.0) {
				try { setPlayerScale(npcId, row.scaleX, row.scaleY, row.scaleZ) } catch (e) {}
			}
			if (row.bodyModel != "" || row.headModel != "") {
				local visual = phoenix.npc.Spawn.normalizeHumanVisual(row)
				try { setPlayerVisual(npcId, visual.bodyModel, visual.bodyTex, visual.headModel, visual.headTex) } catch (e) {}
			}
			if (row.fatness != 0.0) { try { setPlayerFatness(npcId, row.fatness) } catch (e) {} }
			local label = phoenix.npc.Spawn._resolveDisplayName(row)
			try { setPlayerName(npcId, label) } catch (e) {}
			try { spawnPlayer(npcId) } catch (e) {}
			phoenix.npc.Spawn.applyEquipment(npcId, row)
			local ani = row.idleAnimation
			if (ani == null || ani == "") ani = phoenix.npc.Spawn._metadataValue(row.metadata, "animation")
			if (ani != null && ani != "") {
				local upAni = ani.tostring().toupper()
				if (upAni.find("RUN") == null && upAni.find("WALK") == null && upAni.find("ATTACK") == null && upAni.find("WARN") == null) {
					try { playAni(npcId, ani) } catch (e) {}
				}
			}
			phoenix.npc.Spawn.live[row.id] <- {
				row = row,
				npcId = npcId,
				alive = true,
				respawnTimer = null,
				ai = {
					state = "idle",
					targetPid = -1,
					nextTick = 0,
					nextWander = 0,
					anchorX = row.posX,
					anchorY = row.posY,
					anchorZ = row.posZ,
					lastAttack = 0,
					lastMoveSync = 0,
					lastSeen = 0,
					lastAngle = -999.0,
					nextAngleAt = 0,
					waitAction = -1,
					lastAnim = "",
					warnStart = 0,
					idleApplied = "",
					returning = false,
					lastReturnDist = 0.0,
					lastReturnAt = 0,
					returnStartedAt = 0,
					moveWatchAt = 0,
					moveWatchX = 0.0,
					moveWatchY = 0.0,
					moveWatchZ = 0.0,
					moveWatchDist = 0.0,
					stuckCount = 0,
					detourUntil = 0,
					detourX = 0.0,
					detourZ = 0.0,
					lastEquipmentAt = 0,
					nextHomeCheckAt = 0,
					weaponSheathed = true
				}
			}
			phoenix.npc.Spawn.broadcastNameplates()
			try { phoenix.npc.Routines.onSpawnBound(row.id, phoenix.npc.Spawn.live[row.id]) } catch (e) {}
			return npcId
		} catch (e) {
			return -1
		}
	}

	function despawnRow(spawnId) {
		if (!(spawnId in phoenix.npc.Spawn.live)) return
		local entry = phoenix.npc.Spawn.live[spawnId]
		try { destroyNpc(entry.npcId) } catch (e) {}
		if (entry.respawnTimer != null) {
			try { killTimer(entry.respawnTimer) } catch (e) {}
			entry.respawnTimer = null
		}
		delete phoenix.npc.Spawn.live[spawnId]
		phoenix.npc.Spawn.broadcastNameplates()
	}

	function loadAll() {
		if (phoenix.npc.Spawn.loaded || phoenix.npc.Spawn.loading) return
		phoenix.npc.Spawn.loading = true
		phoenix.npc.Spawn.loadAttempts += 1
		phoenix.npc.Spawn.ensureTable(function () {
			ORM.engine.executeAsync("SELECT * FROM `phoenix_npc_spawns` ORDER BY `id` ASC", function (rows) {
				phoenix.npc.Spawn.loading = false
				if (rows == null) {
					phoenix.npc.Spawn.scheduleLoadRetry()
					return
				}
				phoenix.npc.Spawn.loaded = true
				local n = 0
				foreach (r in rows) {
					try {
						local row = phoenix.npc.Spawn.rowToObject(r)
						if (phoenix.npc.Spawn.spawnRow(row) >= 0) n += 1
					} catch (e) {}
				}
				phoenix.npc.Spawn.broadcastNameplates()
				print("[manager] Spawned " + n + "/" + rows.len() + " NPCs\n")
				phoenix.npc.Spawn._printServerStats()
			})
		})
	}

	function ensureTable(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_npc_spawns` (" +
			"`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY," +
			"`instance` VARCHAR(64) NOT NULL," +
			"`name` VARCHAR(96) DEFAULT ''," +
			"`world` VARCHAR(96) NOT NULL DEFAULT 'NEWWORLD\\\\NEWWORLD.ZEN'," +
			"`posX` FLOAT NOT NULL DEFAULT 0,`posY` FLOAT NOT NULL DEFAULT 0,`posZ` FLOAT NOT NULL DEFAULT 0,`angle` FLOAT NOT NULL DEFAULT 0," +
			"`scaleX` FLOAT NOT NULL DEFAULT 1,`scaleY` FLOAT NOT NULL DEFAULT 1,`scaleZ` FLOAT NOT NULL DEFAULT 1,`fatness` FLOAT NOT NULL DEFAULT 0," +
			"`hp` INT NOT NULL DEFAULT 0,`level` INT NOT NULL DEFAULT 0,`experience` INT NOT NULL DEFAULT 0,`strength` INT NOT NULL DEFAULT 0,`dexterity` INT NOT NULL DEFAULT 0," +
			"`bodyModel` VARCHAR(64) NOT NULL DEFAULT '',`bodyTex` INT NOT NULL DEFAULT -1,`headModel` VARCHAR(64) NOT NULL DEFAULT '',`headTex` INT NOT NULL DEFAULT -1,`voice` INT NOT NULL DEFAULT 0," +
			"`idleAnimation` VARCHAR(64) NOT NULL DEFAULT '',`aggroRadius` INT NOT NULL DEFAULT 900,`attackRange` INT NOT NULL DEFAULT 180,`attackDamage` INT NOT NULL DEFAULT 10,`walkSpeed` INT NOT NULL DEFAULT 250,`baseExperience` INT NOT NULL DEFAULT 0," +
			"`hostile` TINYINT NOT NULL DEFAULT 0,`respawnSec` INT NOT NULL DEFAULT 60,`tag` VARCHAR(48) DEFAULT '',`script` VARCHAR(96) DEFAULT '',`metadata` TEXT NULL,`presetId` INT UNSIGNED NULL,`kind` VARCHAR(24) NOT NULL DEFAULT 'monster',`createdBy` INT NULL,`teacherSkills` VARCHAR(128) NOT NULL DEFAULT '',`teachCost` INT NOT NULL DEFAULT 100," +
			"`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"KEY `idx_npc_world` (`world`),KEY `idx_npc_tag` (`tag`),KEY `idx_npc_preset` (`presetId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try {
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.npc.Spawn.ensureColumns(callback)
			})
		} catch (e) {
			phoenix.npc.Spawn.loading = false
			phoenix.npc.Spawn.scheduleLoadRetry()
		}
	}

	function ensureColumns(callback) {
		local defs = {
			scaleX = "FLOAT NOT NULL DEFAULT 1",
			scaleY = "FLOAT NOT NULL DEFAULT 1",
			scaleZ = "FLOAT NOT NULL DEFAULT 1",
			fatness = "FLOAT NOT NULL DEFAULT 0",
			hp = "INT NOT NULL DEFAULT 0",
			level = "INT NOT NULL DEFAULT 0",
			experience = "INT NOT NULL DEFAULT 0",
			strength = "INT NOT NULL DEFAULT 0",
			dexterity = "INT NOT NULL DEFAULT 0",
			bodyModel = "VARCHAR(64) NOT NULL DEFAULT ''",
			bodyTex = "INT NOT NULL DEFAULT -1",
			headModel = "VARCHAR(64) NOT NULL DEFAULT ''",
			headTex = "INT NOT NULL DEFAULT -1",
			voice = "INT NOT NULL DEFAULT 0",
			idleAnimation = "VARCHAR(64) NOT NULL DEFAULT ''",
			aggroRadius = "INT NOT NULL DEFAULT 900",
			attackRange = "INT NOT NULL DEFAULT 180",
			attackDamage = "INT NOT NULL DEFAULT 10",
			walkSpeed = "INT NOT NULL DEFAULT 250",
			baseExperience = "INT NOT NULL DEFAULT 0",
			metadata = "TEXT NULL",
			presetId = "INT UNSIGNED NULL",
			kind = "VARCHAR(24) NOT NULL DEFAULT 'monster'",
			createdBy = "INT NULL",
			teacherSkills = "VARCHAR(128) NOT NULL DEFAULT ''",
			teachCost = "INT NOT NULL DEFAULT 100"
		}
		ORM.engine.executeAsync("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'phoenix_npc_spawns'", function (rows) {
			local present = {}
			if (rows != null) {
				foreach (r in rows) {
					local n = phoenix.npc.Spawn._readStr(r, "COLUMN_NAME", "")
					if (n != "") present[n] <- true
				}
			}
			local missing = []
			foreach (name, def in defs) {
				if (!(name in present)) missing.append({ name = name, def = def })
			}
			phoenix.npc.Spawn.ensureColumnStep(missing, 0, callback)
		})
	}

	function ensureColumnStep(missing, index, callback) {
		if (index >= missing.len()) { if (callback != null) callback(); return }
		local item = missing[index]
		local sql = "ALTER TABLE `phoenix_npc_spawns` ADD COLUMN `" + item.name + "` " + item.def
		ORM.engine.executeAsync(sql, function (_) {
			phoenix.npc.Spawn.ensureColumnStep(missing, index + 1, callback)
		})
	}

	function scheduleLoadRetry() {
		if (phoenix.npc.Spawn.loaded) return
		local delay = 3000
		if (phoenix.npc.Spawn.loadAttempts > 5) delay = 10000
		setTimer(function () {
			try { phoenix.npc.Spawn.loadAll() } catch (e) { phoenix.npc.Spawn.loading = false; phoenix.npc.Spawn.scheduleLoadRetry() }
		}, delay, 1)
	}

	function insertAndSpawn(row, callback) {
		local esc = phoenix.npc.Spawn._esc
		local sql = "INSERT INTO `phoenix_npc_spawns` " +
			"(`instance`,`name`,`world`,`posX`,`posY`,`posZ`,`angle`," +
			"`scaleX`,`scaleY`,`scaleZ`,`fatness`," +
			"`hp`,`level`,`experience`,`strength`,`dexterity`," +
			"`bodyModel`,`bodyTex`,`headModel`,`headTex`,`voice`," +
			"`idleAnimation`,`aggroRadius`,`attackRange`,`attackDamage`,`walkSpeed`,`baseExperience`," +
			"`hostile`,`respawnSec`,`tag`,`script`,`metadata`,`presetId`,`kind`,`createdBy`,`teacherSkills`,`teachCost`) VALUES ('" +
			esc(row.instance) + "','" + esc(row.name) + "','" + esc(row.world) + "'," +
			row.posX + "," + row.posY + "," + row.posZ + "," + row.angle + "," +
			row.scaleX + "," + row.scaleY + "," + row.scaleZ + "," + row.fatness + "," +
			row.hp + "," + row.level + "," + (("experience" in row) ? row.experience : 0) + "," + row.strength + "," + row.dexterity + ",'" +
			esc(row.bodyModel) + "'," + row.bodyTex + ",'" + esc(row.headModel) + "'," + row.headTex + "," + row.voice + ",'" +
			esc(row.idleAnimation) + "'," + row.aggroRadius + "," + row.attackRange + "," + row.attackDamage + "," + row.walkSpeed + "," +
			(("baseExperience" in row) ? row.baseExperience : 0) + "," +
			row.hostile + "," + row.respawnSec + ",'" + esc(row.tag) + "','" + esc(row.script) + "','" + esc(row.metadata) + "'," +
			(row.presetId > 0 ? row.presetId.tostring() : "NULL") + ",'" + esc(row.kind) + "'," +
			(row.createdBy != null ? row.createdBy.tostring() : "NULL") + ",'" + esc(("teacherSkills" in row) ? row.teacherSkills : "") + "'," +
			(("teachCost" in row) ? row.teachCost : 100) + ")"
		ORM.engine.executeAsync(sql, function (_) {
			ORM.engine.executeAsync("SELECT LAST_INSERT_ID() AS id", function (rows) {
				if (rows == null || rows.len() == 0) { if (callback != null) callback(-1); return }
				row.id <- rows[0].id
				phoenix.npc.Spawn.spawnRow(row)
				if (callback != null) callback(row.id)
			})
		})
	}

	function update(spawnId, fields, callback) {
		local sets = []
		local esc = phoenix.npc.Spawn._esc
		local strKeys = ["instance","name","world","tag","script","metadata","bodyModel","headModel","kind","idleAnimation","teacherSkills"]
		local numKeys = ["posX","posY","posZ","angle","scaleX","scaleY","scaleZ","fatness",
			"hp","level","experience","strength","dexterity","bodyTex","headTex","voice",
			"aggroRadius","attackRange","attackDamage","walkSpeed","baseExperience","teachCost",
			"hostile","respawnSec","presetId"]
		foreach (k, v in fields) {
			local isStr = false
			foreach (sk in strKeys) if (sk == k) { isStr = true; break }
			if (isStr) { sets.append("`" + k + "` = '" + esc(v) + "'"); continue }
			local isNum = false
			foreach (nk in numKeys) if (nk == k) { isNum = true; break }
			if (isNum) { sets.append("`" + k + "` = " + v) }
		}
		if (sets.len() == 0) { if (callback != null) callback(false); return }
		local sql = "UPDATE `phoenix_npc_spawns` SET " + sets.reduce(function (a, b) { return a + ", " + b }) + " WHERE `id` = " + spawnId
		ORM.engine.executeAsync(sql, function (_) {
			phoenix.npc.Spawn.despawnRow(spawnId)
			ORM.engine.executeAsync("SELECT * FROM `phoenix_npc_spawns` WHERE `id` = " + spawnId, function (rows) {
				if (rows != null && rows.len() > 0) {
					phoenix.npc.Spawn.spawnRow(phoenix.npc.Spawn.rowToObject(rows[0]))
				}
				if (callback != null) callback(true)
			})
		})
	}

	function remove(spawnId, callback) {
		phoenix.npc.Spawn.despawnRow(spawnId)
		ORM.engine.executeAsync("DELETE FROM `phoenix_npc_spawns` WHERE `id` = " + spawnId, function (_) {
			if (callback != null) callback(true)
		})
	}

	function onNpcKilled(npcId, killerId = -1) {
		foreach (sid, entry in phoenix.npc.Spawn.live) {
			if (entry.npcId == npcId) {
				if (!entry.alive) return
				entry.alive = false
				entry.ai.state = "dead"
				local row = entry.row
				try {
					if (killerId != null && killerId >= 0) {
						local xp = ("baseExperience" in row) ? row.baseExperience.tointeger() : 0
						local killerNpc = phoenix.npc.Spawn._liveByNpcId(killerId)
						if (killerNpc != null) {
							if (xp > 0) phoenix.npc.Spawn.awardNpcExperience(killerId, xp)
						} else {
							local rec = phoenix.character.Structure.getActive(killerId)
							if (rec != null) {
								phoenix.npc.Bestiary.bumpFromEntry(rec.id, entry)
								if (xp > 0) phoenix.player.Progression.awardExperience(killerId, xp)
							}
						}
					}
				} catch (ex) {}
				if (row.respawnSec > 0) {
					local sec = row.respawnSec
					entry.respawnTimer = setTimer(function () {
						try {
							phoenix.npc.Spawn.despawnRow(row.id)
							phoenix.npc.Spawn.spawnRow(row)
						} catch (e) {}
					}, sec * 1000, 1)
				}
				return
			}
		}
	}

	function listAll() {
		local out = []
		foreach (sid, entry in phoenix.npc.Spawn.live) {
			local r = entry.row
			out.append({
				id = r.id, instance = r.instance, name = r.name, world = r.world,
				posX = r.posX, posY = r.posY, posZ = r.posZ, angle = r.angle,
				hostile = r.hostile, respawnSec = r.respawnSec,
				tag = r.tag, alive = entry.alive, npcId = entry.npcId,
				presetId = r.presetId, kind = r.kind,
				scaleX = r.scaleX, scaleY = r.scaleY, scaleZ = r.scaleZ,
				fatness = r.fatness, hp = r.hp, level = r.level, experience = ("experience" in r) ? r.experience : 0,
				bodyModel = r.bodyModel, bodyTex = r.bodyTex,
				headModel = r.headModel, headTex = r.headTex,
				idleAnimation = r.idleAnimation,
				aggroRadius = r.aggroRadius, attackRange = r.attackRange,
				attackDamage = r.attackDamage, walkSpeed = r.walkSpeed,
				teacherSkills = r.teacherSkills, teachCost = r.teachCost, baseExperience = r.baseExperience
			})
		}
		return out
	}

	function _printServerStats() {
		try {
			local npcCount = 0
			local monsterCount = 0
			local humanCount = 0
			foreach (sid, entry in phoenix.npc.Spawn.live) {
				npcCount += 1
				if (phoenix.npc.AI._isHuman(entry.row)) humanCount += 1
				else monsterCount += 1
			}
			print("[stats] NPCs: " + npcCount + " (humans: " + humanCount + ", monsters: " + monsterCount + ")\n")
		} catch (e) {}
		try {
			local sql = "SELECT " +
				"(SELECT COUNT(*) FROM phoenix_accounts) AS accounts, " +
				"(SELECT COUNT(*) FROM phoenix_characters) AS characters, " +
				"(SELECT COUNT(*) FROM phoenix_world_vobs WHERE active=1) AS vobs, " +
				"(SELECT COUNT(*) FROM phoenix_herb_spots WHERE active=1) AS herbs"
			ORM.engine.executeAsync(sql, function(rows) {
				if (rows == null || rows.len() == 0) return
				local r = rows[0]
				local accounts = ("accounts" in r) ? r.accounts : 0
				local characters = ("characters" in r) ? r.characters : 0
				local vobs = ("vobs" in r) ? r.vobs : 0
				local herbs = ("herbs" in r) ? r.herbs : 0
				print("[stats] Accounts: " + accounts + " | Characters: " + characters + " | VOBs: " + vobs + " | Herbs: " + herbs + "\n")
				try {
					local sql2 = "SELECT COUNT(*) AS cnt FROM phoenix_houses"
					ORM.engine.executeAsync(sql2, function(rows2) {
						local houses = (rows2 != null && rows2.len() > 0 && "cnt" in rows2[0]) ? rows2[0].cnt : 0
						print("[stats] Houses: " + houses + "\n")
					})
				} catch (eH) {}
				try {
					print("[stats] Item schemes: " + phoenix.item.count() + "\n")
				} catch (eI) {}
			})
		} catch (eS) {}
	}

	function bootLoad() {
		phoenix.npc.Spawn.ensureNameplateTicker()
		if (phoenix.npc.Spawn.loaded || phoenix.npc.Spawn.loading) return
		if (phoenix.npc.Spawn.bootScheduled) return
		phoenix.npc.Spawn.bootScheduled = true
		setTimer(function () {
			phoenix.npc.Spawn.bootScheduled = false
			local ready = false
			try { ready = phoenix.database.ready } catch (e) {}
			if (!ready) { phoenix.npc.Spawn.bootLoad(); return }
			try { phoenix.npc.Spawn.loadAll() } catch (e) {}
		}, 1000, 1)
	}
}

addEventHandler("onPlayerDamage", function (victimId, killerId, desc) {
	try {
		local entry = phoenix.npc.Spawn._liveByNpcId(victimId)
		if (entry != null && ("unconscious" in entry.ai) && entry.ai.unconscious == true) {
			cancelEvent()
			try { eventValue(0) } catch (e) {}
			return
		}
		local attackerIsPlayer = killerId != null && killerId >= 0 && killerId < getMaxSlots()
		local attackerNpc = null
		if (killerId != null && killerId >= 0) {
			try { attackerNpc = phoenix.npc.Spawn._liveByNpcId(killerId) } catch (en) { attackerNpc = null }
		}
		if (entry != null && (attackerIsPlayer || attackerNpc != null)) {
			cancelEvent()
			if (attackerIsPlayer) {
				try {
					if (phoenix.character.Structure.getActive(killerId) != null) phoenix.player.Hud.consumeStamina(killerId, 1.0)
				} catch (es) {}
			}
			local hp = getPlayerHealth(victimId)
			local summary = phoenix.player.Combat.calculate(killerId, victimId, desc, 0)
			if (summary.miss || summary.dodged || summary.finalDamage <= 0) {
				try { phoenix.player.Combat.emitText(victimId, 0, summary.dodged ? "dodge" : "miss") } catch (ect) {}
				eventValue(0)
				phoenix.npc.Spawn._retaliate(entry, killerId)
				return
			}
			local dmg = summary.finalDamage
			try { phoenix.player.WeaponProgression.onValidHit(killerId, victimId, dmg, desc) } catch (ewp) {}
			try { phoenix.player.Combat.emitText(victimId, dmg, summary.critical ? "crit" : "damage") } catch (ect2) {}
			local newHp = hp - dmg
			if (newHp < 0) newHp = 0
			local lethal = newHp <= 0
			local divertToKnockdown = false
			try { divertToKnockdown = lethal && phoenix.npc.AI._isHuman(entry.row) } catch (eHk) {}
			if (divertToKnockdown) {
				setPlayerHealth(victimId, 1)
				try { eventValue(dmg) } catch (e) {}
				try { phoenix.npc.AI._knockdown(entry, killerId) } catch (eKd) {}
				phoenix.npc.Spawn.broadcastNameplates()
				return
			}
			setPlayerHealth(victimId, newHp)
			try { eventValue(dmg) } catch (e) {}
			phoenix.npc.Spawn._retaliate(entry, killerId)
			if (lethal) phoenix.npc.Spawn.onNpcKilled(victimId, killerId)
			phoenix.npc.Spawn.broadcastNameplates()
			return
		}
		if (getPlayerHealth(victimId) <= 0) {
			phoenix.npc.Spawn.onNpcKilled(victimId, killerId)
		}
		// If an NPC killed a player via ranged attack, mark killedPlayer for loot AI
		if (entry == null && killerId != null && killerId >= 0) {
			local attackerEntry = phoenix.npc.Spawn._liveByNpcId(killerId)
			if (attackerEntry != null) {
				try {
					local victimHp = getPlayerHealth(victimId)
					if (victimHp <= 0 || (victimId in phoenix.player.Gate.reviving)) {
						attackerEntry.ai.killedPlayer <- victimId
						attackerEntry.ai.killedPlayerAt <- getTickCount()
					}
				} catch (eKp) {}
			}
		}
	} catch (e) {}
})

addEventHandler("onInit", function () {
	try { phoenix.npc.Spawn.ensureNameplateTicker() } catch (e) {}
	phoenix.npc.Spawn.bootLoad()
})

addEventHandler("onPlayerJoin", function (playerId) {
	try { phoenix.npc.Spawn.bootLoad() } catch (e) {}
	try { phoenix.npc.Spawn.broadcastNameplates(playerId) } catch (e) {}
	setTimer(function () {
		try { phoenix.npc.Spawn.broadcastNameplates(playerId) } catch (e) {}
	}, 1000, 1)
	setTimer(function () {
		try { phoenix.npc.Spawn.broadcastNameplates(playerId) } catch (e) {}
	}, 5000, 1)
})

addEventHandler("phoenix.player.OnSpawned", function (playerId, _characterId, _record) {
	try { phoenix.npc.Spawn.broadcastNameplates(playerId) } catch (e) {}
	setTimer(function () {
		try { phoenix.npc.Spawn.broadcastNameplates(playerId) } catch (e) {}
	}, 1000, 1)
})

phoenix.npc.Spawn.bootLoad()
