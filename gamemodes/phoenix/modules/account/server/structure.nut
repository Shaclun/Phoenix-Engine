phoenix.account.Structure <- {
	sessions = {}

	function get(playerId) {
		return playerId in sessions ? sessions[playerId] : null
	}

	function isLogged(playerId) {
		return playerId in sessions
	}

	function isAccountActive(accountId) {
		foreach (session in sessions) {
			if (session.id() == accountId) return true
		}
		return false
	}

	function attach(playerId, record) {
		local session = phoenix.account.Session(playerId, record)
		sessions[playerId] <- session
		session.markOnline()
		return session
	}

	function detach(playerId) {
		if (!(playerId in sessions)) return
		sessions[playerId].markOffline()
		sessions.rawdelete(playerId)
	}
}
