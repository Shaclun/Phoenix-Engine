phoenix.chat.Server <- {
	IC_DISTANCE_SQ = 1500.0 * 1500.0
	OOC_DISTANCE_SQ = 2500.0 * 2500.0
	ACTION_DISTANCE_SQ = 1800.0 * 1800.0
	AME_DISTANCE_SQ = 900.0 * 900.0
	MAX_LEN = 240
	rateBuckets = {}

	function getSpeakerName(playerId) {
		try {
			local rec = phoenix.character.Structure.getActive(playerId)
			if (rec != null && ("name" in rec) && rec.name != "") return rec.name
		} catch (e) {}
		try { return getPlayerName(playerId) } catch (e) {}
		return "player_" + playerId
	}

	function sanitize(text) {
		if (text == null) return ""
		local s = text.tostring()
		if (s.len() > phoenix.chat.Server.MAX_LEN) s = s.slice(0, phoenix.chat.Server.MAX_LEN)
		return s
	}

	function distSq(a, b) {
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return dx * dx + dy * dy + dz * dz
	}

	function rateAllowed(playerId, channel) {
		local key = playerId.tostring() + ":" + channel
		local now = getTickCount()
		local bucket = null
		if (key in phoenix.chat.Server.rateBuckets) bucket = phoenix.chat.Server.rateBuckets[key]
		else {
			bucket = { tokens = 5.0, at = now }
			phoenix.chat.Server.rateBuckets[key] <- bucket
		}
		local elapsed = now - bucket.at
		if (elapsed < 0) elapsed = 0
		bucket.tokens += elapsed.tofloat() / 1250.0
		if (bucket.tokens > 5.0) bucket.tokens = 5.0
		bucket.at = now
		if (bucket.tokens < 1.0) {
			try { sendMessageToPlayer(playerId, 255, 160, 80, "[Chat] Zwolnij tempo wiadomości.") } catch (e) {}
			return false
		}
		bucket.tokens -= 1.0
		return true
	}

	function isActionChannel(channel) {
		return channel == phoenix.chat.Channel.ME || channel == phoenix.chat.Channel.DO || channel == phoenix.chat.Channel.TRY || channel == phoenix.chat.Channel.TODO || channel == phoenix.chat.Channel.AME
	}

	function channelEnabled(channel) {
		if (channel == phoenix.chat.Channel.ADMIN) return true
		if (channel == phoenix.chat.Channel.LOCAL) return phoenix.features.Settings.isEnabled("chat.local")
		if (channel == phoenix.chat.Channel.GLOBAL) return phoenix.features.Settings.isEnabled("chat.global")
		if (channel == phoenix.chat.Channel.OOC) return phoenix.features.Settings.isEnabled("chat.ooc")
		if (phoenix.chat.Server.isActionChannel(channel)) return phoenix.features.Settings.isEnabled("chat.rpActions")
		return false
	}

	function broadcast(senderId, channel, name, text, recipientIds) {
		local packet = phoenix.chat.Message.Broadcast()
		packet.playerId = senderId
		packet.channel = channel
		packet.name = name
		packet.text = text
		local serialized = packet.serialize()
		foreach (pid in recipientIds) {
			try { serialized.send(pid, RELIABLE_ORDERED) } catch (e) {}
		}
	}

	function sameContext(senderId, recipientId) {
		try {
			if (getPlayerVirtualWorld(senderId) != getPlayerVirtualWorld(recipientId)) return false
			local senderWorld = getPlayerWorld(senderId)
			local recipientWorld = getPlayerWorld(recipientId)
			if (senderWorld == null || recipientWorld == null) return false
			return senderWorld.tostring().toupper() == recipientWorld.tostring().toupper()
		} catch (e) {}
		return false
	}

	function rangedRecipients(senderId, maxDistanceSq) {
		local list = [senderId]
		local senderPos = null
		try { senderPos = getPlayerPosition(senderId) } catch (e) { return list }
		if (senderPos == null) return list
		local senderVanished = false
		try { senderVanished = phoenix.account.Auth.isVanished(senderId) } catch (e) {}
		local maxSlots = getMaxSlots()
		for (local i = 0; i < maxSlots; i += 1) {
			if (i == senderId) continue
			try {
				if (!isPlayerConnected(i)) continue
				if (!phoenix.chat.Server.sameContext(senderId, i)) continue
				if (senderVanished && !phoenix.account.Auth.isAdmin(i)) continue
				local pos = getPlayerPosition(i)
				if (pos == null) continue
				if (phoenix.chat.Server.distSq(senderPos, pos) <= maxDistanceSq) list.append(i)
			} catch (e) {}
		}
		return list
	}

	function allRecipients() {
		local list = []
		local maxSlots = getMaxSlots()
		for (local i = 0; i < maxSlots; i += 1) {
			try { if (isPlayerConnected(i)) list.append(i) } catch (e) {}
		}
		return list
	}

	function visibleRecipients(senderId) {
		local senderVanished = false
		try { senderVanished = phoenix.account.Auth.isVanished(senderId) } catch (e) {}
		if (!senderVanished) return phoenix.chat.Server.allRecipients()
		local list = [senderId]
		foreach (pid in phoenix.account.Auth.adminPlayerIds()) {
			if (pid != senderId) list.append(pid)
		}
		return list
	}

	function onSubmit(playerId, message) {
		local text = phoenix.chat.Server.sanitize(message.text)
		if (text == "") return

		try {
			if (phoenix.command.Dispatcher.dispatch(playerId, text)) return
		} catch (e) {}
		phoenix.chat.Server.dispatch(playerId, message.channel, text)
	}

	function toggleVanish(playerId, forced) {
		local s = phoenix.account.Structure.get(playerId)
		if (s == null) return
		local next
		if (forced == null) next = !s.vanished
		else next = forced == true
		s.vanished = next
		try { setPlayerInvisible(playerId, next) } catch (e) {}
		// Asymmetric vanish: vanished player stays in VW=0 so they SEE everything,
		// but NPC AI skips them via the isVanished flag, and other players see them invisible.
		try {
			local color = next ? [120, 200, 255] : [180, 220, 140]
			sendMessageToPlayer(playerId, color[0], color[1], color[2],
				next ? "[Admin] Jestes niewidzialny." : "[Admin] Jestes widzialny.")
		} catch (e) {}
		try {
			phoenix.admin.Server.reply(playerId, "vanish", true, "", { vanished = next })
		} catch (e) {}
	}

	function savePos(playerId, label) {
		local name = phoenix.chat.Server.getSpeakerName(playerId)
		local tag = phoenix.chat.Server.trim(label)
		if (tag == "") tag = "spot_" + playerId + "_" + getTickCount()
		local pos = null
		local rot = null
		try { pos = getPlayerPosition(playerId) } catch (e) {}
		try { rot = getPlayerAngle(playerId) } catch (e) {}
		if (pos == null) {
			try { sendMessageToPlayer(playerId, 255, 120, 80, "[/pos] nie udalo sie odczytac pozycji") } catch (e) {}
			return
		}
		local world = ""
		try { world = getPlayerWorld(playerId) } catch (e) {}
		local angle = 0.0
		if (rot != null) {
			if (typeof rot == "float" || typeof rot == "integer") angle = rot
			else { try { angle = rot.y } catch (e) {} }
		}
		local line = "[" + phoenix.chat.Server.timestamp() + "] " + name + " | " + tag
			+ " | world=" + world
			+ " | pos=" + pos.x + "," + pos.y + "," + pos.z
			+ " | angle=" + angle
			+ "\n"
		try {
			local f = file("positions.txt", "a+")
			local b = blob(line.len())
			foreach (idx, ch in line) b.writen(ch, 'b')
			b.seek(0)
			f.writeblob(b)
			f.close()
		} catch (e) {}
		try { sendMessageToPlayer(playerId, 180, 220, 140,
			"[/pos] zapisano '" + tag + "' -> " + pos.x + ", " + pos.y + ", " + pos.z) } catch (e) {}
	}

	function trim(s) {
		if (s == null) return ""
		local i = 0
		local j = s.len()
		while (i < j && (s[i] == ' ' || s[i] == '\t')) i += 1
		while (j > i && (s[j - 1] == ' ' || s[j - 1] == '\t')) j -= 1
		return s.slice(i, j)
	}

	function timestamp() {
		local d = date()
		return format("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.month + 1, d.day, d.hour, d.min, d.sec)
	}

	function dispatch(playerId, channel, text, trusted = false) {
		local allowed = channel == phoenix.chat.Channel.LOCAL || channel == phoenix.chat.Channel.GLOBAL || channel == phoenix.chat.Channel.ADMIN || channel == phoenix.chat.Channel.OOC
		if (trusted && phoenix.chat.Server.isActionChannel(channel)) allowed = true
		if (!allowed) return
		text = phoenix.chat.Server.trim(phoenix.chat.Server.sanitize(text))
		if (text == "") return
		if (channel == phoenix.chat.Channel.ADMIN && !phoenix.account.Auth.requireAdmin(playerId)) return
		if (!phoenix.chat.Server.channelEnabled(channel)) return
		if (!phoenix.chat.Server.rateAllowed(playerId, channel)) return
		local name = phoenix.chat.Server.getSpeakerName(playerId)
		local recipients
		if (channel == phoenix.chat.Channel.ADMIN) recipients = phoenix.account.Auth.adminPlayerIds()
		else if (channel == phoenix.chat.Channel.GLOBAL) recipients = phoenix.chat.Server.visibleRecipients(playerId)
		else {
			local distanceSq = phoenix.chat.Server.IC_DISTANCE_SQ
			if (channel == phoenix.chat.Channel.OOC) distanceSq = phoenix.chat.Server.OOC_DISTANCE_SQ
			else if (channel == phoenix.chat.Channel.AME) distanceSq = phoenix.chat.Server.AME_DISTANCE_SQ
			else if (phoenix.chat.Server.isActionChannel(channel)) distanceSq = phoenix.chat.Server.ACTION_DISTANCE_SQ
			recipients = phoenix.chat.Server.rangedRecipients(playerId, distanceSq)
		}
		phoenix.chat.Server.broadcast(playerId, channel, name, text, recipients)

		local stop = phoenix.chat.Message.Typing()
		stop.playerId = playerId
		stop.typing = false
		stop.channel = channel
		local stopSerialized = stop.serialize()
		foreach (pid in recipients) {
			if (pid == playerId) continue
			try { stopSerialized.send(pid, RELIABLE) } catch (e) {}
		}
	}

	function onPlayerMessage(playerId, message) {
		if (message == null || message == "") return
		local text = message.tostring()

		try {
			if (phoenix.command.Dispatcher.dispatch(playerId, text)) return
		} catch (e) {}
		local channel = phoenix.chat.Channel.LOCAL

		if (text.len() >= 3 && text.slice(0, 3) == "/g ") {
			channel = phoenix.chat.Channel.GLOBAL
			text = text.slice(3)
		} else if (text.len() >= 2 && text.slice(0, 2) == "/g") {
			channel = phoenix.chat.Channel.GLOBAL
			text = text.slice(2)
		}
		text = phoenix.chat.Server.sanitize(text)
		if (text == "") return
		phoenix.chat.Server.dispatch(playerId, channel, text)
	}

	function onTyping(playerId, message) {
		local channel = phoenix.chat.Channel.LOCAL
		try { channel = ("channel" in message) ? message.channel : phoenix.chat.Channel.LOCAL } catch (e) {}
		if (channel != phoenix.chat.Channel.LOCAL && channel != phoenix.chat.Channel.GLOBAL && channel != phoenix.chat.Channel.ADMIN && channel != phoenix.chat.Channel.OOC) return
		if (channel == phoenix.chat.Channel.ADMIN && !phoenix.account.Auth.isAdmin(playerId)) return
		if (!phoenix.chat.Server.channelEnabled(channel)) return
		local recipients
		if (channel == phoenix.chat.Channel.ADMIN) recipients = phoenix.account.Auth.adminPlayerIds()
		else if (channel == phoenix.chat.Channel.GLOBAL) recipients = phoenix.chat.Server.visibleRecipients(playerId)
		else {
			local distanceSq = channel == phoenix.chat.Channel.OOC ? phoenix.chat.Server.OOC_DISTANCE_SQ : phoenix.chat.Server.IC_DISTANCE_SQ
			recipients = phoenix.chat.Server.rangedRecipients(playerId, distanceSq)
		}
		local packet = phoenix.chat.Message.Typing()
		packet.playerId = playerId
		packet.typing = message.typing
		packet.channel = channel
		local serialized = packet.serialize()
		foreach (pid in recipients) {
			if (pid == playerId) continue
			try { serialized.send(pid, RELIABLE) } catch (e) {}
		}
	}
}

phoenix.chat.Message.Submit.bind(phoenix.chat.Server.onSubmit)
phoenix.chat.Message.Typing.bind(phoenix.chat.Server.onTyping)
addEventHandler("onPlayerMessage", phoenix.chat.Server.onPlayerMessage)
addEventHandler("onPlayerDisconnect", function (playerId, _reason) {
	local prefix = playerId.tostring() + ":"
	local remove = []
	foreach (key, _bucket in phoenix.chat.Server.rateBuckets) {
		if (key.find(prefix) == 0) remove.append(key)
	}
	foreach (key in remove) phoenix.chat.Server.rateBuckets.rawdelete(key)
})
