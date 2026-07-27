phoenix.features.Settings <- {
	profile = "mmorpg"
	revision = 0
	schemaVersion = 2
	ready = false
	busy = false
	updatedBy = 0
	updatedAt = 0
	flags = {}
	keys = []
	registryByKey = {}
	aliases = {
		levelingEnabled = "progression.leveling",
		mobExperienceEnabled = "progression.mobExperience",
		rpChatEnabled = "chat.ooc",
		rpCommandsEnabled = "chat.rpActions"
	}
	registry = [
		{ key = "account.registration", defaultValue = true, domain = "account", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "character.creation", defaultValue = true, domain = "account", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "character.deletion", defaultValue = true, domain = "account", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "character.preview", defaultValue = true, domain = "account", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "lobby.enabled", defaultValue = true, domain = "account", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "progression.leveling", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "progression.mobExperience", defaultValue = true, domain = "progression", dependencies = ["progression.leveling"], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "progression.partyExperience", defaultValue = true, domain = "progression", dependencies = ["progression.leveling", "social.party"], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "progression.weaponExperience", defaultValue = true, domain = "progression", dependencies = ["progression.leveling"], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "progression.magicExperience", defaultValue = true, domain = "progression", dependencies = ["progression.leveling"], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "progression.learnPoints", defaultValue = true, domain = "progression", dependencies = ["progression.leveling"], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "progression.statsSpending", defaultValue = true, domain = "progression", dependencies = ["progression.leveling"], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "player.stamina", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "player.regeneration", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "player.sitting", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "player.knockdown", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "player.fallDamage", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "player.combatText", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
		{ key = "player.targetHud", defaultValue = true, domain = "progression", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false }
	]
}

phoenix.features.Settings.registry.extend([
	{ key = "items.inventory", defaultValue = true, domain = "items", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "items.use", defaultValue = true, domain = "items", dependencies = ["items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "items.equipment", defaultValue = true, domain = "items", dependencies = ["items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "items.upgrades", defaultValue = true, domain = "items", dependencies = ["items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "items.spells", defaultValue = true, domain = "items", dependencies = ["items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "player.hotbar", defaultValue = true, domain = "items", dependencies = ["items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "crafting.enabled", defaultValue = true, domain = "items", dependencies = ["items.inventory", "worldVobs.enabled"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "professions.enabled", defaultValue = true, domain = "items", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "professions.hunting", defaultValue = true, domain = "items", dependencies = ["professions.enabled"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "herbs.enabled", defaultValue = true, domain = "items", dependencies = ["professions.enabled", "items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "housing.enabled", defaultValue = true, domain = "items", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "worldVobs.enabled", defaultValue = true, domain = "items", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "npc.spawning", defaultValue = true, domain = "npc", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "npc.ai", defaultValue = true, domain = "npc", dependencies = ["npc.spawning"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "npc.interaction", defaultValue = true, domain = "npc", dependencies = ["npc.spawning"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "npc.teachers", defaultValue = true, domain = "npc", dependencies = ["npc.interaction"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "npc.merchants", defaultValue = true, domain = "npc", dependencies = ["npc.interaction", "items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "npc.routines", defaultValue = true, domain = "npc", dependencies = ["npc.spawning"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "npc.nameplates", defaultValue = true, domain = "npc", dependencies = ["npc.spawning"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "bestiary.enabled", defaultValue = true, domain = "npc", dependencies = ["npc.spawning"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "quests.enabled", defaultValue = true, domain = "npc", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "quests.dialogs", defaultValue = true, domain = "npc", dependencies = ["quests.enabled"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "quests.markers", defaultValue = true, domain = "npc", dependencies = ["quests.enabled"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "quests.zones", defaultValue = true, domain = "npc", dependencies = ["quests.enabled"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "quests.rewards", defaultValue = true, domain = "npc", dependencies = ["quests.enabled"], clientVisible = true, hotReload = true, restartRequired = false }
])


phoenix.features.Settings.registry.extend([
	{ key = "chat.local", defaultValue = true, domain = "social", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "chat.global", defaultValue = true, domain = "social", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "chat.ooc", defaultValue = false, domain = "social", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "chat.rpActions", defaultValue = false, domain = "social", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "social.party", defaultValue = true, domain = "social", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "social.trade", defaultValue = true, domain = "social", dependencies = ["items.inventory"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "social.directMessages", defaultValue = true, domain = "social", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "worldclock.enabled", defaultValue = true, domain = "world", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "weather.enabled", defaultValue = true, domain = "world", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "minimap.enabled", defaultValue = true, domain = "world", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "hud.levelExperience", defaultValue = true, domain = "world", dependencies = ["progression.leveling"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "hud.magicExperience", defaultValue = true, domain = "world", dependencies = ["progression.magicExperience"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "hud.weaponExperience", defaultValue = true, domain = "world", dependencies = ["progression.weaponExperience"], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "notifications.enabled", defaultValue = true, domain = "world", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "camera.orbital", defaultValue = true, domain = "world", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "commands.gameplay", defaultValue = true, domain = "operations", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false },
	{ key = "admin.contentEditors", defaultValue = true, domain = "operations", dependencies = [], clientVisible = true, hotReload = true, restartRequired = false }
])

phoenix.features.Settings.profiles <- {}

phoenix.features.Settings.resolveKey <- function(key) {
	return key in phoenix.features.Settings.aliases ? phoenix.features.Settings.aliases[key] : key
}

phoenix.features.Settings.copyFlags <- function(source) {
	local out = {}
	foreach (key in phoenix.features.Settings.keys) out[key] <- key in source && source[key] == true
	return out
}

phoenix.features.Settings.defaultFlags <- function() {
	local out = {}
	foreach (meta in phoenix.features.Settings.registry) out[meta.key] <- meta.defaultValue == true
	return out
}

phoenix.features.Settings.profileFlags <- function(profile) {
	local key = profile == null ? "custom" : profile.tostring().tolower()
	if (key in phoenix.features.Settings.profiles) return phoenix.features.Settings.copyFlags(phoenix.features.Settings.profiles[key])
	return phoenix.features.Settings.copyFlags(phoenix.features.Settings.flags)
}

phoenix.features.Settings.buildRegistry <- function() {
	phoenix.features.Settings.keys = []
	phoenix.features.Settings.registryByKey = {}
	foreach (meta in phoenix.features.Settings.registry) {
		phoenix.features.Settings.keys.push(meta.key)
		phoenix.features.Settings.registryByKey[meta.key] <- meta
	}
	local mmorpg = phoenix.features.Settings.defaultFlags()
	local hybrid = phoenix.features.Settings.copyFlags(mmorpg)
	hybrid["chat.ooc"] = true
	hybrid["chat.rpActions"] = true
	local rp = phoenix.features.Settings.copyFlags(hybrid)
	foreach (key in ["progression.leveling", "progression.mobExperience", "progression.partyExperience", "progression.weaponExperience", "progression.magicExperience", "progression.learnPoints", "progression.statsSpending", "hud.levelExperience", "hud.magicExperience", "hud.weaponExperience"]) rp[key] = false
	phoenix.features.Settings.profiles = { mmorpg = mmorpg, rp = rp, hybrid = hybrid }
	phoenix.features.Settings.flags = phoenix.features.Settings.copyFlags(mmorpg)
}

phoenix.features.Settings.buildRegistry()


phoenix.features.Settings.publicRegistry <- function() {
	local out = []
	foreach (meta in phoenix.features.Settings.registry) {
		local entry = {}
		foreach (field, value in meta) entry[field] <- value
		entry["default"] <- meta.defaultValue == true
		out.push(entry)
	}
	return out
}

phoenix.features.Settings.snapshot <- function() {
	local out = {
		profile = phoenix.features.Settings.profile,
		revision = phoenix.features.Settings.revision,
		schemaVersion = phoenix.features.Settings.schemaVersion,
		flags = phoenix.features.Settings.copyFlags(phoenix.features.Settings.flags),
		registry = phoenix.features.Settings.publicRegistry(),
		profiles = {},
		updatedBy = phoenix.features.Settings.updatedBy,
		updatedAt = phoenix.features.Settings.updatedAt,
		ready = phoenix.features.Settings.ready
	}
	foreach (name, values in phoenix.features.Settings.profiles) out.profiles[name] <- phoenix.features.Settings.copyFlags(values)
	out.levelingEnabled <- phoenix.features.Settings.isEnabled("progression.leveling")
	out.mobExperienceEnabled <- phoenix.features.Settings.isEnabled("progression.mobExperience")
	out.rpChatEnabled <- phoenix.features.Settings.isEnabled("chat.ooc")
	out.rpCommandsEnabled <- phoenix.features.Settings.isEnabled("chat.rpActions")
	return out
}

phoenix.features.Settings.isEnabled <- function(key) {
	local resolved = phoenix.features.Settings.resolveKey(key)
	return resolved in phoenix.features.Settings.flags && phoenix.features.Settings.flags[resolved] == true
}

phoenix.features.Settings.effectiveEnabled <- function(key, visiting = null) {
	local resolved = phoenix.features.Settings.resolveKey(key)
	if (!phoenix.features.Settings.isEnabled(resolved)) return false
	if (!(resolved in phoenix.features.Settings.registryByKey)) return false
	if (visiting == null) visiting = {}
	if (resolved in visiting) return false
	visiting[resolved] <- true
	foreach (dependency in phoenix.features.Settings.registryByKey[resolved].dependencies) {
		if (!phoenix.features.Settings.effectiveEnabled(dependency, visiting)) return false
	}
	visiting.rawdelete(resolved)
	return true
}

phoenix.features.Settings.applyRow <- function(row) {
	if (row == null) return false
	local nextFlags = phoenix.features.Settings.defaultFlags()
	local decoded = null
	try {
		if (row.flagsJson != null && row.flagsJson.tostring() != "") decoded = phoenix.web.Json.parse(row.flagsJson.tostring())
	} catch (e) { decoded = null }
	if (decoded != null && typeof decoded == "table") {
		foreach (key, value in decoded) {
			local resolved = phoenix.features.Settings.resolveKey(key)
			if (resolved in phoenix.features.Settings.registryByKey && typeof value == "bool") nextFlags[resolved] = value
			else if (resolved in phoenix.features.Settings.registryByKey && (typeof value == "integer" || typeof value == "float")) nextFlags[resolved] = value != 0
		}
	} else {
		try { nextFlags["progression.leveling"] = row.levelingEnabled.tointeger() != 0 } catch (e) {}
		try { nextFlags["progression.mobExperience"] = row.mobExperienceEnabled.tointeger() != 0 } catch (e) {}
		try { nextFlags["chat.ooc"] = row.rpChatEnabled.tointeger() != 0 } catch (e) {}
		try { nextFlags["chat.rpActions"] = row.rpCommandsEnabled.tointeger() != 0 } catch (e) {}
	}
	local nextProfile = "custom"
	try { nextProfile = row.profile.tostring().tolower() } catch (e) {}
	if (nextProfile != "mmorpg" && nextProfile != "rp" && nextProfile != "hybrid" && nextProfile != "custom") nextProfile = "custom"
	phoenix.features.Settings.profile = nextProfile
	phoenix.features.Settings.flags = nextFlags
	try { phoenix.features.Settings.revision = row.revision.tointeger() } catch (e) { phoenix.features.Settings.revision = 0 }
	try { phoenix.features.Settings.schemaVersion = row.schemaVersion.tointeger() } catch (e) { phoenix.features.Settings.schemaVersion = 2 }
	try { phoenix.features.Settings.updatedBy = row.updatedBy == null ? 0 : row.updatedBy.tointeger() } catch (e) { phoenix.features.Settings.updatedBy = 0 }
	try { phoenix.features.Settings.updatedAt = row.updatedAt == null ? 0 : row.updatedAt.tointeger() } catch (e) { phoenix.features.Settings.updatedAt = 0 }
	return true
}

phoenix.features.Settings.escapeSql <- function(value) {
	if (value == null) return ""
	local source = value.tostring()
	local out = ""
	for (local i = 0; i < source.len(); i++) {
		local c = source[i]
		if (c == '\\') out += "\\\\"
		else if (c == '\'') out += "\\'"
		else if (c == 0) out += "\\0"
		else if (c == 10) out += "\\n"
		else if (c == 13) out += "\\r"
		else if (c == 26) out += "\\Z"
		else out += source.slice(i, i + 1)
	}
	return out
}

phoenix.features.Settings.select <- function(callback) {
	local sql = "SELECT `profile`,`levelingEnabled`,`mobExperienceEnabled`,`rpChatEnabled`,`rpCommandsEnabled`,`flagsJson`,`schemaVersion`,`revision`,`updatedBy`,UNIX_TIMESTAMP(`updatedAt`) AS `updatedAt` FROM `phoenix_server_feature_settings` WHERE `id`=1 LIMIT 1"
	ORM.engine.executeAsync(sql, callback)
}

phoenix.features.Settings.finishLoad <- function(rows) {
	if (rows != null && rows.len() > 0) phoenix.features.Settings.applyRow(rows[0])
	phoenix.features.Settings.ready = true
	phoenix.features.Settings.broadcast()
}

phoenix.features.Settings.load <- function() {
	try {
		phoenix.features.Settings.select(function(rows) {
			if (rows != null && rows.len() > 0) { phoenix.features.Settings.finishLoad(rows); return }
			local encoded = phoenix.web.Json.encode(phoenix.features.Settings.profileFlags("mmorpg"))
			local escaped = phoenix.features.Settings.escapeSql(encoded)
			local sql = "INSERT INTO `phoenix_server_feature_settings` (`id`,`profile`,`levelingEnabled`,`mobExperienceEnabled`,`rpChatEnabled`,`rpCommandsEnabled`,`flagsJson`,`schemaVersion`,`revision`) VALUES (1,'mmorpg',1,1,0,0,'" + escaped + "',2,1)"
			ORM.engine.executeAsync(sql, function(_) { phoenix.features.Settings.select(phoenix.features.Settings.finishLoad) })
		})
	} catch (e) {
		phoenix.features.Settings.ready = true
		phoenix.features.Settings.broadcast()
	}
}

phoenix.features.Settings.sendTo <- function(playerId) {
	local message = phoenix.features.Message.FeatureSettingsSnapshot()
	message.revision = phoenix.features.Settings.revision
	message.settings = phoenix.features.Settings.snapshot()
	try { message.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
}

phoenix.features.Settings.broadcast <- function() {
	for (local playerId = 0; playerId < getMaxSlots(); playerId += 1) {
		try { if (isPlayerConnected(playerId)) phoenix.features.Settings.sendTo(playerId) } catch (e) {}
	}
}


phoenix.features.Settings.validateUpdate <- function(payload) {
	if (payload == null || typeof payload != "table") return { ok = false, error = "invalidPayload" }
	local allowed = { profile = true, expectedRevision = true, flags = true }
	foreach (key, _value in payload) if (!(key in allowed)) return { ok = false, error = "unknownField" }
	foreach (key in ["profile", "expectedRevision", "flags"]) if (!(key in payload)) return { ok = false, error = "missingField" }
	if (typeof payload.profile != "string") return { ok = false, error = "invalidProfile" }
	local profile = payload.profile.tolower()
	if (profile != "mmorpg" && profile != "rp" && profile != "hybrid" && profile != "custom") return { ok = false, error = "invalidProfile" }
	if (typeof payload.expectedRevision != "integer" || payload.expectedRevision < 0) return { ok = false, error = "invalidRevision" }
	if (typeof payload.flags != "table") return { ok = false, error = "invalidFlags" }
	foreach (key, _value in payload.flags) if (!(key in phoenix.features.Settings.registryByKey)) return { ok = false, error = "unknownFlag:" + key }
	local parsedFlags = {}
	foreach (key in phoenix.features.Settings.keys) {
		if (!(key in payload.flags)) return { ok = false, error = "missingFlag:" + key }
		if (typeof payload.flags[key] != "bool") return { ok = false, error = "invalidBoolean:" + key }
		parsedFlags[key] <- payload.flags[key]
	}
	if (profile != "custom") {
		local preset = phoenix.features.Settings.profiles[profile]
		foreach (key in phoenix.features.Settings.keys) if (parsedFlags[key] != preset[key]) return { ok = false, error = "profileMismatch" }
	}
	foreach (meta in phoenix.features.Settings.registry) {
		if (!parsedFlags[meta.key]) continue
		foreach (dependency in meta.dependencies) if (!parsedFlags[dependency]) return { ok = false, error = "dependency:" + meta.key + ":" + dependency }
	}
	return { ok = true, profile = profile, expectedRevision = payload.expectedRevision, flags = parsedFlags }
}

phoenix.features.Settings.setFlagIn <- function(flags, key, enabled, visiting = null) {
	local resolved = phoenix.features.Settings.resolveKey(key)
	if (!(resolved in phoenix.features.Settings.registryByKey) || !(resolved in flags)) return
	if (visiting == null) visiting = {}
	if (resolved in visiting) return
	visiting[resolved] <- true
	flags[resolved] = enabled == true
	if (enabled) {
		foreach (dependency in phoenix.features.Settings.registryByKey[resolved].dependencies) {
			phoenix.features.Settings.setFlagIn(flags, dependency, true, visiting)
		}
	} else {
		foreach (meta in phoenix.features.Settings.registry) {
			foreach (dependency in meta.dependencies) {
				if (phoenix.features.Settings.resolveKey(dependency) == resolved) {
					phoenix.features.Settings.setFlagIn(flags, meta.key, false, visiting)
					break
				}
			}
		}
	}
	visiting.rawdelete(resolved)
}

phoenix.features.Settings.sanitizeFlags <- function(source) {
	local out = phoenix.features.Settings.copyFlags(source)
	local changed = true
	local passes = 0
	while (changed && passes <= phoenix.features.Settings.keys.len()) {
		changed = false
		passes += 1
		foreach (meta in phoenix.features.Settings.registry) {
			if (!out[meta.key]) continue
			foreach (dependency in meta.dependencies) {
				local resolved = phoenix.features.Settings.resolveKey(dependency)
				if (!(resolved in out) || !out[resolved]) {
					phoenix.features.Settings.setFlagIn(out, meta.key, false)
					changed = true
					break
				}
			}
		}
	}
	return out
}

phoenix.features.Settings.reconcileFlags <- function(requested) {
	local before = phoenix.features.Settings.sanitizeFlags(phoenix.features.Settings.flags)
	local out = phoenix.features.Settings.copyFlags(before)
	foreach (key in phoenix.features.Settings.keys) {
		if (before[key] != requested[key] && !requested[key]) phoenix.features.Settings.setFlagIn(out, key, false)
	}
	foreach (key in phoenix.features.Settings.keys) {
		if (before[key] != requested[key] && requested[key]) phoenix.features.Settings.setFlagIn(out, key, true)
	}
	return phoenix.features.Settings.sanitizeFlags(out)
}

foreach (profile, values in phoenix.features.Settings.profiles) {
	phoenix.features.Settings.profiles[profile] = phoenix.features.Settings.sanitizeFlags(values)
}

local phoenixFeaturesApplyRow = phoenix.features.Settings.applyRow
phoenix.features.Settings.applyRow = function(row) {
	local applied = phoenixFeaturesApplyRow(row)
	if (applied) {
		if (phoenix.features.Settings.profile != "custom" && phoenix.features.Settings.profile in phoenix.features.Settings.profiles) {
			phoenix.features.Settings.flags = phoenix.features.Settings.copyFlags(phoenix.features.Settings.profiles[phoenix.features.Settings.profile])
		} else {
			phoenix.features.Settings.flags = phoenix.features.Settings.sanitizeFlags(phoenix.features.Settings.flags)
		}
	}
	return applied
}

phoenix.features.Settings.validateUpdate = function(payload) {
	if (payload == null || typeof payload != "table") return { ok = false, error = "invalidPayload" }
	local allowed = { profile = true, expectedRevision = true, flags = true }
	foreach (key, _value in payload) if (!(key in allowed)) return { ok = false, error = "unknownField" }
	foreach (key in ["profile", "expectedRevision"]) if (!(key in payload)) return { ok = false, error = "missingField" }
	if (typeof payload.profile != "string") return { ok = false, error = "invalidProfile" }
	local profile = payload.profile.tolower()
	if (profile != "mmorpg" && profile != "rp" && profile != "hybrid" && profile != "custom") return { ok = false, error = "invalidProfile" }
	local revisionType = typeof payload.expectedRevision
	if (revisionType != "integer" && revisionType != "float") return { ok = false, error = "invalidRevision" }
	local expectedRevision = payload.expectedRevision.tointeger()
	if (expectedRevision < 0 || expectedRevision.tofloat() != payload.expectedRevision.tofloat()) return { ok = false, error = "invalidRevision" }
	if (profile != "custom") {
		return {
			ok = true,
			profile = profile,
			expectedRevision = expectedRevision,
			flags = phoenix.features.Settings.copyFlags(phoenix.features.Settings.profiles[profile])
		}
	}
	if (!("flags" in payload) || typeof payload.flags != "table") return { ok = false, error = "invalidFlags" }
	foreach (key, _value in payload.flags) if (!(key in phoenix.features.Settings.registryByKey)) return { ok = false, error = "unknownFlag:" + key }
	local requested = {}
	foreach (key in phoenix.features.Settings.keys) {
		if (!(key in payload.flags)) return { ok = false, error = "missingFlag:" + key }
		local value = payload.flags[key]
		local valueType = typeof value
		if (valueType == "bool") requested[key] <- value
		else if ((valueType == "integer" || valueType == "float") && (value == 0 || value == 1)) requested[key] <- value != 0
		else return { ok = false, error = "invalidBoolean:" + key }
	}
	local parsedFlags = phoenix.features.Settings.reconcileFlags(requested)
	foreach (meta in phoenix.features.Settings.registry) {
		if (!parsedFlags[meta.key]) continue
		foreach (dependency in meta.dependencies) {
			if (!parsedFlags[dependency]) return { ok = false, error = "dependencyGraph" }
		}
	}
	return { ok = true, profile = profile, expectedRevision = expectedRevision, flags = parsedFlags }
}

phoenix.features.Settings.changedKeys <- function(before, after) {
	local changed = []
	foreach (key in phoenix.features.Settings.keys) if (before[key] != after[key]) changed.push(key)
	return changed
}

phoenix.features.Settings.update <- function(payload, updatedBy, callback) {
	local parsed = phoenix.features.Settings.validateUpdate(payload)
	if (!parsed.ok) { callback(false, parsed.error, phoenix.features.Settings.snapshot(), []); return }
	if (phoenix.features.Settings.busy) { callback(false, "busy", phoenix.features.Settings.snapshot(), []); return }
	if (parsed.expectedRevision != phoenix.features.Settings.revision) { callback(false, "conflict", phoenix.features.Settings.snapshot(), []); return }
	local before = phoenix.features.Settings.copyFlags(phoenix.features.Settings.flags)
	local changed = phoenix.features.Settings.changedKeys(before, parsed.flags)
	if (changed.len() == 0 && parsed.profile == phoenix.features.Settings.profile) { callback(true, "", phoenix.features.Settings.snapshot(), changed); return }
	local encoded = ""
	try { encoded = phoenix.web.Json.encode(parsed.flags) } catch (e) { callback(false, "encoding", phoenix.features.Settings.snapshot(), []); return }
	local escaped = ""
	try { escaped = phoenix.features.Settings.escapeSql(encoded) } catch (e) { callback(false, "database", phoenix.features.Settings.snapshot(), []); return }
	phoenix.features.Settings.busy = true
	local updater = updatedBy > 0 ? updatedBy.tostring() : "NULL"
	local sql = "UPDATE `phoenix_server_feature_settings` SET `profile`='" + parsed.profile +
		"',`flagsJson`='" + escaped + "',`schemaVersion`=2" +
		",`levelingEnabled`=" + (parsed.flags["progression.leveling"] ? 1 : 0) +
		",`mobExperienceEnabled`=" + (parsed.flags["progression.mobExperience"] ? 1 : 0) +
		",`rpChatEnabled`=" + (parsed.flags["chat.ooc"] ? 1 : 0) +
		",`rpCommandsEnabled`=" + (parsed.flags["chat.rpActions"] ? 1 : 0) +
		",`revision`=`revision`+1,`updatedBy`=" + updater +
		" WHERE `id`=1 AND `revision`=" + parsed.expectedRevision
	try {
		ORM.engine.executeAsync(sql, function(_) {
			phoenix.features.Settings.select(function(rows) {
				phoenix.features.Settings.busy = false
				if (rows == null || rows.len() == 0) { callback(false, "database", phoenix.features.Settings.snapshot(), []); return }
				phoenix.features.Settings.applyRow(rows[0])
				local applied = phoenix.features.Settings.revision == parsed.expectedRevision + 1 && phoenix.features.Settings.profile == parsed.profile
				if (applied) foreach (key in phoenix.features.Settings.keys) if (phoenix.features.Settings.flags[key] != parsed.flags[key]) { applied = false; break }
				if (!applied) { phoenix.features.Settings.broadcast(); callback(false, "conflict", phoenix.features.Settings.snapshot(), []); return }
				foreach (key in changed) {
					try { callEvent("phoenix.features.OnChanged", key, phoenix.features.Settings.flags[key]) } catch (e) {}
				}
				phoenix.features.Settings.broadcast()
				callback(true, "", phoenix.features.Settings.snapshot(), changed)
			})
		})
	} catch (e) {
		phoenix.features.Settings.busy = false
		callback(false, "database", phoenix.features.Settings.snapshot(), [])
	}
}

phoenix.features.Message.FeatureSettingsRequest.bind(function(playerId, _message) { phoenix.features.Settings.sendTo(playerId) })
addEventHandler("onPlayerJoin", function(playerId) { phoenix.features.Settings.sendTo(playerId) })
addEventHandler("phoenix.character.OnSelected", function(playerId, _characterId) { phoenix.features.Settings.sendTo(playerId) })
addEventHandler("phoenix.database.OnReady", function() { phoenix.features.Settings.load() })