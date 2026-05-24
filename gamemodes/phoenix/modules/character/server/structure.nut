phoenix.character.MAX_SLOTS <- 4
phoenix.character.InventoryOwnerPlayer <- 0
phoenix.character.ItemQualityCommon <- 2
phoenix.character.ItemSlotNone <- 0

phoenix.character.Scenarios <- (("config" in phoenix) && ("CharacterSpots" in phoenix.config) && ("Scenarios" in phoenix.config.CharacterSpots))
	? phoenix.config.CharacterSpots.Scenarios.map(function (s) { return { x = s.X, y = s.Y, z = s.Z, angle = s.Angle } })
	: [
		{ x = -37591.7, y = -2033.3,  z = 15142.5,  angle = 91.6603 },
		{ x = 21282.2,  y = -5116.71, z = 4491.03,  angle = 57.3989 },
		{ x = -19429.0, y = -2791.03, z = -11997.8, angle = 0.181277 }
	]

phoenix.character.StarterMelee <- [
	{ key = "melee_1h", instance = "ITMW_1H_BAU_AXE" },
	{ key = "melee_2h", instance = "ITMW_2H_AXE_L_01" }
]

phoenix.character.StarterRanged <- [
	{ key = "ranged_bow",      instance = "ITRW_BOW_L_01",      ammo = "ITRW_ARROW" },
	{ key = "ranged_crossbow", instance = "ITRW_CROSSBOW_L_01", ammo = "ITRW_BOLT" }
]

phoenix.character.StarterOutfits <- [
	{ key = "outfit_worker",  male = "ITAR_BAU_L",     female = "ITAR_BAUBABE_L" },
	{ key = "outfit_citizen", male = "ITAR_VLK_M",     female = "ITAR_BAUBABE_M" },
	{ key = "outfit_leather", male = "ITAR_LEATHER_L", female = "ITAR_DJG_BABE" }
]

phoenix.character.buildStarterItems <- function(gender, weaponIdx, rangedIdx, outfitIdx) {
	local items = []
	if (outfitIdx >= 0 && outfitIdx < phoenix.character.StarterOutfits.len()) {
		local o = phoenix.character.StarterOutfits[outfitIdx]
		local instance = (gender == PhoenixCharacterGender.Female) ? o.female : o.male
		if (instance != "") items.push({ instance = instance, amount = 1, equipped = true })
	}
	if (weaponIdx >= 0 && weaponIdx < phoenix.character.StarterMelee.len()) {
		local w = phoenix.character.StarterMelee[weaponIdx]
		if (w.instance != "") items.push({ instance = w.instance, amount = 1, equipped = true })
	}
	if (rangedIdx >= 0 && rangedIdx < phoenix.character.StarterRanged.len()) {
		local r = phoenix.character.StarterRanged[rangedIdx]
		if (r.instance != "") items.push({ instance = r.instance, amount = 1, equipped = true })
		if (r.ammo != "") items.push({ instance = r.ammo, amount = 100, equipped = false })
	}
	return items
}

phoenix.character.buildStarterEquipment <- function(gender, weaponIdx, rangedIdx, outfitIdx) {
	local items = phoenix.character.buildStarterItems(gender, weaponIdx, rangedIdx, outfitIdx)
	local result = ""
	for (local i = 0; i < items.len(); i += 1) {
		if (i > 0) result += ","
		result += items[i].instance + "|" + items[i].amount
	}
	return result
}

phoenix.character.createStarterInventory <- function(characterId, items, callback) {
	local index = 0
	local next = null
	next = function() {
		if (index >= items.len()) return callback()
		local entry = items[index]
		index += 1
		local scheme = phoenix.item.find(entry.instance)
		if (scheme == null) return next()
		local rec = ItemModel()
		rec.ownerType = phoenix.character.InventoryOwnerPlayer
		rec.ownerId = characterId
		rec.instanceId = entry.instance
		rec.amount = entry.amount
		rec.quality = phoenix.character.ItemQualityCommon
		rec.upgrade = 0
		rec.durability = 100
		rec.equipped = entry.equipped ? 1 : 0
		rec.slot = ("slot" in scheme) ? scheme.slot : phoenix.character.ItemSlotNone
		rec.source = "starter"
		rec.insertAsync(@(_) next())
	}
	next()
}

