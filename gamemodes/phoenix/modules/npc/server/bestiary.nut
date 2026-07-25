phoenix.npc.Bestiary <- {

	schemaReady = false
	schemaLoading = false

	function ensureSchema(callback = null) {
		if (phoenix.npc.Bestiary.schemaReady) { if (callback != null) callback(); return }
		if (phoenix.npc.Bestiary.schemaLoading) {
			if (callback != null) setTimer(function () {
				try { phoenix.npc.Bestiary.ensureSchema(callback) } catch (e) {}
			}, 400, 1)
			return
		}
		phoenix.npc.Bestiary.schemaLoading = true
		local createSql = "CREATE TABLE IF NOT EXISTS `phoenix_bestiary` (" +
			"`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY," +
			"`characterId` INT NOT NULL," +
			"`instance` VARCHAR(64) NOT NULL," +
			"`name` VARCHAR(96) NOT NULL DEFAULT ''," +
			"`visual` VARCHAR(96) NOT NULL DEFAULT ''," +
			"`kind` VARCHAR(24) NOT NULL DEFAULT 'monster'," +
			"`killed` INT NOT NULL DEFAULT 0," +
			"`firstKilledAt` TIMESTAMP NULL DEFAULT NULL," +
			"`lastKilledAt` TIMESTAMP NULL DEFAULT NULL," +
			"KEY `idx_best_char` (`characterId`)," +
			"UNIQUE KEY `uniq_char_inst_name` (`characterId`,`instance`,`name`)" +
			") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try {
			ORM.engine.executeAsync(createSql, function (_) {
				phoenix.npc.Bestiary._ensureColumns(function () {
					phoenix.npc.Bestiary.schemaReady = true
					phoenix.npc.Bestiary.schemaLoading = false
					if (callback != null) callback()
				})
			})
		} catch (e) {
			phoenix.npc.Bestiary.schemaLoading = false
			if (callback != null) callback()
		}
	}

	function _ensureColumns(callback) {
		ORM.engine.executeAsync("SHOW COLUMNS FROM `phoenix_bestiary`", function (rows) {
			local cols = {}
			if (rows != null) foreach (r in rows) {
				try { cols[r.Field.tostring()] <- true } catch (e) {}
			}
			local steps = []
			if (!("name" in cols)) steps.append("ALTER TABLE `phoenix_bestiary` ADD COLUMN `name` VARCHAR(96) NOT NULL DEFAULT '' AFTER `instance`")
			if (!("visual" in cols)) steps.append("ALTER TABLE `phoenix_bestiary` ADD COLUMN `visual` VARCHAR(96) NOT NULL DEFAULT '' AFTER `name`")
			if (!("kind" in cols)) steps.append("ALTER TABLE `phoenix_bestiary` ADD COLUMN `kind` VARCHAR(24) NOT NULL DEFAULT 'monster' AFTER `visual`")
			ORM.engine.executeAsync("SHOW INDEX FROM `phoenix_bestiary`", function (indexRows) {
				local idx = {}
				if (indexRows != null) foreach (r in indexRows) {
					try { idx[r.Key_name.tostring()] <- true } catch (e) {}
				}
				if ("uniq_char_inst" in idx) steps.append("ALTER TABLE `phoenix_bestiary` DROP INDEX `uniq_char_inst`")
				if (!("uniq_char_inst_name" in idx)) steps.append("ALTER TABLE `phoenix_bestiary` ADD UNIQUE KEY `uniq_char_inst_name` (`characterId`,`instance`,`name`)")
				local i = 0
				local runner = null
				runner = function () {
					if (i >= steps.len()) { if (callback != null) callback(); return }
					local sql = steps[i]
					i += 1
					try { ORM.engine.executeAsync(sql, function (_) { runner() }) }
					catch (e) { runner() }
				}
				runner()
			})
		})
	}

	function bump(characterId, instance, name, visual = "", kind = "monster", callback = null) {
		phoenix.npc.Bestiary.ensureSchema(function () {
			if (characterId == null || characterId <= 0 || instance == null || instance == "") {
				if (callback != null) callback(false); return
			}
			local instEsc = instance
			local nameEsc = name != null ? name.tostring() : ""
			local visualEsc = visual != null ? visual.tostring() : ""
			local kindEsc = kind != null ? kind.tostring() : "monster"
			try { instEsc = ORM.engine.escape(instance) } catch (e) {}
			try { nameEsc = ORM.engine.escape(nameEsc) } catch (e) {}
			try { visualEsc = ORM.engine.escape(visualEsc) } catch (e) {}
			try { kindEsc = ORM.engine.escape(kindEsc) } catch (e) {}
			local sql = "INSERT INTO `phoenix_bestiary` " +
				"(`characterId`,`instance`,`name`,`visual`,`kind`,`killed`,`firstKilledAt`,`lastKilledAt`) VALUES (" +
				characterId + ",'" + instEsc + "','" + nameEsc + "','" + visualEsc + "','" + kindEsc + "',1,NOW(),NOW()) " +
				"ON DUPLICATE KEY UPDATE `killed` = `killed` + 1, `lastKilledAt` = NOW()," +
				"`visual` = IF(VALUES(`visual`) <> '', VALUES(`visual`), `visual`)," +
				"`kind` = IF(VALUES(`kind`) <> '', VALUES(`kind`), `kind`)"
			try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback(true) }) }
			catch (e) { if (callback != null) callback(false) }
		})
	}

	function loadFor(characterId, callback) {
		phoenix.npc.Bestiary.ensureSchema(function () {
			local sql = "SELECT `instance`,`name`,`visual`,`kind`,`killed`," +
				"UNIX_TIMESTAMP(`firstKilledAt`) AS firstKilledAt," +
				"UNIX_TIMESTAMP(`lastKilledAt`) AS lastKilledAt " +
				"FROM `phoenix_bestiary` WHERE `characterId` = " + characterId +
				" AND `kind` IN ('monster','boss') " +
				"ORDER BY `killed` DESC, `lastKilledAt` DESC LIMIT 500"
			try {
				ORM.engine.executeAsync(sql, function (rows) {
					local out = []
					if (rows != null) foreach (r in rows) {
						out.append({
							instance = ("instance" in r) ? r.instance : "",
							name = ("name" in r && r.name != null) ? r.name : "",
							visual = ("visual" in r && r.visual != null) ? r.visual : "",
							kind = ("kind" in r && r.kind != null) ? r.kind : "monster",
							killed = ("killed" in r) ? r.killed : 0,
							firstKilledAt = ("firstKilledAt" in r && r.firstKilledAt != null) ? r.firstKilledAt : 0,
							lastKilledAt = ("lastKilledAt" in r && r.lastKilledAt != null) ? r.lastKilledAt : 0
						})
					}
					if (callback != null) callback(out)
				})
			} catch (e) {
				if (callback != null) callback([])
			}
		})
	}

	function visualFromEntry(entry) {
		if (entry == null) return ""
		try {
			local row = entry.row
			if ("bodyModel" in row && row.bodyModel != null && row.bodyModel != "") return row.bodyModel.tostring()
			if ("instance" in row && row.instance != null) return row.instance.tostring()
		} catch (e) {}
		return ""
	}

	function bumpFromEntry(characterId, entry) {
		if (entry == null) return
		try {
			local row = entry.row
			local instance = ("instance" in row) ? row.instance.tostring() : ""
			local name = ("name" in row && row.name != null) ? row.name.tostring() : ""
			local visual = phoenix.npc.Bestiary.visualFromEntry(entry)
			local kind = ("kind" in row && row.kind != null) ? row.kind.tostring() : "monster"
			if (kind != "monster" && kind != "boss") return
			phoenix.npc.Bestiary.bump(characterId, instance, name, visual, kind, null)
		} catch (e) {}
	}
}

