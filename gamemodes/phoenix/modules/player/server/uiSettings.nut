phoenix.player.UiSettings <- {
	function pushSnapshot(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		local raw = ""
		try { if ("uiSettings" in record && record.uiSettings != null) raw = record.uiSettings.tostring() } catch (e) {}
		local m = phoenix.player.Message.UiSettingsSnapshot()
		m.data = raw
		try { m.serialize().send(playerId, RELIABLE_ORDERED) } catch (e2) {}
	}

	function onUpdate(playerId, message) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		local raw = (message.data != null) ? message.data.tostring() : ""
		if (raw.len() > 8192) raw = raw.slice(0, 8192)
		record.uiSettings = raw
		try { record.saveAsync(function (_) {}) } catch (e) {}
	}
}

phoenix.player.Message.UiSettingsUpdate.bind(phoenix.player.UiSettings.onUpdate)

addEventHandler("phoenix.character.OnSelected", function (playerId, _characterId) {
	setTimer(function () {
		try { phoenix.player.UiSettings.pushSnapshot(playerId) } catch (e) {}
	}, 600, 1)
})
