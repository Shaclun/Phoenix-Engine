phoenix.command.Dispatcher <- {
	registry = []

	function register(name, handler, requireAdmin = true, aliases = null, usage = "", featureKey = "") {
		local entry = {
			name = name.tolower(),
			handler = handler,
			requireAdmin = requireAdmin,
			aliases = [],
			usage = usage,
			featureKey = featureKey
		}
		if (aliases != null) {
			foreach (a in aliases) entry.aliases.append(a.tolower())
		}
		phoenix.command.Dispatcher.registry.append(entry)
	}

	function _split(text) {
		local out = []
		if (text == null) return out
		local s = text.tostring()
		local i = 0
		local n = s.len()
		while (i < n) {
			while (i < n && (s[i] == ' ' || s[i] == '\t')) i += 1
			if (i >= n) break
			local start = i
			while (i < n && s[i] != ' ' && s[i] != '\t') i += 1
			out.append(s.slice(start, i))
		}
		return out
	}

	function _matches(entry, cmd) {
		if (cmd == entry.name) return true
		foreach (alias in entry.aliases) {
			if (cmd == alias) return true
		}
		return false
	}

	function _bypassesGameplay(entry) {
		if (entry.requireAdmin) return true
		if (entry.name == "revive" || entry.name == "respawn") return true
		if (entry.name == "login" || entry.name == "register" || entry.name == "auth" || entry.name == "logout") return true
		if (entry.featureKey == "commands.auth" || entry.featureKey.find("commands.auth.") == 0 || entry.featureKey.find("auth.") == 0) return true
		return false
	}

	function dispatch(playerId, text) {
		if (text == null) return false
		local s = text.tostring()
		if (s.len() == 0 || s[0] != '/') return false
		local parts = phoenix.command.Dispatcher._split(s.slice(1))
		if (parts.len() == 0) return false
		local cmd = parts[0].tolower()
		local args = parts.slice(1)
		foreach (entry in phoenix.command.Dispatcher.registry) {
			if (!phoenix.command.Dispatcher._matches(entry, cmd)) continue
			if (entry.requireAdmin && !phoenix.account.Auth.requireAdmin(playerId)) return true
			if (!phoenix.command.Dispatcher._bypassesGameplay(entry) && !phoenix.features.Settings.isEnabled("commands.gameplay")) {
				phoenix.command.Dispatcher.error(playerId, "[Command] Komendy gracza są wyłączone w profilu serwera.")
				return true
			}
			if (entry.featureKey != "" && !phoenix.features.Settings.isEnabled(entry.featureKey)) {
				phoenix.command.Dispatcher.error(playerId, "[Command] Ta funkcja jest wyłączona w profilu serwera.")
				return true
			}
			try {
				entry.handler.call(phoenix.command.Dispatcher, playerId, args, s)
			} catch (e) {
				try { sendMessageToPlayer(playerId, 220, 80, 80, "[Command] Blad wykonania: " + cmd) } catch (eS) {}
			}
			return true
		}
		return false
	}

	function reply(playerId, color, text) {
		try { sendMessageToPlayer(playerId, color[0], color[1], color[2], text) } catch (e) {}
	}

	function info(playerId, text) {
		phoenix.command.Dispatcher.reply(playerId, [180, 220, 140], text)
	}

	function error(playerId, text) {
		phoenix.command.Dispatcher.reply(playerId, [220, 80, 80], text)
	}

	function hint(playerId, text) {
		phoenix.command.Dispatcher.reply(playerId, [255, 200, 0], text)
	}
}