addEventHandler("phoenix.database.OnReady", function () {
	try { phoenix.npc.Bestiary.ensureSchema(null) } catch (e) {}
})

phoenix.npc.Bestiary.onRequest <- function (playerId, _message) {
	try {
		local rec = phoenix.character.Structure.getActive(playerId)
		if (rec == null) {
			phoenix.npc.Bestiary._sendSnapshot(playerId, [])
			return
		}
		phoenix.npc.Bestiary.loadFor(rec.id, function (rows) {
			phoenix.npc.Bestiary._sendSnapshot(playerId, rows)
		})
	} catch (e) {}
}

phoenix.npc.Bestiary._sendSnapshot <- function (playerId, rows) {
	local payload = ""
	try {
		if (rows != null) {
			local first = true
			foreach (r in rows) {
				local name = (r.name == null) ? "" : r.name.tostring()
				local visual = (r.visual == null) ? "" : r.visual.tostring()
				local kind = (r.kind == null) ? "monster" : r.kind.tostring()
				local inst = (r.instance == null) ? "" : r.instance.tostring()
				name = phoenix.npc.Bestiary._escape(name)
				visual = phoenix.npc.Bestiary._escape(visual)
				inst = phoenix.npc.Bestiary._escape(inst)
				kind = phoenix.npc.Bestiary._escape(kind)
				local line = inst + "|" + name + "|" + visual + "|" + kind + "|" + r.killed + "|" + r.firstKilledAt + "|" + r.lastKilledAt
				if (first) { payload = line; first = false }
				else payload = payload + "\n" + line
			}
		}
	} catch (e) {}
	try {
		local msg = phoenix.npc.Message.BestiarySnapshot()
		msg.entries = payload
		msg.serialize().send(playerId, RELIABLE_ORDERED)
	} catch (e) {}
}

