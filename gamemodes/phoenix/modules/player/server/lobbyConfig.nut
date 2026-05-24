phoenix.player.LobbyConfig <- {
	cache = { lobbyCameras = "", characterDefaultSpawn = "", characterScenarios = "", characterCreateCamera = "", characterSelectCamera = "", hudPortrait = "" }
	loaded = false

	function ensureTable(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_admin_config` (" +
			"`id` INT UNSIGNED NOT NULL AUTO_INCREMENT," +
			"`configKey` VARCHAR(64) NOT NULL," +
			"`payload` TEXT NOT NULL," +
			"`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"PRIMARY KEY (`id`),UNIQUE KEY `idx_config_key` (`configKey`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback() }) }
		catch (e) { if (callback != null) callback() }
	}

	function load(callback) {
		phoenix.player.LobbyConfig.ensureTable(function () {
			local sql = "SELECT `configKey`, `payload` FROM `phoenix_admin_config` WHERE `configKey` IN ('lobbyCameras','characterDefaultSpawn','characterScenarios','characterCreateCamera','characterSelectCamera','hudPortrait')"
			ORM.engine.executeAsync(sql, function (rows) {
				local cache = phoenix.player.LobbyConfig.cache
				if (rows != null) foreach (r in rows) {
					if (!("configKey" in r)) continue
					local key = r.configKey.tostring()
					local val = ("payload" in r) ? r.payload.tostring() : ""
					if (key in cache) cache[key] = val
				}
				phoenix.player.LobbyConfig.loaded = true
				if (callback != null) callback()
			})
		})
	}

	function buildMessage() {
		local m = phoenix.player.Message.LobbyConfig()
		m.lobbyCameras = phoenix.player.LobbyConfig.cache.lobbyCameras
		m.characterDefaultSpawn = phoenix.player.LobbyConfig.cache.characterDefaultSpawn
		m.characterScenarios = phoenix.player.LobbyConfig.cache.characterScenarios
		m.characterCreateCamera = phoenix.player.LobbyConfig.cache.characterCreateCamera
		m.characterSelectCamera = phoenix.player.LobbyConfig.cache.characterSelectCamera
		m.hudPortrait = phoenix.player.LobbyConfig.cache.hudPortrait
		return m
	}

	function pushTo(playerId) {
		try {
			if (!phoenix.player.LobbyConfig.loaded) {
				phoenix.player.LobbyConfig.load(function () {
					try { phoenix.player.LobbyConfig.buildMessage().serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
				})
				return
			}
			phoenix.player.LobbyConfig.buildMessage().serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}

	function broadcast() {
		phoenix.player.LobbyConfig.load(function () {
			try {
				local serialized = phoenix.player.LobbyConfig.buildMessage().serialize()
				local maxSlots = getMaxSlots()
				for (local pid = 0; pid < maxSlots; pid += 1) {
					try { if (isPlayerConnected(pid)) serialized.send(pid, RELIABLE_ORDERED) } catch (e) {}
				}
			} catch (e2) {}
		})
	}
}

addEventHandler("phoenix.database.OnReady", function () {
	try { phoenix.player.LobbyConfig.load(null) } catch (e) {}
})

addEventHandler("onPlayerJoin", function (playerId) {
	setTimer(function () {
		try { phoenix.player.LobbyConfig.pushTo(playerId) } catch (e) {}
	}, 500, 1)
})
