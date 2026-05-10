phoenix.chat.Server <- {
	LOCAL_DISTANCE_SQ = 4000.0 * 4000.0
	MAX_LEN = 240

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

	function localRecipients(senderId) {
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
				if (senderVanished && !phoenix.account.Auth.isAdmin(i)) continue
				local pos = getPlayerPosition(i)
				if (pos == null) continue
				if (phoenix.chat.Server.distSq(senderPos, pos) <= phoenix.chat.Server.LOCAL_DISTANCE_SQ)
					list.append(i)
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

		if (text.len() >= 4 && text.slice(0, 4) == "/pos") {
			if (!phoenix.account.Auth.requireAdmin(playerId)) return
			phoenix.chat.Server.savePos(playerId, (text.len() > 5) ? text.slice(5) : "")
			return
		}

		if (text == "/vanish" || (text.len() >= 8 && text.slice(0, 8) == "/vanish ")) {
			if (!phoenix.account.Auth.requireAdmin(playerId)) return
			phoenix.chat.Server.toggleVanish(playerId, null)
			return
		}

		if (text == "/revive" || text == "/respawn") {
			try { phoenix.player.Gate.revive(playerId) } catch (e) {}
			return
		}

		try {
			if (phoenix.item.Handlers.tryAdminCommand(playerId, text)) return
		} catch (e) {}
		try {
			if (phoenix.herb.Handlers.tryAdminCommand(playerId, text)) return
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

	function dispatch(playerId, channel, text) {
		if (channel == phoenix.chat.Channel.ADMIN) {
			if (!phoenix.account.Auth.requireAdmin(playerId)) return
		}
		local name = phoenix.chat.Server.getSpeakerName(playerId)
		local recipients
		if (channel == phoenix.chat.Channel.ADMIN) {
			recipients = phoenix.account.Auth.adminPlayerIds()
		} else if (channel == phoenix.chat.Channel.GLOBAL) {
			recipients = phoenix.chat.Server.visibleRecipients(playerId)
		} else {
			recipients = phoenix.chat.Server.localRecipients(playerId)
		}
		phoenix.chat.Server.broadcast(playerId, channel, name, text, recipients)

		local stop = phoenix.chat.Message.Typing()
		stop.playerId = playerId
		stop.typing = false
		stop.channel = channel
		local stopSerialized = stop.serialize()
		foreach (pid in phoenix.chat.Server.allRecipients()) {
			try { stopSerialized.send(pid, RELIABLE) } catch (e) {}
		}
	}

	function onPlayerMessage(playerId, message) {
		if (message == null || message == "") return
		local text = message.tostring()

		if (text.len() >= 4 && text.slice(0, 4) == "/pos") {
			if (!phoenix.account.Auth.requireAdmin(playerId)) return
			phoenix.chat.Server.savePos(playerId, (text.len() > 5) ? text.slice(5) : "")
			return
		}
		if (text == "/vanish" || (text.len() >= 8 && text.slice(0, 8) == "/vanish ")) {
			if (!phoenix.account.Auth.requireAdmin(playerId)) return
			phoenix.chat.Server.toggleVanish(playerId, null)
			return
		}
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

		local channel = 0
		try { channel = ("channel" in message) ? message.channel : 0 } catch (e) {}
		local recipients
		if (channel == phoenix.chat.Channel.ADMIN || phoenix.account.Auth.isVanished(playerId)) {
			recipients = phoenix.account.Auth.adminPlayerIds()
		} else {
			recipients = phoenix.chat.Server.allRecipients()
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
