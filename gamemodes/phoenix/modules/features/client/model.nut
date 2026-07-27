phoenix.features.Client <- {
	revision = 0
	settings = {
		profile = "mmorpg",
		revision = 0,
		schemaVersion = 2,
		flags = {},
		registry = [],
		profiles = {},
		ready = false
	}
	aliases = {
		levelingEnabled = "progression.leveling",
		mobExperienceEnabled = "progression.mobExperience",
		rpChatEnabled = "chat.ooc",
		rpCommandsEnabled = "chat.rpActions"
	}

	function resolveKey(key) {
		return key in phoenix.features.Client.aliases ? phoenix.features.Client.aliases[key] : key
	}

	function isEnabled(key) {
		local resolved = phoenix.features.Client.resolveKey(key)
		return resolved in phoenix.features.Client.settings.flags && phoenix.features.Client.settings.flags[resolved] == true
	}

	function effectiveEnabled(key, visiting = null) {
		local resolved = phoenix.features.Client.resolveKey(key)
		if (!phoenix.features.Client.isEnabled(resolved)) return false
		if (visiting == null) visiting = {}
		if (resolved in visiting) return false
		visiting[resolved] <- true
		foreach (meta in phoenix.features.Client.settings.registry) {
			if (meta.key != resolved) continue
			foreach (dependency in meta.dependencies) {
				if (!phoenix.features.Client.effectiveEnabled(dependency, visiting)) return false
			}
			break
		}
		return true
	}

	function nestedFlags(source) {
		local out = {}
		foreach (key, enabled in source) {
			local dot = key.find(".")
			if (dot == null) { out[key] <- enabled; continue }
			local domain = key.slice(0, dot)
			local name = key.slice(dot + 1)
			if (!(domain in out)) out[domain] <- {}
			out[domain][name] <- enabled
		}
		return out
	}

	function webSettings() {
		local out = clone phoenix.features.Client.settings
		out.flags = phoenix.features.Client.nestedFlags(phoenix.features.Client.settings.flags)
		return out
	}

	function emit() {
		phoenix.web.Manager.emit("phoenix:features:snapshot", {
			revision = phoenix.features.Client.revision,
			settings = phoenix.features.Client.webSettings()
		})
	}

	function onSnapshot(message) {
		if (message == null || message.settings == null) return
		local previous = phoenix.features.Client.settings.flags
		phoenix.features.Client.revision = message.revision
		phoenix.features.Client.settings = message.settings
		foreach (key, enabled in phoenix.features.Client.settings.flags) {
			local changed = !(key in previous) || previous[key] != enabled
			if (changed) {
				try { callEvent("phoenix.features.ClientChanged", key, enabled) } catch (e) {}
			}
		}
		phoenix.features.Client.emit()
	}

	function request() {
		try { phoenix.features.Message.FeatureSettingsRequest().serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}
}

phoenix.features.Message.FeatureSettingsSnapshot.bind(phoenix.features.Client.onSnapshot)
addEventHandler("phoenix.web.OnReady", function () {
	phoenix.features.Client.emit()
	phoenix.features.Client.request()
})