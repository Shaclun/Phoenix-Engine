phoenix.worldclock.Weather <- {

	kind = "clear"
	wind = 0.0
	lightning = false
	dirty = false

	function _syncSky() {
		try {
			local k = phoenix.worldclock.Weather.kind
			if (k == "clear" || k == "stop") {
				Sky.raining = false
				Sky.dontRain = true
				Sky.renderLightning = false
			} else {
				if (k == "snow") Sky.weather = WEATHER_SNOW
				else Sky.weather = WEATHER_RAIN

				try { Sky.setRainStartTime(0, 0) } catch (eS) {}
				try { Sky.setRainStopTime(23, 59) } catch (eE) {}

				Sky.raining = true
				Sky.dontRain = false
				Sky.renderLightning = k == "storm"
			}
			Sky.windScale = phoenix.worldclock.Weather.wind
		} catch (e) {}
	}

	function set(kind) {
		if (kind == null) return
		local k = kind.tostring().tolower()
		if (k != "clear" && k != "rain" && k != "snow" && k != "storm" && k != "stop") k = "clear"
		phoenix.worldclock.Weather.kind = k
		phoenix.worldclock.Weather.lightning = k == "storm"
		phoenix.worldclock.Weather._syncSky()
		phoenix.worldclock.Weather.dirty = true
	}

	function setWind(scale) {
		local v = scale == null ? 0.0 : scale.tofloat()
		if (v < 0.0) v = 0.0
		if (v > 5.0) v = 5.0
		phoenix.worldclock.Weather.wind = v
		try { Sky.windScale = v } catch (e) {}
		phoenix.worldclock.Weather.dirty = true
	}

	function setRainWindow(startHour, startMin, stopHour, stopMin) {
		try { Sky.setRainStartTime(startHour, startMin) } catch (e) {}
		try { Sky.setRainStopTime(stopHour, stopMin) } catch (e) {}
		phoenix.worldclock.Weather.dirty = true
	}

	function current() {
		return {
			kind = phoenix.worldclock.Weather.kind,
			wind = phoenix.worldclock.Weather.wind,
			lightning = phoenix.worldclock.Weather.lightning
		}
	}
}
