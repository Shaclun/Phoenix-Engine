phoenix.npc.Bestiary <- {

	function bump(characterId, instance, callback) {
		if (characterId == null || characterId <= 0 || instance == null || instance == "") {
			if (callback != null) callback(false); return
		}
		local instEsc = instance
		try { instEsc = ORM.engine.escape(instance) } catch (e) {}
		local sql = "INSERT INTO `phoenix_bestiary` (`characterId`,`instance`,`killed`,`firstKilledAt`,`lastKilledAt`) VALUES (" +
			characterId + ",'" + instEsc + "',1,NOW(),NOW()) " +
			"ON DUPLICATE KEY UPDATE `killed` = `killed` + 1, `lastKilledAt` = NOW()"
		try { ORM.engine.executeAsync(sql, function (_) { if (callback != null) callback(true) }) }
		catch (e) { if (callback != null) callback(false) }
	}

	function loadFor(characterId, callback) {
		local sql = "SELECT `instance`,`killed`,UNIX_TIMESTAMP(`firstKilledAt`) AS firstKilledAt,UNIX_TIMESTAMP(`lastKilledAt`) AS lastKilledAt " +
			"FROM `phoenix_bestiary` WHERE `characterId` = " + characterId + " ORDER BY `killed` DESC LIMIT 200"
		try {
			ORM.engine.executeAsync(sql, function (rows) {
				local out = []
				if (rows != null) foreach (r in rows) out.append(r)
				if (callback != null) callback(out)
			})
		} catch (e) {
			if (callback != null) callback([])
		}
	}
}

addEventHandler("onPlayerDamage", function (victimId, killerId, desc) {
	try {
		if (getPlayerHealth(victimId) > 0) return
		local victimInstance = null
		local alreadyHandled = false
		foreach (sid, entry in phoenix.npc.Spawn.live) {
			if (entry.npcId == victimId) { victimInstance = entry.row.instance; alreadyHandled = !entry.alive; break }
		}
		if (alreadyHandled) return
		if (victimInstance == null) return
		if (killerId == null || killerId < 0) return
		local killerRec = phoenix.character.Structure.getActive(killerId)
		if (killerRec == null) return
		phoenix.npc.Bestiary.bump(killerRec.id, victimInstance, null)
	} catch (e) {}
})
