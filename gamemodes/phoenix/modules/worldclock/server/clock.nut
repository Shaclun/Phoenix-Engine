phoenix.worldclock.Clock <- {

	defaultDayLength = 60
	autoSaveIntervalMs = 30000
	dirty = false

	function applyDayLength(minutes, force = false) {
		if (!force && !phoenix.features.Settings.isEnabled("worldclock.enabled")) return
		if (minutes == null) return
		local v = minutes.tointeger()
		if (v < 1) v = 1
		local ms = v * 60000
		if (ms < 10000) ms = 10000
		try { ::setDayLength(ms.tofloat()) } catch (e) {}
		phoenix.worldclock.Clock.dirty = true
	}

	function readDayLength() {
		try {
			local ms = ::getDayLength()
			if (ms == null) return phoenix.worldclock.Clock.defaultDayLength
			local minutes = (ms.tofloat() / 60000.0).tointeger()
			if (minutes < 1) minutes = 1
			return minutes
		} catch (e) {}
		return phoenix.worldclock.Clock.defaultDayLength
	}

	function applyTime(hour, min, requesterPid = -1, force = false) {
		if (!force && !phoenix.features.Settings.isEnabled("worldclock.enabled")) return
		local h = hour == null ? 0 : hour.tointeger()
		local m = min == null ? 0 : min.tointeger()
		if (h < 0) h = 0
		if (h > 23) h = 23
		if (m < 0) m = 0
		if (m > 59) m = 59
		try { ::setTime(h, m) } catch (e) {}
		phoenix.worldclock.Clock.dirty = true
	}

	function readTime() {
		try { return ::getTime() } catch (e) {}
		return { hour = 12, min = 0 }
	}

	function currentHour() {
		local t = phoenix.worldclock.Clock.readTime()
		if (t == null) return 12
		try { return t.hour } catch (e) {}
		return 12
	}

	function isNight() {
		local h = phoenix.worldclock.Clock.currentHour()
		return h >= 21 || h < 6
	}

	function isDay() {
		local h = phoenix.worldclock.Clock.currentHour()
		return h >= 6 && h < 21
	}

	// Aliases kept for external callers (dispatcher used to call setTime/setDayLength/getTime)
	function setTime(hour, min, requesterPid = -1) {
		phoenix.worldclock.Clock.applyTime(hour, min, requesterPid)
	}

	function setDayLength(minutes) {
		phoenix.worldclock.Clock.applyDayLength(minutes)
	}

	function getTime() {
		return phoenix.worldclock.Clock.readTime()
	}

	function getDayLength() {
		return phoenix.worldclock.Clock.readDayLength()
	}
}
