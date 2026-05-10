phoenix.account.Auth <- {
	SHACLOW_USERNAME = "shaclow"

	function isShaclow(username) {
		if (username == null) return false
		return username.tolower() == phoenix.account.Auth.SHACLOW_USERNAME
	}

	function ensureShaclowAdmin(record) {
		if (record == null) return
		if (!phoenix.account.Auth.isShaclow(record.username)) return
		if (record.role == PhoenixAccountRole.Admin) return
		record.role = PhoenixAccountRole.Admin
		try { record.saveAsync() } catch (e) {}
	}

	function isAdmin(playerId) {
		local s = phoenix.account.Structure.get(playerId)
		if (s == null) return false
		try { return s.record.role == PhoenixAccountRole.Admin } catch (e) { return false }
	}

	function requireAdmin(playerId) {
		if (phoenix.account.Auth.isAdmin(playerId)) return true
		try { sendMessageToPlayer(playerId, 220, 80, 80, "[Admin] Brak uprawnien.") } catch (e) {}
		return false
	}

	function isVanished(playerId) {
		local s = phoenix.account.Structure.get(playerId)
		if (s == null) return false
		try { return s.vanished == true } catch (e) { return false }
	}

	function adminPlayerIds() {
		local list = []
		local maxSlots = getMaxSlots()
		for (local i = 0; i < maxSlots; i += 1) {
			try {
				if (!isPlayerConnected(i)) continue
				if (phoenix.account.Auth.isAdmin(i)) list.append(i)
			} catch (e) {}
		}
		return list
	}

	function nowEpoch() {
		try { return time() } catch (e) {}
		try { local d = date(); return d.year * 31536000 + d.yday * 86400 + d.hour * 3600 + d.min * 60 + d.sec } catch (e) {}
		return 0
	}

	function isBanRowActive(row) {
		if (row == null) return false
		try { if (!row.active) return false } catch (e) {}
		try {
			if (row.expiresAt == null) return true
			local exp = row.expiresAt
			if (typeof exp == "string") {

				return true
			}
			if (typeof exp == "integer" || typeof exp == "float") {
				return exp == 0 || exp > phoenix.account.Auth.nowEpoch()
			}
		} catch (e) {}
		return true
	}

	function checkLoginBans(record, playerId, callback) {
		local ip = ""
		local serial = ""
		try { ip = getPlayerIP(playerId) } catch (e) {}
		try { serial = getPlayerSerial(playerId) } catch (e) {}

		local ipEsc = ip; local serEsc = serial
		try { ipEsc = ORM.engine.escape(ip) } catch (e) {}
		try { serEsc = ORM.engine.escape(serial) } catch (e) {}

		local where = "`active` = 1 AND (`expiresAt` IS NULL OR `expiresAt` > NOW()) AND ("
		where += "`accountId` = " + record.id
		if (ip != "")     where += " OR `ipAddress` = '" + ipEsc + "'"
		if (serial != "") where += " OR `serial` = '" + serEsc + "'"
		where += ")"

		local sql = "SELECT `id`,`scope`,`reason`,UNIX_TIMESTAMP(`expiresAt`) AS expiresAt FROM `phoenix_bans` WHERE " + where + " LIMIT 1"
		ORM.engine.executeAsync(sql, function(rows) {
			if (rows == null || rows.len() == 0) return callback(null)
			callback(rows[0])
		})
	}
}
