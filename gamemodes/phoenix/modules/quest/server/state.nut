phoenix.quest.State <- {

	function start(characterId, code, goal, callback) {
		if (characterId == null || characterId <= 0 || code == null || code == "") {
			if (callback != null) callback(false); return
		}
		local codeEsc = code; try { codeEsc = ORM.engine.escape(code) } catch (e) {}
		local sql = "INSERT INTO `phoenix_quest_states` (`characterId`,`questCode`,`status`,`progress`,`progressGoal`) VALUES (" +
			characterId + ",'" + codeEsc + "','active',0," + (goal != null ? goal : 1) + ") " +
			"ON DUPLICATE KEY UPDATE `status` = IF(`status`='completed','completed','active'), `startedAt` = NOW()"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback(true) }) }
		catch (e) { if (callback != null) callback(false) }
	}

	function complete(characterId, code, callback) {
		local codeEsc = code; try { codeEsc = ORM.engine.escape(code) } catch (e) {}
		local sql = "UPDATE `phoenix_quest_states` SET `status` = 'completed', `completedAt` = NOW(), `progress` = `progressGoal` " +
			"WHERE `characterId` = " + characterId + " AND `questCode` = '" + codeEsc + "'"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback(true) }) }
		catch (e) { if (callback != null) callback(false) }
	}

	function bumpProgress(characterId, code, delta, callback) {
		local codeEsc = code; try { codeEsc = ORM.engine.escape(code) } catch (e) {}
		local d = delta != null ? delta : 1
		local sql = "UPDATE `phoenix_quest_states` SET `progress` = LEAST(`progress` + " + d + ", `progressGoal`)," +
			" `status` = IF(`progress` + " + d + " >= `progressGoal`, 'completed', `status`)," +
			" `completedAt` = IF(`progress` + " + d + " >= `progressGoal`, NOW(), `completedAt`)" +
			" WHERE `characterId` = " + characterId + " AND `questCode` = '" + codeEsc + "' AND `status` = 'active'"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback(true) }) }
		catch (e) { if (callback != null) callback(false) }
	}

	function listFor(characterId, callback) {
		local sql = "SELECT `id`,`questCode`,`status`,`progress`,`progressGoal`," +
			"UNIX_TIMESTAMP(`startedAt`) AS startedAt," +
			"UNIX_TIMESTAMP(`completedAt`) AS completedAt," +
			"`notes` FROM `phoenix_quest_states` WHERE `characterId` = " + characterId + " ORDER BY `id` DESC LIMIT 200"
		try {
			ORM.engine.executeAsync(sql, function (rows) {
				local out = []
				if (rows != null) foreach (r in rows) out.append(r)
				if (callback != null) callback(out)
			})
		} catch (e) { if (callback != null) callback([]) }
	}
}
addEventHandler("onInit", function () {
	try {
		ORM.engine.executeAsync("SELECT * FROM `phoenix_quests`", function (rows) {
			if (rows == null) return
			local n = 0
			foreach (r in rows) {
				try {
					phoenix.quest.register(r.code, {
						title = r.title,
						description = r.description,
						giverInstance = r.giverInstance,
						type = r.type,
						payload = r.payload
					})
					n += 1
				} catch (e) {}
			}
		})
	} catch (e) {}
})
