phoenix.npc.BestiaryClient <- {

	function init() {
		try { phoenix.web.Router.on("phoenix:bestiary:request", phoenix.npc.BestiaryClient.onRequest) } catch (e) {}
	}

	function onRequest(_payload) {
		try { phoenix.npc.Message.BestiaryRequest().serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onSnapshot(message) {
		local raw = ""
		try { raw = message.entries.tostring() } catch (e) { raw = "" }
		local entries = []
		if (raw != null && raw != "") {
			local lines = split(raw, "\n")
			foreach (line in lines) {
				if (line == "") continue
				local parts = split(line, "|")
				if (parts.len() < 7) continue
				entries.append({
					instance = parts[0],
					name = parts[1],
					visual = parts[2],
					kind = parts[3],
					killed = parts[4].tointeger(),
					firstKilledAt = parts[5].tointeger(),
					lastKilledAt = parts[6].tointeger()
				})
			}
		}
		try {
			phoenix.web.Manager.emit("phoenix:bestiary:snapshot", { entries = entries })
		} catch (e) {}
	}
}

phoenix.npc.Message.BestiarySnapshot.bind(phoenix.npc.BestiaryClient.onSnapshot)
phoenix.npc.BestiaryClient.init()
