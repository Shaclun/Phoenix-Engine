phoenix.admin.Server <- {

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
		try { m.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
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
					hp = 0,
					hpMax = 0,
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
					try { entry.hpMax = rec.hpMax } catch (e) {}
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
					local v = ("visual" in scheme) ? scheme.visual : null
					if (v == null || v == "") {
						try { v = phoenix.item.lookupVisual(instanceId) } catch (e) {}
					}
					if (v != null) entry.visual = v
				} catch (e) {}
				rows.append(entry)
			}
		} catch (e) {}
		phoenix.admin.Server.reply(playerId, "schemes", true, "", { schemes = rows })
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

	function dispatchSaveCustomItem(playerId, payload) {
		if (payload == null) return phoenix.admin.Server.reply(playerId, "saveCustom", false, "payload", null)
		local inst = ("instance" in payload) ? payload.instance.tostring().toupper() : ""
		if (inst == "" || inst.len() > 64) return phoenix.admin.Server.reply(playerId, "saveCustom", false, "badInstance", null)
		local name = ("name" in payload) ? payload.name.tostring() : inst
		local description = ("description" in payload) ? payload.description.tostring() : ""
		local visual = ("visual" in payload) ? payload.visual.tostring() : ""
		local category = ("category" in payload) ? payload.category : 0
		local slot = ("slot" in payload) ? payload.slot : 0
		local value = ("value" in payload) ? payload.value : 0
		local weight = ("weight" in payload) ? payload.weight.tofloat() : 0.0
		local stackMax = ("stackMax" in payload) ? payload.stackMax : 1
		local damage = ("damage" in payload) ? payload.damage : 0
		local damageType = ("damageType" in payload) ? payload.damageType : 0
		local flags = ("flags" in payload) ? payload.flags : 0
		local pe = 0; local pb = 0; local pp = 0; local pf = 0; local pm = 0
		if ("protection" in payload && payload.protection != null) {
			local pr = payload.protection
			if ("edge" in pr) pe = pr.edge
			if ("blunt" in pr) pb = pr.blunt
			if ("point" in pr) pp = pr.point
			if ("fire" in pr) pf = pr.fire
			if ("magic" in pr) pm = pr.magic
		}

		local data = {
			category = category, slot = slot, name = name, description = description,
			value = value, visual = (visual != "" ? visual : null), weight = weight,
			stackMax = stackMax, damage = damage, damageType = damageType, flags = flags,
			protection = { edge = pe, blunt = pb, point = pp, fire = pf, magic = pm }
		}
		try { phoenix.item.register(inst, data) } catch (e) {
			return phoenix.admin.Server.reply(playerId, "saveCustom", false, "register", null)
		}

		local s = phoenix.account.Structure.get(playerId)
		local adminId = (s != null) ? s.id() : 0
		local adminSql = (adminId > 0) ? adminId.tostring() : "NULL"
		local function esc(v) { try { return ORM.engine.escape(v) } catch (e) { return v } }
		local sql = "INSERT INTO `phoenix_custom_items` " +
			"(`instance`,`category`,`slot`,`name`,`description`,`visual`,`value`,`weight`,`stackMax`,`damage`,`damageType`,`protEdge`,`protBlunt`,`protPoint`,`protFire`,`protMagic`,`flags`,`createdBy`) " +
			"VALUES ('" + esc(inst) + "'," + category + "," + slot + ",'" + esc(name) + "','" + esc(description) + "','" + esc(visual) + "'," +
			value + "," + weight + "," + stackMax + "," + damage + "," + damageType + "," + pe + "," + pb + "," + pp + "," + pf + "," + pm + "," + flags + "," + adminSql + ") " +
			"ON DUPLICATE KEY UPDATE `category`=VALUES(`category`),`slot`=VALUES(`slot`),`name`=VALUES(`name`),`description`=VALUES(`description`),`visual`=VALUES(`visual`),`value`=VALUES(`value`),`weight`=VALUES(`weight`),`stackMax`=VALUES(`stackMax`),`damage`=VALUES(`damage`),`damageType`=VALUES(`damageType`),`protEdge`=VALUES(`protEdge`),`protBlunt`=VALUES(`protBlunt`),`protPoint`=VALUES(`protPoint`),`protFire`=VALUES(`protFire`),`protMagic`=VALUES(`protMagic`),`flags`=VALUES(`flags`)"
		try { ORM.engine.executeAsync(sql, function(_){}) } catch (e) {}

		phoenix.admin.Server.audit(playerId, "saveCustom", "item", null, inst, name)
		phoenix.admin.Server.reply(playerId, "saveCustom", true, "", { instance = inst })
	}

	function loadCustomItems() {
		local sql = "SELECT * FROM `phoenix_custom_items`"
		try {
			phoenix.admin.Server.ensureTables(function () {
				ORM.engine.executeAsync(sql, function(rows) {
					if (rows == null) return
					local n = 0
					foreach (r in rows) {
						try {
							local data = {
								category = r.category, slot = r.slot,
								name = r.name, description = r.description,
								value = r.value, visual = (r.visual != "" ? r.visual : null),
								weight = r.weight.tofloat(), stackMax = r.stackMax,
								damage = r.damage, damageType = r.damageType, flags = r.flags,
								protection = { edge = r.protEdge, blunt = r.protBlunt, point = r.protPoint, fire = r.protFire, magic = r.protMagic }
							}
							phoenix.item.register(r.instance, data)
							n += 1
						} catch (e) {}
						}
				})
			})
		} catch (e) {}
	}

	function ensureTables(callback) {
		local sqlLog = "CREATE TABLE IF NOT EXISTS `phoenix_admin_log` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,`adminId` INT NULL,`adminName` VARCHAR(64) DEFAULT '',`action` VARCHAR(48) NOT NULL,`targetType` VARCHAR(24) DEFAULT '',`targetId` INT NULL,`targetName` VARCHAR(64) DEFAULT '',`details` TEXT NULL,`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,KEY `idx_log_admin` (`adminId`),KEY `idx_log_action` (`action`),KEY `idx_log_created` (`createdAt`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		local sqlItems = "CREATE TABLE IF NOT EXISTS `phoenix_custom_items` (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,`instance` VARCHAR(64) NOT NULL UNIQUE,`category` TINYINT NOT NULL DEFAULT 0,`slot` TINYINT NOT NULL DEFAULT 0,`name` VARCHAR(96) DEFAULT '',`description` VARCHAR(512) DEFAULT '',`visual` VARCHAR(96) DEFAULT '',`value` INT DEFAULT 0,`weight` FLOAT DEFAULT 0,`stackMax` INT DEFAULT 1,`damage` INT DEFAULT 0,`damageType` TINYINT DEFAULT 0,`protEdge` INT DEFAULT 0,`protBlunt` INT DEFAULT 0,`protPoint` INT DEFAULT 0,`protFire` INT DEFAULT 0,`protMagic` INT DEFAULT 0,`flags` INT DEFAULT 0,`createdBy` INT NULL,`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,KEY `idx_custom_category` (`category`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try {
			ORM.engine.executeAsync(sqlLog, function (_) {
				ORM.engine.executeAsync(sqlItems, function (_) {
					if (callback != null) callback()
				})
			})
		} catch (e) {}
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
			local input = {
				enabled = ("enabled" in payload) ? payload.enabled : 1,
				loop = ("loop" in payload) ? payload.loop : 1,
				nodes = ("nodes" in payload) ? payload.nodes : [],
				createdBy = playerId
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

	dispatchers = null

	function onRequest(playerId, message) {
		if (!phoenix.account.Auth.isAdmin(playerId)) {
			phoenix.admin.Server.reply(playerId, message.action, false, "denied", null)
			return
		}
		local action = message.action
		if (!(action in phoenix.admin.Server.dispatchers)) {
			phoenix.admin.Server.reply(playerId, action, false, "unknownAction", null)
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
	schemes = phoenix.admin.Server.dispatchListSchemes,
	schemeDetails = phoenix.admin.Server.dispatchSchemeDetails,
	giveItem = phoenix.admin.Server.dispatchGiveItem,
	tpTo = phoenix.admin.Server.dispatchTeleportTo,
	tpHere = phoenix.admin.Server.dispatchTeleportHere,
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
	bestiary = phoenix.admin.Server.dispatchBestiary
}

phoenix.admin.Message.Request.bind(phoenix.admin.Server.onRequest)

try { phoenix.admin.Server.loadCustomItems() } catch (e) {}

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
