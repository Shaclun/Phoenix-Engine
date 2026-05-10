phoenix.worldclock.Broadcast <- {

	function buildMessage() {
		local msg = phoenix.worldclock.Message.Sync()
		local t = phoenix.worldclock.Clock.readTime()
		local h = 8
		local m = 0
		try { h = t.hour.tointeger() } catch (e) {}
		try { m = t.min.tointeger() } catch (e) {}
		msg.timeHour = h
		msg.timeMin = m
		msg.dayLength = phoenix.worldclock.Clock.readDayLength()
		msg.weather = phoenix.worldclock.Weather.kind
		msg.wind = phoenix.worldclock.Weather.wind
		msg.lightning = phoenix.worldclock.Weather.lightning ? 1 : 0
		return msg
	}

	function sendTo(playerId) {
		if (playerId == null || playerId < 0) return
		try {
			local msg = phoenix.worldclock.Broadcast.buildMessage()
			msg.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}

	function sendAll() {
		local msg = null
		try { msg = phoenix.worldclock.Broadcast.buildMessage() } catch (e) { return }
		local serialized = null
		try { serialized = msg.serialize() } catch (e2) { return }
		local maxSlots = getMaxSlots()
		for (local pid = 0; pid < maxSlots; pid += 1) {
			try { if (isPlayerConnected(pid)) serialized.send(pid, RELIABLE_ORDERED) } catch (e3) {}
		}
	}
}

addEventHandler("onPlayerJoin", function (playerId) {
	setTimer(function () {
		try { phoenix.worldclock.Broadcast.sendTo(playerId) } catch (e) {}
	}, 3500, 1)
})
