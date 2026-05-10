phoenix.worldclock.HudClient <- {

	weather = "clear"
	wind = 0.0
	lightning = false
	lastAppliedKind = ""

	function onSync(message) {
		if (message == null) return
		try { phoenix.worldclock.HudClient.weather = message.weather } catch (e) {}
		try { phoenix.worldclock.HudClient.wind = message.wind.tofloat() } catch (e) {}
		try { phoenix.worldclock.HudClient.lightning = message.lightning == 1 } catch (e) {}
		phoenix.worldclock.HudClient.applyWeather()
		phoenix.worldclock.HudClient.push()
	}

	function applyWeather() {
		local kind = phoenix.worldclock.HudClient.weather
		try {
			if (kind == "clear" || kind == "stop") {
				Sky.dontRain = true
				Sky.raining = false
				Sky.renderLightning = false
			} else {
				if (kind == "snow") Sky.weather = WEATHER_SNOW
				else Sky.weather = WEATHER_RAIN

				try { Sky.setRainStartTime(0, 0) } catch (eS) {}
				try { Sky.setRainStopTime(23, 59) } catch (eE) {}

				Sky.dontRain = false
				Sky.raining = true
				Sky.renderLightning = kind == "storm"
			}
			Sky.windScale = phoenix.worldclock.HudClient.wind
		} catch (e) {}
		phoenix.worldclock.HudClient.lastAppliedKind = kind
	}

	function reapplyIfNeeded() {
		local kind = phoenix.worldclock.HudClient.weather
		if (kind == "clear" || kind == "stop") return
		try {
			if (Sky.raining == false || Sky.dontRain == true) {
				phoenix.worldclock.HudClient.applyWeather()
			}
		} catch (e) {}
	}

	function syncRealTime() {
		local d = null
		try { d = date() } catch (e) { return }
		if (d == null) return
		local h = 12
		local m = 0
		try { h = d.hour.tointeger() } catch (e) {}
		try { m = d.min.tointeger() } catch (e) {}
		try { ::setTime(h, m) } catch (e) {}
		phoenix.worldclock.HudClient.push()
	}

	function push() {
		try {
			local d = date()
			local h = 12
			local m = 0
			try { h = d.hour.tointeger() } catch (e) {}
			try { m = d.min.tointeger() } catch (e) {}
			phoenix.web.Manager.emit("phoenix:worldclock:update", {
				hour = h,
				minute = m,
				weather = phoenix.worldclock.HudClient.weather,
				wind = phoenix.worldclock.HudClient.wind,
				lightning = phoenix.worldclock.HudClient.lightning ? 1 : 0
			})
		} catch (e) {}
	}
}

phoenix.worldclock.Message.Sync.bind(phoenix.worldclock.HudClient.onSync)

addEventHandler("onInit", function () {
	setTimer(function () {
		try { phoenix.worldclock.HudClient.syncRealTime() } catch (e) {}
	}, 5000, 0)

	setTimer(function () {
		try { phoenix.worldclock.HudClient.reapplyIfNeeded() } catch (e) {}
	}, 2500, 0)
})
