phoenix.social.Structure <- {
	interactionRange = 420.0
	partyExpRange = 5000.0
	maxTradeGold = 999999999
	trades = {}
	friends = {}
	fakeFriends = {}
	partyByPlayer = {}
	parties = {}
	recentCombat = {}
	schemaReady = false
	schemaLoading = false
	nextTradeId = 1
	nextPartyId = 1
	_awardingParty = false
	testNpcTradeGold = 1000

	function notify(playerId, kind, title, text) {
		try { phoenix.notification.notify(playerId, kind, title, text, 3500) } catch (e) {
			try { sendMessageToPlayer(playerId, kind == "error" ? 255 : 160, kind == "error" ? 90 : 220, 120, "[" + title + "] " + text) } catch (e2) {}
		}
	}

	function send(playerId, action, success = true, error = "", payload = null) {
		try {
			local msg = phoenix.social.Message.State()
			msg.action = action
			msg.success = success
			msg.error = error
			msg.payload = payload
			msg.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}

	function charOf(playerId) {
		try { return phoenix.character.Structure.getActive(playerId) } catch (e) {}
		return null
	}

	function charId(playerId) {
		local rec = phoenix.social.Structure.charOf(playerId)
		return rec != null ? rec.id : 0
	}

	function playerName(playerId) {
		local rec = phoenix.social.Structure.charOf(playerId)
		if (rec != null && "name" in rec && rec.name != null && rec.name != "") return rec.name
		try { return getPlayerName(playerId) } catch (e) {}
		return "Gracz " + playerId
	}

	function dist(a, b) {
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function isNear(a, b, range) {
		local pa = null
		local pb = null
		try { pa = getPlayerPosition(a); pb = getPlayerPosition(b) } catch (e) { return false }
		if (pa == null || pb == null) return false
		local wa = ""
		local wb = ""
		try { wa = getPlayerWorld(a) } catch (e2) {}
		try { wb = getPlayerWorld(b) } catch (e3) {}
		if (wa != null && wb != null && wa != "" && wb != "" && wa != wb) return false
		return phoenix.social.Structure.dist(pa, pb) <= range
	}

	function testPlayerNpcEntry(targetId) {
		try {
			if (!("npc" in phoenix) || phoenix.npc == null || !("Spawn" in phoenix.npc) || phoenix.npc.Spawn == null) return null
			local entry = phoenix.npc.Spawn._liveByNpcId(targetId)
			if (entry == null || !("row" in entry) || entry.row == null) return null
			local marker = phoenix.npc.Spawn._metadataInt(entry.row.metadata, "testPlayer", 0)
			if (marker <= 0) return null
			return entry
		} catch (e) {}
		return null
	}

	function isTestPlayerNpc(targetId) {
		return phoenix.social.Structure.testPlayerNpcEntry(targetId) != null
	}

	function canInteract(playerId, targetId) {
		if (targetId == playerId) return false
		local fakeTarget = phoenix.social.Structure.isTestPlayerNpc(targetId)
		if (!fakeTarget) {
			try { if (!isPlayerConnected(targetId)) return false } catch (e) { return false }
		}
		try {
			local now = getTickCount()
			if ((playerId in phoenix.social.Structure.recentCombat) && now - phoenix.social.Structure.recentCombat[playerId] < 5000) return false
			if (!fakeTarget && (targetId in phoenix.social.Structure.recentCombat) && now - phoenix.social.Structure.recentCombat[targetId] < 5000) return false
		} catch (eCombat) {}
		try { if (getPlayerWeaponMode(playerId) != WEAPONMODE_NONE) return false } catch (e2) {}
		if (!fakeTarget) { try { if (getPlayerWeaponMode(targetId) != WEAPONMODE_NONE) return false } catch (e3) {} }
		return phoenix.social.Structure.isNear(playerId, targetId, phoenix.social.Structure.interactionRange)
	}

	function playerEntry(playerId) {
		local fake = phoenix.social.Structure.testPlayerNpcEntry(playerId)
		if (fake != null) {
			local label = "Testowy gracz"
			try { label = fake.row.name != null && fake.row.name != "" ? fake.row.name : getPlayerName(playerId) } catch (eName) {}
			return {
				playerId = playerId,
				characterId = 0,
				name = label,
				level = fake.row.level > 0 ? fake.row.level : 1,
				headModel = fake.row.headModel != null ? fake.row.headModel : "HUM_HEAD_PONY",
				face = fake.row.headTex != null ? fake.row.headTex : 0,
				testPlayerNpc = true
			}
		}
		local record = phoenix.social.Structure.charOf(playerId)
		return {
			playerId = playerId,
			characterId = record != null ? record.id : 0,
			name = phoenix.social.Structure.playerName(playerId),
			level = record != null && record.level > 0 ? record.level : 1,
			headModel = record != null && record.headModel != null ? record.headModel : "",
			face = record != null && record.face != null ? record.face : 0,
			testPlayerNpc = false
		}
	}

	function esc(value) {
		try { return ORM.engine.escape(value == null ? "" : value.tostring()) } catch (e) {}
		return value == null ? "" : value.tostring()
	}

	function ensureSchema(callback = null) {
		if (phoenix.social.Structure.schemaReady) { if (callback != null) callback(); return }
		if (phoenix.social.Structure.schemaLoading) { if (callback != null) setTimer(callback, 350, 1); return }
		phoenix.social.Structure.schemaLoading = true
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_social_friends` (`id` INT(11) NOT NULL AUTO_INCREMENT,`characterId` INT(11) NOT NULL,`friendCharacterId` INT(11) NOT NULL,`friendName` VARCHAR(64) NOT NULL DEFAULT '',`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY (`id`),UNIQUE KEY `social_friend_unique` (`characterId`,`friendCharacterId`),KEY `social_friend_character_idx` (`characterId`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
		try { ORM.engine.executeAsync(sql, function(_) { phoenix.social.Structure.schemaReady = true; phoenix.social.Structure.schemaLoading = false; if (callback != null) callback() }) }
		catch (e) { phoenix.social.Structure.schemaLoading = false; if (callback != null) callback() }
	}

	function loadFriends(characterId, callback) {
		phoenix.social.Structure.ensureSchema(function() {
			local map = {}
			try {
				local sql = "SELECT sf.`friendCharacterId`,sf.`friendName`,pc.`level`,pc.`headModel`,pc.`face` FROM `phoenix_social_friends` sf LEFT JOIN `phoenix_characters` pc ON pc.`id`=sf.`friendCharacterId` WHERE sf.`characterId`=" + characterId + " ORDER BY sf.`friendName` ASC"
				ORM.engine.executeAsync(sql, function(rows) {
					if (rows != null) foreach (row in rows) {
						map[row.friendCharacterId.tointeger()] <- {
							name = row.friendName,
							level = row.level != null && row.level > 0 ? row.level : 1,
							headModel = row.headModel != null ? row.headModel : "",
							face = row.face != null ? row.face : 0
						}
					}
					phoenix.social.Structure.friends[characterId] <- map
					if (callback != null) callback(map)
				})
			} catch (e) { phoenix.social.Structure.friends[characterId] <- map; if (callback != null) callback(map) }
		})
	}

	function findOnlineByCharacter(characterId) {
		local slots = 0
		try { slots = getMaxSlots() } catch (e) { slots = 128 }
		for (local pid = 0; pid < slots; pid += 1) {
			try { if (!isPlayerConnected(pid)) continue } catch (e2) { continue }
			if (phoenix.social.Structure.charId(pid) == characterId) return pid
		}
		return -1
	}

	function onlinePlayers(viewerId) {
		local list = []
		local slots = 0
		try { slots = getMaxSlots() } catch (e) { slots = 128 }
		for (local pid = 0; pid < slots; pid += 1) {
			if (pid == viewerId) continue
			try { if (!isPlayerConnected(pid)) continue } catch (e) { continue }
			local charId = phoenix.social.Structure.charId(pid)
			if (charId <= 0) continue
			local near = false
			try { near = phoenix.social.Structure.isNear(viewerId, pid, phoenix.social.Structure.partyExpRange) } catch (e2) {}
			local entry = phoenix.social.Structure.playerEntry(pid)
			entry.near <- near
			list.append(entry)
		}
		return list
	}

	function tradeOf(playerId) {
		foreach (_id, session in phoenix.social.Structure.trades) {
			if (session.a == playerId || session.b == playerId) return session
		}
		return null
	}

	function emptyOffer() {
		return { items = [], gold = 0, accepted = false }
	}

	function testNpcOffer() {
		return { items = [{ itemId = 0, amount = phoenix.social.Structure.testNpcTradeGold, name = "Zloto", instance = "ITMI_GOLD", visual = "ITMI_GOLD.MRM", quality = PhoenixItemQuality.Common, upgrade = 0, testNpc = true }], gold = 0, accepted = true }
	}

	function findTradeByPlayers(a, b) {
		foreach (_id, session in phoenix.social.Structure.trades) {
			if ((session.a == a && session.b == b) || (session.a == b && session.b == a)) return session
		}
		return null
	}

	function startTrade(playerId, targetId) {
		if (!phoenix.social.Structure.canInteract(playerId, targetId)) { phoenix.social.Structure.send(playerId, "error", false, "tooFar", null); return }
		if (phoenix.social.Structure.tradeOf(playerId) != null || phoenix.social.Structure.tradeOf(targetId) != null) { phoenix.social.Structure.send(playerId, "error", false, "tradeBusy", null); return }
		local id = phoenix.social.Structure.nextTradeId++
		local fakeTarget = phoenix.social.Structure.isTestPlayerNpc(targetId)
		local session = { id = id, a = playerId, b = targetId, open = true, offers = {}, testPlayerNpcTrade = fakeTarget }
		session.offers[playerId] <- phoenix.social.Structure.emptyOffer()
		session.offers[targetId] <- fakeTarget ? phoenix.social.Structure.testNpcOffer() : phoenix.social.Structure.emptyOffer()
		phoenix.social.Structure.trades[id] <- session
		phoenix.social.Structure.emitTrade(session, "tradeOpen")
	}

	function offerFor(session, playerId) {
		if (!(playerId in session.offers)) session.offers[playerId] <- phoenix.social.Structure.emptyOffer()
		return session.offers[playerId]
	}

	function resetAccept(session) {
		foreach (_pid, offer in session.offers) offer.accepted = false
		if (("testPlayerNpcTrade" in session) && session.testPlayerNpcTrade) {
			local fakeId = session.b
			try { phoenix.social.Structure.offerFor(session, fakeId).accepted = true } catch (e) {}
		}
	}

	function setTradeGold(playerId, gold) {
		local session = phoenix.social.Structure.tradeOf(playerId)
		if (session == null) return
		if (gold < 0) gold = 0
		if (gold > phoenix.social.Structure.maxTradeGold) gold = phoenix.social.Structure.maxTradeGold
		local available = phoenix.social.Structure.goldOf(playerId)
		if (gold > available) gold = available
		local offer = phoenix.social.Structure.offerFor(session, playerId)
		offer.gold = gold
		phoenix.social.Structure.resetAccept(session)
		phoenix.social.Structure.emitTrade(session, "tradeUpdate")
	}

	function setTradeItem(playerId, itemId, amount) {
		local session = phoenix.social.Structure.tradeOf(playerId)
		if (session == null) return
		local rec = phoenix.social.Structure.findItem(playerId, itemId)
		if (rec == null || rec.equipped == 1) { phoenix.social.Structure.send(playerId, "error", false, "badItem", null); return }
		if (amount < 0) amount = 0
		if (amount > rec.amount) amount = rec.amount
		local offer = phoenix.social.Structure.offerFor(session, playerId)
		for (local i = offer.items.len() - 1; i >= 0; i -= 1) {
			if (offer.items[i].itemId == itemId) offer.items.remove(i)
		}
		if (amount > 0) {
			local visual = ""
			try { local scheme = phoenix.item.find(rec.instanceId); if (scheme != null && "visual" in scheme && scheme.visual != null) visual = scheme.visual } catch (eVisual) {}
			offer.items.append({ itemId = itemId, amount = amount, name = phoenix.social.Structure.itemName(rec), instance = rec.instanceId, visual = visual, quality = rec.quality, upgrade = rec.upgrade })
		}
		phoenix.social.Structure.resetAccept(session)
		phoenix.social.Structure.emitTrade(session, "tradeUpdate")
	}

	function acceptTrade(playerId) {
		local session = phoenix.social.Structure.tradeOf(playerId)
		if (session == null) return
		phoenix.social.Structure.offerFor(session, playerId).accepted = true
		if (phoenix.social.Structure.offerFor(session, session.a).accepted && phoenix.social.Structure.offerFor(session, session.b).accepted) {
			phoenix.social.Structure.finishTrade(session)
		} else phoenix.social.Structure.emitTrade(session, "tradeUpdate")
	}

	function cancelTrade(playerId, reason = "cancel") {
		local session = phoenix.social.Structure.tradeOf(playerId)
		if (session == null) return
		phoenix.social.Structure.closeTrade(session, reason)
	}

	function closeTrade(session, reason) {
		if (session == null) return
		local payload = { reason = reason }
		phoenix.social.Structure.send(session.a, "tradeClosed", false, reason, payload)
		if (!("testPlayerNpcTrade" in session) || !session.testPlayerNpcTrade) phoenix.social.Structure.send(session.b, "tradeClosed", false, reason, payload)
		try { delete phoenix.social.Structure.trades[session.id] } catch (e) {}
	}

	function findItem(playerId, itemId) {
		local charId = phoenix.social.Structure.charId(playerId)
		if (charId <= 0) return null
		local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, charId)
		if (inv == null) return null
		foreach (rec in inv.items) if (rec.id == itemId) return rec
		return null
	}

	function itemName(rec) {
		try { local scheme = phoenix.item.find(rec.instanceId); if (scheme != null) return scheme.name } catch (e) {}
		return rec.instanceId
	}

	function goldOf(playerId) {
		local charId = phoenix.social.Structure.charId(playerId)
		if (charId <= 0) return 0
		try { return phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, charId, "ITMI_GOLD") } catch (e) {}
		return 0
	}

	function setGold(playerId, gold) {
		local charId = phoenix.social.Structure.charId(playerId)
		if (charId <= 0) return false
		local current = phoenix.social.Structure.goldOf(playerId)
		local diff = gold - current
		if (diff > 0) {
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, charId, "ITMI_GOLD", { amount = diff, quality = PhoenixItemQuality.Common, upgrade = 0, source = "gold" }, function(_) {
				try { phoenix.item.Structure.sendInventorySnapshot(playerId, charId) } catch (e) {}
			})
			return true
		}
		if (diff < 0) {
			phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, charId, "ITMI_GOLD", -diff, function(_) {
				try { phoenix.item.Structure.sendInventorySnapshot(playerId, charId) } catch (e) {}
			})
			return true
		}
		return true
	}

	function transferGold(fromPid, toPid, amount, callback) {
		if (amount <= 0) { callback(true); return }
		local fromChar = phoenix.social.Structure.charId(fromPid)
		local toChar = phoenix.social.Structure.charId(toPid)
		if (fromChar <= 0 || toChar <= 0) { callback(false); return }
		phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, fromChar, "ITMI_GOLD", amount, function(ok) {
			if (!ok) { callback(false); return }
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, toChar, "ITMI_GOLD", { amount = amount, quality = PhoenixItemQuality.Common, upgrade = 0, source = "trade" }, function(_) {
				try { phoenix.item.Structure.sendInventorySnapshot(fromPid, fromChar) } catch (e) {}
				try { phoenix.item.Structure.sendInventorySnapshot(toPid, toChar) } catch (e2) {}
				callback(true)
			})
		})
	}

	function validateOffer(playerId, offer) {
		if (phoenix.social.Structure.goldOf(playerId) < offer.gold) return false
		foreach (entry in offer.items) {
			local rec = phoenix.social.Structure.findItem(playerId, entry.itemId)
			if (rec == null || rec.equipped == 1 || rec.amount < entry.amount) return false
		}
		return true
	}

	function transferItem(fromPid, toPid, itemId, amount, callback) {
		local fromChar = phoenix.social.Structure.charId(fromPid)
		local toChar = phoenix.social.Structure.charId(toPid)
		local rec = phoenix.social.Structure.findItem(fromPid, itemId)
		if (rec == null || rec.amount < amount || rec.equipped == 1 || fromChar <= 0 || toChar <= 0) { callback(false); return }
		local opts = { amount = amount, quality = rec.quality, upgrade = rec.upgrade, source = "trade" }
		local instance = rec.instanceId
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, fromChar, itemId, amount, function(ok) {
			if (!ok) { callback(false); return }
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, toChar, instance, opts, function(_newRec) {
				try { phoenix.item.Structure.sendInventorySnapshot(fromPid, fromChar) } catch (e) {}
				try { phoenix.item.Structure.sendInventorySnapshot(toPid, toChar) } catch (e2) {}
				callback(true)
			})
		})
	}

	function transferOfferItems(session, fromPid, toPid, items, index, done) {
		if (index >= items.len()) { done(true); return }
		local item = items[index]
		phoenix.social.Structure.transferItem(fromPid, toPid, item.itemId, item.amount, function(ok) {
			if (!ok) { phoenix.social.Structure.closeTrade(session, "itemChanged"); return }
			phoenix.social.Structure.transferOfferItems(session, fromPid, toPid, items, index + 1, done)
		})
	}

	function consumeOfferItems(session, fromPid, items, index, done) {
		if (index >= items.len()) { done(true); return }
		local item = items[index]
		local fromChar = phoenix.social.Structure.charId(fromPid)
		if (fromChar <= 0) { done(false); return }
		local rec = phoenix.social.Structure.findItem(fromPid, item.itemId)
		if (rec == null || rec.amount < item.amount || rec.equipped == 1) { done(false); return }
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, fromChar, item.itemId, item.amount, function(ok) {
			if (!ok) { done(false); return }
			try { phoenix.item.Structure.sendInventorySnapshot(fromPid, fromChar) } catch (e) {}
			phoenix.social.Structure.consumeOfferItems(session, fromPid, items, index + 1, done)
		})
	}

	function finishTrade(session) {
		if (!phoenix.social.Structure.isNear(session.a, session.b, phoenix.social.Structure.interactionRange + 200.0)) { phoenix.social.Structure.closeTrade(session, "tooFar"); return }
		local offerA = phoenix.social.Structure.offerFor(session, session.a)
		local offerB = phoenix.social.Structure.offerFor(session, session.b)
		if (("testPlayerNpcTrade" in session) && session.testPlayerNpcTrade) {
			local charId = phoenix.social.Structure.charId(session.a)
			if (charId <= 0) { phoenix.social.Structure.closeTrade(session, "changed"); return }
			if (!phoenix.social.Structure.validateOffer(session.a, offerA)) { phoenix.social.Structure.closeTrade(session, "changed"); return }
			phoenix.social.Structure.consumeOfferItems(session, session.a, offerA.items, 0, function(itemsOk) {
				if (!itemsOk) { phoenix.social.Structure.closeTrade(session, "changed"); return }
				phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, charId, "ITMI_GOLD", offerA.gold, function(goldOk) {
					if (!goldOk) { phoenix.social.Structure.closeTrade(session, "changed"); return }
					phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, charId, "ITMI_GOLD", { amount = phoenix.social.Structure.testNpcTradeGold, quality = PhoenixItemQuality.Common, upgrade = 0, source = "test-player-trade" }, function(_) {
						try { phoenix.item.Structure.sendInventorySnapshot(session.a, charId) } catch (e) {}
						phoenix.social.Structure.send(session.a, "tradeClosed", true, "done", { reason = "done" })
						try { delete phoenix.social.Structure.trades[session.id] } catch (e2) {}
					})
				})
			})
			return
		}
		if (!phoenix.social.Structure.validateOffer(session.a, offerA) || !phoenix.social.Structure.validateOffer(session.b, offerB)) { phoenix.social.Structure.closeTrade(session, "changed"); return }
		phoenix.social.Structure.transferGold(session.a, session.b, offerA.gold, function(goldOkA) {
			if (!goldOkA) { phoenix.social.Structure.closeTrade(session, "changed"); return }
			phoenix.social.Structure.transferGold(session.b, session.a, offerB.gold, function(goldOkB) {
				if (!goldOkB) { phoenix.social.Structure.closeTrade(session, "changed"); return }
				phoenix.social.Structure.transferOfferItems(session, session.a, session.b, offerA.items, 0, function(okA) {
					if (!okA) return
					phoenix.social.Structure.transferOfferItems(session, session.b, session.a, offerB.items, 0, function(okB) {
						if (!okB) return
						phoenix.social.Structure.send(session.a, "tradeClosed", true, "done", { reason = "done" })
						phoenix.social.Structure.send(session.b, "tradeClosed", true, "done", { reason = "done" })
						try { delete phoenix.social.Structure.trades[session.id] } catch (e) {}
					})
				})
			})
		})
	}

	function emitTrade(session, action) {
		local payloadA = phoenix.social.Structure.tradePayload(session, session.a)
		phoenix.social.Structure.send(session.a, action, true, "", payloadA)
		if (!("testPlayerNpcTrade" in session) || !session.testPlayerNpcTrade) {
			local payloadB = phoenix.social.Structure.tradePayload(session, session.b)
			phoenix.social.Structure.send(session.b, action, true, "", payloadB)
		}
	}

	function tradePayload(session, viewer) {
		local other = session.a == viewer ? session.b : session.a
		return {
			id = session.id,
			self = phoenix.social.Structure.playerEntry(viewer),
			other = phoenix.social.Structure.playerEntry(other),
			ownOffer = phoenix.social.Structure.offerFor(session, viewer),
			otherOffer = phoenix.social.Structure.offerFor(session, other)
		}
	}

	function addFriend(playerId, targetId) {
		if (phoenix.social.Structure.isTestPlayerNpc(targetId)) {
			local entry = phoenix.social.Structure.playerEntry(targetId)
			if (!(playerId in phoenix.social.Structure.fakeFriends)) phoenix.social.Structure.fakeFriends[playerId] <- {}
			phoenix.social.Structure.fakeFriends[playerId][targetId] <- entry
			phoenix.social.Structure.notify(playerId, "success", "Znajomi", "Dodano znajomego: " + entry.name)
			phoenix.social.Structure.pushSocial(playerId)
			return
		}
		local cid = phoenix.social.Structure.charId(playerId)
		local tid = phoenix.social.Structure.charId(targetId)
		if (cid <= 0 || tid <= 0 || cid == tid) { phoenix.social.Structure.send(playerId, "error", false, "badFriend", null); return }
		local name = phoenix.social.Structure.playerName(targetId)
		local targetRecord = phoenix.social.Structure.charOf(targetId)
		if (!(cid in phoenix.social.Structure.friends)) phoenix.social.Structure.friends[cid] <- {}
		phoenix.social.Structure.friends[cid][tid] <- {
			name = name,
			level = targetRecord != null && targetRecord.level > 0 ? targetRecord.level : 1,
			headModel = targetRecord != null && targetRecord.headModel != null ? targetRecord.headModel : "",
			face = targetRecord != null && targetRecord.face != null ? targetRecord.face : 0
		}
		phoenix.social.Structure.ensureSchema(function() {
			local sql = "INSERT IGNORE INTO `phoenix_social_friends` (`characterId`,`friendCharacterId`,`friendName`) VALUES (" + cid + "," + tid + ",'" + phoenix.social.Structure.esc(name) + "')"
			try { ORM.engine.executeAsync(sql, function(_) { phoenix.social.Structure.pushSocial(playerId) }) } catch (e) { phoenix.social.Structure.pushSocial(playerId) }
		})
		phoenix.social.Structure.notify(playerId, "success", "Znajomi", "Dodano znajomego: " + name)
	}

	function sendDm(playerId, targetId, text) {
		if (text == null || text == "") return
		if (targetId <= 0) return
		local payload = { from = phoenix.social.Structure.playerEntry(playerId), to = phoenix.social.Structure.playerEntry(targetId), text = text }
		phoenix.social.Structure.send(playerId, "dm", true, "", payload)
		phoenix.social.Structure.send(targetId, "dm", true, "", payload)
		phoenix.social.Structure.notify(targetId, "info", "Prywatna wiadomosc", phoenix.social.Structure.playerName(playerId) + ": " + text)
	}

	function partyIdOf(playerId) {
		return (playerId in phoenix.social.Structure.partyByPlayer) ? phoenix.social.Structure.partyByPlayer[playerId] : 0
	}

	function inviteParty(playerId, targetId) {
		if (!phoenix.social.Structure.canInteract(playerId, targetId)) { phoenix.social.Structure.send(playerId, "error", false, "tooFar", null); return }
		if (phoenix.social.Structure.isTestPlayerNpc(targetId)) {
			local partyId = phoenix.social.Structure.partyIdOf(playerId)
			if (partyId <= 0) {
				partyId = phoenix.social.Structure.nextPartyId++
				phoenix.social.Structure.parties[partyId] <- { id = partyId, leader = playerId, members = {} }
				phoenix.social.Structure.parties[partyId].members[playerId] <- true
				phoenix.social.Structure.partyByPlayer[playerId] <- partyId
			}
			phoenix.social.Structure.parties[partyId].members[targetId] <- true
			phoenix.social.Structure.partyByPlayer[targetId] <- partyId
			phoenix.social.Structure.pushSocial(playerId)
			phoenix.social.Structure.notify(playerId, "success", "Party", "Testowy gracz dolaczyl do party.")
			return
		}
		phoenix.social.Structure.send(targetId, "partyInvite", true, "", { from = phoenix.social.Structure.playerEntry(playerId) })
		phoenix.social.Structure.notify(playerId, "info", "Party", "Wyslano zaproszenie do party.")
	}

	function acceptParty(playerId, leaderId) {
		if (leaderId <= 0 || !phoenix.social.Structure.isNear(playerId, leaderId, phoenix.social.Structure.partyExpRange)) { phoenix.social.Structure.send(playerId, "error", false, "tooFar", null); return }
		local partyId = phoenix.social.Structure.partyIdOf(leaderId)
		if (partyId <= 0) {
			partyId = phoenix.social.Structure.nextPartyId++
			phoenix.social.Structure.parties[partyId] <- { id = partyId, leader = leaderId, members = {} }
			phoenix.social.Structure.parties[partyId].members[leaderId] <- true
			phoenix.social.Structure.partyByPlayer[leaderId] <- partyId
		}
		phoenix.social.Structure.parties[partyId].members[playerId] <- true
		phoenix.social.Structure.partyByPlayer[playerId] <- partyId
		phoenix.social.Structure.pushParty(partyId)
	}

	function leaveParty(playerId) {
		local partyId = phoenix.social.Structure.partyIdOf(playerId)
		if (partyId <= 0 || !(partyId in phoenix.social.Structure.parties)) return
		local party = phoenix.social.Structure.parties[partyId]
		try { delete party.members[playerId] } catch (e) {}
		try { delete phoenix.social.Structure.partyByPlayer[playerId] } catch (e2) {}
		local first = -1
		foreach (pid, _v in party.members) { first = pid; break }
		if (first < 0) { try { delete phoenix.social.Structure.parties[partyId] } catch (e3) {} }
		else { party.leader = first; phoenix.social.Structure.pushParty(partyId) }
		phoenix.social.Structure.pushSocial(playerId)
	}

	function partyMembers(playerId) {
		local partyId = phoenix.social.Structure.partyIdOf(playerId)
		local result = []
		if (partyId <= 0 || !(partyId in phoenix.social.Structure.parties)) return result
		foreach (pid, _v in phoenix.social.Structure.parties[partyId].members) {
			try { if (isPlayerConnected(pid)) result.append(pid) } catch (e) {}
		}
		return result
	}

	function pushParty(partyId) {
		if (!(partyId in phoenix.social.Structure.parties)) return
		local members = []
		foreach (pid, _v in phoenix.social.Structure.parties[partyId].members) members.append(phoenix.social.Structure.playerEntry(pid))
		foreach (pid, _v in phoenix.social.Structure.parties[partyId].members) phoenix.social.Structure.pushSocial(pid)
	}

	function pushSocial(playerId) {
		local cid = phoenix.social.Structure.charId(playerId)
		if (cid > 0 && !(cid in phoenix.social.Structure.friends)) {
			phoenix.social.Structure.loadFriends(cid, function(_) { phoenix.social.Structure.pushSocial(playerId) })
			return
		}
		local list = []
		if (cid in phoenix.social.Structure.friends) {
			foreach (friendId, data in phoenix.social.Structure.friends[cid]) {
				local friendName = typeof data == "table" ? data.name : data
				local onlinePid = phoenix.social.Structure.findOnlineByCharacter(friendId)
				if (onlinePid >= 0) {
					local onlineEntry = phoenix.social.Structure.playerEntry(onlinePid)
					onlineEntry.characterId = friendId
					list.append(onlineEntry)
				} else {
					list.append({
						characterId = friendId,
						playerId = -1,
						name = friendName,
						level = typeof data == "table" ? data.level : 1,
						headModel = typeof data == "table" ? data.headModel : "",
						face = typeof data == "table" ? data.face : 0,
						testPlayerNpc = false
					})
				}
			}
		}
		if (playerId in phoenix.social.Structure.fakeFriends) {
			foreach (_pid, entry in phoenix.social.Structure.fakeFriends[playerId]) list.append(entry)
		}
		local partyState = { partyId = 0, leaderId = -1, maxMembers = 4, members = [] }
		try {
			if ("Party" in phoenix.social && phoenix.social.Party != null)
				partyState = phoenix.social.Party.socialPayload(playerId)
		} catch (eParty) {}
		phoenix.social.Structure.send(playerId, "socialState", true, "", {
			self = phoenix.social.Structure.playerEntry(playerId),
			friends = list,
			party = partyState.members,
			partyId = partyState.partyId,
			partyLeaderId = partyState.leaderId,
			partyMaxMembers = partyState.maxMembers,
			players = phoenix.social.Structure.onlinePlayers(playerId)
		})
	}

	function distributeExperience(playerId, amount) {
		if (phoenix.social.Structure._awardingParty) return false
		local members = phoenix.social.Structure.partyMembers(playerId)
		local eligible = []
		foreach (pid in members) {
			if (pid == playerId || phoenix.social.Structure.isNear(playerId, pid, phoenix.social.Structure.partyExpRange)) eligible.append(pid)
		}
		if (eligible.len() <= 1) return false
		local share = amount / eligible.len()
		if (share <= 0) share = 1
		phoenix.social.Structure._awardingParty = true
		foreach (pid in eligible) {
			try { phoenix.player.Progression.awardExperience(pid, share) } catch (e) {}
		}
		phoenix.social.Structure._awardingParty = false
		return true
	}

	function onDisconnect(playerId) {
		phoenix.social.Structure.cancelTrade(playerId, "disconnect")
		try { phoenix.social.Party.onDisconnect(playerId) } catch (eParty) {}
		try { delete phoenix.social.Structure.recentCombat[playerId] } catch (e) {}
	}
}