phoenix.character.Structure <- {
	active = {}
	playTicks = {}

	function getActive(playerId) {
		return playerId in active ? active[playerId] : null
	}

	function setActive(playerId, record) {
		active[playerId] <- record
		playTicks[playerId] <- getTickCount()
	}

	function clearActive(playerId) {
		if (playerId in active) active.rawdelete(playerId)
		if (playerId in playTicks) playTicks.rawdelete(playerId)
	}

	function bumpPlayTime(playerId, record) {
		if (record == null) return
		local now = getTickCount()
		local started = playerId in playTicks ? playTicks[playerId] : now
		local delta = ((now - started) / 1000).tointeger()
		if (delta > 0) {
			record.playTimeSec = record.playTimeSec + delta
			playTicks[playerId] <- now
		}
	}

	function markPlayed(characterId) {
		local sql = "UPDATE `phoenix_characters` SET `lastPlayedAt` = CURRENT_TIMESTAMP WHERE `id` = " + characterId
		ORM.engine.executeAsync(sql, function(_) {})
	}

	function listForAccount(accountId, callback) {
		CharacterModel.findByAccount(accountId, callback)
	}

	function ensureSlots(accountId, callback) {
		CharacterModel.countByAccount(accountId, callback)
	}

	function findOwned(accountId, characterId, callback) {
		CharacterModel.findOneAsync(@(q) q.where("id", "=", characterId).and("accountId", "=", accountId), callback)
	}

	function reloadActive(playerId, callback = null) {
		local current = playerId in active ? active[playerId] : null
		if (current == null) { if (callback != null) callback(null); return }
		local cid = current.id
		try {
			CharacterModel.findOneAsync(@(q) q.where("id", "=", cid), function (rec) {
				if (rec != null) {
					try { rec.hotbar = current.hotbar } catch (eH) {}
					active[playerId] <- rec
					try { phoenix.player.Progression.normalizeRecordStats(rec) } catch (eN) {}
					try { setPlayerMaxHealth(playerId, rec.hpMax) } catch (eA) {}
					try { setPlayerHealth(playerId, rec.hp > 0 ? rec.hp : rec.hpMax) } catch (eA2) {}
					try { setPlayerMaxMana(playerId, rec.manaMax) } catch (eA3) {}
					try { setPlayerMana(playerId, rec.mana > 0 ? rec.mana : rec.manaMax) } catch (eA4) {}
					try { setPlayerStrength(playerId, rec.strength) } catch (eA5) {}
					try { setPlayerDexterity(playerId, rec.dexterity) } catch (eA6) {}
					try { phoenix.player.Stats.pushSnapshot(playerId) } catch (eS) {}
					try { phoenix.player.Hud.pushSnapshot(playerId) } catch (eHd) {}
				}
				if (callback != null) callback(rec)
			})
		} catch (e) { if (callback != null) callback(null) }
	}

	function reloadByCharacterId(characterId) {
		foreach (pid, rec in active) {
			if (rec != null && rec.id == characterId) {
				phoenix.character.Structure.reloadActive(pid)
				return pid
			}
		}
		return -1
	}

	function create(accountId, payload, callback) {
		CharacterModel.findByNormalizedName(payload.name, function(existing) {
			if (existing != null) return callback("phoenix.character.error.nameTaken", null)

			CharacterModel.countByAccount(accountId, function(count) {
				if (count >= phoenix.character.MAX_SLOTS)
					return callback("phoenix.character.error.noSlots", null)

				local record = CharacterModel()
				record.accountId = accountId
				record.name = payload.name
				record.normalizedName = payload.name.tolower()
				record.gender = payload.gender
				record.klass = payload.klass
				record.race = payload.race
				record.fatness = payload.fatness
				record.walking = payload.walking
				record.weapon = payload.weapon
				record.outfit = payload.outfit
				record.scenario = payload.scenario
				record.bodyModel = payload.bodyModel
				record.headModel = payload.headModel
				record.bodyTexIndex = payload.bodyTexIndex
				record.face = payload.face
				record.voice = payload.voice
				record.world = "NEWWORLD.ZEN"

				local _default = (("config" in phoenix) && ("CharacterSpots" in phoenix.config) && ("DEFAULT_RECORD" in phoenix.config.CharacterSpots))
					? phoenix.config.CharacterSpots.DEFAULT_RECORD
					: null
				record.positionX = (_default != null && ("X" in _default.Position)) ? _default.Position.X : 870.118
				record.positionY = (_default != null && ("Y" in _default.Position)) ? _default.Position.Y : -96.2501
				record.positionZ = (_default != null && ("Z" in _default.Position)) ? _default.Position.Z : -1848.33
				record.angle     = (_default != null && ("Angle" in _default)) ? _default.Angle : 65.1225
				local starterItems = phoenix.character.buildStarterItems(payload.gender, payload.weapon, payload.ranged, payload.outfit)
				record.equipment = ""
				record.hpMax = 100
				record.hp = 100
				record.staminaMax = 100
				record.stamina = 100
				record.manaMax = (payload.klass == 1) ? 50 : 10
				record.mana = record.manaMax
				record.experience = 0
				record.experienceNext = 500
				local meleeInstance = ""
				local rangedInstance = ""
				try {
					if (payload.weapon >= 0 && payload.weapon < phoenix.character.StarterMelee.len())
						meleeInstance = phoenix.character.StarterMelee[payload.weapon].instance
				} catch (eM) {}
				try {
					if (payload.ranged >= 0 && payload.ranged < phoenix.character.StarterRanged.len())
						rangedInstance = phoenix.character.StarterRanged[payload.ranged].instance
				} catch (eR) {}
				try { phoenix.player.Hotbar.setDefaults(record, meleeInstance, rangedInstance) } catch (eH) {}
				record.insertAsync(function(_) {
					phoenix.character.createStarterInventory(record.id, starterItems, function() {
						callback(null, record)
					})
				})
			})
		})
	}

	function remove(accountId, characterId, callback) {
		findOwned(accountId, characterId, function(record) {
			if (record == null) return callback("phoenix.character.error.notOwned")
			ItemModel.deleteByOwner(phoenix.character.InventoryOwnerPlayer, record.id, function(_) {
				local sql = "DELETE FROM `phoenix_characters` WHERE `id` = " + record.id + " AND `accountId` = " + accountId
				ORM.engine.executeAsync(sql, function(_) { callback(null) })
			})
		})
	}
}
