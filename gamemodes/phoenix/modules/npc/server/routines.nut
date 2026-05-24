phoenix.npc.Routines <- {

	cache = {}
	loaded = false
	ensured = false

	function _esc(v) { try { return ORM.engine.escape(v.tostring()) } catch (e) { return v.tostring() } }

	function ensureTable(callback) {
		if (phoenix.npc.Routines.ensured) { if (callback != null) callback(); return }
		local sql = "CREATE TABLE IF NOT EXISTS `phoenix_npc_routines` (" +
			"`id` INT UNSIGNED NOT NULL AUTO_INCREMENT," +
			"`spawnId` INT UNSIGNED NOT NULL," +
			"`enabled` TINYINT NOT NULL DEFAULT 1," +
			"`loop` TINYINT NOT NULL DEFAULT 1," +
			"`nodes` MEDIUMTEXT NOT NULL," +
			"`createdBy` INT UNSIGNED NULL," +
			"`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP," +
			"`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
			"PRIMARY KEY (`id`)," +
			"UNIQUE KEY `uq_npc_routines_spawn` (`spawnId`)," +
			"KEY `idx_npc_routines_enabled` (`enabled`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
		try {
			ORM.engine.executeAsync(sql, function (_) {
				phoenix.npc.Routines.ensured = true
				if (callback != null) callback()
			})
		} catch (e) {
			if (callback != null) callback()
		}
	}

	function rowToObject(r) {
		local read = phoenix.npc.Spawn
		local nodes = []
		local raw = read._readStr(r, "nodes", "")
		if (raw != "") {
			try { nodes = phoenix.npc.Routines.parseNodes(raw) } catch (e) { nodes = [] }
		}
		return {
			id = read._readInt(r, "id", 0),
			spawnId = read._readInt(r, "spawnId", 0),
			enabled = read._readInt(r, "enabled", 1),
			loop = read._readInt(r, "loop", 1),
			nodes = nodes
		}
	}

	function parseNodes(raw) {
		local out = []
		if (raw == null || raw == "") return out
		local n = raw.len()
		local i = 0
		while (i < n && raw[i] != '[') i += 1
		if (i >= n) return out
		i += 1
		while (i < n) {
			while (i < n && (raw[i] == ' ' || raw[i] == ',' || raw[i] == '\t' || raw[i] == '\n' || raw[i] == '\r')) i += 1
			if (i >= n || raw[i] == ']') break
			if (raw[i] != '{') { i += 1; continue }
			local start = i
			local depth = 0
			local inStr = false
			local esc = false
			while (i < n) {
				local ch = raw[i]
				if (esc) { esc = false }
				else if (ch == '\\') { esc = true }
				else if (inStr) { if (ch == '"') inStr = false }
				else if (ch == '"') inStr = true
				else if (ch == '{') depth += 1
				else if (ch == '}') { depth -= 1; if (depth == 0) { i += 1; break } }
				i += 1
			}
			local slice = raw.slice(start, i)
			local node = phoenix.npc.Routines.parseNode(slice)
			if (node != null) out.append(node)
		}
		return out
	}

	function parseNode(raw) {
		if (raw == null || raw == "") return null
		local getStr = function (key) {
			local needle = "\"" + key + "\":\""
			local s = raw.find(needle)
			if (s == null) return ""
			s += needle.len()
			local rest = raw.slice(s)
			local e = -1
			local esc = false
			for (local k = 0; k < rest.len(); k += 1) {
				local ch = rest[k]
				if (esc) { esc = false; continue }
				if (ch == '\\') { esc = true; continue }
				if (ch == '"') { e = k; break }
			}
			if (e < 0) return ""
			return rest.slice(0, e)
		}
		local getNum = function (key, fallback) {
			local needle = "\"" + key + "\":"
			local s = raw.find(needle)
			if (s == null) return fallback
			s += needle.len()
			local rest = raw.slice(s)
			local e = 0
			while (e < rest.len()) {
				local ch = rest[e]
				if (ch == ',' || ch == '}' || ch == ']' || ch == ' ' || ch == '\t') break
				e += 1
			}
			try { return rest.slice(0, e).tofloat() } catch (err) {}
			return fallback
		}
		return {
			type = getStr("type"),
			x = getNum("x", 0.0),
			y = getNum("y", 0.0),
			z = getNum("z", 0.0),
			angle = getNum("angle", 0.0),
			waitMs = getNum("waitMs", 0.0).tointeger(),
			animation = getStr("animation"),
			walkMode = getStr("walkMode"),
			label = getStr("label")
		}
	}

	function serializeNodes(nodes) {
		if (nodes == null || nodes.len() == 0) return "[]"
		local parts = []
		foreach (n in nodes) {
			local type = ("type" in n) ? n.type.tostring() : "waypoint"
			local x = ("x" in n) ? n.x.tofloat() : 0.0
			local y = ("y" in n) ? n.y.tofloat() : 0.0
			local z = ("z" in n) ? n.z.tofloat() : 0.0
			local angle = ("angle" in n) ? n.angle.tofloat() : 0.0
			local waitMs = ("waitMs" in n) ? n.waitMs.tointeger() : 0
			local animation = phoenix.npc.Routines._escStr(("animation" in n) ? n.animation.tostring() : "")
			local walkMode = phoenix.npc.Routines._escStr(("walkMode" in n) ? n.walkMode.tostring() : "walk")
			local label = phoenix.npc.Routines._escStr(("label" in n) ? n.label.tostring() : "")
			local part = "{\"type\":\"" + phoenix.npc.Routines._escStr(type) + "\"," +
				"\"x\":" + x + "," +
				"\"y\":" + y + "," +
				"\"z\":" + z + "," +
				"\"angle\":" + angle + "," +
				"\"waitMs\":" + waitMs + "," +
				"\"animation\":\"" + animation + "\"," +
				"\"walkMode\":\"" + walkMode + "\"," +
				"\"label\":\"" + label + "\"}"
			parts.append(part)
		}
		local result = "["
		for (local i = 0; i < parts.len(); i += 1) {
			if (i > 0) result += ","
			result += parts[i]
		}
		result += "]"
		return result
	}

	function _escStr(s) {
		if (s == null || s == "") return ""
		local out = ""
		for (local i = 0; i < s.len(); i += 1) {
			local ch = s[i]
			if (ch == '\\') out += "\\\\"
			else if (ch == '"') out += "\\\""
			else if (ch == '\n') out += "\\n"
			else if (ch == '\r') out += "\\r"
			else if (ch == '\t') out += "\\t"
			else out += s.slice(i, i + 1)
		}
		return out
	}

	function loadAll(callback) {
		phoenix.npc.Routines.ensureTable(function () {
			ORM.engine.executeAsync("SELECT * FROM `phoenix_npc_routines` WHERE `enabled` = 1", function (rows) {
				phoenix.npc.Routines.cache = {}
				if (rows != null) {
					foreach (r in rows) {
						try {
							local obj = phoenix.npc.Routines.rowToObject(r)
							if (obj.spawnId > 0) phoenix.npc.Routines.cache[obj.spawnId] <- obj
						} catch (e) {}
					}
				}
				phoenix.npc.Routines.loaded = true
				if (callback != null) callback(phoenix.npc.Routines.cache)
			})
		})
	}

	function getBySpawnId(spawnId) {
		if (spawnId in phoenix.npc.Routines.cache) return phoenix.npc.Routines.cache[spawnId]
		return null
	}

	function getForNpc(npcId) {
		local entry = null
		try { entry = phoenix.npc.Spawn._liveByNpcId(npcId) } catch (e) {}
		if (entry == null) return null
		foreach (sid, e in phoenix.npc.Spawn.live) {
			if (e.npcId == npcId) return phoenix.npc.Routines.getBySpawnId(sid)
		}
		return null
	}

	function save(spawnId, input, callback) {
		if (spawnId == null || spawnId <= 0) { if (callback != null) callback(false); return }
		local enabled = ("enabled" in input) ? input.enabled.tointeger() : 1
		local loop = ("loop" in input) ? input.loop.tointeger() : 1
		local nodesRaw = ("nodes" in input) ? input.nodes : []
		local normalizedNodes = phoenix.npc.Routines._normalizeNodes(nodesRaw)
		local createdBy = ("createdBy" in input && input.createdBy != null) ? input.createdBy.tointeger() : 0
		local serialized = phoenix.npc.Routines.serializeNodes(normalizedNodes)
		local esc = phoenix.npc.Routines._esc
		phoenix.npc.Routines.ensureTable(function () {
			local sql = "INSERT INTO `phoenix_npc_routines` (`spawnId`,`enabled`,`loop`,`nodes`,`createdBy`) VALUES (" +
				spawnId + "," + enabled + "," + loop + ",'" + esc(serialized) + "'," +
				(createdBy > 0 ? createdBy.tostring() : "NULL") + ") " +
				"ON DUPLICATE KEY UPDATE `enabled`=VALUES(`enabled`),`loop`=VALUES(`loop`),`nodes`=VALUES(`nodes`)"
			ORM.engine.executeAsync(sql, function (_) {
				local routine = {
					id = 0,
					spawnId = spawnId,
					enabled = enabled,
					loop = loop,
					nodes = normalizedNodes
				}
				phoenix.npc.Routines.cache[spawnId] <- routine
				foreach (sid, e in phoenix.npc.Spawn.live) {
					if (sid == spawnId) { phoenix.npc.Routines.bindRoutineToEntry(e, routine); break }
				}
				if (callback != null) callback(true)
			})
		})
	}

	function _normalizeNodes(raw) {
		local out = []
		if (raw == null) return out
		foreach (n in raw) {
			if (n == null) continue
			local type = ("type" in n && n.type != null) ? n.type.tostring() : "waypoint"
			local nx = 0.0; local ny = 0.0; local nz = 0.0
			local angle = 0.0; local waitMs = 0
			local animation = ""; local walkMode = "walk"; local label = ""
			try { if ("x" in n && n.x != null) nx = n.x.tofloat() } catch (e) {}
			try { if ("y" in n && n.y != null) ny = n.y.tofloat() } catch (e) {}
			try { if ("z" in n && n.z != null) nz = n.z.tofloat() } catch (e) {}
			try { if ("angle" in n && n.angle != null) angle = n.angle.tofloat() } catch (e) {}
			try { if ("waitMs" in n && n.waitMs != null) waitMs = n.waitMs.tointeger() } catch (e) {}
			try { if ("animation" in n && n.animation != null) animation = n.animation.tostring() } catch (e) {}
			try { if ("walkMode" in n && n.walkMode != null) walkMode = n.walkMode.tostring() } catch (e) {}
			try { if ("label" in n && n.label != null) label = n.label.tostring() } catch (e) {}
			out.append({
				type = type, x = nx, y = ny, z = nz, angle = angle,
				waitMs = waitMs, animation = animation, walkMode = walkMode, label = label
			})
		}
		return out
	}

	function remove(spawnId, callback) {
		if (spawnId == null || spawnId <= 0) { if (callback != null) callback(false); return }
		phoenix.npc.Routines.ensureTable(function () {
			ORM.engine.executeAsync("DELETE FROM `phoenix_npc_routines` WHERE `spawnId` = " + spawnId, function (_) {
				if (spawnId in phoenix.npc.Routines.cache) delete phoenix.npc.Routines.cache[spawnId]
				foreach (sid, e in phoenix.npc.Spawn.live) {
					if (sid == spawnId && ("ai" in e) && ("routine" in e.ai)) {
						e.ai.routine <- null
						e.ai.routineIndex <- 0
						e.ai.routineWaitUntil <- 0
					}
				}
				if (callback != null) callback(true)
			})
		})
	}

	function bindRoutineToEntry(entry, routine) {
		if (entry == null) return
		entry.ai.routine <- routine
		entry.ai.routineIndex <- 0
		entry.ai.routineWaitUntil <- 0
		entry.ai.routineAnimApplied <- ""
	}

	function findNearestWaypoint(entry) {
		if (entry == null) return -1
		local r = ("routine" in entry.ai) ? entry.ai.routine : null
		if (r == null || !("nodes" in r) || r.nodes.len() == 0) return -1
		local pos = null
		try { pos = getPlayerPosition(entry.npcId) } catch (e) { return 0 }
		if (pos == null) return 0
		local bestIdx = 0
		local bestDist = 999999999.0
		for (local i = 0; i < r.nodes.len(); i += 1) {
			local n = r.nodes[i]
			if (n.type == "wait") continue
			local dx = n.x - pos.x; local dz = n.z - pos.z
			local d = sqrt(dx * dx + dz * dz)
			if (d < bestDist) { bestDist = d; bestIdx = i }
		}
		return bestIdx
	}

	function onSpawnBound(spawnId, entry) {
		if (!phoenix.npc.Routines.loaded) return
		local r = phoenix.npc.Routines.getBySpawnId(spawnId)
		if (r != null) phoenix.npc.Routines.bindRoutineToEntry(entry, r)
	}

	function _walkSpeedMultiplier(mode) {
		if (mode == "run") return 1.6
		if (mode == "sneak") return 0.5
		return 1.0
	}

	function _runAnimFor(entry, mode) {
		local row = entry.row
		local isHuman = false
		try { isHuman = phoenix.npc.AI._isHuman(row) } catch (e) {}
		if (!isHuman) return (mode == "run") ? "S_FISTRUNL" : "S_FISTWALKL"
		return (mode == "run") ? "S_RUNL" : "S_WALKL"
	}

	function tick(entry, now) {
		if (entry == null || !entry.alive) return false
		if (("dialogPartner" in entry.ai) && entry.ai.dialogPartner >= 0) {
			local partner = entry.ai.dialogPartner
			local partnerValid = false
			local underAttack = ("targetPid" in entry.ai) && entry.ai.targetPid >= 0
			try {
				if (!underAttack && isPlayerConnected(partner)) {
					local pp = getPlayerPosition(partner)
					local np = getPlayerPosition(entry.npcId)
					if (pp != null && np != null) {
						local ddx = pp.x - np.x; local ddy = pp.y - np.y; local ddz = pp.z - np.z
						local d3 = sqrt(ddx * ddx + ddy * ddy + ddz * ddz)
						if (d3 <= 800.0) partnerValid = true
					}
				}
			} catch (e) {}
			if (!partnerValid) {
				entry.ai.dialogPartner <- -1
				entry.ai.dialogPaused <- false
			} else {
				if (!("dialogPaused" in entry.ai) || entry.ai.dialogPaused != true) {
					local npcId = entry.npcId
					try { clearNpcActions(npcId) } catch (e) {}
					try {
						foreach (anim in [
							"S_RUN", "S_WALK", "S_STAND",
							"S_FISTRUNL", "S_FISTWALKL",
							"S_1HRUNL", "S_1HWALKL",
							"S_2HRUNL", "S_2HWALKL",
							"S_BOWRUNL", "S_BOWWALKL",
							"S_CBOWRUNL", "S_CBOWWALKL"
						]) {
							try { stopAni(npcId, anim) } catch (eS) {}
						}
					} catch (eS2) {}
					try {
						local pos = getPlayerPosition(npcId)
						if (pos != null) setPlayerPosition(npcId, pos.x, pos.y, pos.z)
					} catch (eP) {}
					local idle = "S_STAND"
					try {
						if ("idleAnimation" in entry.row && entry.row.idleAnimation != null && entry.row.idleAnimation != "") {
							local up = entry.row.idleAnimation.tostring().toupper()
							if (up.find("RUN") == null && up.find("WALK") == null && up.find("ATTACK") == null && up.find("WARN") == null) {
								idle = entry.row.idleAnimation.tostring()
							}
						}
					} catch (eI) {}
					try { playAni(npcId, idle) } catch (eA) {}
					entry.ai.idleApplied <- idle
					entry.ai.dialogPaused <- true
					entry.ai.routineAnimApplied <- ""
				}
				try {
					local np2 = getPlayerPosition(entry.npcId)
					local pp2 = getPlayerPosition(partner)
					if (np2 != null && pp2 != null) {
						phoenix.npc.AI._setAngleTo(entry.npcId, np2.x, np2.z, pp2.x, pp2.z, entry.ai, now, false)
					}
				} catch (e2) {}
				entry.ai.state = "dialog"
				return true
			}
		}
		if (("dialogPaused" in entry.ai) && entry.ai.dialogPaused == true) {
			entry.ai.dialogPaused <- false
			entry.ai.idleApplied <- ""
			entry.ai.routineAnimApplied <- ""
		}
		local r = ("routine" in entry.ai) ? entry.ai.routine : null
		if (r == null || !("nodes" in r) || r.nodes.len() == 0) return false
		if (r.enabled != 1) return false
		if (("targetPid" in entry.ai) && entry.ai.targetPid >= 0) return false
		if (("returning" in entry.ai) && entry.ai.returning == true) return false
		if (entry.ai.state == "loot" || entry.ai.state == "combat" || entry.ai.state == "attack" || entry.ai.state == "chase") return false

		local idx = ("routineIndex" in entry.ai) ? entry.ai.routineIndex : 0
		if (idx >= r.nodes.len()) {
			if (r.loop == 1) { entry.ai.routineIndex = 0; idx = 0 }
			else return false
		}
		local node = r.nodes[idx]
		local pos = null
		try { pos = getPlayerPosition(entry.npcId) } catch (e) { return false }
		if (pos == null) return false

		local type = ("type" in node) ? node.type : "waypoint"

		if (type == "wait") {
			local waitUntil = ("routineWaitUntil" in entry.ai) ? entry.ai.routineWaitUntil : 0
			if (waitUntil == 0) {
				entry.ai.routineWaitUntil <- now + node.waitMs
				if (node.animation != "" && entry.ai.routineAnimApplied != node.animation) {
					try { playAni(entry.npcId, node.animation) } catch (e) {}
					entry.ai.routineAnimApplied <- node.animation
				}
				entry.ai.state = "routine-wait"
				return true
			}
			if (now >= waitUntil) {
				entry.ai.routineWaitUntil <- 0
				entry.ai.routineIndex = idx + 1
				entry.ai.routineAnimApplied <- ""
				return true
			}
			return true
		}

		local tx = ("x" in node) ? node.x : 0.0
		local ty = ("y" in node) ? node.y : 0.0
		local tz = ("z" in node) ? node.z : 0.0
		local dx = tx - pos.x
		local dz = tz - pos.z
		local dist = sqrt(dx * dx + dz * dz)
		if (dist < 80.0) {
			if (node.angle != 0.0) {
				try { setPlayerAngle(entry.npcId, node.angle, true) } catch (e) {}
			}
			if (node.animation != "") {
				try { playAni(entry.npcId, node.animation) } catch (e) {}
				entry.ai.routineAnimApplied <- node.animation
			}
			local waitMs = node.waitMs
			if (waitMs > 0) {
				local waitUntil = ("routineWaitUntil" in entry.ai) ? entry.ai.routineWaitUntil : 0
				if (waitUntil == 0) {
					entry.ai.routineWaitUntil <- now + waitMs
					entry.ai.state = "routine-wait"
					return true
				}
				if (now < waitUntil) return true
				entry.ai.routineWaitUntil <- 0
			}
			entry.ai.routineIndex = idx + 1
			entry.ai.routineAnimApplied <- ""
			phoenix.npc.AI._resetMoveWatch(entry)
			return true
		}

		local mode = ("walkMode" in node) ? node.walkMode : "walk"
		local anim = phoenix.npc.Routines._runAnimFor(entry, mode)

		// Stuck detection: if NPC hasn't made progress toward waypoint, try
		// to navigate around the obstacle using a detour angle.
		local watch = phoenix.npc.AI._moveWatch(entry, pos, dist, now)
		if (watch >= 2) {
			// Severely stuck — skip to next waypoint instead of teleporting
			// (teleport caused NPC to clip under terrain)
			phoenix.npc.AI._resetMoveWatch(entry)
			entry.ai.routineIndex = idx + 1
			entry.ai.routineAnimApplied <- ""
			try { stopAni(entry.npcId, anim) } catch (eS) {}
			phoenix.npc.AI._ensureIdle(entry, true)
			return true
		}
		if (watch == 1) {
			// Mildly stuck — try detour: offset angle by ±90 degrees
			local stuckCount = ("stuckCount" in entry.ai) ? entry.ai.stuckCount : 1
			local side = (stuckCount % 2 == 0) ? -90.0 : 90.0
			local baseAngle = phoenix.npc.AI._vectorAngle(pos.x, pos.z, tx, tz)
			local detourAngle = baseAngle + side
			try { setPlayerAngle(entry.npcId, detourAngle, true) } catch (eA) { try { setPlayerAngle(entry.npcId, detourAngle) } catch (eA2) {} }
			try {
				local cur = getPlayerAni(entry.npcId)
				if (cur != anim) playAni(entry.npcId, anim)
			} catch (eP) {}
			entry.ai.state = "routine-move"
			return true
		}

		try {
			phoenix.npc.AI._setAngleTo(entry.npcId, pos.x, pos.z, tx, tz, entry.ai, now, true)
		} catch (e) {}
		try {
			local cur = getPlayerAni(entry.npcId)
			if (cur != anim) playAni(entry.npcId, anim)
		} catch (e) {}
		entry.ai.state = "routine-move"
		return true
	}
}

addEventHandler("onInit", function () {
	setTimer(function () {
		try {
			phoenix.npc.Routines.loadAll(function (_) {
				foreach (sid, entry in phoenix.npc.Spawn.live) {
					phoenix.npc.Routines.onSpawnBound(sid, entry)
				}
			})
		} catch (e) {}
	}, 3500, 1)
})
