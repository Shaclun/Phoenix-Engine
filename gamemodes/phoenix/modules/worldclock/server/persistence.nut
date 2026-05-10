phoenix.worldclock.Persistence <- {

	tableEnsured = false

	function ensureTable(callback) {
		if (phoenix.worldclock.Persistence.tableEnsured) { if (callback != null) callback(); return }
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_world_state` (" +
			"`id` TINYINT UNSIGNED NOT NULL DEFAULT 1," +
			"`timeHour` TINYINT UNSIGNED NOT NULL DEFAULT 8," +
			"`timeMin` TINYINT UNSIGNED NOT NULL DEFAULT 0," +
			"`dayLength` INT UNSIGNED NOT NULL DEFAULT 60," +
			"`weather` VARCHAR(16) NOT NULL DEFAULT 'clear'," +
			"`wind` FLOAT NOT NULL DEFAULT 0.0," +
			"`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try {
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.worldclock.Persistence.tableEnsured = true
				if (callback != null) callback()
			})
		} catch (e) {
			if (callback != null) callback()
		}
	}

	function load(callback) {
		phoenix.worldclock.Persistence.ensureTable(function () {
			ORM.engine.executeAsync("SELECT * FROM `phoenix_world_state` WHERE `id` = 1 LIMIT 1", function (rows) {
				if (rows == null || rows.len() == 0) { if (callback != null) callback(null); return }
				local r = rows[0]
				local read = function (key, fallback) {
					try { if (key in r && r[key] != null) return r[key] } catch (e) {}
					return fallback
				}
				local state = {
					timeHour = read("timeHour", 8).tointeger(),
					timeMin = read("timeMin", 0).tointeger(),
					dayLength = read("dayLength", 60).tointeger(),
					weather = read("weather", "clear").tostring(),
					wind = read("wind", 0.0).tofloat()
				}
				if (callback != null) callback(state)
			})
		})
	}

	function save() {
		phoenix.worldclock.Persistence.ensureTable(function () {
			local t = phoenix.worldclock.Clock.readTime()
			local h = 8
			local m = 0
			try { h = t.hour.tointeger() } catch (e) {}
			try { m = t.min.tointeger() } catch (e) {}
			local dl = 60
			try { dl = phoenix.worldclock.Clock.readDayLength() } catch (e) {}
			local w = phoenix.worldclock.Weather.kind
			local wind = phoenix.worldclock.Weather.wind
			local esc = function (v) { try { return ORM.engine.escape(v.tostring()) } catch (e) { return v.tostring() } }
			local sql = "INSERT INTO `phoenix_world_state` (`id`,`timeHour`,`timeMin`,`dayLength`,`weather`,`wind`) VALUES (" +
				"1," + h + "," + m + "," + dl + ",'" + esc(w) + "'," + wind + ") " +
				"ON DUPLICATE KEY UPDATE `timeHour`=VALUES(`timeHour`),`timeMin`=VALUES(`timeMin`)," +
				"`dayLength`=VALUES(`dayLength`),`weather`=VALUES(`weather`),`wind`=VALUES(`wind`)"
			try {
				ORM.engine.executeAsync(sql, function (_) {
					phoenix.worldclock.Clock.dirty = false
					phoenix.worldclock.Weather.dirty = false
				})
			} catch (e) {}
		})
	}

	function maybeSave() {
		if (phoenix.worldclock.Clock.dirty || phoenix.worldclock.Weather.dirty) {
			phoenix.worldclock.Persistence.save()
		}
	}
}
