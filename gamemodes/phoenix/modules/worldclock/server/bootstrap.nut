phoenix.worldclock.Bootstrap <- {

	autoSaveTimer = null
	realTimeTimer = null

	function restoreState(state) {
		if (state == null) return
		try { phoenix.worldclock.Weather.set(state.weather) } catch (e) {}
		try { phoenix.worldclock.Weather.setWind(state.wind) } catch (e) {}
		phoenix.worldclock.Clock.dirty = false
		phoenix.worldclock.Weather.dirty = false
	}

	function applyRealTime() {
		try {
			local d = date()
			if (d == null) return
			local h = d.hour.tointeger()
			local m = d.min.tointeger()
			::setTime(h, m)
		} catch (e) {}
	}

	function start() {
		phoenix.worldclock.Persistence.load(function (state) {
			if (state != null) {
				phoenix.worldclock.Bootstrap.restoreState(state)
			} else {
				phoenix.worldclock.Weather.set("clear")
				phoenix.worldclock.Persistence.save()
			}
			phoenix.worldclock.Bootstrap.applyRealTime()
		})
		try { ::setDayLength((24 * 60 * 60 * 1000).tofloat()) } catch (e) {}
		phoenix.worldclock.Bootstrap.applyRealTime()
		if (phoenix.worldclock.Bootstrap.realTimeTimer == null) {
			phoenix.worldclock.Bootstrap.realTimeTimer = setTimer(function () {
				try { phoenix.worldclock.Bootstrap.applyRealTime() } catch (e) {}
				try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
			}, 30000, 0)
		}
		if (phoenix.worldclock.Bootstrap.autoSaveTimer == null) {
			phoenix.worldclock.Bootstrap.autoSaveTimer = setTimer(function () {
				try { phoenix.worldclock.Persistence.maybeSave() } catch (e) {}
			}, phoenix.worldclock.Clock.autoSaveIntervalMs, 0)
		}
	}
}

addEventHandler("phoenix.database.OnReady", function () {
	try { phoenix.worldclock.Bootstrap.start() } catch (e) {}
})

addEventHandler("onTime", function (day, hour, min) {
	try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
	if ((hour % 6) == 0 && min == 0) {
		try { phoenix.worldclock.Persistence.maybeSave() } catch (e) {}
	}
})

addEventHandler("onExit", function () {
	try { phoenix.worldclock.Persistence.save() } catch (e) {}
})
