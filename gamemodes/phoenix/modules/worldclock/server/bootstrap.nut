phoenix.worldclock.Bootstrap <- {

	autoSaveTimer = null
	realTimeTimer = null

	function restoreState(state) {
		if (state == null) return
		try { phoenix.worldclock.Weather.set(state.weather, true) } catch (e) {}
		try { phoenix.worldclock.Weather.setWind(state.wind, true) } catch (e) {}
		phoenix.worldclock.Clock.dirty = false
		phoenix.worldclock.Weather.dirty = false
	}

	function applyRealTime() {
		if (!phoenix.features.Settings.isEnabled("worldclock.enabled")) return
		try {
			local d = date()
			if (d == null) return
			local h = d.hour.tointeger()
			local m = d.min.tointeger()
			::setTime(h, m)
		} catch (e) {}
	}

	function stop(saveState = true) {
		if (phoenix.worldclock.Bootstrap.realTimeTimer != null) {
			try { killTimer(phoenix.worldclock.Bootstrap.realTimeTimer) } catch (e) {}
			phoenix.worldclock.Bootstrap.realTimeTimer = null
		}
		if (phoenix.worldclock.Bootstrap.autoSaveTimer != null) {
			try { killTimer(phoenix.worldclock.Bootstrap.autoSaveTimer) } catch (e) {}
			phoenix.worldclock.Bootstrap.autoSaveTimer = null
		}
		if (saveState) try { phoenix.worldclock.Persistence.save() } catch (e) {}
	}

	function start() {
		if (!phoenix.features.Settings.isEnabled("worldclock.enabled")) return
		phoenix.worldclock.Persistence.load(function (state) {
			if (!phoenix.features.Settings.isEnabled("worldclock.enabled")) return
			if (state != null) {
				phoenix.worldclock.Bootstrap.restoreState(state)
			} else {
				phoenix.worldclock.Weather.set("clear", true)
				phoenix.worldclock.Persistence.save()
			}
			phoenix.worldclock.Bootstrap.applyRealTime()
		})
		try { ::setDayLength((24 * 60 * 60 * 1000).tofloat()) } catch (e) {}
		phoenix.worldclock.Bootstrap.applyRealTime()
		if (phoenix.worldclock.Bootstrap.realTimeTimer == null) {
			phoenix.worldclock.Bootstrap.realTimeTimer = setTimer(function () {
				if (!phoenix.features.Settings.isEnabled("worldclock.enabled")) return
				try { phoenix.worldclock.Bootstrap.applyRealTime() } catch (e) {}
				try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
			}, 30000, 0)
		}
		if (phoenix.worldclock.Bootstrap.autoSaveTimer == null) {
			phoenix.worldclock.Bootstrap.autoSaveTimer = setTimer(function () {
				if (!phoenix.features.Settings.isEnabled("worldclock.enabled")) return
				try { phoenix.worldclock.Persistence.maybeSave() } catch (e) {}
			}, phoenix.worldclock.Clock.autoSaveIntervalMs, 0)
		}
	}
}

addEventHandler("phoenix.database.OnReady", function () {
	try { phoenix.worldclock.Bootstrap.start() } catch (e) {}
})

addEventHandler("phoenix.features.OnChanged", function (key, enabled) {
	if (key != "worldclock.enabled") return
	if (phoenix.features.Settings.isEnabled("worldclock.enabled")) {
		try { phoenix.worldclock.Bootstrap.start() } catch (e) {}
	} else {
		try { phoenix.worldclock.Bootstrap.stop(true) } catch (e) {}
	}
})

addEventHandler("onTime", function (day, hour, min) {
	if (!phoenix.features.Settings.isEnabled("worldclock.enabled")) return
	try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
	if ((hour % 6) == 0 && min == 0) {
		try { phoenix.worldclock.Persistence.maybeSave() } catch (e) {}
	}
})

addEventHandler("onExit", function () {
	try { phoenix.worldclock.Persistence.save() } catch (e) {}
})
