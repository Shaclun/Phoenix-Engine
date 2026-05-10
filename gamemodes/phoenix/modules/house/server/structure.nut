phoenix.house.Structure <- {
	houses = {}
	loaded = false
	loading = false
	bootScheduled = false
	guardBusy = false
	minEdge = 50.0
	minHeight = 40.0
	rejectDistance = 400.0
	heightMargin = 150.0
	ownerTypePlayer = 1
	weekSeconds = 604800
	maxExtendWeeks = 12
	ownerNames = {}
	pendingRequests = {}

	function esc(value) {
		try { return ORM.engine.escape(value == null ? "" : value.tostring()) } catch (e) {}
		return value == null ? "" : value.tostring()
	}

	function number(value, fallback = 0.0) {
		if (value == null) return fallback
		try { return value.tofloat() } catch (e) {}
		return fallback
	}

	function integer(value, fallback = 0) {
		if (value == null) return fallback
		try { return value.tointeger() } catch (e) {}
		return fallback
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
		return up
	}

	function trim(value) {
		if (value == null) return ""
		local text = value.tostring()
		local start = 0
		local stop = text.len()
		while (start < stop && text[start] <= ' ') start += 1
		while (stop > start && text[stop - 1] <= ' ') stop -= 1
		if (stop <= start) return ""
		return text.slice(start, stop)
	}

	function slugify(value) {
		local text = phoenix.house.Structure.trim(value).tolower()
		local out = ""
		local dash = false
		for (local i = 0; i < text.len(); i += 1) {
			local ch = text[i]
			local ok = (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9')
			if (ok) { out += text.slice(i, i + 1); dash = false }
			else if (!dash && out.len() > 0) { out += "-"; dash = true }
		}
		if (dash && out.len() > 0) out = out.slice(0, out.len() - 1)
		return out
	}

	function normalizeColor(value) {
		local text = phoenix.house.Structure.trim(value).toupper()
		if (text == "") return null
		if (text[0] != '#') text = "#" + text
		if (text.len() != 7 && text.len() != 9) return null
		for (local i = 1; i < text.len(); i += 1) {
			local ch = text[i]
			if (!((ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'F'))) return null
		}
		return text
	}

	function encodePoints(points) {
		if (points == null || points.len() == 0) return null
		local out = ""
		for (local i = 0; i < points.len(); i += 1) {
			local p = points[i]
			if (p == null) continue
			if (out != "") out += "|"
			out += phoenix.house.Structure.number(p.x) + "," + phoenix.house.Structure.number(p.y) + "," + phoenix.house.Structure.number(p.z)
		}
		return out == "" ? null : out
	}

	function decodePoints(text) {
		local out = []
		if (text == null || text == "") return out
		local body = text.tostring()
		local start = 0
		while (start <= body.len()) {
			local sep = body.find("|", start)
			local chunk = sep == null ? body.slice(start) : body.slice(start, sep)
			local first = chunk.find(",")
			local second = first == null ? null : chunk.find(",", first + 1)
			if (first != null && second != null) {
				out.append({ x = phoenix.house.Structure.number(chunk.slice(0, first)), y = phoenix.house.Structure.number(chunk.slice(first + 1, second)), z = phoenix.house.Structure.number(chunk.slice(second + 1)) })
			}
			if (sep == null) break
			start = sep + 1
		}
		return out
	}

	function encodeGuests(list) {
		if (list == null || list.len() == 0) return null
		local out = ""
		foreach (value in list) {
			local id = phoenix.house.Structure.integer(value, 0)
			if (id <= 0) continue
			if (out != "") out += ","
			out += id
		}
		return out == "" ? null : out
	}

	function guestLabelList(list) {
		if (list == null || list.len() == 0) return ""
		local out = ""
		foreach (value in list) {
			local id = phoenix.house.Structure.integer(value, 0)
			if (id <= 0) continue
			if (out != "") out += ", "
			out += "Konto #" + id
		}
		return out
	}

	function decodeGuests(text) {
		local result = { list = [], lookup = {} }
		if (text == null || text == "") return result
		local raw = text.tostring()
		local start = 0
		while (start <= raw.len()) {
			local sep = raw.find(",", start)
			local chunk = sep == null ? raw.slice(start) : raw.slice(start, sep)
			local id = phoenix.house.Structure.integer(chunk, 0)
			if (id > 0 && !(id in result.lookup)) { result.lookup[id] <- true; result.list.append(id) }
			if (sep == null) break
			start = sep + 1
		}
		return result
	}

	function defaultCorners(bounds) {
		return [
			{ x = bounds.min.x, y = bounds.min.y, z = bounds.min.z },
			{ x = bounds.max.x, y = bounds.min.y, z = bounds.min.z },
			{ x = bounds.max.x, y = bounds.min.y, z = bounds.max.z },
			{ x = bounds.min.x, y = bounds.min.y, z = bounds.max.z }
		]
	}

	function normalizePoints(points, fallback) {
		local out = []
		if (points != null) {
			foreach (point in points) {
				if (point == null) continue
				out.append({ x = phoenix.house.Structure.number(point.x), y = phoenix.house.Structure.number(point.y), z = phoenix.house.Structure.number(point.z) })
			}
		}
		if (out.len() < 3 && fallback != null) out = fallback
		return out
	}

	function boundsFromPoints(points, fallbackPos) {
		local source = points
		if (source == null || source.len() == 0) {
			local p = fallbackPos != null ? fallbackPos : { x = 0.0, y = 0.0, z = 0.0 }
			source = [{ x = p.x - 150.0, y = p.y - 30.0, z = p.z - 150.0 }, { x = p.x + 150.0, y = p.y + 30.0, z = p.z + 150.0 }]
		}
		local min = { x = source[0].x, y = source[0].y, z = source[0].z }
		local max = { x = source[0].x, y = source[0].y, z = source[0].z }
		foreach (p in source) {
			if (p.x < min.x) min.x = p.x
			if (p.y < min.y) min.y = p.y
			if (p.z < min.z) min.z = p.z
			if (p.x > max.x) max.x = p.x
			if (p.y > max.y) max.y = p.y
			if (p.z > max.z) max.z = p.z
		}
		if (max.y - min.y < phoenix.house.Structure.minHeight) max.y = min.y + phoenix.house.Structure.minHeight
		return { min = min, max = max }
	}

	function ensureSchema(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_houses` (`id` INT(11) NOT NULL AUTO_INCREMENT,`name` VARCHAR(64) NOT NULL,`slug` VARCHAR(64) NOT NULL,`world` VARCHAR(64) NOT NULL DEFAULT 'NEWWORLD',`centerX` FLOAT NOT NULL DEFAULT 0,`centerY` FLOAT NOT NULL DEFAULT 0,`centerZ` FLOAT NOT NULL DEFAULT 0,`minX` FLOAT NOT NULL DEFAULT 0,`minY` FLOAT NOT NULL DEFAULT 0,`minZ` FLOAT NOT NULL DEFAULT 0,`maxX` FLOAT NOT NULL DEFAULT 0,`maxY` FLOAT NOT NULL DEFAULT 0,`maxZ` FLOAT NOT NULL DEFAULT 0,`cornersJson` TEXT NULL,`metadataJson` TEXT NULL,`entryX` FLOAT NULL,`entryY` FLOAT NULL,`entryZ` FLOAT NULL,`entryHeading` FLOAT NULL,`ownerType` TINYINT(4) NULL,`ownerId` INT(11) NULL,`priceGold` INT(11) NOT NULL DEFAULT 0,`weeklyRentGold` INT(11) NOT NULL DEFAULT 0,`rentPaidUntil` INT(11) NOT NULL DEFAULT 0,`guestAccountIds` TEXT NULL,`color` VARCHAR(9) NULL,`modeId` INT(11) NOT NULL DEFAULT 0,`active` TINYINT(1) NOT NULL DEFAULT 1,`createdBy` INT(11) NULL,`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,PRIMARY KEY (`id`),UNIQUE KEY `house_slug_unique` (`slug`),KEY `house_world_idx` (`world`),KEY `house_owner_idx` (`ownerType`,`ownerId`),KEY `house_active_idx` (`active`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
		try { ORM.engine.executeAsync(sql, function(_) {
			try { ORM.engine.executeAsync("ALTER TABLE `phoenix_houses` ADD COLUMN `weeklyRentGold` INT(11) NOT NULL DEFAULT 0 AFTER `priceGold`", function(__) {}) } catch (ea) {}
			try { ORM.engine.executeAsync("ALTER TABLE `phoenix_houses` ADD COLUMN `rentPaidUntil` INT(11) NOT NULL DEFAULT 0 AFTER `weeklyRentGold`", function(__) {}) } catch (eb) {}
			if (callback != null) callback()
		}) } catch (e) { if (callback != null) callback() }
	}

	function rowToHouse(row) {
		if (row == null) return null
		local bounds = { min = { x = phoenix.house.Structure.number(row.minX), y = phoenix.house.Structure.number(row.minY), z = phoenix.house.Structure.number(row.minZ) }, max = { x = phoenix.house.Structure.number(row.maxX), y = phoenix.house.Structure.number(row.maxY), z = phoenix.house.Structure.number(row.maxZ) } }
		local corners = phoenix.house.Structure.decodePoints(("cornersJson" in row) ? row.cornersJson : null)
		if (corners.len() < 3) corners = phoenix.house.Structure.defaultCorners(bounds)
		local guests = phoenix.house.Structure.decodeGuests(("guestAccountIds" in row) ? row.guestAccountIds : null)
		local ownerType = ("ownerType" in row && row.ownerType != null) ? phoenix.house.Structure.integer(row.ownerType, 0) : null
		local ownerId = ("ownerId" in row && row.ownerId != null) ? phoenix.house.Structure.integer(row.ownerId, 0) : null
		if (ownerType != null && ownerType <= 0) ownerType = null
		if (ownerId != null && ownerId <= 0) ownerId = null
		local entry = null
		if ("entryX" in row && row.entryX != null) entry = { x = phoenix.house.Structure.number(row.entryX), y = phoenix.house.Structure.number(row.entryY), z = phoenix.house.Structure.number(row.entryZ) }
		return {
			id = phoenix.house.Structure.integer(row.id), name = row.name, slug = row.slug, world = phoenix.house.Structure.normalizeWorld(row.world), bounds = bounds,
			center = { x = phoenix.house.Structure.number(row.centerX), y = phoenix.house.Structure.number(row.centerY), z = phoenix.house.Structure.number(row.centerZ) },
			corners = corners, points = corners, entry = entry, entryHeading = ("entryHeading" in row && row.entryHeading != null) ? phoenix.house.Structure.number(row.entryHeading) : null,
			ownerType = ownerType, ownerId = ownerId, ownerLabel = phoenix.house.Structure.ownerLabel(ownerType, ownerId), priceGold = phoenix.house.Structure.integer(row.priceGold, 0), weeklyRentGold = phoenix.house.Structure.integer(("weeklyRentGold" in row) ? row.weeklyRentGold : 0, 0), rentPaidUntil = phoenix.house.Structure.integer(("rentPaidUntil" in row) ? row.rentPaidUntil : 0, 0), guests = guests.list, guestLookup = guests.lookup,
			color = ("color" in row && row.color != null) ? row.color : null, modeId = phoenix.house.Structure.integer(row.modeId, 0)
		}
	}

	function bootLoad() {
		if (phoenix.house.Structure.loaded || phoenix.house.Structure.loading || phoenix.house.Structure.bootScheduled) return
		phoenix.house.Structure.bootScheduled = true
		setTimer(phoenix.house.Structure.bootLoadTick, 1000, 1)
	}

	function bootLoadTick() {
		phoenix.house.Structure.bootScheduled = false
		local ready = false
		try { ready = phoenix.database.ready } catch (e) {}
		if (!ready) { phoenix.house.Structure.bootLoad(); return }
		phoenix.house.Structure.loading = true
		phoenix.house.Structure.ensureSchema(function() { phoenix.house.Structure.loadDb(function() { phoenix.house.Structure.loading = false }) })
	}

	function loadDb(callback) {
		try {
			ORM.engine.executeAsync("SELECT * FROM `phoenix_houses` WHERE `active` = 1 ORDER BY `world` ASC, `name` ASC", function(rows) {
				phoenix.house.Structure.houses.clear()
				if (rows != null) {
					foreach (row in rows) {
						local house = phoenix.house.Structure.rowToHouse(row)
						if (house != null && house.id > 0) phoenix.house.Structure.houses[house.id] <- house
					}
				}
				phoenix.house.Structure.loaded = true
				if (callback != null) callback()
			})
		} catch (e) { if (callback != null) callback() }
	}

	function listAll(callback) {
		phoenix.house.Structure.ensureSchema(function() {
			phoenix.house.Structure.loadDb(function() {
				local out = []
				foreach (_id, house in phoenix.house.Structure.houses) out.append(house)
				if (callback != null) callback(out)
			})
		})
	}

	function validatePayload(payload, playerId) {
		if (payload == null) return { ok = false, error = "badPayload" }
		local name = phoenix.house.Structure.trim(("name" in payload) ? payload.name : "")
		if (name.len() < 3) return { ok = false, error = "name" }
		local slug = phoenix.house.Structure.trim(("slug" in payload) ? payload.slug : "")
		if (slug == "") slug = phoenix.house.Structure.slugify(name)
		if (slug == "") return { ok = false, error = "slug" }
		local points = []
		if ("points" in payload && payload.points != null) points = phoenix.house.Structure.normalizePoints(payload.points, null)
		local fallback = null
		try { fallback = getPlayerPosition(playerId) } catch (e) {}
		local bounds = null
		if (points.len() >= 3) bounds = phoenix.house.Structure.boundsFromPoints(points, fallback)
		else if ("bounds" in payload && payload.bounds != null && "min" in payload.bounds && "max" in payload.bounds) bounds = { min = { x = phoenix.house.Structure.number(payload.bounds.min.x), y = phoenix.house.Structure.number(payload.bounds.min.y), z = phoenix.house.Structure.number(payload.bounds.min.z) }, max = { x = phoenix.house.Structure.number(payload.bounds.max.x), y = phoenix.house.Structure.number(payload.bounds.max.y), z = phoenix.house.Structure.number(payload.bounds.max.z) } }
		else bounds = phoenix.house.Structure.boundsFromPoints(null, fallback)
		if (bounds.min.x > bounds.max.x) { local tmp = bounds.min.x; bounds.min.x = bounds.max.x; bounds.max.x = tmp }
		if (bounds.min.y > bounds.max.y) { local tmpY = bounds.min.y; bounds.min.y = bounds.max.y; bounds.max.y = tmpY }
		if (bounds.min.z > bounds.max.z) { local tmpZ = bounds.min.z; bounds.min.z = bounds.max.z; bounds.max.z = tmpZ }
		if (bounds.max.x - bounds.min.x < phoenix.house.Structure.minEdge || bounds.max.z - bounds.min.z < phoenix.house.Structure.minEdge) return { ok = false, error = "size" }
		if (bounds.max.y - bounds.min.y < phoenix.house.Structure.minHeight) bounds.max.y = bounds.min.y + phoenix.house.Structure.minHeight
		if (points.len() < 3) points = phoenix.house.Structure.defaultCorners(bounds)
		return { ok = true, name = name, slug = slug, bounds = bounds, points = points }
	}

	function saveFromAdmin(playerId, payload, callback) {
		local v = phoenix.house.Structure.validatePayload(payload, playerId)
		if (!v.ok) { if (callback != null) callback(false, v.error, null); return }
		local id = (payload != null && "id" in payload) ? phoenix.house.Structure.integer(payload.id, 0) : 0
		local world = phoenix.house.Structure.normalizeWorld((payload != null && "world" in payload) ? payload.world : null)
		local entry = (payload != null && "entry" in payload && payload.entry != null) ? payload.entry : null
		local entryHeading = (payload != null && "entryHeading" in payload && payload.entryHeading != null) ? phoenix.house.Structure.number(payload.entryHeading) : null
		local ownerType = (payload != null && "ownerType" in payload && payload.ownerType != null && payload.ownerType != "") ? phoenix.house.Structure.integer(payload.ownerType, 0) : 0
		local ownerId = (payload != null && "ownerId" in payload && payload.ownerId != null && payload.ownerId != "") ? phoenix.house.Structure.integer(payload.ownerId, 0) : 0
		if (ownerType <= 0) ownerId = 0
		local priceGold = (payload != null && "priceGold" in payload) ? phoenix.house.Structure.integer(payload.priceGold, 0) : 0
		if (priceGold < 0) priceGold = 0
		local weeklyRentGold = (payload != null && "weeklyRentGold" in payload) ? phoenix.house.Structure.integer(payload.weeklyRentGold, 0) : 0
		if (weeklyRentGold < 0) weeklyRentGold = 0
		local color = phoenix.house.Structure.normalizeColor((payload != null && "color" in payload) ? payload.color : null)
		local modeId = (payload != null && "modeId" in payload) ? phoenix.house.Structure.integer(payload.modeId, 0) : 0
		local guests = (payload != null && "guests" in payload) ? phoenix.house.Structure.encodeGuests(payload.guests) : null
		local adminId = "NULL"
		try { local s = phoenix.account.Structure.get(playerId); if (s != null && s.id() > 0) adminId = s.id().tostring() } catch (e) {}
		local bounds = v.bounds
		local centerX = (bounds.min.x + bounds.max.x) / 2.0
		local centerY = (bounds.min.y + bounds.max.y) / 2.0
		local centerZ = (bounds.min.z + bounds.max.z) / 2.0
		local corners = phoenix.house.Structure.encodePoints(v.points)
		local ownerTypeSql = ownerType > 0 ? ownerType.tostring() : "NULL"
		local ownerIdSql = ownerId > 0 ? ownerId.tostring() : "NULL"
		local entryX = entry != null ? phoenix.house.Structure.number(entry.x).tostring() : "NULL"
		local entryY = entry != null ? phoenix.house.Structure.number(entry.y).tostring() : "NULL"
		local entryZ = entry != null ? phoenix.house.Structure.number(entry.z).tostring() : "NULL"
		local headingSql = entryHeading != null ? entryHeading.tostring() : "NULL"
		local colorSql = color != null ? ("'" + phoenix.house.Structure.esc(color) + "'") : "NULL"
		local guestsSql = guests != null ? ("'" + phoenix.house.Structure.esc(guests) + "'") : "NULL"
		local insertSql = "INSERT INTO `phoenix_houses` (`name`,`slug`,`world`,`centerX`,`centerY`,`centerZ`,`minX`,`minY`,`minZ`,`maxX`,`maxY`,`maxZ`,`cornersJson`,`metadataJson`,`entryX`,`entryY`,`entryZ`,`entryHeading`,`ownerType`,`ownerId`,`priceGold`,`weeklyRentGold`,`guestAccountIds`,`color`,`modeId`,`active`,`createdBy`) VALUES ('" + phoenix.house.Structure.esc(v.name) + "','" + phoenix.house.Structure.esc(v.slug) + "','" + phoenix.house.Structure.esc(world) + "'," + centerX + "," + centerY + "," + centerZ + "," + bounds.min.x + "," + bounds.min.y + "," + bounds.min.z + "," + bounds.max.x + "," + bounds.max.y + "," + bounds.max.z + ",'" + phoenix.house.Structure.esc(corners) + "',NULL," + entryX + "," + entryY + "," + entryZ + "," + headingSql + "," + ownerTypeSql + "," + ownerIdSql + "," + priceGold + "," + weeklyRentGold + "," + guestsSql + "," + colorSql + "," + modeId + ",1," + adminId + ")"
		local updateSql = "UPDATE `phoenix_houses` SET `name`='" + phoenix.house.Structure.esc(v.name) + "',`slug`='" + phoenix.house.Structure.esc(v.slug) + "',`world`='" + phoenix.house.Structure.esc(world) + "',`centerX`=" + centerX + ",`centerY`=" + centerY + ",`centerZ`=" + centerZ + ",`minX`=" + bounds.min.x + ",`minY`=" + bounds.min.y + ",`minZ`=" + bounds.min.z + ",`maxX`=" + bounds.max.x + ",`maxY`=" + bounds.max.y + ",`maxZ`=" + bounds.max.z + ",`cornersJson`='" + phoenix.house.Structure.esc(corners) + "',`entryX`=" + entryX + ",`entryY`=" + entryY + ",`entryZ`=" + entryZ + ",`entryHeading`=" + headingSql + ",`ownerType`=" + ownerTypeSql + ",`ownerId`=" + ownerIdSql + ",`priceGold`=" + priceGold + ",`weeklyRentGold`=" + weeklyRentGold + ",`guestAccountIds`=" + guestsSql + ",`color`=" + colorSql + ",`modeId`=" + modeId + ",`active`=1 WHERE `id`=" + id
		phoenix.house.Structure.ensureSchema(function() {
			local sql = id > 0 ? updateSql : insertSql
			try {
				ORM.engine.executeAsync(sql, function(_) {
					local selectSql = id > 0 ? ("SELECT * FROM `phoenix_houses` WHERE `id`=" + id + " LIMIT 1") : "SELECT * FROM `phoenix_houses` WHERE `id`=LAST_INSERT_ID() LIMIT 1"
					ORM.engine.executeAsync(selectSql, function(rows) {
						if (rows == null || rows.len() == 0) { if (callback != null) callback(false, "notFound", null); return }
						local house = phoenix.house.Structure.rowToHouse(rows[0])
						if (house != null) phoenix.house.Structure.houses[house.id] <- house
						try { phoenix.house.Structure.broadcastSnapshot() } catch (ebs) {}
						if (callback != null) callback(true, "", house)
					})
				})
			} catch (e) { if (callback != null) callback(false, "exception", null) }
		})
	}

	function deleteById(id, callback) {
		local houseId = phoenix.house.Structure.integer(id, 0)
		if (houseId <= 0) { if (callback != null) callback(false); return }
		phoenix.house.Structure.ensureSchema(function() {
			try { ORM.engine.executeAsync("UPDATE `phoenix_houses` SET `active`=0 WHERE `id`=" + houseId, function(_) { if (houseId in phoenix.house.Structure.houses) phoenix.house.Structure.houses.rawdelete(houseId); try { phoenix.house.Structure.broadcastSnapshot() } catch (ebs) {}; if (callback != null) callback(true) }) }
			catch (e) { if (callback != null) callback(false) }
		})
	}

	function accountId(playerId) {
		try { local s = phoenix.account.Structure.get(playerId); if (s != null) return s.id() } catch (e) {}
		return 0
	}

	function ownerLabel(ownerType, ownerId) {
		if (ownerType == null || ownerId == null || ownerId <= 0) return null
		if (ownerType == phoenix.house.Structure.ownerTypePlayer) return "Konto #" + ownerId
		return "Wlasciciel #" + ownerId
	}

	function sanitizeName(value) {
		if (value == null) return ""
		local text = value.tostring()
		local out = ""
		for (local i = 0; i < text.len(); i += 1) {
			local ch = text[i]
			if (ch == '|' || ch == ';') out += " "
			else out += text.slice(i, i + 1)
		}
		return out
	}

	function serializeAccountList(list) {
		if (list == null || list.len() == 0) return ""
		local out = ""
		foreach (entry in list) {
			if (entry == null) continue
			local aid = phoenix.house.Structure.integer(("accountId" in entry) ? entry.accountId : 0, 0)
			if (aid <= 0) continue
			local name = phoenix.house.Structure.sanitizeName(("name" in entry) ? entry.name : "")
			if (out != "") out += ";"
			out += aid + "|" + name
		}
		return out
	}

	function findOnlinePidByAccount(accountId) {
		if (accountId == null || accountId <= 0) return -1
		local maxSlots = 0
		try { maxSlots = getMaxSlots() } catch (e) { return -1 }
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try { if (!isPlayerConnected(pid)) continue } catch (e0) { continue }
			if (phoenix.house.Structure.accountId(pid) == accountId) return pid
		}
		return -1
	}

	function accountUsernameSync(accountId) {
		if (accountId == null || accountId <= 0) return null
		local maxSlots = 0
		try { maxSlots = getMaxSlots() } catch (e) { maxSlots = 0 }
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try { if (!isPlayerConnected(pid)) continue } catch (e0) { continue }
			local session = null
			try { session = phoenix.account.Structure.get(pid) } catch (e1) { session = null }
			if (session == null) continue
			local aid = 0
			try { aid = session.id() } catch (e2) { aid = 0 }
			if (aid != accountId) continue
			local username = ""
			try { username = session.username() } catch (e3) { username = "" }
			local charName = phoenix.house.Structure.playerName(pid)
			local resolved = (charName != null && charName != "" && charName != "Gracz") ? charName : username
			if (resolved != null && resolved != "") {
				phoenix.house.Structure.ownerNames[accountId] <- resolved
				return resolved
			}
		}
		if (accountId in phoenix.house.Structure.ownerNames) return phoenix.house.Structure.ownerNames[accountId]
		return null
	}

	function fetchOwnerName(accountId) {
		if (accountId == null || accountId <= 0) return
		try {
			ORM.engine.executeAsync("SELECT `username` FROM `phoenix_accounts` WHERE `id`=" + accountId + " LIMIT 1", function(rows) {
				if (rows == null || rows.len() == 0) return
				local row = rows[0]
				if (!("username" in row) || row.username == null) return
				phoenix.house.Structure.ownerNames[accountId] <- row.username.tostring()
			})
		} catch (e) {}
	}

	function ownerDisplayName(house) {
		if (house == null || house.ownerType == null || house.ownerId == null || house.ownerId <= 0) return ""
		if (house.ownerType != phoenix.house.Structure.ownerTypePlayer) return "Wlasciciel #" + house.ownerId
		local cached = phoenix.house.Structure.accountUsernameSync(house.ownerId)
		if (cached != null && cached != "") return cached
		phoenix.house.Structure.fetchOwnerName(house.ownerId)
		return "Konto #" + house.ownerId
	}

	function guestEntries(house) {
		local out = []
		if (house == null || house.guests == null) return out
		foreach (value in house.guests) {
			local aid = phoenix.house.Structure.integer(value, 0)
			if (aid <= 0) continue
			local name = phoenix.house.Structure.accountUsernameSync(aid)
			if (name == null || name == "") {
				phoenix.house.Structure.fetchOwnerName(aid)
				name = "Konto #" + aid
			}
			out.append({ accountId = aid, name = name })
		}
		return out
	}

	function friendListForInvite(playerId, house) {
		local out = []
		local seen = {}
		local cid = 0
		try { local rec = phoenix.character.Structure.getActive(playerId); if (rec != null) cid = rec.id } catch (e) {}
		local ownerId = (house != null && house.ownerId != null) ? house.ownerId : 0
		local guestLookup = (house != null && house.guestLookup != null) ? house.guestLookup : null
		if (cid > 0 && !(cid in phoenix.social.Structure.friends)) {
			try { phoenix.social.Structure.loadFriends(cid, function(_) { try { phoenix.house.Structure.sendPanel(playerId) } catch (esp) {} }) } catch (eload) {}
		}
		if (cid > 0 && (cid in phoenix.social.Structure.friends)) {
			foreach (friendCharId, friendName in phoenix.social.Structure.friends[cid]) {
				local pid = phoenix.social.Structure.findOnlineByCharacter(friendCharId)
				if (pid < 0) continue
				local aid = phoenix.house.Structure.accountId(pid)
				if (aid <= 0 || aid == ownerId) continue
				if (guestLookup != null && (aid in guestLookup)) continue
				if (aid in seen) continue
				seen[aid] <- true
				local name = friendName != null && friendName != "" ? friendName.tostring() : phoenix.house.Structure.playerName(pid)
				out.append({ accountId = aid, name = name })
			}
		}
		return out
	}

	function requestEntries(house) {
		local out = []
		if (house == null) return out
		if (!(house.id in phoenix.house.Structure.pendingRequests)) return out
		local bucket = phoenix.house.Structure.pendingRequests[house.id]
		foreach (aid, entry in bucket) {
			out.append({ accountId = phoenix.house.Structure.integer(aid, 0), name = entry.name != null ? entry.name : ("Konto #" + aid) })
		}
		return out
	}

	function canEnter(playerId, house) {
		if (house == null) return true
		try { if (phoenix.account.Auth.isAdmin(playerId)) return true } catch (e) {}
		if (house.ownerType == null || house.ownerId == null || house.ownerId <= 0) return false
		if (house.rentPaidUntil > 0 && house.rentPaidUntil < phoenix.house.Structure.unixNow()) return false
		if (house.ownerType == phoenix.house.Structure.ownerTypePlayer) {
			local accountId = phoenix.house.Structure.accountId(playerId)
			if (accountId > 0 && accountId == house.ownerId) return true
			if (accountId > 0 && house.guestLookup != null && (accountId in house.guestLookup)) return true
		}
		return false
	}

	function areaHeight(house) {
		local minY = house.bounds.min.y - phoenix.house.Structure.heightMargin
		local maxY = house.bounds.max.y + phoenix.house.Structure.heightMargin
		if (maxY < minY) maxY = minY + phoenix.house.Structure.minHeight
		return { minY = minY, maxY = maxY }
	}

	function pointInPolygon(x, z, points) {
		if (points == null || points.len() < 3) return false
		local inside = false
		local last = points.len() - 1
		for (local i = 0; i < points.len(); i += 1) {
			local current = points[i]
			local previous = points[last]
			local intersects = ((current.z > z) != (previous.z > z))
			if (intersects) {
				local ratio = previous.z - current.z
				local boundaryX = current.x
				if (ratio != 0.0) boundaryX = current.x + (previous.x - current.x) * (z - current.z) / ratio
				if (x < boundaryX) inside = !inside
			}
			last = i
		}
		return inside
	}

	function isInside(house, pos, world) {
		if (house == null || pos == null) return false
		if (world != null && phoenix.house.Structure.normalizeWorld(world) != house.world) return false
		if (!phoenix.house.Structure.pointInPolygon(pos.x, pos.z, house.points)) return false
		local h = phoenix.house.Structure.areaHeight(house)
		return pos.y >= h.minY && pos.y <= h.maxY
	}

	function repel(playerId, house) {
		local p = null
		try { p = getPlayerPosition(playerId) } catch (e) {}
		if (p == null) return
		local dx = p.x - house.center.x
		local dz = p.z - house.center.z
		local len = sqrt(dx * dx + dz * dz)
		if (len <= 0.0001) { dx = 0.0; dz = 1.0; len = 1.0 }
		local origin = p
		if (house.entry != null) origin = house.entry
		if (house.entry != null) { dx = house.entry.x - house.center.x; dz = house.entry.z - house.center.z; len = sqrt(dx * dx + dz * dz); if (len <= 0.0001) { dx = 0.0; dz = 1.0; len = 1.0 } }
		local tx = origin.x + (dx / len) * phoenix.house.Structure.rejectDistance
		local tz = origin.z + (dz / len) * phoenix.house.Structure.rejectDistance
		try { setPlayerPosition(playerId, tx, p.y, tz) } catch (e2) {}
		try { phoenix.notification.notify(playerId, "error", "Dom", "Nie masz dostepu do tego domu.", 2500) } catch (e3) {}
	}

	function netEntry(house) {
		return {
			id = house.id, name = house.name, world = house.world, points = phoenix.house.Structure.encodePoints(house.points),
			entryX = house.entry != null ? house.entry.x : house.center.x, entryY = house.entry != null ? house.entry.y : house.center.y, entryZ = house.entry != null ? house.entry.z : house.center.z,
			entryHeading = house.entryHeading != null ? house.entryHeading : 0.0, priceGold = house.priceGold, weeklyRentGold = house.weeklyRentGold,
			ownerType = house.ownerType != null ? house.ownerType : 0, ownerId = house.ownerId != null ? house.ownerId : 0, rentPaidUntil = house.rentPaidUntil, color = house.color != null ? house.color : "#79C8FF"
		}
	}

	function sendSnapshot(playerId) {
		local msg = phoenix.house.Message.Snapshot()
		msg.entries = []
		foreach (_id, house in phoenix.house.Structure.houses) msg.entries.append(phoenix.house.Structure.netEntry(house))
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function broadcastSnapshot() {
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try { if (isPlayerConnected(pid)) phoenix.house.Structure.sendSnapshot(pid) } catch (e) {}
		}
	}

	function playerGold(playerId) {
		try {
			local rec = phoenix.character.Structure.getActive(playerId)
			if (rec != null) return phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, rec.id, "ITMI_GOLD")
		} catch (e) {}
		return 0
	}

	function playerName(playerId) {
		try { local rec = phoenix.character.Structure.getActive(playerId); if (rec != null && rec.name != null) return rec.name.tostring() } catch (e) {}
		try { local s = phoenix.account.Structure.get(playerId); if (s != null) return s.username() } catch (e2) {}
		return "Gracz"
	}

	function remainingExtendWeeks(house) {
		if (house == null) return phoenix.house.Structure.maxExtendWeeks
		local now = phoenix.house.Structure.unixNow()
		local paidUntil = house.rentPaidUntil > now ? house.rentPaidUntil : now
		local maxUntil = now + (phoenix.house.Structure.weekSeconds * phoenix.house.Structure.maxExtendWeeks)
		local left = maxUntil - paidUntil
		if (left <= 0) return 0
		local weeks = left / phoenix.house.Structure.weekSeconds
		if (weeks < 1) return 0
		if (weeks > phoenix.house.Structure.maxExtendWeeks) weeks = phoenix.house.Structure.maxExtendWeeks
		return weeks.tointeger()
	}

	function findOwnedHouse(playerId) {
		local accountId = phoenix.house.Structure.accountId(playerId)
		if (accountId <= 0) return null
		foreach (_id, house in phoenix.house.Structure.houses) {
			if (house.ownerType == phoenix.house.Structure.ownerTypePlayer && house.ownerId == accountId) return house
		}
		return null
	}

	function findOnlineAccount(query) {
		local text = phoenix.house.Structure.trim(query)
		if (text == "") return { accountId = 0, playerId = -1, name = "" }
		local numeric = phoenix.house.Structure.integer(text, -1)
		local lower = text.tolower()
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try { if (!isPlayerConnected(pid)) continue } catch (e0) { continue }
			local session = null
			try { session = phoenix.account.Structure.get(pid) } catch (e1) { session = null }
			if (session == null) continue
			local aid = 0
			try { aid = session.id() } catch (e2) { aid = 0 }
			local username = ""
			try { username = session.username() } catch (e3) { username = "" }
			local charName = phoenix.house.Structure.playerName(pid)
			if (numeric > 0 && aid == numeric) return { accountId = aid, playerId = pid, name = charName }
			if (username.tolower() == lower || charName.tolower() == lower) return { accountId = aid, playerId = pid, name = charName }
		}
		if (numeric > 0) return { accountId = numeric, playerId = -1, name = "Konto #" + numeric }
		return { accountId = 0, playerId = -1, name = "" }
	}

	function fillResult(result, house, mode, playerId, error = "") {
		local canEnter = phoenix.house.Structure.canEnter(playerId, house)
		local access = "none"
		if (house != null) {
			local accountId = phoenix.house.Structure.accountId(playerId)
			if (house.ownerType == null || house.ownerId == null || house.ownerId <= 0) access = "free"
			else if (house.ownerType == phoenix.house.Structure.ownerTypePlayer && accountId > 0 && accountId == house.ownerId) access = "owner"
			else if (accountId > 0 && house.guestLookup != null && (accountId in house.guestLookup)) access = "guest"
			else access = "locked"
			try { if (phoenix.account.Auth.isAdmin(playerId)) access = "admin" } catch (e) {}
		}
		result.success = (error == "" || error == "open" || error == "panel")
		result.canEnter = canEnter
		result.error = error
		result.access = access
		result.mode = mode
		result.houseId = house != null ? house.id : 0
		result.name = house != null ? house.name : ""
		result.priceGold = house != null ? house.priceGold : 0
		result.weeklyRentGold = house != null ? house.weeklyRentGold : 0
		result.rentPaidUntil = house != null ? house.rentPaidUntil : 0
		result.ownerId = (house != null && house.ownerId != null) ? house.ownerId : 0
		result.playerGold = phoenix.house.Structure.playerGold(playerId)
		result.guests = house != null ? phoenix.house.Structure.guestLabelList(house.guests) : ""
		result.guestsData = house != null ? phoenix.house.Structure.serializeAccountList(phoenix.house.Structure.guestEntries(house)) : ""
		result.ownerName = house != null ? phoenix.house.Structure.ownerDisplayName(house) : ""
		result.friends = (house != null && access == "owner") ? phoenix.house.Structure.serializeAccountList(phoenix.house.Structure.friendListForInvite(playerId, house)) : ""
		result.requests = (house != null && access == "owner") ? phoenix.house.Structure.serializeAccountList(phoenix.house.Structure.requestEntries(house)) : ""
		result.maxExtendWeeks = phoenix.house.Structure.remainingExtendWeeks(house)
	}

	function sendPanel(playerId, error = "") {
		local result = phoenix.house.Message.InteractResult()
		local house = phoenix.house.Structure.findOwnedHouse(playerId)
		phoenix.house.Structure.fillResult(result, house, "panel", playerId, house == null ? "noHouse" : error)
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function setPlayerGold(playerId, value) {
		try {
			local rec = phoenix.character.Structure.getActive(playerId)
			if (rec == null) return false
			local current = phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, rec.id, "ITMI_GOLD")
			local diff = value - current
			if (diff > 0) {
				phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, rec.id, "ITMI_GOLD", { amount = diff, quality = PhoenixItemQuality.Common, upgrade = 0, source = "house" }, function(_) {
					try { phoenix.item.Structure.sendInventorySnapshot(playerId, rec.id) } catch (e2) {}
				})
				return true
			}
			if (diff < 0) {
				phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, rec.id, "ITMI_GOLD", -diff, function(_) {
					try { phoenix.item.Structure.sendInventorySnapshot(playerId, rec.id) } catch (e3) {}
				})
				return true
			}
			return true
		} catch (e) {}
		return false
	}

	function unixNow() {
		try { return time().tointeger() } catch (e) {}
		return 0
	}

	function buyOrRent(playerId, houseId, weeks = 1) {
		local id = phoenix.house.Structure.integer(houseId, 0)
		local rentWeeks = phoenix.house.Structure.integer(weeks, 1)
		if (rentWeeks < 1) rentWeeks = 1
		if (rentWeeks > phoenix.house.Structure.maxExtendWeeks) rentWeeks = phoenix.house.Structure.maxExtendWeeks
		local result = phoenix.house.Message.InteractResult()
		result.houseId = id
		result.playerGold = phoenix.house.Structure.playerGold(playerId)
		if (!(id in phoenix.house.Structure.houses)) { result.success = false; result.error = "notFound"; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local house = phoenix.house.Structure.houses[id]
		local pos = null
		try { pos = getPlayerPosition(playerId) } catch (e) {}
		if (pos == null || house.entry == null) { result.success = false; result.error = "noEntry"; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local dx = pos.x - house.entry.x, dy = pos.y - house.entry.y, dz = pos.z - house.entry.z
		if (sqrt(dx * dx + dy * dy + dz * dz) > 420.0) { result.success = false; result.error = "tooFar"; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local accountId = phoenix.house.Structure.accountId(playerId)
		if (accountId <= 0) { result.success = false; result.error = "account"; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local isOwner = house.ownerType == phoenix.house.Structure.ownerTypePlayer && house.ownerId == accountId
		if (house.ownerId != null && house.ownerId > 0 && !isOwner) { result.success = false; result.error = "owned"; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (isOwner) {
			local allowedWeeks = phoenix.house.Structure.remainingExtendWeeks(house)
			if (allowedWeeks <= 0) { result.success = false; result.error = "maxRent"; result.playerGold = phoenix.house.Structure.playerGold(playerId); result.serialize().send(playerId, RELIABLE_ORDERED); return }
			if (rentWeeks > allowedWeeks) rentWeeks = allowedWeeks
		}
		local rent = house.weeklyRentGold != null ? house.weeklyRentGold : 0
		local cost = isOwner ? (rent * rentWeeks) : (house.priceGold + rent)
		if (cost <= 0 && !isOwner) cost = house.priceGold
		local gold = phoenix.house.Structure.playerGold(playerId)
		if (gold < cost) { result.success = false; result.error = "noGold"; result.playerGold = gold; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (cost > 0) phoenix.house.Structure.setPlayerGold(playerId, gold - cost)
		local now = phoenix.house.Structure.unixNow()
		local baseUntil = house.rentPaidUntil > now ? house.rentPaidUntil : now
		local until = rent > 0 ? baseUntil + (phoenix.house.Structure.weekSeconds * rentWeeks) : 0
		local sql = "UPDATE `phoenix_houses` SET `ownerType`=" + phoenix.house.Structure.ownerTypePlayer + ",`ownerId`=" + accountId + ",`rentPaidUntil`=" + until + " WHERE `id`=" + id
		house.ownerType = phoenix.house.Structure.ownerTypePlayer
		house.ownerId = accountId
		house.ownerLabel = phoenix.house.Structure.ownerLabel(house.ownerType, house.ownerId)
		house.rentPaidUntil = until
		try { ORM.engine.executeAsync(sql, function(_) { phoenix.house.Structure.loadDb(function() { phoenix.house.Structure.broadcastSnapshot() }) }) } catch (e) {}
		phoenix.house.Structure.fillResult(result, house, isOwner ? "panel" : "entry", playerId, isOwner ? "rentExtended" : "bought")
		result.success = true
		result.playerGold = gold - cost
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (er) {}
	}

	function extendRent(playerId, houseId, weeks) {
		local house = phoenix.house.Structure.findOwnedHouse(playerId)
		if (house == null || house.id != phoenix.house.Structure.integer(houseId, 0)) { phoenix.house.Structure.sendPanel(playerId, "noHouse"); return }
		phoenix.house.Structure.buyOrRent(playerId, house.id, weeks)
	}

	function isFriendAccount(playerId, house, targetAccountId) {
		local friends = phoenix.house.Structure.friendListForInvite(playerId, house)
		foreach (entry in friends) { if (entry.accountId == targetAccountId) return true }
		return false
	}

	function persistGuests(house, callback = null) {
		local guests = phoenix.house.Structure.encodeGuests(house.guests)
		local guestsSql = guests != null ? ("'" + phoenix.house.Structure.esc(guests) + "'") : "NULL"
		try { ORM.engine.executeAsync("UPDATE `phoenix_houses` SET `guestAccountIds`=" + guestsSql + " WHERE `id`=" + house.id, function(_) { phoenix.house.Structure.broadcastSnapshot(); if (callback != null) callback() }) } catch (e) {}
	}

	function dropPendingRequest(houseId, accountId) {
		if (!(houseId in phoenix.house.Structure.pendingRequests)) return
		local bucket = phoenix.house.Structure.pendingRequests[houseId]
		if (accountId in bucket) bucket.rawdelete(accountId)
		if (bucket.len() == 0) phoenix.house.Structure.pendingRequests.rawdelete(houseId)
	}

	function inviteGuest(playerId, houseId, target) {
		local house = phoenix.house.Structure.findOwnedHouse(playerId)
		local result = phoenix.house.Message.InteractResult()
		if (house == null || house.id != phoenix.house.Structure.integer(houseId, 0)) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "noHouse"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local targetAccount = phoenix.house.Structure.integer(target, 0)
		local found = null
		if (targetAccount > 0) {
			local pid = phoenix.house.Structure.findOnlinePidByAccount(targetAccount)
			if (pid >= 0) found = { accountId = targetAccount, playerId = pid, name = phoenix.house.Structure.playerName(pid) }
			else found = { accountId = targetAccount, playerId = -1, name = "Konto #" + targetAccount }
		} else {
			found = phoenix.house.Structure.findOnlineAccount(target)
		}
		if (found.accountId <= 0) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "targetNotFound"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (found.accountId == house.ownerId) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "targetOwner"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (house.guestLookup != null && (found.accountId in house.guestLookup)) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "alreadyGuest"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (!phoenix.house.Structure.isFriendAccount(playerId, house, found.accountId)) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "notFriend"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		house.guests.append(found.accountId)
		house.guestLookup[found.accountId] <- true
		phoenix.house.Structure.dropPendingRequest(house.id, found.accountId)
		phoenix.house.Structure.persistGuests(house)
		if (found.playerId >= 0) { try { phoenix.notification.notify(found.playerId, "info", "Dom", "Otrzymales zaproszenie do domu: " + house.name, 4500) } catch (en) {} }
		phoenix.house.Structure.fillResult(result, house, "panel", playerId, "guestAdded")
		result.success = true
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (er) {}
	}

	function acceptRequest(playerId, houseId, target) {
		local house = phoenix.house.Structure.findOwnedHouse(playerId)
		local result = phoenix.house.Message.InteractResult()
		if (house == null || house.id != phoenix.house.Structure.integer(houseId, 0)) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "noHouse"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local targetAccount = phoenix.house.Structure.integer(target, 0)
		if (targetAccount <= 0 || !(house.id in phoenix.house.Structure.pendingRequests) || !(targetAccount in phoenix.house.Structure.pendingRequests[house.id])) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "noRequest"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (house.guestLookup == null || !(targetAccount in house.guestLookup)) {
			house.guests.append(targetAccount)
			house.guestLookup[targetAccount] <- true
			phoenix.house.Structure.persistGuests(house)
		}
		local guestPid = phoenix.house.Structure.findOnlinePidByAccount(targetAccount)
		phoenix.house.Structure.dropPendingRequest(house.id, targetAccount)
		if (guestPid >= 0) { try { phoenix.notification.notify(guestPid, "success", "Dom", "Wlasciciel wpuscil Cie do: " + house.name, 4500) } catch (en) {} }
		phoenix.house.Structure.fillResult(result, house, "panel", playerId, "requestAccepted")
		result.success = true
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (er) {}
	}

	function denyRequest(playerId, houseId, target) {
		local house = phoenix.house.Structure.findOwnedHouse(playerId)
		local result = phoenix.house.Message.InteractResult()
		if (house == null || house.id != phoenix.house.Structure.integer(houseId, 0)) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "noHouse"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local targetAccount = phoenix.house.Structure.integer(target, 0)
		if (targetAccount <= 0) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "noRequest"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local guestPid = phoenix.house.Structure.findOnlinePidByAccount(targetAccount)
		phoenix.house.Structure.dropPendingRequest(house.id, targetAccount)
		if (guestPid >= 0) { try { phoenix.notification.notify(guestPid, "warning", "Dom", "Wlasciciel odrzucil prosbe o wpuszczenie do: " + house.name, 4500) } catch (en) {} }
		phoenix.house.Structure.fillResult(result, house, "panel", playerId, "requestDenied")
		result.success = true
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (er) {}
	}

	function kickGuest(playerId, houseId, target) {
		local house = phoenix.house.Structure.findOwnedHouse(playerId)
		local result = phoenix.house.Message.InteractResult()
		if (house == null || house.id != phoenix.house.Structure.integer(houseId, 0)) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "noHouse"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local targetAccount = phoenix.house.Structure.integer(target, 0)
		if (targetAccount <= 0 || house.guestLookup == null || !(targetAccount in house.guestLookup)) { phoenix.house.Structure.fillResult(result, house, "panel", playerId, "notGuest"); result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local filtered = []
		foreach (value in house.guests) {
			local aid = phoenix.house.Structure.integer(value, 0)
			if (aid > 0 && aid != targetAccount) filtered.append(aid)
		}
		house.guests = filtered
		house.guestLookup.rawdelete(targetAccount)
		phoenix.house.Structure.persistGuests(house)
		local guestPid = phoenix.house.Structure.findOnlinePidByAccount(targetAccount)
		if (guestPid >= 0) {
			try { phoenix.notification.notify(guestPid, "warning", "Dom", "Wlasciciel usunal Cie z listy gosci: " + house.name, 4500) } catch (en) {}
			try { phoenix.house.Structure.repel(guestPid, house) } catch (er) {}
		}
		phoenix.house.Structure.fillResult(result, house, "panel", playerId, "guestRemoved")
		result.success = true
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (er) {}
	}

	function leaveHouse(playerId, houseId) {
		local id = phoenix.house.Structure.integer(houseId, 0)
		local result = phoenix.house.Message.InteractResult()
		result.houseId = id

		local accountId = phoenix.house.Structure.accountId(playerId)
		if (accountId <= 0) {
			result.success = false
			result.error = "account"
			try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
			return
		}

		local house = (id in phoenix.house.Structure.houses) ? phoenix.house.Structure.houses[id] : null
		if (house == null || house.id != id) {
			phoenix.house.Structure.sendPanel(playerId, "noHouse")
			return
		}
		if (house.ownerType != phoenix.house.Structure.ownerTypePlayer || house.ownerId != accountId) {
			phoenix.house.Structure.sendPanel(playerId, "owned")
			return
		}

		phoenix.house.Structure.ensureSchema(function() {
			try {
				local sql = "UPDATE `phoenix_houses` SET `ownerType`=NULL,`ownerId`=NULL,`rentPaidUntil`=0,`guestAccountIds`=NULL WHERE `id`=" + id
				ORM.engine.executeAsync(sql, function(_) {
					// update snapshot cache
					if (house != null) {
						house.ownerType = null
						house.ownerId = null
						house.ownerLabel = null
						house.rentPaidUntil = 0
						house.guests = []
						house.guestLookup = {}
						phoenix.house.Structure.houses[id] <- house
					}
					phoenix.house.Structure.broadcastSnapshot()
					// notify & return UI panel state
					try { phoenix.house.Structure.sendPanel(playerId, "houseLeft") } catch (e2) {}
					try { result.success = true; result.error = "houseLeft"; result.serialize().send(playerId, RELIABLE_ORDERED) } catch (e3) {}
				})
			} catch (e) {
				try { phoenix.house.Structure.sendPanel(playerId, "houseLeft") } catch (e2) {}
			}
		})
	}

	function requestAccess(playerId, houseId) {
		local id = phoenix.house.Structure.integer(houseId, 0)
		local result = phoenix.house.Message.InteractResult()
		if (!(id in phoenix.house.Structure.houses)) { result.success = false; result.error = "notFound"; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local house = phoenix.house.Structure.houses[id]
		local accountId = phoenix.house.Structure.accountId(playerId)
		if (house.ownerType == null || house.ownerId == null || house.ownerId <= 0) { phoenix.house.Structure.fillResult(result, house, "entry", playerId, "freeHouse"); result.success = false; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (house.ownerType == phoenix.house.Structure.ownerTypePlayer && accountId > 0 && accountId == house.ownerId) { phoenix.house.Structure.fillResult(result, house, "entry", playerId, "ownerAccess"); result.success = true; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (accountId > 0 && house.guestLookup != null && (accountId in house.guestLookup)) { phoenix.house.Structure.fillResult(result, house, "entry", playerId, "guestAccess"); result.success = true; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		if (accountId <= 0) { phoenix.house.Structure.fillResult(result, house, "entry", playerId, "account"); result.success = false; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local requesterName = phoenix.house.Structure.playerName(playerId)
		if (!(id in phoenix.house.Structure.pendingRequests)) phoenix.house.Structure.pendingRequests[id] <- {}
		phoenix.house.Structure.pendingRequests[id][accountId] <- { playerId = playerId, name = requesterName, at = phoenix.house.Structure.unixNow() }
		local ownerPid = phoenix.house.Structure.findOnlinePidByAccount(house.ownerId)
		if (ownerPid >= 0) {
			try { phoenix.notification.notify(ownerPid, "info", "Dom", requesterName + " prosi o wpuszczenie do: " + house.name, 6000) } catch (en) {}
			try { phoenix.house.Structure.sendPanel(ownerPid) } catch (ep) {}
			result.success = true; result.error = "requestSent"
		} else {
			phoenix.house.Structure.dropPendingRequest(id, accountId)
			result.success = false; result.error = "ownerOffline"
		}
		result.mode = "entry"; result.houseId = id; result.playerGold = phoenix.house.Structure.playerGold(playerId); result.access = "locked"; result.canEnter = false
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (er) {}
	}

	function openEntry(playerId, houseId) {
		local id = phoenix.house.Structure.integer(houseId, 0)
		local result = phoenix.house.Message.InteractResult()
		if (!(id in phoenix.house.Structure.houses)) { result.success = false; result.error = "notFound"; result.serialize().send(playerId, RELIABLE_ORDERED); return }
		local house = phoenix.house.Structure.houses[id]
		phoenix.house.Structure.fillResult(result, house, "entry", playerId, "open")
		try { result.serialize().send(playerId, RELIABLE_ORDERED) } catch (er) {}
	}

	function handleAction(playerId, message) {
		if (message == null) return
		local action = message.action != null ? message.action.tostring() : ""
		if (action == "open") { phoenix.house.Structure.openEntry(playerId, message.houseId); return }
		if (action == "request") { phoenix.house.Structure.requestAccess(playerId, message.houseId); return }
		if (action == "extend") { phoenix.house.Structure.extendRent(playerId, message.houseId, message.weeks); return }
		if (action == "invite") { phoenix.house.Structure.inviteGuest(playerId, message.houseId, message.target); return }
		if (action == "accept") { phoenix.house.Structure.acceptRequest(playerId, message.houseId, message.target); return }
		if (action == "deny") { phoenix.house.Structure.denyRequest(playerId, message.houseId, message.target); return }
		if (action == "kick") { phoenix.house.Structure.kickGuest(playerId, message.houseId, message.target); return }
		if (action == "leave") { phoenix.house.Structure.leaveHouse(playerId, message.houseId); return }
		phoenix.house.Structure.buyOrRent(playerId, message.houseId, message.weeks)
	}

	function guardTick() {
		if (phoenix.house.Structure.guardBusy) return
		phoenix.house.Structure.guardBusy = true
		try {
			local maxSlots = getMaxSlots()
			for (local pid = 0; pid < maxSlots; pid += 1) {
				try { if (!isPlayerConnected(pid)) continue } catch (e0) { continue }
				local rec = null
				try { rec = phoenix.character.Structure.getActive(pid) } catch (e1) { rec = null }
				if (rec == null) continue
				local pos = null
				try { pos = getPlayerPosition(pid) } catch (e2) {}
				if (pos == null) continue
				local world = null
				try { world = getPlayerWorld(pid) } catch (e3) {}
				foreach (_id, house in phoenix.house.Structure.houses) {
					if (phoenix.house.Structure.canEnter(pid, house)) continue
					if (phoenix.house.Structure.isInside(house, pos, world)) { phoenix.house.Structure.repel(pid, house); break }
				}
			}
		} catch (e) {}
		phoenix.house.Structure.guardBusy = false
	}
}
