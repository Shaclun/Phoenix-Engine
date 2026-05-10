class phoenix.account.Session {
	gameId = -1
	record = null
	vanished = false

	constructor(_gameId, _record) {
		gameId = _gameId
		record = _record
	}

	function id() { return record.id }
	function username() { return record.username }

	function markOnline() {
		record.online = 1
		record.serial = getPlayerSerial(gameId)
		record.saveAsync()
	}

	function markOffline() {
		record.online = 0
		record.saveAsync()
	}
}
