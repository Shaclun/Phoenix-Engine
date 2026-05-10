phoenix.character.Handlers <- {
	function send(playerId, message) {
		message.serialize().send(playerId, RELIABLE_ORDERED)
	}

	function rejectCreate(playerId, error) {
		phoenix.character.Handlers.send(playerId, phoenix.character.Message.CreateResult(false, error))
	}

	function asListEntries(records) {
		local out = []
		foreach (record in records) {
			local status = 1
			try { status = record.status } catch (e) { status = 1 }
			out.push({
				id = record.id
				name = record.name
				klass = record.klass
				gender = record.gender
				level = record.level
				bodyModel = record.bodyModel != null ? record.bodyModel : ""
				headModel = record.headModel != null ? record.headModel : ""
				bodyTexIndex = record.bodyTexIndex
				face = record.face
				fatness = record.fatness
				equipment = record.equipment != null ? record.equipment : ""
				playTimeSec = record.playTimeSec
				lastPlayedAt = 0
				createdAt = 0
				status = status
			})
		}
		return out
	}

	function equipmentStringFromItems(items) {
		local parts = []
		if (items == null) return ""
		foreach (item in items) {
			if (item.equipped != 1) continue
			parts.push(item.instanceId + "|" + item.amount)
		}
		local result = ""
		for (local i = 0; i < parts.len(); i += 1) {
			if (i > 0) result += ","
			result += parts[i]
		}
		return result
	}

	function pushList(playerId, accountId) {
		phoenix.character.Structure.listForAccount(accountId, function(records) {
			local entries = phoenix.character.Handlers.asListEntries(records)
			if (entries.len() == 0) return phoenix.character.Handlers.send(playerId, phoenix.character.Message.List(entries))

			local pending = entries.len() * 3
			local done = function() {
				pending -= 1
				if (pending <= 0) phoenix.character.Handlers.send(playerId, phoenix.character.Message.List(entries))
			}
			foreach (entry in entries) {
				local target = entry
				ItemModel.findByOwner(phoenix.character.InventoryOwnerPlayer, target.id, function(items) {
					local equipment = phoenix.character.Handlers.equipmentStringFromItems(items)
					if (equipment != "") target.equipment = equipment
					done()
				})
				BanModel.findActiveForCharacter(target.id, function(bans) {
					if (bans != null && bans.len() > 0) target.status = 2
					done()
				})
				local sql = "SELECT UNIX_TIMESTAMP(`createdAt`) AS createdAt, UNIX_TIMESTAMP(`lastPlayedAt`) AS lastPlayedAt FROM `phoenix_characters` WHERE `id` = " + target.id + " LIMIT 1"
				ORM.engine.executeAsync(sql, function(rows) {
					if (rows != null && rows.len() > 0) {
						try { target.createdAt = rows[0].createdAt.tointeger() } catch (e) {}
						try { if (rows[0].lastPlayedAt != null) target.lastPlayedAt = rows[0].lastPlayedAt.tointeger() } catch (e2) {}
					}
					done()
				})
			}
		})
	}

	function onAuthenticated(playerId) {
		local session = phoenix.account.Structure.get(playerId)
		if (session == null) return
		phoenix.character.Handlers.pushList(playerId, session.id())
	}

	function onRequestList(playerId, _message) {
		local session = phoenix.account.Structure.get(playerId)
		if (session == null) return
		phoenix.character.Handlers.pushList(playerId, session.id())
	}

	function onCreate(playerId, message) {
		local session = phoenix.account.Structure.get(playerId)
		if (session == null) return phoenix.character.Handlers.rejectCreate(playerId, "phoenix.character.error.notLogged")

		local err = phoenix.character.Validator.name(message.name)
		if (err == null) err = phoenix.character.Validator.gender(message.gender)
		if (err == null) err = phoenix.character.Validator.appearance(message.face, message.voice)
		if (err != null) return phoenix.character.Handlers.rejectCreate(playerId, err)

		local payload = {
			name = message.name
			gender = message.gender
			klass = 3
			race = message.race
			fatness = message.fatness
			walking = message.walking
			weapon = message.weapon
			ranged = message.ranged
			outfit = message.outfit
			scenario = message.scenario
			bodyModel = message.bodyModel
			headModel = message.headModel
			bodyTexIndex = message.bodyTexIndex
			face = message.face
			voice = message.voice
		}

		phoenix.character.Structure.create(session.id(), payload, function(error, record) {
			if (error != null) return phoenix.character.Handlers.rejectCreate(playerId, error)
			phoenix.character.Handlers.send(playerId, phoenix.character.Message.CreateResult(true, ""))
			phoenix.character.Handlers.pushList(playerId, session.id())
		})
	}

	function onSelect(playerId, message) {
		local session = phoenix.account.Structure.get(playerId)
		if (session == null) return

		phoenix.character.Structure.findOwned(session.id(), message.characterId, function(record) {
			if (record == null) return
			BanModel.findActiveForCharacter(record.id, function(bans) {
				if (bans != null && bans.len() > 0) return
				phoenix.character.Structure.setActive(playerId, record)
				phoenix.character.Structure.markPlayed(record.id)
				phoenix.character.Handlers.send(playerId, phoenix.character.Message.AfterSelect(record.id, record.name))
				callEvent("phoenix.character.OnSelected", playerId, record.id)
			})
		})
	}

	function onPreviewRestore(playerId, _message) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		try { phoenix.player.Gate.restoreVisual(playerId) } catch (e) {}
		try { phoenix.player.Gate.restoreEquipment(playerId, record) } catch (e2) {}
	}

	function onDelete(playerId, message) {
		local session = phoenix.account.Structure.get(playerId)
		if (session == null) return

		phoenix.character.Structure.remove(session.id(), message.characterId, function(error) {
			phoenix.character.Handlers.pushList(playerId, session.id())
		})
	}

	function onPlayerDisconnect(playerId, reason) {
		try { phoenix.player.Gate.persist(playerId) } catch (e) {}
		phoenix.character.Structure.clearActive(playerId)
	}
}

phoenix.character.Message.RequestList.bind(phoenix.character.Handlers.onRequestList)
phoenix.character.Message.Create.bind(phoenix.character.Handlers.onCreate)
phoenix.character.Message.Select.bind(phoenix.character.Handlers.onSelect)
phoenix.character.Message.Delete.bind(phoenix.character.Handlers.onDelete)
phoenix.character.Message.PreviewRestore.bind(phoenix.character.Handlers.onPreviewRestore)
addEventHandler("onPlayerDisconnect", function(playerId, reason) { phoenix.character.Handlers.onPlayerDisconnect(playerId, reason) })
