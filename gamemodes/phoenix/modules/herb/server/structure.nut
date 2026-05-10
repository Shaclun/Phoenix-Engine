phoenix.herb.Structure <- {
	active = {}
	range = 180.0
	spotsLoaded = false
	loading = false
	bootScheduled = false
	loadAttempts = 0

	function dist(a, b) {
		local dx = a.x - b.x
		local dz = a.z - b.z
		return sqrt(dx * dx + dz * dz)
	}

	function normalizeWorld(value) {
		if (value == null || value == "") return "NEWWORLD"
		local s = value.tostring()
		local sep = -1
		for (local i = s.len() - 1; i >= 0; i -= 1) {
			local ch = s[i]
			if (ch == '\\' || ch == '/') { sep = i; break }
		}
		if (sep >= 0) s = s.slice(sep + 1)
		local up = s.toupper()
		local zenAt = up.find(".ZEN")
		if (zenAt != null) up = up.slice(0, zenAt)
		local n = up.len()
		if (n > 0 && (n % 2) == 0) {
			local half = n / 2
			if (up.slice(0, half) == up.slice(half)) up = up.slice(half)
		}
		return up
	}

	function sameWorld(a, b) {
		local aw = phoenix.herb.Structure.normalizeWorld(a)
		local bw = phoenix.herb.Structure.normalizeWorld(b)
		if (aw == "" || bw == "") return true
		return aw == bw
	}

	function spotById(plantId) {
		foreach (spot in phoenix.herb.Spots) {
			if (spot.id == plantId) return spot
		}
		return null
	}

	function removeRuntimeSpot(plantId) {
		for (local i = phoenix.herb.Spots.len() - 1; i >= 0; i -= 1) {
			try {
				if (phoenix.herb.Spots[i].id == plantId) phoenix.herb.Spots.remove(i)
			} catch (e) {}
		}
	}

	function esc(value) {
		try { return ORM.engine.escape(value.tostring()) } catch (e) {}
		return value == null ? "" : value.tostring()
	}

	function rowToSpot(row) {
		local instance = ("instanceId" in row) ? row.instanceId.tostring().toupper() : "ITPL_HEALTH_HERB_01"
		local catalog = phoenix.herb.catalogOf(instance)
		if (catalog == null) return null
		return {
			id = ("plantId" in row) ? row.plantId.tostring() : ("herb_" + instance.tolower()),
			instance = instance,
			world = ("world" in row) ? phoenix.herb.Structure.normalizeWorld(row.world) : "NEWWORLD",
			x = ("posX" in row) ? row.posX.tofloat() : 0.0,
			y = ("posY" in row) ? row.posY.tofloat() : 0.0,
			z = ("posZ" in row) ? row.posZ.tofloat() : 0.0,
			gatherMs = ("gatherMs" in row) ? row.gatherMs.tointeger() : catalog.gatherMs,
			cooldownSec = ("cooldownSec" in row) ? row.cooldownSec.tointeger() : catalog.cooldownSec,
			successChance = ("successChance" in row) ? row.successChance.tointeger() : catalog.successChance,
			db = true
		}
	}

	function broadcastSnapshot() {
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try {
				if (isPlayerConnected(pid)) phoenix.herb.Structure.sendSnapshot(pid)
			} catch (e) {}
		}
	}

	function entryOf(spot, cooldownLeftSec = 0) {
		local instance = spot.instance.tostring().toupper()
		local catalog = phoenix.herb.catalogOf(instance)
		local visual = ""
		try {
			local v = phoenix.item.lookupVisual(instance)
			if (v != null) visual = v
		} catch (e) {}
		local gatherMs = ("gatherMs" in spot) ? spot.gatherMs : catalog.gatherMs
		local cooldownSec = ("cooldownSec" in spot) ? spot.cooldownSec : catalog.cooldownSec
		local successChance = ("successChance" in spot) ? spot.successChance : catalog.successChance
		return {
			plantId = spot.id,
			instance = instance,
			visual = visual,
			namePl = catalog.pl,
			nameEn = catalog.en,
			nameDe = catalog.de,
			nameRu = catalog.ru,
			world = spot.world,
			x = spot.x.tofloat(),
			y = spot.y.tofloat(),
			z = spot.z.tofloat(),
			gatherMs = gatherMs,
			cooldownSec = cooldownSec,
			cooldownLeftSec = cooldownLeftSec,
			successChance = successChance
		}
	}

	function cooldownMapSql(characterId) {
		return "SELECT `plantId`, UNIX_TIMESTAMP(`lastGatheredAt`) AS ts FROM `phoenix_herb_gathers` WHERE `characterId` = " + characterId
	}

	function cooldownMapFromRows(rows) {
		local out = {}
		if (rows == null) return out
		foreach (row in rows) {
			try { out[row.plantId.tostring()] <- row.ts.tointeger() } catch (e) {}
		}
		return out
	}

	function remainingFromTimestamp(ts, cooldownSec) {
		if (ts <= 0) return 0
		local now = 0
		try { now = time() } catch (e) { now = 0 }
		local left = cooldownSec - (now - ts)
		return left > 0 ? left : 0
	}

	function snapshotList() {
		local out = []
		foreach (spot in phoenix.herb.Spots) {
			local catalog = phoenix.herb.catalogOf(spot.instance)
			if (catalog == null) continue
			out.append(phoenix.herb.Structure.entryOf(spot))
		}
		return out
	}

	function snapshotListWithCooldowns(characterId, rows) {
		local timestamps = phoenix.herb.Structure.cooldownMapFromRows(rows)
		local out = []
		foreach (spot in phoenix.herb.Spots) {
			local catalog = phoenix.herb.catalogOf(spot.instance)
			if (catalog == null) continue
			local cooldownSec = ("cooldownSec" in spot) ? spot.cooldownSec : catalog.cooldownSec
			local ts = (spot.id in timestamps) ? timestamps[spot.id] : 0
			local left = phoenix.herb.Structure.remainingFromTimestamp(ts, cooldownSec)
			out.append(phoenix.herb.Structure.entryOf(spot, left))
		}
		return out
	}

	function sendSnapshot(playerId) {
		local active = null
		try { active = phoenix.character.Structure.getActive(playerId) } catch (e) { active = null }
		if (active != null && active.id > 0) {
			try {
				ORM.engine.executeAsync(phoenix.herb.Structure.cooldownMapSql(active.id), function(rows) {
					local msg = phoenix.herb.Message.Snapshot()
					msg.entries = phoenix.herb.Structure.snapshotListWithCooldowns(active.id, rows)
					try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e2) {}
				})
				return
			} catch (e3) {}
		}
		local msg = phoenix.herb.Message.Snapshot()
		msg.entries = phoenix.herb.Structure.snapshotList()
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function ensureSchema(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_herb_gathers` (`id` INT(11) NOT NULL AUTO_INCREMENT, `characterId` INT(11) NOT NULL, `plantId` VARCHAR(96) NOT NULL, `instanceId` VARCHAR(64) NOT NULL, `lastGatheredAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `lastSuccess` TINYINT(1) NOT NULL DEFAULT 0, `attempts` INT(11) NOT NULL DEFAULT 0, PRIMARY KEY (`id`), UNIQUE KEY `character_plant_unique` (`characterId`, `plantId`), KEY `plant_idx` (`plantId`), KEY `character_idx` (`characterId`)) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci"
		local sqlSpots = "CREATE TABLE IF NOT EXISTS `phoenix_herb_spots` (`id` INT(11) NOT NULL AUTO_INCREMENT, `plantId` VARCHAR(96) NOT NULL, `instanceId` VARCHAR(64) NOT NULL, `world` VARCHAR(96) NOT NULL DEFAULT 'NEWWORLD.ZEN', `posX` FLOAT NOT NULL DEFAULT 0, `posY` FLOAT NOT NULL DEFAULT 0, `posZ` FLOAT NOT NULL DEFAULT 0, `gatherMs` INT(11) NOT NULL DEFAULT 0, `cooldownSec` INT(11) NOT NULL DEFAULT 0, `successChance` INT(11) NOT NULL DEFAULT 100, `active` TINYINT(1) NOT NULL DEFAULT 1, `createdBy` INT(11) NULL, `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, PRIMARY KEY (`id`), UNIQUE KEY `plant_unique` (`plantId`), KEY `world_idx` (`world`), KEY `instance_idx` (`instanceId`)) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci"
		try {
			ORM.engine.executeAsync(sql, function(_) {
				ORM.engine.executeAsync(sqlSpots, function(__) { if (callback != null) callback() })
			})
		} catch (e) { if (callback != null) callback() }
	}

	function bootLoad() {
		if (phoenix.herb.Structure.spotsLoaded || phoenix.herb.Structure.loading) return
		if (phoenix.herb.Structure.bootScheduled) return
		phoenix.herb.Structure.bootScheduled = true
		setTimer(phoenix.herb.Structure.bootLoadTick, 1000, 1)
	}

	function bootLoadTick() {
		phoenix.herb.Structure.bootScheduled = false
		local ready = false
		try { ready = phoenix.database.ready } catch (e) {}
		if (!ready) { phoenix.herb.Structure.bootLoad(); return }
		phoenix.herb.Structure.loading = true
		phoenix.herb.Structure.loadAttempts += 1
		phoenix.herb.Structure.ensureSchema(phoenix.herb.Structure.afterSchema)
	}

	function afterSchema() {
		phoenix.herb.Structure.loadDbSpots(phoenix.herb.Structure.afterLoad)
	}

	function afterLoad() {
		phoenix.herb.Structure.loading = false
		phoenix.herb.Structure.broadcastSnapshot()
	}

	function loadDbSpots(callback) {
		if (phoenix.herb.Structure.spotsLoaded) { if (callback != null) callback(); return }
		try {
			ORM.engine.executeAsync("SELECT * FROM `phoenix_herb_spots` WHERE `active` = 1 ORDER BY `id` ASC", function(rows) {
				phoenix.herb.Structure.spotsLoaded = true
				if (rows != null) {
					foreach (row in rows) {
						local spot = phoenix.herb.Structure.rowToSpot(row)
						if (spot == null) continue
						phoenix.herb.Structure.removeRuntimeSpot(spot.id)
						phoenix.herb.Spots.append(spot)
					}
				}
				if (callback != null) callback()
			})
		} catch (e) { if (callback != null) callback() }
	}

	function listSpots() {
		local out = []
		foreach (spot in phoenix.herb.Spots) {
			try { out.append(phoenix.herb.Structure.entryOf(spot)) } catch (e) {}
		}
		return out
	}

	function saveSpotFromAdmin(playerId, payload, callback) {
		if (payload == null) { if (callback != null) callback(false, "badPayload", null); return }
		local instance = ("instance" in payload && payload.instance != null) ? payload.instance.tostring().toupper() : ""
		local catalog = phoenix.herb.catalogOf(instance)
		if (catalog == null) { if (callback != null) callback(false, "badInstance", null); return }
		local pos = null
		try { pos = getPlayerPosition(playerId) } catch (e) {}
		local x = pos != null ? pos.x : 0.0
		local y = pos != null ? pos.y : 0.0
		local z = pos != null ? pos.z : 0.0
		local world = "NEWWORLD"
		try { local w = getPlayerWorld(playerId); if (w != null && w != "") world = w } catch (e) {}
		if ("posX" in payload) x = payload.posX.tofloat()
		if ("posY" in payload) y = payload.posY.tofloat()
		if ("posZ" in payload) z = payload.posZ.tofloat()
		if ("world" in payload && payload.world != "") world = payload.world.tostring()
		world = phoenix.herb.Structure.normalizeWorld(world)
		local plantId = ("plantId" in payload && payload.plantId != null && payload.plantId != "") ? payload.plantId.tostring() : ("herb_" + instance.tolower() + "_" + getTickCount())
		local gatherMs = ("gatherMs" in payload && payload.gatherMs > 0) ? payload.gatherMs.tointeger() : catalog.gatherMs
		local cooldownSec = ("cooldownSec" in payload && payload.cooldownSec > 0) ? payload.cooldownSec.tointeger() : catalog.cooldownSec
		local successChance = ("successChance" in payload) ? payload.successChance.tointeger() : catalog.successChance
		if (successChance < 1) successChance = 1
		if (successChance > 100) successChance = 100
		local spot = { id = plantId, instance = instance, world = world, x = x, y = y, z = z, gatherMs = gatherMs, cooldownSec = cooldownSec, successChance = successChance, db = true }
		local adminId = "NULL"
		try { local s = phoenix.account.Structure.get(playerId); if (s != null && s.id() > 0) adminId = s.id().tostring() } catch (e) {}
		local sql = "INSERT INTO `phoenix_herb_spots` (`plantId`,`instanceId`,`world`,`posX`,`posY`,`posZ`,`gatherMs`,`cooldownSec`,`successChance`,`active`,`createdBy`) VALUES ('" + phoenix.herb.Structure.esc(plantId) + "','" + phoenix.herb.Structure.esc(instance) + "','" + phoenix.herb.Structure.esc(world) + "'," + x + "," + y + "," + z + "," + gatherMs + "," + cooldownSec + "," + successChance + ",1," + adminId + ") ON DUPLICATE KEY UPDATE `instanceId`=VALUES(`instanceId`),`world`=VALUES(`world`),`posX`=VALUES(`posX`),`posY`=VALUES(`posY`),`posZ`=VALUES(`posZ`),`gatherMs`=VALUES(`gatherMs`),`cooldownSec`=VALUES(`cooldownSec`),`successChance`=VALUES(`successChance`),`active`=1"
		try {
			ORM.engine.executeAsync(sql, function(_) {
				phoenix.herb.Structure.removeRuntimeSpot(plantId)
				phoenix.herb.Spots.append(spot)
				phoenix.herb.Structure.broadcastSnapshot()
				if (callback != null) callback(true, "", spot)
			})
		} catch (e) { if (callback != null) callback(false, "exception", null) }
	}

	function deleteSpot(plantId, callback) {
		if (plantId == null || plantId == "") { if (callback != null) callback(false); return }
		local safe = phoenix.herb.Structure.esc(plantId)
		try {
			ORM.engine.executeAsync("UPDATE `phoenix_herb_spots` SET `active` = 0 WHERE `plantId` = '" + safe + "'", function(_) {
				phoenix.herb.Structure.removeRuntimeSpot(plantId)
				phoenix.herb.Structure.broadcastSnapshot()
				if (callback != null) callback(true)
			})
		} catch (e) { if (callback != null) callback(false) }
	}

	function cooldownSql(characterId, plantId) {
		local safe = plantId
		try { safe = ORM.engine.escape(plantId) } catch (e) {}
		return "SELECT UNIX_TIMESTAMP(`lastGatheredAt`) AS ts FROM `phoenix_herb_gathers` WHERE `characterId` = " + characterId + " AND `plantId` = '" + safe + "' LIMIT 1"
	}

	function recordSql(characterId, plantId, instance, success) {
		local safePlant = plantId
		local safeInstance = instance
		try { safePlant = ORM.engine.escape(plantId) } catch (e) {}
		try { safeInstance = ORM.engine.escape(instance) } catch (e) {}
		local ok = success ? 1 : 0
		return "INSERT INTO `phoenix_herb_gathers` (`characterId`,`plantId`,`instanceId`,`lastGatheredAt`,`lastSuccess`,`attempts`) VALUES (" + characterId + ", '" + safePlant + "', '" + safeInstance + "', NOW(), " + ok + ", 1) ON DUPLICATE KEY UPDATE `instanceId` = VALUES(`instanceId`), `lastGatheredAt` = NOW(), `lastSuccess` = VALUES(`lastSuccess`), `attempts` = `attempts` + 1"
	}

	function remainingFromRows(rows, cooldownSec) {
		if (rows == null || rows.len() == 0) return 0
		local ts = 0
		try { ts = rows[0].ts.tointeger() } catch (e) { ts = 0 }
		if (ts <= 0) return 0
		local now = 0
		try { now = time() } catch (e) { now = 0 }
		return phoenix.herb.Structure.remainingFromTimestamp(ts, cooldownSec)
	}

	function validatePlayer(playerId, spot) {
		local pos = null
		try { pos = getPlayerPosition(playerId) } catch (e) { return false }
		if (pos == null) return false
		local world = ""
		try { world = getPlayerWorld(playerId) } catch (e) {}
		if (!phoenix.herb.Structure.sameWorld(world, spot.world)) return false
		local target = { x = spot.x.tofloat(), y = spot.y.tofloat(), z = spot.z.tofloat() }
		return phoenix.herb.Structure.dist(pos, target) <= phoenix.herb.Structure.range
	}

	function start(playerId, plantId) {
		local spot = phoenix.herb.Structure.spotById(plantId)
		if (spot == null) return
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return
		if (playerId in phoenix.herb.Structure.active) return
		if (!phoenix.herb.Structure.validatePlayer(playerId, spot)) return
		local entry = phoenix.herb.Structure.entryOf(spot)
		ORM.engine.executeAsync(phoenix.herb.Structure.cooldownSql(active.id, spot.id), function(rows) {
			local left = phoenix.herb.Structure.remainingFromRows(rows, entry.cooldownSec)
			if (left > 0) {
				phoenix.herb.Structure.sendResult(playerId, spot.id, false, entry.instance, entry.namePl, "cooldown", left)
				return
			}
			phoenix.herb.Structure.active[playerId] <- { plantId = spot.id, characterId = active.id, startedAt = getTickCount(), finishAt = getTickCount() + entry.gatherMs, entry = entry }
			local msg = phoenix.herb.Message.Started()
			msg.plantId = spot.id
			msg.label = entry.namePl
			msg.gatherMs = entry.gatherMs
			try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
			setTimer(phoenix.herb.Structure.finishSweep, entry.gatherMs, 1)
		})
	}

	function finishSweep() {
		local now = getTickCount()
		local due = []
		foreach (playerId, state in phoenix.herb.Structure.active) {
			local finishAt = ("finishAt" in state) ? state.finishAt : now
			if (finishAt <= now + 50) due.append({ playerId = playerId, plantId = state.plantId })
		}
		foreach (entry in due) phoenix.herb.Structure.finish(entry.playerId, entry.plantId)
	}

	function finish(playerId, plantId) {
		if (!(playerId in phoenix.herb.Structure.active)) return
		local state = phoenix.herb.Structure.active[playerId]
		if (state.plantId != plantId) return
		phoenix.herb.Structure.active.rawdelete(playerId)
		local spot = phoenix.herb.Structure.spotById(plantId)
		if (spot == null) return
		local okDistance = phoenix.herb.Structure.validatePlayer(playerId, spot)
		local roll = 1 + (rand() % 100)
		local success = okDistance && roll <= state.entry.successChance
		ORM.engine.executeAsync(phoenix.herb.Structure.recordSql(state.characterId, plantId, state.entry.instance, success), function(_) {})
		if (success) {
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, state.characterId, state.entry.instance, { amount = 1, source = "herb" }, function(_) {})
			phoenix.herb.Structure.sendResult(playerId, plantId, true, state.entry.instance, state.entry.namePl, "", state.entry.cooldownSec)
			return
		}
		local error = okDistance ? "failed" : "moved"
		phoenix.herb.Structure.sendResult(playerId, plantId, false, state.entry.instance, state.entry.namePl, error, state.entry.cooldownSec)
	}

	function sendResult(playerId, plantId, success, instance, label, error, cooldownSec) {
		local msg = phoenix.herb.Message.Result()
		msg.plantId = plantId
		msg.success = success
		msg.instance = instance
		msg.label = label
		msg.error = error
		msg.cooldownSec = cooldownSec
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function cancel(playerId, plantId, sendMessage) {
		if (!(playerId in phoenix.herb.Structure.active)) return
		local state = phoenix.herb.Structure.active[playerId]
		if (plantId != null && plantId != "" && state.plantId != plantId) return
		phoenix.herb.Structure.active.rawdelete(playerId)
		if (sendMessage) phoenix.herb.Structure.sendResult(playerId, state.plantId, false, state.entry.instance, state.entry.namePl, "cancelled", state.entry.cooldownSec)
	}
}

phoenix.herb.Structure.bootLoad()

addEventHandler("onInit", function() { try { phoenix.herb.Structure.bootLoad() } catch (e) {} })
addEventHandler("onPlayerJoin", function(_pid) { try { phoenix.herb.Structure.bootLoad() } catch (e) {} })