phoenix.npc.Bestiary._escape <- function (s) {
	if (s == null) return ""
	local out = ""
	local text = s.tostring()
	for (local i = 0; i < text.len(); i += 1) {
		local ch = text[i]
		if (ch == '\n' || ch == '|') out += " "
		else out += text.slice(i, i + 1)
	}
	return out
}

phoenix.npc.Message.BestiaryRequest.bind(phoenix.npc.Bestiary.onRequest)



phoenix.npc.BestiaryRender <- {
	cache = ""
	loaded = false

	function ensureTable(callback) {
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

	function load(callback) {
		phoenix.npc.BestiaryRender.ensureTable(function () {
			ORM.engine.executeAsync("SELECT `instance`,`rotX`,`rotY`,`rotZ`,`scaleValue`,`lightIntensity` FROM `phoenix_bestiary_render`", function (rows) {
				local payload = ""
				if (rows != null) {
					local first = true
					foreach (r in rows) {
						local line = r.instance + "|" + r.rotX + "|" + r.rotY + "|" + r.rotZ + "|" + r.scaleValue + "|" + r.lightIntensity
						if (first) { payload = line; first = false }
						else payload = payload + "\n" + line
					}
				}
				phoenix.npc.BestiaryRender.cache = payload
				phoenix.npc.BestiaryRender.loaded = true
				if (callback != null) callback()
			})
		})
	}

	function buildMessage() {
		local m = phoenix.npc.Message.BestiaryRenderConfig()
		m.entries = phoenix.npc.BestiaryRender.cache
		return m
	}

	function pushTo(playerId) {
		try {
			if (!phoenix.npc.BestiaryRender.loaded) {
				phoenix.npc.BestiaryRender.load(function () {
					try { phoenix.npc.BestiaryRender.buildMessage().serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
				})
				return
			}
			phoenix.npc.BestiaryRender.buildMessage().serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}

	function broadcast() {
		phoenix.npc.BestiaryRender.load(function () {
			try {
				local serialized = phoenix.npc.BestiaryRender.buildMessage().serialize()
				local maxSlots = getMaxSlots()
				for (local pid = 0; pid < maxSlots; pid += 1) {
					try { if (isPlayerConnected(pid)) serialized.send(pid, RELIABLE_ORDERED) } catch (e) {}
				}
			} catch (e2) {}
		})
	}
}

addEventHandler("phoenix.database.OnReady", function () {
	try { phoenix.npc.BestiaryRender.load(null) } catch (e) {}
})

addEventHandler("onPlayerJoin", function (playerId) {
	setTimer(function () {
		try { phoenix.npc.BestiaryRender.pushTo(playerId) } catch (e) {}
	}, 600, 1)
})
