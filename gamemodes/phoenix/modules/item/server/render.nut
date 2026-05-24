phoenix.item.RenderConfig <- {
	cache = ""
	loaded = false

	function ensureTable(callback) {
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_item_render` (" +
			"`instance` VARCHAR(64) NOT NULL," +
			"`rotX` FLOAT NOT NULL DEFAULT 1.584," +
			"`rotY` FLOAT NOT NULL DEFAULT -1.662," +
			"`rotZ` FLOAT NOT NULL DEFAULT -0.488," +
			"`scaleValue` FLOAT NOT NULL DEFAULT 1.4," +
			"`lightIntensity` FLOAT NOT NULL DEFAULT 2.85," +
			"`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"PRIMARY KEY (`instance`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback() }) }
		catch (e) { if (callback != null) callback() }
	}

	function load(callback) {
		phoenix.item.RenderConfig.ensureTable(function () {
			ORM.engine.executeAsync("SELECT `instance`,`rotX`,`rotY`,`rotZ`,`scaleValue`,`lightIntensity` FROM `phoenix_item_render`", function (rows) {
				local payload = ""
				if (rows != null) {
					local first = true
					foreach (r in rows) {
						local line = r.instance + "|" + r.rotX + "|" + r.rotY + "|" + r.rotZ + "|" + r.scaleValue + "|" + r.lightIntensity
						if (first) { payload = line; first = false }
						else payload = payload + "\n" + line
					}
				}
				phoenix.item.RenderConfig.cache = payload
				phoenix.item.RenderConfig.loaded = true
				if (callback != null) callback()
			})
		})
	}

	function buildMessage() {
		local m = phoenix.item.Message.RenderConfig()
		m.entries = phoenix.item.RenderConfig.cache
		return m
	}

	function pushTo(playerId) {
		try {
			if (!phoenix.item.RenderConfig.loaded) {
				phoenix.item.RenderConfig.load(function () {
					try { phoenix.item.RenderConfig.buildMessage().serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
				})
				return
			}
			phoenix.item.RenderConfig.buildMessage().serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}

	function broadcast() {
		phoenix.item.RenderConfig.load(function () {
			try {
				local serialized = phoenix.item.RenderConfig.buildMessage().serialize()
				local maxSlots = getMaxSlots()
				for (local pid = 0; pid < maxSlots; pid += 1) {
					try { if (isPlayerConnected(pid)) serialized.send(pid, RELIABLE_ORDERED) } catch (e) {}
				}
			} catch (e2) {}
		})
	}
}

addEventHandler("phoenix.database.OnReady", function () {
	try { phoenix.item.RenderConfig.load(null) } catch (e) {}
})

addEventHandler("onPlayerJoin", function (playerId) {
	setTimer(function () {
		try { phoenix.item.RenderConfig.pushTo(playerId) } catch (e) {}
	}, 600, 1)
})
