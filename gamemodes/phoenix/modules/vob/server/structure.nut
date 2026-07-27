phoenix.vob.Structure <- {
	entries = {}
	loaded = false
	loading = false
	bootScheduled = false
	range = 360.0
	droppedItems = {}
	pickupLocks = {}

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

	function esc(value) {
		try { return ORM.engine.escape(value.tostring()) } catch (e) {}
		return value == null ? "" : value.tostring()
	}

	function boolInt(value) {
		if (value == true) return 1
		try { return value.tointeger() != 0 ? 1 : 0 } catch (e) {}
		return 0
	}

	function visualAllowed(visual) {
		if (visual == null || visual == "") return false
		local up = visual.tostring().toupper()
		if (up.find(".3DS") != null) return true
		if (up.find(".MRM") != null) return true
		if (up.find(".MMB") != null) return true
		if (up.find(".MDL") != null) return true
		if (up.find(".MDS") != null) return true
		if (up.find(".ASC") != null) return true
		return false
	}

	function normalizeVisual(visual) {
		if (visual == null) return ""
		return strip(visual.tostring()).toupper()
	}

	function previewVisual(visual) {
		local up = phoenix.vob.Structure.normalizeVisual(visual)
		local ext = up.find(".3DS")
		if (ext != null) return up.slice(0, ext) + ".MRM"
		return up
	}

	function tagValue(line, tag) {
		local open = "<" + tag + ">"
		local close = "</" + tag + ">"
		local start = line.find(open)
		local stop = line.find(close)
		if (start == null || stop == null || stop < start) return ""
		return strip(line.slice(start + open.len(), stop))
	}

	function catalogAppend(out, seen, instance, visual, name = "", preview = "", source = "", category = "") {
		if (instance == null || instance == "") return
		local normalized = phoenix.vob.Structure.normalizeVisual(visual)
		if (!phoenix.vob.Structure.visualAllowed(normalized)) return
		local key = instance.tostring().toupper()
		if (key in seen) return
		seen[key] <- true
		local label = name != null && name != "" ? name : key
		if (label == key) {
			try {
				local scheme = phoenix.item.find(key)
				if (scheme != null && scheme.name != null && scheme.name != "") label = scheme.name
			} catch (e) {}
		}
		local pv = preview != null && preview != "" ? phoenix.vob.Structure.normalizeVisual(preview) : phoenix.vob.Structure.previewVisual(normalized)
		out.append({ instance = key, name = label, visual = normalized, previewVisual = pv, source = source, category = category })
	}

	function generatedCatalog() {
		local out = []
		local seen = {}
		try {
			foreach (entry in phoenix.vob.Catalog) {
				local instance = ("instance" in entry) ? entry.instance : ""
				local visual = ("visual" in entry) ? entry.visual : ""
				local name = ("name" in entry) ? entry.name : instance
				local preview = ("previewVisual" in entry) ? entry.previewVisual : ""
				local source = ("source" in entry) ? entry.source : "generated"
				local category = ("category" in entry) ? entry.category : ""
				phoenix.vob.Structure.catalogAppend(out, seen, instance, visual, name, preview, source, category)
			}
		} catch (e) {}
		return out
	}

	function dataXmlCatalog() {
		local out = []
		local seen = {}
		local f = null
		try { f = file("data.xml", "r") } catch (e) { f = null }
		if (f == null) return out
		local inItems = false
		local inItem = false
		local instance = ""
		local visual = ""
		local name = ""
		local line = null
		while (line = f.read()) {
			local s = strip(line.tostring())
			if (!inItems) {
				if (s == "<items>") inItems = true
				continue
			}
			if (s == "</items>") break
			if (s == "<item>") {
				inItem = true
				instance = ""
				visual = ""
				name = ""
				continue
			}
			if (s == "</item>") {
				if (inItem) phoenix.vob.Structure.catalogAppend(out, seen, instance, visual, name, "", "data.xml")
				inItem = false
				continue
			}
			if (!inItem) continue
			local value = phoenix.vob.Structure.tagValue(s, "instance")
			if (value != "") { instance = value; continue }
			value = phoenix.vob.Structure.tagValue(s, "visual")
			if (value != "") { visual = value; continue }
			value = phoenix.vob.Structure.tagValue(s, "name")
			if (value != "") name = value
		}
		try { f.close() } catch (e2) {}
		return out
	}

	function schemeCatalog() {
		local out = []
		local seen = {}
		try {
			foreach (instance, scheme in phoenix.item.Schemes.byInstance) {
				local visual = ""
				local name = instance
				try { if ("visual" in scheme && scheme.visual != null && scheme.visual != "") visual = scheme.visual } catch (e) {}
				if (visual == "") { try { visual = phoenix.item.lookupVisual(instance) } catch (e2) {} }
				try { if ("name" in scheme && scheme.name != null && scheme.name != "") name = scheme.name } catch (e3) {}
				phoenix.vob.Structure.catalogAppend(out, seen, instance, visual, name, "", "schemes")
			}
		} catch (e4) {}
		return out
	}

	function catalogVisual(instance) {
		if (instance == null || instance == "") return ""
		local key = instance.tostring().toupper()
		foreach (entry in phoenix.vob.Structure.makeCatalog()) {
			try { if (entry.instance == key) return entry.visual } catch (e) {}
		}
		return ""
	}

	function makeCatalog() {
		local out = phoenix.vob.Structure.generatedCatalog()
		if (out.len() > 0) return out
		out = phoenix.vob.Structure.schemeCatalog()
		if (out.len() > 0) return out
		try { out = phoenix.vob.Structure.dataXmlCatalog() } catch (e) { out = [] }
		if (out.len() > 0) return out
		local seen = {}
		try {
			foreach (instance, visual in phoenix.item.visuals) {
				phoenix.vob.Structure.catalogAppend(out, seen, instance, visual, "", "", "visuals")
			}
		} catch (e) {}
		return out
	}

	function filteredCatalog(payload) {
		local filter = ""
		local source = "data.xml"
		local category = ""
		local limit = 120
		local offset = 0
		try { if (payload != null && "filter" in payload && payload.filter != null) filter = payload.filter.tostring().tolower() } catch (e) {}
		try { if (payload != null && "source" in payload && payload.source != null) source = payload.source.tostring().tolower() } catch (e1) {}
		try { if (payload != null && "category" in payload && payload.category != null) category = payload.category.tostring() } catch (e8) {}
		try { if (payload != null && "limit" in payload) limit = payload.limit.tointeger() } catch (e2) {}
		try { if (payload != null && "offset" in payload) offset = payload.offset.tointeger() } catch (e12) {}
		if (limit < 40) limit = 40
		if (limit > 160) limit = 160
		if (offset < 0) offset = 0
		local out = []
		local categories = []
		local seenCategories = {}
		local categoryCounts = {}
		local categoryStats = []
		local sourceTotal = 0
		local matched = 0
		local all = phoenix.vob.Structure.makeCatalog()
		foreach (entry in all) {
			if (source != "") {
				local entrySource = ""
				try { entrySource = entry.source.tostring().tolower() } catch (e6) {}
				if (entrySource != source) continue
			}
			sourceTotal += 1
			local entryCategory = ""
			try { entryCategory = entry.category.tostring() } catch (e9) {}
			if (entryCategory != "" && !(entryCategory in seenCategories)) {
				seenCategories[entryCategory] <- true
				categories.append(entryCategory)
			}
			if (entryCategory != "") {
				if (!(entryCategory in categoryCounts)) categoryCounts[entryCategory] <- 0
				categoryCounts[entryCategory] += 1
			}
		}
		categories.sort()
		foreach (entryCategory in categories) categoryStats.append({ name = entryCategory, count = categoryCounts[entryCategory] })
		foreach (entry in all) {
			if (source != "") {
				local entrySource2 = ""
				try { entrySource2 = entry.source.tostring().tolower() } catch (e10) {}
				if (entrySource2 != source) continue
			}
			if (category != "") {
				local entryCategory2 = ""
				try { entryCategory2 = entry.category.tostring() } catch (e11) {}
				if (entryCategory2 != category) continue
			}
			if (filter != "") {
				local text = ""
				try { text += entry.instance.tostring().tolower() + " " } catch (e3) {}
				try { text += entry.name.tostring().tolower() + " " } catch (e4) {}
				try { text += entry.visual.tostring().tolower() + " " } catch (e5) {}
				try { text += entry.category.tostring().tolower() + " " } catch (e7) {}
				if (text.find(filter) == null) continue
			}
			matched += 1
			if (matched <= offset) continue
			if (out.len() < limit) out.append(entry)
		}
		return { entries = out, total = all.len(), sourceTotal = sourceTotal, matched = matched, returned = out.len(), offset = offset, limit = limit, filter = filter, source = source, category = category, categories = categories, categoryStats = categoryStats }
	}

	function entryOf(row) {
		return {
			vobId = ("vobId" in row) ? row.vobId.tostring() : "",
			name = ("name" in row && row.name != null) ? row.name.tostring() : "",
			visual = ("visual" in row && row.visual != null) ? row.visual.tostring() : "",
			world = ("world" in row && row.world != null) ? phoenix.vob.Structure.normalizeWorld(row.world) : "NEWWORLD",
			x = ("posX" in row) ? row.posX.tofloat() : 0.0,
			y = ("posY" in row) ? row.posY.tofloat() : 0.0,
			z = ("posZ" in row) ? row.posZ.tofloat() : 0.0,
			rotX = ("rotX" in row) ? row.rotX.tofloat() : 0.0,
			rotY = ("rotY" in row) ? row.rotY.tofloat() : 0.0,
			rotZ = ("rotZ" in row) ? row.rotZ.tofloat() : 0.0,
			interactive = ("interactive" in row) ? phoenix.vob.Structure.boolInt(row.interactive) == 1 : false,
			noCollision = ("noCollision" in row) ? phoenix.vob.Structure.boolInt(row.noCollision) == 1 : false,
			craftInteraction = ("craftInteraction" in row) ? phoenix.vob.Structure.boolInt(row.craftInteraction) == 1 : false,
			entryKind = "vob",
			itemInstance = "",
			itemAmount = 0,
			itemQuality = 0
		}
	}

	function dist(a, b) {
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function snapshotList() {
		local out = []
		foreach (_id, entry in phoenix.vob.Structure.entries) {
			local copy = {
				vobId = entry.vobId, name = entry.name, visual = entry.visual, world = entry.world,
				x = entry.x, y = entry.y, z = entry.z, rotX = entry.rotX, rotY = entry.rotY, rotZ = entry.rotZ,
				interactive = entry.interactive, entryKind = entry.entryKind,
				noCollision = ("noCollision" in entry) ? entry.noCollision : false,
				craftInteraction = ("craftInteraction" in entry) ? entry.craftInteraction : false,
				itemInstance = entry.itemInstance, itemAmount = entry.itemAmount, itemQuality = entry.itemQuality
			}
			if (copy.craftInteraction) copy.interactive = true
			if (copy.visual != null && copy.visual != "") {
				try {
					if ("crafting" in phoenix && "Structure" in phoenix.crafting && phoenix.crafting.Structure.isStationVisual(copy.visual))
						copy.interactive = true
				} catch (eCraft) {}
			}
			out.append(copy)
		}
		return out
	}

	function sendSnapshot(playerId) {
		local msg = phoenix.vob.Message.Snapshot()
		msg.entries = phoenix.vob.Structure.snapshotList()
		try { msg.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function broadcastSnapshot() {
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try { if (isPlayerConnected(pid)) phoenix.vob.Structure.sendSnapshot(pid) } catch (e) {}
		}
	}

	function ensureSchema(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_world_vobs` (`id` INT(11) NOT NULL AUTO_INCREMENT, `vobId` VARCHAR(96) NOT NULL, `name` VARCHAR(128) DEFAULT '', `visual` VARCHAR(128) NOT NULL, `world` VARCHAR(96) NOT NULL DEFAULT 'NEWWORLD', `posX` FLOAT NOT NULL DEFAULT 0, `posY` FLOAT NOT NULL DEFAULT 0, `posZ` FLOAT NOT NULL DEFAULT 0, `rotX` FLOAT NOT NULL DEFAULT 0, `rotY` FLOAT NOT NULL DEFAULT 0, `rotZ` FLOAT NOT NULL DEFAULT 0, `interactive` TINYINT(1) NOT NULL DEFAULT 0, `noCollision` TINYINT(1) NOT NULL DEFAULT 0, `craftInteraction` TINYINT(1) NOT NULL DEFAULT 0, `active` TINYINT(1) NOT NULL DEFAULT 1, `createdBy` INT(11) NULL, `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, PRIMARY KEY (`id`), UNIQUE KEY `vob_unique` (`vobId`), KEY `world_idx` (`world`), KEY `visual_idx` (`visual`)) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci"
		try {
			ORM.engine.executeAsync(sql, function(_) {
				ORM.engine.executeAsync("SHOW COLUMNS FROM `phoenix_world_vobs` LIKE 'noCollision'", function(rows) {
					local hasNoCol = rows != null && rows.len() > 0
					local addCraft = function () {
						ORM.engine.executeAsync("SHOW COLUMNS FROM `phoenix_world_vobs` LIKE 'craftInteraction'", function(rows2) {
							local hasCraft = rows2 != null && rows2.len() > 0
							if (hasCraft) { if (callback != null) callback(); return }
							try { ORM.engine.executeAsync("ALTER TABLE `phoenix_world_vobs` ADD COLUMN `craftInteraction` TINYINT(1) NOT NULL DEFAULT 0 AFTER `noCollision`", function(_3) { if (callback != null) callback() }) }
							catch (eC) { if (callback != null) callback() }
						})
					}
					if (hasNoCol) { addCraft(); return }
					try { ORM.engine.executeAsync("ALTER TABLE `phoenix_world_vobs` ADD COLUMN `noCollision` TINYINT(1) NOT NULL DEFAULT 0 AFTER `interactive`", function(_2) { addCraft() }) }
					catch (e) { addCraft() }
				})
			})
		} catch (e) { if (callback != null) callback() }
	}

	function bootLoad() {
		if (phoenix.vob.Structure.loaded || phoenix.vob.Structure.loading) return
		if (phoenix.vob.Structure.bootScheduled) return
		phoenix.vob.Structure.bootScheduled = true
		setTimer(phoenix.vob.Structure.bootLoadTick, 1000, 1)
	}

	function bootLoadTick() {
		phoenix.vob.Structure.bootScheduled = false
		local ready = false
		try { ready = phoenix.database.ready } catch (e) {}
		if (!ready) { phoenix.vob.Structure.bootLoad(); return }
		phoenix.vob.Structure.loading = true
		phoenix.vob.Structure.ensureSchema(function() { phoenix.vob.Structure.loadDb(function() { phoenix.vob.Structure.loading = false; phoenix.vob.Structure.broadcastSnapshot() }) })
	}

	function loadDb(callback) {
		if (phoenix.vob.Structure.loaded) { if (callback != null) callback(); return }
		local runtimeEntries = []
		foreach (_id, existing in phoenix.vob.Structure.entries) {
			try { if (existing.entryKind == "item" || existing.entryKind == "carcass") runtimeEntries.append(existing) } catch (e0) {}
		}
		try {
			ORM.engine.executeAsync("SELECT * FROM `phoenix_world_vobs` WHERE `active` = 1 ORDER BY `id` ASC", function(rows) {
				phoenix.vob.Structure.loaded = true
				phoenix.vob.Structure.entries.clear()
				if (rows != null) {
					foreach (row in rows) {
						local entry = phoenix.vob.Structure.entryOf(row)
						if (entry.vobId == "" || entry.visual == "") continue
						phoenix.vob.Structure.entries[entry.vobId] <- entry
					}
				}
				foreach (runtimeEntry in runtimeEntries) phoenix.vob.Structure.entries[runtimeEntry.vobId] <- runtimeEntry
				if (callback != null) callback()
			})
		} catch (e) { if (callback != null) callback() }
	}

	function listAll(callback) {
		phoenix.vob.Structure.ensureSchema(function() {
			phoenix.vob.Structure.loaded = false
			phoenix.vob.Structure.loadDb(function() { if (callback != null) callback(phoenix.vob.Structure.snapshotList()) })
		})
	}

	function saveFromAdmin(playerId, payload, callback) {
		if (payload == null) { if (callback != null) callback(false, "badPayload", null); return }
		local visual = ("visual" in payload && payload.visual != null) ? phoenix.vob.Structure.normalizeVisual(payload.visual) : ""
		if (visual == "" && "instance" in payload && payload.instance != null) {
			try { visual = phoenix.vob.Structure.catalogVisual(payload.instance) } catch (e0) {}
			if (visual == "") { try { local v = phoenix.item.lookupVisual(payload.instance.tostring().toupper()); if (v != null) visual = phoenix.vob.Structure.normalizeVisual(v) } catch (e) {} }
		}
		if (!phoenix.vob.Structure.visualAllowed(visual)) { if (callback != null) callback(false, "badVisual", null); return }
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
		if ("world" in payload && payload.world != null && payload.world != "") world = payload.world.tostring()
		world = phoenix.vob.Structure.normalizeWorld(world)
		local rotX = ("rotX" in payload) ? payload.rotX.tofloat() : 0.0
		local rotY = ("rotY" in payload) ? payload.rotY.tofloat() : 0.0
		local rotZ = ("rotZ" in payload) ? payload.rotZ.tofloat() : 0.0
		local name = ("name" in payload && payload.name != null) ? payload.name.tostring() : ""
		local vobId = ("vobId" in payload && payload.vobId != null && payload.vobId != "") ? payload.vobId.tostring() : ("vob_" + getTickCount())
		local interactive = ("interactive" in payload) ? phoenix.vob.Structure.boolInt(payload.interactive) : 0
		local noCollision = ("noCollision" in payload) ? phoenix.vob.Structure.boolInt(payload.noCollision) : 0
		local craftInteraction = ("craftInteraction" in payload) ? phoenix.vob.Structure.boolInt(payload.craftInteraction) : 0
		if (craftInteraction == 1) interactive = 1
		local entry = { vobId = vobId, name = name, visual = visual, world = world, x = x, y = y, z = z, rotX = rotX, rotY = rotY, rotZ = rotZ, interactive = interactive == 1, noCollision = noCollision == 1, craftInteraction = craftInteraction == 1, entryKind = "vob", itemInstance = "", itemAmount = 0, itemQuality = 0 }
		local adminId = "NULL"
		try { local s = phoenix.account.Structure.get(playerId); if (s != null && s.id() > 0) adminId = s.id().tostring() } catch (e) {}
		local sql = "INSERT INTO `phoenix_world_vobs` (`vobId`,`name`,`visual`,`world`,`posX`,`posY`,`posZ`,`rotX`,`rotY`,`rotZ`,`interactive`,`noCollision`,`craftInteraction`,`active`,`createdBy`) VALUES ('" + phoenix.vob.Structure.esc(vobId) + "','" + phoenix.vob.Structure.esc(name) + "','" + phoenix.vob.Structure.esc(visual) + "','" + phoenix.vob.Structure.esc(world) + "'," + x + "," + y + "," + z + "," + rotX + "," + rotY + "," + rotZ + "," + interactive + "," + noCollision + "," + craftInteraction + ",1," + adminId + ") ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`visual`=VALUES(`visual`),`world`=VALUES(`world`),`posX`=VALUES(`posX`),`posY`=VALUES(`posY`),`posZ`=VALUES(`posZ`),`rotX`=VALUES(`rotX`),`rotY`=VALUES(`rotY`),`rotZ`=VALUES(`rotZ`),`interactive`=VALUES(`interactive`),`noCollision`=VALUES(`noCollision`),`craftInteraction`=VALUES(`craftInteraction`),`active`=1"
		phoenix.vob.Structure.ensureSchema(function() {
			try {
				ORM.engine.executeAsync(sql, function(_) {
					phoenix.vob.Structure.entries[vobId] <- entry
					phoenix.vob.Structure.broadcastSnapshot()
					if (callback != null) callback(true, "", entry)
				})
			} catch (e) { if (callback != null) callback(false, "exception", null) }
		})
	}

	function deleteById(vobId, callback) {
		if (vobId == null || vobId == "") { if (callback != null) callback(false); return }
		local safe = phoenix.vob.Structure.esc(vobId)
		phoenix.vob.Structure.ensureSchema(function() {
			try {
				ORM.engine.executeAsync("UPDATE `phoenix_world_vobs` SET `active` = 0 WHERE `vobId` = '" + safe + "'", function(_) {
					if (vobId in phoenix.vob.Structure.entries) phoenix.vob.Structure.entries.rawdelete(vobId)
					phoenix.vob.Structure.broadcastSnapshot()
					if (callback != null) callback(true)
				})
			} catch (e) { if (callback != null) callback(false) }
		})
	}

	function itemLabel(scheme, amount, upgrade) {
		local label = "Przedmiot"
		try { if (scheme != null && scheme.name != null && scheme.name != "") label = scheme.name } catch (e) {}
		if (upgrade > 0) label += " +" + upgrade
		if (amount > 1) label += " x" + amount
		return label
	}

	function itemVisual(instanceId, scheme) {
		local visual = ""
		try { if (scheme != null && "visual" in scheme && scheme.visual != null && scheme.visual != "") visual = scheme.visual } catch (e) {}
		if (visual == "") { try { visual = phoenix.item.lookupVisual(instanceId) } catch (e2) {} }
		if (visual == null) visual = ""
		visual = phoenix.vob.Structure.normalizeVisual(visual)
		if (!phoenix.vob.Structure.visualAllowed(visual)) visual = phoenix.vob.Structure.catalogVisual(instanceId)
		return phoenix.vob.Structure.normalizeVisual(visual)
	}

	function dropPosition(playerId) {
		local pos = null
		try { pos = getPlayerPosition(playerId) } catch (e) { pos = null }
		if (pos == null) pos = { x = 0.0, y = 0.0, z = 0.0 }
		local angle = 0.0
		try { angle = getPlayerAngle(playerId).tofloat() } catch (e2) {}
		local rad = angle * 3.14159 / 180.0
		return { x = pos.x + sin(rad) * 110.0, y = pos.y + 25.0, z = pos.z + cos(rad) * 110.0, angle = angle }
	}

	function addRuntimeDroppedItem(playerId, data, callback = null) {
		if (data == null) { if (callback != null) callback(false, "badData"); return }
		local instanceId = ("instanceId" in data) ? data.instanceId.tostring().toupper() : ""
		local scheme = phoenix.item.find(instanceId)
		local amount = ("amount" in data) ? data.amount.tointeger() : 1
		local quality = ("quality" in data) ? data.quality.tointeger() : PhoenixItemQuality.Common
		local upgrade = ("upgrade" in data) ? data.upgrade.tointeger() : 0
		if (amount <= 0 || scheme == null) { if (callback != null) callback(false, "badItem"); return }
		local visual = ""
		try { if ("visual" in data && data.visual != null && data.visual != "") visual = phoenix.vob.Structure.normalizeVisual(data.visual) } catch (ev) {}
		if (visual == "") visual = phoenix.vob.Structure.itemVisual(instanceId, scheme)
		if (visual == "") { if (callback != null) callback(false, "badVisual"); return }
		local drop = phoenix.vob.Structure.dropPosition(playerId)
		local world = "NEWWORLD"
		try { local w = getPlayerWorld(playerId); if (w != null && w != "") world = w } catch (e) {}
		world = phoenix.vob.Structure.normalizeWorld(world)
		local vobId = "drop_" + playerId + "_" + getTickCount() + "_" + (rand() % 10000)
		local label = ""
		try { if ("name" in data && data.name != null && data.name != "") label = data.name.tostring() } catch (en) {}
		if (label == "") label = phoenix.vob.Structure.itemLabel(scheme, amount, upgrade)
		local entry = { vobId = vobId, name = label, visual = visual, world = world, x = drop.x, y = drop.y, z = drop.z, rotX = 0.0, rotY = drop.angle, rotZ = 0.0, interactive = true, entryKind = "item", itemInstance = instanceId, itemAmount = amount, itemQuality = quality }
		phoenix.vob.Structure.entries[vobId] <- entry
		phoenix.vob.Structure.droppedItems[vobId] <- { instanceId = instanceId, amount = amount, quality = quality, upgrade = upgrade, label = label }
		phoenix.vob.Structure.broadcastSnapshot()
		if (callback != null) callback(true, "")
	}

	function pickupDroppedItem(playerId, vobId) {
		if (!(vobId in phoenix.vob.Structure.droppedItems)) return false
		if (vobId in phoenix.vob.Structure.pickupLocks) return true
		if (!(vobId in phoenix.vob.Structure.entries)) return false
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return true
		local entry = phoenix.vob.Structure.entries[vobId]
		local pos = null
		try { pos = getPlayerPosition(playerId) } catch (e) { pos = null }
		if (pos == null) return true
		if (phoenix.vob.Structure.dist(pos, { x = entry.x, y = entry.y, z = entry.z }) > phoenix.vob.Structure.range + 80.0) return true
		local item = phoenix.vob.Structure.droppedItems[vobId]
		phoenix.vob.Structure.pickupLocks[vobId] <- true
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, item.instanceId, { amount = item.amount, quality = item.quality, upgrade = item.upgrade, source = "ground" }, function(rec) {
			if (rec == null) {
				if (vobId in phoenix.vob.Structure.pickupLocks) phoenix.vob.Structure.pickupLocks.rawdelete(vobId)
				try { phoenix.notification.notify(playerId, "error", "Przedmiot", "Nie mozna podniesc przedmiotu.", 3000) } catch (e) {}
				return
			}
			if (vobId in phoenix.vob.Structure.entries) phoenix.vob.Structure.entries.rawdelete(vobId)
			if (vobId in phoenix.vob.Structure.droppedItems) phoenix.vob.Structure.droppedItems.rawdelete(vobId)
			if (vobId in phoenix.vob.Structure.pickupLocks) phoenix.vob.Structure.pickupLocks.rawdelete(vobId)
			phoenix.vob.Structure.broadcastSnapshot()
			try { phoenix.notification.notify(playerId, "success", "Podniesiono", item.label, 2800) } catch (e2) {}
		})
		return true
	}
}
