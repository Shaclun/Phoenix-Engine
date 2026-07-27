phoenix.social.Party <- {
	maxMembers = 4
	inviteTtlMs = 30000
	snapshotIntervalMs = 500
	invitesByTarget = {}
	nextInviteId = 1
	nextJoinSeq = 1
	lastSnapshot = {}

	function now() {
		try { return getTickCount() } catch (e) {}
		return 0
	}

	function active(playerId) {
		try { return phoenix.character.Structure.getActive(playerId) } catch (e) {}
		return null
	}

	function connectedAs(playerId, characterId) {
		try { if (!isPlayerConnected(playerId)) return false } catch (e) { return false }
		local record = phoenix.social.Party.active(playerId)
		return record != null && record.id == characterId
	}

	function memberIsLive(playerId, member) {
		if (member == null) return false
		if (("testPlayerNpc" in member) && member.testPlayerNpc) {
			local entry = phoenix.social.Structure.testPlayerNpcEntry(playerId)
			if (entry == null) return false
			return !("alive" in entry) || entry.alive
		}
		return phoenix.social.Party.connectedAs(playerId, member.characterId)
	}

	function partyIdOf(playerId) {
		if (!(playerId in phoenix.social.Structure.partyByPlayer)) return 0
		local partyId = phoenix.social.Structure.partyByPlayer[playerId]
		if (!(partyId in phoenix.social.Structure.parties)) {
			try { delete phoenix.social.Structure.partyByPlayer[playerId] } catch (e) {}
			return 0
		}
		local party = phoenix.social.Structure.parties[partyId]
		if (!(playerId in party.members)) {
			try { delete phoenix.social.Structure.partyByPlayer[playerId] } catch (e2) {}
			return 0
		}
		local member = party.members[playerId]
		if (!phoenix.social.Party.memberIsLive(playerId, member)) return 0
		return partyId
	}

	function orderedMembers(party) {
		local result = []
		if (party == null) return result
		foreach (playerId, member in party.members) {
			if (phoenix.social.Party.memberIsLive(playerId, member)) {
				result.push({
					playerId = playerId,
					characterId = member.characterId,
					joinSeq = member.joinSeq,
					testPlayerNpc = ("testPlayerNpc" in member) && member.testPlayerNpc
				})
			}
		}
		result.sort(function(a, b) { return a.joinSeq <=> b.joinSeq })
		return result
	}

	function countMembers(party) {
		return phoenix.social.Party.orderedMembers(party).len()
	}

	function createParty(leaderId) {
		local record = phoenix.social.Party.active(leaderId)
		if (record == null) return null
		local id = phoenix.social.Structure.nextPartyId++
		local party = { id = id, leader = leaderId, members = {}, remainderCursor = 0 }
		party.members[leaderId] <- { characterId = record.id, joinSeq = phoenix.social.Party.nextJoinSeq++ }
		phoenix.social.Structure.parties[id] <- party
		phoenix.social.Structure.partyByPlayer[leaderId] <- id
		return party
	}

	function invalidateInvite(targetId, notifyTarget = false) {
		if (!(targetId in phoenix.social.Party.invitesByTarget)) return
		try { delete phoenix.social.Party.invitesByTarget[targetId] } catch (e) {}
		if (notifyTarget) phoenix.social.Structure.send(targetId, "partyInviteClosed", false, "expired", null)
	}

	function addTestPlayerNpc(playerId, targetId, npcEntry) {
		if (phoenix.social.Party.partyIdOf(targetId) > 0) {
			phoenix.social.Structure.send(playerId, "error", false, "alreadyInParty", null)
			return
		}
		local partyId = phoenix.social.Party.partyIdOf(playerId)
		local party = partyId > 0 ? phoenix.social.Structure.parties[partyId] : phoenix.social.Party.createParty(playerId)
		if (party == null) return
		if (party.leader != playerId) {
			phoenix.social.Structure.send(playerId, "error", false, "leaderOnly", null)
			return
		}
		if (targetId in party.members) {
			phoenix.social.Structure.send(playerId, "error", false, "alreadyInParty", null)
			return
		}
		if (phoenix.social.Party.countMembers(party) >= phoenix.social.Party.maxMembers) {
			phoenix.social.Structure.send(playerId, "error", false, "partyFull", null)
			return
		}
		party.members[targetId] <- { characterId = 0, joinSeq = phoenix.social.Party.nextJoinSeq++, testPlayerNpc = true }
		phoenix.social.Structure.partyByPlayer[targetId] <- party.id
		phoenix.social.Party.push(party.id, true)
		phoenix.social.Structure.notify(playerId, "success", "Party", "Testowy gracz dołączył do party.")
	}

	function invite(playerId, targetId) {
		local inviter = phoenix.social.Party.active(playerId)
		if (inviter == null || playerId == targetId) {
			phoenix.social.Structure.send(playerId, "error", false, "badPartyTarget", null)
			return
		}
		if (!phoenix.social.Structure.canInteract(playerId, targetId)) {
			phoenix.social.Structure.send(playerId, "error", false, "tooFar", null)
			return
		}
		local testNpc = phoenix.social.Structure.testPlayerNpcEntry(targetId)
		if (testNpc != null) {
			phoenix.social.Party.addTestPlayerNpc(playerId, targetId, testNpc)
			return
		}
		local target = phoenix.social.Party.active(targetId)
		if (target == null) {
			phoenix.social.Structure.send(playerId, "error", false, "badPartyTarget", null)
			return
		}
		if (phoenix.social.Party.partyIdOf(targetId) > 0) {
			phoenix.social.Structure.send(playerId, "error", false, "alreadyInParty", null)
			return
		}
		local partyId = phoenix.social.Party.partyIdOf(playerId)
		if (partyId > 0) {
			local party = phoenix.social.Structure.parties[partyId]
			if (party.leader != playerId) {
				phoenix.social.Structure.send(playerId, "error", false, "leaderOnly", null)
				return
			}
			if (phoenix.social.Party.countMembers(party) >= phoenix.social.Party.maxMembers) {
				phoenix.social.Structure.send(playerId, "error", false, "partyFull", null)
				return
			}
		}
		local inviteId = phoenix.social.Party.nextInviteId++
		local invite = {
			id = inviteId,
			inviterId = playerId,
			inviterCharacterId = inviter.id,
			targetId = targetId,
			targetCharacterId = target.id,
			expiresAt = phoenix.social.Party.now() + phoenix.social.Party.inviteTtlMs
		}
		phoenix.social.Party.invitesByTarget[targetId] <- invite
		phoenix.social.Structure.send(targetId, "partyInvite", true, "", {
			inviteId = inviteId,
			expiresIn = phoenix.social.Party.inviteTtlMs,
			from = phoenix.social.Structure.playerEntry(playerId)
		})
		phoenix.social.Structure.notify(playerId, "info", "Party", "Wysłano zaproszenie do party.")
	}

	function accept(playerId, inviteId) {
		if (!(playerId in phoenix.social.Party.invitesByTarget)) {
			phoenix.social.Structure.send(playerId, "error", false, "inviteMissing", null)
			return
		}
		local invite = phoenix.social.Party.invitesByTarget[playerId]
		if (invite.id != inviteId || invite.expiresAt < phoenix.social.Party.now()) {
			phoenix.social.Party.invalidateInvite(playerId, true)
			return
		}
		if (!phoenix.social.Party.connectedAs(playerId, invite.targetCharacterId) || !phoenix.social.Party.connectedAs(invite.inviterId, invite.inviterCharacterId)) {
			phoenix.social.Party.invalidateInvite(playerId, true)
			return
		}
		if (phoenix.social.Party.partyIdOf(playerId) > 0) {
			phoenix.social.Party.invalidateInvite(playerId)
			phoenix.social.Structure.send(playerId, "error", false, "alreadyInParty", null)
			return
		}
		local partyId = phoenix.social.Party.partyIdOf(invite.inviterId)
		local party = partyId > 0 ? phoenix.social.Structure.parties[partyId] : phoenix.social.Party.createParty(invite.inviterId)
		if (party == null || party.leader != invite.inviterId) {
			phoenix.social.Party.invalidateInvite(playerId, true)
			return
		}
		if (phoenix.social.Party.countMembers(party) >= phoenix.social.Party.maxMembers) {
			phoenix.social.Party.invalidateInvite(playerId)
			phoenix.social.Structure.send(playerId, "error", false, "partyFull", null)
			return
		}
		party.members[playerId] <- { characterId = invite.targetCharacterId, joinSeq = phoenix.social.Party.nextJoinSeq++ }
		phoenix.social.Structure.partyByPlayer[playerId] <- party.id
		phoenix.social.Party.invalidateInvite(playerId)
		phoenix.social.Party.push(party.id, true)
	}

	function decline(playerId, inviteId) {
		if (!(playerId in phoenix.social.Party.invitesByTarget)) return
		local invite = phoenix.social.Party.invitesByTarget[playerId]
		if (inviteId != 0 && invite.id != inviteId) return
		phoenix.social.Party.invalidateInvite(playerId)
		phoenix.social.Structure.send(playerId, "partyInviteClosed", true, "declined", null)
		if (phoenix.social.Party.connectedAs(invite.inviterId, invite.inviterCharacterId))
			phoenix.social.Structure.notify(invite.inviterId, "info", "Party", "Zaproszenie zostało odrzucone.")
	}

	function removeMember(playerId, reason = "leave") {
		local partyId = (playerId in phoenix.social.Structure.partyByPlayer) ? phoenix.social.Structure.partyByPlayer[playerId] : 0
		if (partyId <= 0 || !(partyId in phoenix.social.Structure.parties)) {
			try { delete phoenix.social.Structure.partyByPlayer[playerId] } catch (e) {}
			phoenix.social.Party.sendSnapshot(playerId, [], true)
			return
		}
		local party = phoenix.social.Structure.parties[partyId]
		local removedMember = (playerId in party.members) ? party.members[playerId] : null
		local removedWasTestNpc = removedMember != null && ("testPlayerNpc" in removedMember) && removedMember.testPlayerNpc
		try { delete party.members[playerId] } catch (e2) {}
		try { delete phoenix.social.Structure.partyByPlayer[playerId] } catch (e3) {}
		if (!removedWasTestNpc) {
			phoenix.social.Party.sendSnapshot(playerId, [], true)
			phoenix.social.Structure.pushSocial(playerId)
		}
		local members = phoenix.social.Party.orderedMembers(party)
		if (members.len() <= 1) {
			foreach (member in members) {
				try { delete phoenix.social.Structure.partyByPlayer[member.playerId] } catch (e4) {}
				if (!member.testPlayerNpc) {
					phoenix.social.Party.sendSnapshot(member.playerId, [], true)
					phoenix.social.Structure.pushSocial(member.playerId)
				}
			}
			try { delete phoenix.social.Structure.parties[partyId] } catch (e5) {}
			return
		}
		if (party.leader == playerId) party.leader = members[0].playerId
		phoenix.social.Party.push(partyId, true)
	}

	function leave(playerId) {
		phoenix.social.Party.removeMember(playerId, "leave")
	}

	function kick(leaderId, targetId) {
		local partyId = phoenix.social.Party.partyIdOf(leaderId)
		if (partyId <= 0) return
		local party = phoenix.social.Structure.parties[partyId]
		if (party.leader != leaderId) {
			phoenix.social.Structure.send(leaderId, "error", false, "leaderOnly", null)
			return
		}
		if (targetId == leaderId || !(targetId in party.members)) return
		local targetMember = party.members[targetId]
		local targetIsTestNpc = ("testPlayerNpc" in targetMember) && targetMember.testPlayerNpc
		phoenix.social.Party.removeMember(targetId, "kicked")
		if (!targetIsTestNpc) phoenix.social.Structure.notify(targetId, "warn", "Party", "Zostałeś usunięty z party.")
	}

	function transfer(leaderId, targetId) {
		local partyId = phoenix.social.Party.partyIdOf(leaderId)
		if (partyId <= 0) return
		local party = phoenix.social.Structure.parties[partyId]
		if (party.leader != leaderId) {
			phoenix.social.Structure.send(leaderId, "error", false, "leaderOnly", null)
			return
		}
		if (targetId == leaderId || !(targetId in party.members)) return
		local member = party.members[targetId]
		if (("testPlayerNpc" in member) && member.testPlayerNpc) return
		if (!phoenix.social.Party.connectedAs(targetId, member.characterId)) return
		party.leader = targetId
		phoenix.social.Party.push(partyId, true)
	}

	function memberPayload(playerId, party) {
		local member = (party != null && playerId in party.members) ? party.members[playerId] : null
		if (member != null && ("testPlayerNpc" in member) && member.testPlayerNpc) {
			local entry = phoenix.social.Structure.testPlayerNpcEntry(playerId)
			if (entry == null || entry.row == null) return null
			local row = entry.row
			local hpMax = row.hp > 0 ? row.hp : 100
			local hp = hpMax
			local mana = 0
			local manaMax = 0
			try { hp = getPlayerHealth(playerId) } catch (eHp) {}
			try { local runtimeHpMax = getPlayerMaxHealth(playerId); if (runtimeHpMax > 0) hpMax = runtimeHpMax } catch (eHpMax) {}
			try { mana = getPlayerMana(playerId) } catch (eMana) {}
			try { local runtimeManaMax = getPlayerMaxMana(playerId); if (runtimeManaMax > 0) manaMax = runtimeManaMax } catch (eManaMax) {}
			return {
				playerId = playerId,
				characterId = 0,
				isLeader = false,
				testPlayerNpc = true,
				name = row.name != null && row.name != "" ? row.name : "Testowy gracz",
				level = row.level > 0 ? row.level : 1,
				headModel = row.headModel != null ? row.headModel : "HUM_HEAD_PONY",
				face = row.headTex != null ? row.headTex : 0,
				hp = hp,
				hpMax = hpMax,
				mana = mana,
				manaMax = manaMax
			}
		}
		local record = phoenix.social.Party.active(playerId)
		if (record == null) return null
		local hp = record.hp
		local hpMax = record.hpMax > 0 ? record.hpMax : 100
		local mana = record.mana
		local manaMax = record.manaMax > 0 ? record.manaMax : 0
		try { hp = getPlayerHealth(playerId) } catch (eHp) {}
		try { local runtimeHpMax = getPlayerMaxHealth(playerId); if (runtimeHpMax > 0) hpMax = runtimeHpMax } catch (eHpMax) {}
		try { mana = getPlayerMana(playerId) } catch (eMana) {}
		try { local runtimeManaMax = getPlayerMaxMana(playerId); if (runtimeManaMax > 0) manaMax = runtimeManaMax } catch (eManaMax) {}
		return {
			playerId = playerId,
			characterId = record.id,
			isLeader = party != null && party.leader == playerId,
			testPlayerNpc = false,
			name = record.name,
			level = record.level,
			headModel = record.headModel != null ? record.headModel : "",
			face = record.face != null ? record.face : 0,
			hp = hp,
			hpMax = hpMax,
			mana = mana,
			manaMax = manaMax
		}
	}

	function socialPayload(playerId) {
		local result = { partyId = 0, leaderId = -1, maxMembers = phoenix.social.Party.maxMembers, members = [] }
		local partyId = phoenix.social.Party.partyIdOf(playerId)
		if (partyId <= 0) return result
		local party = phoenix.social.Structure.parties[partyId]
		result.partyId = partyId
		result.leaderId = party.leader
		foreach (member in phoenix.social.Party.orderedMembers(party)) {
			local payload = phoenix.social.Party.memberPayload(member.playerId, party)
			if (payload != null) result.members.push(payload)
		}
		return result
	}

	function snapshotFor(playerId) {
		local result = []
		local partyId = phoenix.social.Party.partyIdOf(playerId)
		if (partyId <= 0) return result
		local party = phoenix.social.Structure.parties[partyId]
		foreach (member in phoenix.social.Party.orderedMembers(party)) {
			if (member.playerId == playerId || result.len() >= 3) continue
			local payload = phoenix.social.Party.memberPayload(member.playerId, party)
			if (payload != null) result.push(payload)
		}
		return result
	}

	function fingerprint(members) {
		local value = ""
		foreach (entry in members) {
			value += entry.playerId + ":" + entry.characterId + ":" + (entry.isLeader ? 1 : 0) + ":" + entry.name + ":" + entry.level + ":" + entry.headModel + ":" + entry.face + ":" + entry.hp + ":" + entry.hpMax + ":" + entry.mana + ":" + entry.manaMax + "|"
		}
		return value
	}

	function sendSnapshot(playerId, members = null, force = false) {
		if (members == null) members = phoenix.social.Party.snapshotFor(playerId)
		local signature = phoenix.social.Party.fingerprint(members)
		if (!force && playerId in phoenix.social.Party.lastSnapshot && phoenix.social.Party.lastSnapshot[playerId] == signature) return
		phoenix.social.Party.lastSnapshot[playerId] <- signature
		phoenix.social.Structure.send(playerId, "partySnapshot", true, "", { members = members, maxMembers = phoenix.social.Party.maxMembers })
	}

	function push(partyId, force = false) {
		if (!(partyId in phoenix.social.Structure.parties)) return
		local party = phoenix.social.Structure.parties[partyId]
		foreach (member in phoenix.social.Party.orderedMembers(party)) {
			if (member.testPlayerNpc) continue
			if (force) phoenix.social.Structure.pushSocial(member.playerId)
			phoenix.social.Party.sendSnapshot(member.playerId, null, force)
		}
	}

	function sameExpContext(originId, playerId) {
		if (originId == playerId) return true
		try {
			if (getPlayerWorld(originId) != getPlayerWorld(playerId)) return false
			if (getPlayerVirtualWorld(originId) != getPlayerVirtualWorld(playerId)) return false
			return phoenix.social.Structure.isNear(originId, playerId, phoenix.social.Structure.partyExpRange)
		} catch (e) {}
		return false
	}

	function distributeExperience(originId, amount) {
		if (!phoenix.features.Settings.isEnabled("progression.partyExperience")) return false
		amount = amount.tointeger()
		if (amount <= 0) return true
		local partyId = phoenix.social.Party.partyIdOf(originId)
		if (partyId <= 0) return false
		local party = phoenix.social.Structure.parties[partyId]
		local eligible = []
		foreach (member in phoenix.social.Party.orderedMembers(party)) {
			local record = phoenix.social.Party.active(member.playerId)
			if (record == null || record.level >= phoenix.player.Progression.maxLevel) continue
			if (!phoenix.social.Party.sameExpContext(originId, member.playerId)) continue
			eligible.push(member.playerId)
		}
		if (eligible.len() == 0) return true
		local shares = []
		local baseShare = amount / eligible.len()
		local remainder = amount % eligible.len()
		for (local i = 0; i < eligible.len(); i += 1) shares.push(baseShare)
		local cursor = party.remainderCursor % eligible.len()
		for (local j = 0; j < remainder; j += 1) shares[(cursor + j) % eligible.len()] += 1
		party.remainderCursor = (cursor + (remainder > 0 ? remainder : 1)) % eligible.len()
		for (local k = 0; k < eligible.len(); k += 1) {
			if (shares[k] > 0) phoenix.player.Progression.awardExperienceDirect(eligible[k], shares[k])
		}
		return true
	}

	function onDisconnect(playerId) {
		phoenix.social.Party.invalidateInvite(playerId)
		local targets = []
		foreach (targetId, invite in phoenix.social.Party.invitesByTarget) {
			if (invite.inviterId == playerId) targets.push(targetId)
		}
		foreach (targetId in targets) phoenix.social.Party.invalidateInvite(targetId, true)
		phoenix.social.Party.removeMember(playerId, "disconnect")
		try { delete phoenix.social.Party.lastSnapshot[playerId] } catch (e) {}
	}

	function cleanupMissingMembers() {
		local missing = []
		foreach (_partyId, party in phoenix.social.Structure.parties) {
			foreach (playerId, member in party.members) {
				if (!phoenix.social.Party.memberIsLive(playerId, member)) missing.push(playerId)
			}
		}
		foreach (playerId in missing) phoenix.social.Party.removeMember(playerId, "missing")
	}

	function tick() {
		local nowValue = phoenix.social.Party.now()
		local expired = []
		foreach (targetId, invite in phoenix.social.Party.invitesByTarget) {
			if (invite.expiresAt < nowValue) expired.push(targetId)
		}
		foreach (targetId in expired) phoenix.social.Party.invalidateInvite(targetId, true)
		phoenix.social.Party.cleanupMissingMembers()
		local partyIds = []
		foreach (partyId, _party in phoenix.social.Structure.parties) partyIds.push(partyId)
		foreach (partyId in partyIds) phoenix.social.Party.push(partyId)
	}
}

try { setTimer(phoenix.social.Party.tick, phoenix.social.Party.snapshotIntervalMs, 0) } catch (e) {}
