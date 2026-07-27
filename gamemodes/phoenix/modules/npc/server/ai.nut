phoenix.npc.AI <- {

	tickIntervalMs = 350
	timer = null
	homeCheckMs = 1200
	homeReturnRadius = 700.0
	homeTeleportRadius = 3600.0
	homeReturnTimeoutMs = 14000
	postCombatSettleMs = 700

	function _dist(ax, ay, az, bx, by, bz) {
		local dx = ax - bx; local dy = ay - by; local dz = az - bz
		return sqrt(dx * dx + dy * dy + dz * dz)
	}

	function _distFlat(ax, az, bx, bz) {
		local dx = ax - bx; local dz = az - bz
		return sqrt(dx * dx + dz * dz)
	}

	function _vectorAngle(fromX, fromZ, toX, toZ) {
		local dx = toX - fromX; local dz = toZ - fromZ
		if (dx == 0 && dz == 0) return 0.0
		local a = atan2(dx, dz) * 180.0 / 3.14159265358979
		if (a < 0) a += 360.0
		return a
	}

	function _angleDiff(a, b) {
		local d = a - b
		while (d > 180.0) d -= 360.0
		while (d < -180.0) d += 360.0
		return d < 0 ? -d : d
	}

	function _effectiveAggro(row) {
		local aggro = row.aggroRadius.tofloat()
		if (aggro > 900.0) aggro = aggro * 0.5
		if (aggro < 250.0) aggro = 250.0
		return aggro
	}

	function _leashRadius(row) {
		local aggro = phoenix.npc.AI._effectiveAggro(row)
		local leash = aggro * 2.4
		local minLeash = aggro + 1400.0
		return leash > minLeash ? leash : minLeash
	}

	function _wmName(wm) {
		switch (wm) {
			case WEAPONMODE_FIST: return "FIST"
			case WEAPONMODE_1HS:  return "1H"
			case WEAPONMODE_2HS:  return "2H"
			case WEAPONMODE_BOW:  return "BOW"
			case WEAPONMODE_CBOW: return "CBOW"
			case WEAPONMODE_MAG:  return "MAG"
		}
		return "FIST"
	}

	function _isHuman(row) {
		return row.kind == "humanoid" || row.kind == "npc" || row.kind == "merchant" || row.kind == "guard"
	}

	function _resolveWeaponMode(row, distance = -1.0) {
		if (!phoenix.npc.AI._isHuman(row)) return WEAPONMODE_FIST
		local rangedInst = ("ranged" in row && row.ranged != null && row.ranged != "") ? row.ranged : ""
		if (rangedInst != "" && distance > 400.0) {
			try {
				local rs = phoenix.item.find(rangedInst)
				if (rs != null) {
					if (rs.category == PhoenixItemCategory.Bow) return WEAPONMODE_BOW
					if (rs.category == PhoenixItemCategory.Crossbow) return WEAPONMODE_CBOW
				}
			} catch (e) {}
			local rup = rangedInst.toupper()
			if (rup.find("CBOW") != null || rup.find("CROSSBOW") != null) return WEAPONMODE_CBOW
			return WEAPONMODE_BOW
		}
		local w = ("weapon" in row) ? row.weapon : ""
		if ((w == null || w == "") && "ranged" in row) w = row.ranged
		if (w == null || w == "") return WEAPONMODE_FIST
		try {
			local scheme = phoenix.item.find(w)
			if (scheme != null) {
				// If close range and weapon is ranged-only, check if NPC has
				// a separate melee weapon in metadata to fall back to
				if (distance >= 0.0 && distance <= 400.0) {
					if (scheme.category == PhoenixItemCategory.Bow || scheme.category == PhoenixItemCategory.Crossbow) {
						local melee = phoenix.npc.AI._metadataEquip(row, "melee")
						if (melee == null || melee == "") melee = phoenix.npc.AI._metadataEquip(row, "weapon")
						if (melee != null && melee != "" && melee != w) {
							try {
								local ms = phoenix.item.find(melee)
								if (ms != null) {
									if (ms.category == PhoenixItemCategory.Weapon2H) return WEAPONMODE_2HS
									if (ms.category == PhoenixItemCategory.Weapon1H) return WEAPONMODE_1HS
								}
							} catch (eM) {}
						}
						return WEAPONMODE_FIST
					}
				}
				if (scheme.category == PhoenixItemCategory.Weapon2H) return WEAPONMODE_2HS
				if (scheme.category == PhoenixItemCategory.Bow) return WEAPONMODE_BOW
				if (scheme.category == PhoenixItemCategory.Crossbow) return WEAPONMODE_CBOW
				if (scheme.category == PhoenixItemCategory.Weapon1H) return WEAPONMODE_1HS
			}
		} catch (e) {}
		// Scheme not found — try to detect from item name patterns
		local up = w.toupper()
		if (up.find("CROSSBOW") != null || up.find("CBOW") != null) return WEAPONMODE_CBOW
		if (up.find("ITRC_") != null) return WEAPONMODE_CBOW
		if (up.find("BOW") != null) return WEAPONMODE_BOW
		if (up.find("ITRW_") != null) return WEAPONMODE_BOW
		if (up.find("2H") != null) return WEAPONMODE_2HS
		// For unregistered items without "2H" in name, use 1HS — G2O drawWeapon
		// with WEAPONMODE_1HS works for both 1H and 2H melee weapons.
		return WEAPONMODE_1HS
	}

	function _runAnimFor(row, wm = -1) {
		if (!phoenix.npc.AI._isHuman(row)) return "S_FISTRUNL"
		if (wm < 0) wm = phoenix.npc.AI._resolveWeaponMode(row)
		return "S_" + phoenix.npc.AI._wmName(wm) + "RUNL"
	}

	function _walkAnimFor(row, wm = -1) {
		if (!phoenix.npc.AI._isHuman(row)) return "S_FISTWALKL"
		if (wm < 0) wm = phoenix.npc.AI._resolveWeaponMode(row)
		return "S_" + phoenix.npc.AI._wmName(wm) + "WALKL"
	}

	function _neutralWalkAnim(row) {
		if (!phoenix.npc.AI._isHuman(row)) return "S_FISTWALKL"
		return "S_WALKL"
	}

	function _neutralRunAnim(row) {
		if (!phoenix.npc.AI._isHuman(row)) return "S_FISTRUNL"
		return "S_RUNL"
	}

	function _attackAnimFor(row, wm = -1) {
		if (!phoenix.npc.AI._isHuman(row)) return "T_FISTATTACK"
		if (wm < 0) wm = phoenix.npc.AI._resolveWeaponMode(row)
		return "T_" + phoenix.npc.AI._wmName(wm) + "ATTACK"
	}

	function _play(npcId, anim) {
		if (anim == null || anim == "") return
		try {
			if (getPlayerAni(npcId) == anim) return
		} catch (e) {}
		try { playAni(npcId, anim) } catch (e) { try { playAnimation(npcId, anim) } catch (e2) {} }
	}

	function _isBadIdleAnim(anim) {
		if (anim == null || anim == "") return true
		local up = anim.tostring().toupper()
		if (up == "S_RUN") return true
		if (up.find("RUN") != null) return true
		if (up.find("WALK") != null) return true
		if (up.find("ATTACK") != null) return true
		if (up.find("WARN") != null) return true
		return false
	}

	function _idleAnim(row) {
		local fallback = phoenix.npc.AI._isHuman(row) ? "S_STAND" : "S_FISTSTAND"
		if (row == null || !("idleAnimation" in row) || phoenix.npc.AI._isBadIdleAnim(row.idleAnimation)) return fallback
		return row.idleAnimation
	}

	function _metadataEquip(row, key) {
		try { return phoenix.npc.Spawn._metadataValue(row.metadata, key) } catch (e) {}
		return ""
	}

	function _rangedAmmoFor(wm) {
		if (wm == WEAPONMODE_BOW) return "ITRW_ARROW"
		if (wm == WEAPONMODE_CBOW) return "ITRW_BOLT"
		return ""
	}

	function _attackRangeFor(row, wm = -1) {
		local range = row.attackRange > 0 ? row.attackRange : 250
		if (wm < 0) wm = phoenix.npc.AI._resolveWeaponMode(row, range)
		if (wm == WEAPONMODE_BOW || wm == WEAPONMODE_CBOW) {
			if (range < 700) range = 700
		}
		return range
	}

	function _ensureEquipment(entry, includeWeapon = true, force = false) {
		if (entry == null || !phoenix.npc.AI._isHuman(entry.row)) return
		local now = getTickCount()
		if (!force && ("lastEquipmentAt" in entry.ai) && now - entry.ai.lastEquipmentAt < 2500) return
		entry.ai.lastEquipmentAt <- now
		local row = entry.row
		local npcId = entry.npcId
		foreach (key in ["armor", "helmet", "shield"]) {
			local inst = phoenix.npc.AI._metadataEquip(row, key)
			if (inst == null || inst == "") continue
			try { equipItem(npcId, inst) } catch (e) {}
		}
		if (!includeWeapon) return
		local weapon = ("weapon" in row) ? row.weapon : ""
		if (weapon == null || weapon == "") weapon = phoenix.npc.AI._metadataEquip(row, "melee")
		if (weapon == null || weapon == "") weapon = phoenix.npc.AI._metadataEquip(row, "ranged")
		if (weapon != null && weapon != "") { try { equipItem(npcId, weapon) } catch (e2) {} }
		// Ensure NPC always has ammo for ranged weapons
		local rangedInst = phoenix.npc.AI._metadataEquip(row, "ranged")
		if (rangedInst != null && rangedInst != "") {
			try { giveItem(npcId, "ITRW_ARROW", 200) } catch (e3) {}
			try { giveItem(npcId, "ITRW_BOLT", 200) } catch (e4) {}
		}
	}

	function _ensureIdle(entry, force = false) {
		local anim = phoenix.npc.AI._idleAnim(entry.row)
		if (anim == null || anim == "") return
		if (!force && ("idleApplied" in entry.ai) && entry.ai.idleApplied == anim) return
		entry.ai.idleApplied <- anim
		phoenix.npc.AI._play(entry.npcId, anim)
	}

	function _sheatheWeapon(entry) {
		if (entry == null || !phoenix.npc.AI._isHuman(entry.row)) return
		if (("weaponSheathed" in entry.ai) && entry.ai.weaponSheathed == true) return
		local npcId = entry.npcId
		try {
			if (getPlayerWeaponMode(npcId) != WEAPONMODE_NONE) drawWeapon(npcId, WEAPONMODE_NONE)
		} catch (e) {}
		entry.ai.weaponSheathed <- true
		phoenix.npc.AI._ensureEquipment(entry, false, true)
	}

	function _stopCombatAnims(entry) {
		if (entry == null) return
		local npcId = entry.npcId
		foreach (anim in [
			"S_RUN", "S_WALK", "S_STAND",
			"S_FISTRUNL", "S_FISTWALKL",
			"S_1HRUNL", "S_1HWALKL",
			"S_2HRUNL", "S_2HWALKL",
			"S_BOWRUNL", "S_BOWWALKL",
			"S_CBOWRUNL", "S_CBOWWALKL",
			"T_WARN", "T_FISTATTACK", "T_1HATTACK", "T_2HATTACK", "T_BOWATTACK", "T_CBOWATTACK"
		]) {
			try { stopAni(npcId, anim) } catch (e) {}
		}
	}

	function _clearCombatMovement(entry) {
		if (entry == null) return
		if (("combatCleared" in entry.ai) && entry.ai.combatCleared == true) return
		entry.ai.combatCleared <- true
		local npcId = entry.npcId
		local human = phoenix.npc.AI._isHuman(entry.row)
		try { clearNpcActions(npcId) } catch (e) {}
		if (human) {
			try {
				local p = getPlayerPosition(npcId)
				if (p != null) setPlayerPosition(npcId, p.x, p.y, p.z)
			} catch (ep) {}
		}
		phoenix.npc.AI._stopCombatAnims(entry)
		try { stopAni(npcId, phoenix.npc.AI._runAnimFor(entry.row)) } catch (e2) {}
		try { stopAni(npcId, phoenix.npc.AI._walkAnimFor(entry.row)) } catch (e3) {}
		local fistRun = phoenix.npc.AI._runAnimFor(entry.row, WEAPONMODE_FIST)
		local fistWalk = phoenix.npc.AI._walkAnimFor(entry.row, WEAPONMODE_FIST)
		try { stopAni(npcId, fistRun) } catch (e4) {}
		try { stopAni(npcId, fistWalk) } catch (e5) {}
		if (human) phoenix.npc.AI._sheatheWeapon(entry)
	}

	function _pinPosition(entry, pos) {
		if (entry == null || pos == null) return
		try { setPlayerPosition(entry.npcId, pos.x, pos.y, pos.z) } catch (e) {}
	}

	function _stop(npcId, anim = null) {
		try {
			if (anim == null) return
			else stopAni(npcId, anim)
		} catch (e) {}
	}

	function _actionFinished(npcId, actionId) {
		if (actionId == null || actionId < 0) return true
		try { return isNpcActionFinished(npcId, actionId) } catch (e) { return true }
	}

	function _lastAction(npcId) {
		try { return getNpcLastActionId(npcId) } catch (e) { return -1 }
	}

	function _findHostileTarget(npcId, npcPos, radius, world) {
		local best = -1
		local bestDist = radius
		local npcVw = 0
		try { npcVw = getPlayerVirtualWorld(npcId) } catch (e) {}
		for (local pid = 0; pid < getMaxSlots(); pid += 1) {
			if (!isPlayerConnected(pid)) continue
			local pw = ""
			try { pw = getPlayerWorld(pid) } catch (e) {}
			if (world != "" && pw != "" && pw != world) continue
			local pvw = 0
			try { pvw = getPlayerVirtualWorld(pid) } catch (e) {}
			if (pvw != npcVw) continue
			try { if (phoenix.account.Auth.isVanished(pid)) continue } catch (e) {}
			try { if (pid in phoenix.player.Gate.reviving) continue } catch (e) {}
			local hp = 0
			try { hp = getPlayerHealth(pid) } catch (e) {}
			if (hp <= 0) continue
			try {
				local p = getPlayerPosition(pid)
				if (p == null) continue
				local d = phoenix.npc.AI._dist(npcPos.x, npcPos.y, npcPos.z, p.x, p.y, p.z)
				if (d < bestDist) { bestDist = d; best = pid }
			} catch (e) {}
		}
		return best
	}

	function _liveNpcEntry(npcId) {
		try { return phoenix.npc.Spawn._liveByNpcId(npcId) } catch (e) {}
		return null
	}

	function _isNpcEnemy(row, otherRow) {
		if (row == null || otherRow == null) return false
		local hostile = ("hostile" in row) ? row.hostile : 0
		local otherHostile = ("hostile" in otherRow) ? otherRow.hostile : 0
		if (hostile == 1) return otherHostile != 1
		return otherHostile == 1
	}

	function _findNpcEnemyTarget(entry, npcPos, radius, world) {
		local now = getTickCount()
		if (entry == null || entry.row == null) return -1
		if (("unconscious" in entry.ai) && entry.ai.unconscious == true) return -1
		if (("returning" in entry.ai) && entry.ai.returning == true) return -1
		if (("postCombatReturn" in entry.ai) && entry.ai.postCombatReturn == true) return -1
		if (("combatCooldownUntil" in entry.ai) && now < entry.ai.combatCooldownUntil) return -1
		local best = -1
		local bestDist = radius
		local npcVw = 0
		try { npcVw = getPlayerVirtualWorld(entry.npcId) } catch (e) {}
		foreach (_sid, other in phoenix.npc.Spawn.live) {
			if (other == null || !other.alive || other.npcId == entry.npcId) continue
			if (("unconscious" in other.ai) && other.ai.unconscious == true) continue
			if (!phoenix.npc.AI._isNpcEnemy(entry.row, other.row)) continue
			local ow = ""
			try { ow = getPlayerWorld(other.npcId) } catch (e) {}
			if (world != "" && ow != "" && ow != world) continue
			local ovw = 0
			try { ovw = getPlayerVirtualWorld(other.npcId) } catch (e) {}
			if (ovw != npcVw) continue
			local hp = 0
			try { hp = getPlayerHealth(other.npcId) } catch (e) {}
			if (hp <= 0) continue
			try {
				local p = getPlayerPosition(other.npcId)
				if (p == null) continue
				local d = phoenix.npc.AI._dist(npcPos.x, npcPos.y, npcPos.z, p.x, p.y, p.z)
				if (d < bestDist) { bestDist = d; best = other.npcId }
			} catch (e) {}
		}
		return best
	}

	function _findCombatTarget(entry, npcPos, radius, world) {
		local now = getTickCount()
		if (("returning" in entry.ai) && entry.ai.returning == true) return -1
		if (("postCombatReturn" in entry.ai) && entry.ai.postCombatReturn == true) return -1
		if (("combatCooldownUntil" in entry.ai) && now < entry.ai.combatCooldownUntil) return -1
		local best = -1
		local bestDist = radius
		if (entry.row.hostile == 1) {
			local playerTarget = phoenix.npc.AI._findHostileTarget(entry.npcId, npcPos, radius, world)
			if (playerTarget >= 0) {
				best = playerTarget
				try {
					local p = getPlayerPosition(playerTarget)
					bestDist = phoenix.npc.AI._dist(npcPos.x, npcPos.y, npcPos.z, p.x, p.y, p.z)
				} catch (e) {}
			}
		}
		local npcTarget = phoenix.npc.AI._findNpcEnemyTarget(entry, npcPos, radius, world)
		if (npcTarget >= 0) {
			try {
				local p = getPlayerPosition(npcTarget)
				local d = phoenix.npc.AI._dist(npcPos.x, npcPos.y, npcPos.z, p.x, p.y, p.z)
				if (d < bestDist) best = npcTarget
			} catch (e) { if (best < 0) best = npcTarget }
		}
		return best
	}

	function _setAngleTo(npcId, fromX, fromZ, toX, toZ, ai = null, now = 0, force = false) {
		local target = phoenix.npc.AI._vectorAngle(fromX, fromZ, toX, toZ)
		try { target = getVectorAngle(fromX, fromZ, toX, toZ) } catch (e) {}
		local current = target
		try { current = getPlayerAngle(npcId) } catch (e) {}
		local diff = target - current
		while (diff > 180.0) diff -= 360.0
		while (diff < -180.0) diff += 360.0
		local absDiff = diff < 0 ? -diff : diff
		if (absDiff < 8.0) return
		local applied = target
		if (ai != null) { ai.lastAngle <- applied }
		try { setPlayerAngle(npcId, applied, true) } catch (e) { try { setPlayerAngle(npcId, applied) } catch (e2) {} }
	}

	function _runAt(entry, pos, tx, tz, anim, now = 0, stateName = "run") {
		local npcId = entry.npcId
		entry.ai.idleApplied <- ""
		phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, tx, tz, entry.ai, now, true)
		try {
			if (getPlayerAni(npcId) != anim) playAni(npcId, anim)
		} catch (e) {}
		entry.ai.state = stateName
	}

	function _kickRun(entry, pos, tx, tz, anim, now = 0, stateName = "run") {
		local npcId = entry.npcId
		entry.ai.idleApplied <- ""
		entry.ai.lastAngle <- -999.0
		try { stopAni(npcId, anim) } catch (e) {}
		phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, tx, tz, entry.ai, now, true)
		try { playAni(npcId, anim) } catch (e2) {}
		entry.ai.state = stateName
	}

	function _restoreHomeAngle(entry) {
		if (entry == null) return
		entry.ai.lastAngle <- -999.0
		try { setPlayerAngle(entry.npcId, entry.row.angle, true) } catch (e) { try { setPlayerAngle(entry.npcId, entry.row.angle) } catch (e2) {} }
	}

	function _chaseTarget(entry, target, pos, tp, now) {
		local row = entry.row
		local npcId = entry.npcId
		entry.ai.idleApplied <- ""
		phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, tp.x, tp.z, entry.ai, now, true)
		local anim = phoenix.npc.AI._runAnimFor(row)
		try {
			if (getPlayerAni(npcId) != anim) playAni(npcId, anim)
		} catch (e) {}
		entry.ai.state = "chase"
	}

	function _resetMoveWatch(entry) {
		entry.ai.moveWatchAt <- 0
		entry.ai.moveWatchX <- 0.0
		entry.ai.moveWatchY <- 0.0
		entry.ai.moveWatchZ <- 0.0
		entry.ai.moveWatchDist <- 0.0
		entry.ai.stuckCount <- 0
		entry.ai.detourUntil <- 0
	}

	function _moveWatch(entry, pos, dist, now) {
		if (!("moveWatchAt" in entry.ai) || entry.ai.moveWatchAt <= 0) {
			entry.ai.moveWatchAt <- now
			entry.ai.moveWatchX <- pos.x
			entry.ai.moveWatchY <- pos.y
			entry.ai.moveWatchZ <- pos.z
			entry.ai.moveWatchDist <- dist
			entry.ai.stuckCount <- 0
			return 0
		}
		if (now - entry.ai.moveWatchAt < 1200) return 0
		local moved = phoenix.npc.AI._dist(pos.x, pos.y, pos.z, entry.ai.moveWatchX, entry.ai.moveWatchY, entry.ai.moveWatchZ)
		local progress = entry.ai.moveWatchDist - dist
		entry.ai.moveWatchAt <- now
		entry.ai.moveWatchX <- pos.x
		entry.ai.moveWatchY <- pos.y
		entry.ai.moveWatchZ <- pos.z
		entry.ai.moveWatchDist <- dist
		if (progress < 30.0) {
			entry.ai.stuckCount <- (("stuckCount" in entry.ai) ? entry.ai.stuckCount : 0) + 1
			return entry.ai.stuckCount >= 2 ? 2 : 1
		}
		entry.ai.stuckCount <- 0
		return 0
	}

	function _detourReturn(entry, pos, now) {
		local baseAngle = phoenix.npc.AI._vectorAngle(pos.x, pos.z, entry.ai.anchorX, entry.ai.anchorZ)
		local side = (("stuckCount" in entry.ai) && (entry.ai.stuckCount % 2) == 0) ? -95.0 : 95.0
		local angle = (baseAngle + side) * 3.14159265358979 / 180.0
		local radius = 260.0 + ((("stuckCount" in entry.ai) ? entry.ai.stuckCount : 0) * 65.0)
		entry.ai.detourX <- pos.x + sin(angle) * radius
		entry.ai.detourZ <- pos.z + cos(angle) * radius
		entry.ai.detourUntil <- now + 1800
		phoenix.npc.AI._runAt(entry, pos, entry.ai.detourX, entry.ai.detourZ, phoenix.npc.AI._neutralWalkAnim(entry.row), now, "return")
	}

	function _finishReturn(entry, forceIdle = false) {
		entry.ai.combatCleared <- false
		phoenix.npc.AI._clearCombatMovement(entry)
		entry.ai.state = "idle"
		entry.ai.returning <- false
		entry.ai.postCombatReturn <- false
		entry.ai.postCombatSettleUntil <- 0
		entry.ai.combatCooldownUntil <- 0
		entry.ai.lastReturnDist <- 0.0
		entry.ai.lastReturnAt <- 0
		entry.ai.returnStartedAt <- 0
		entry.ai.weaponSheathed <- true
		entry.ai.nextWander <- getTickCount() + 6000 + (rand() % 6000)
		if ("routine" in entry.ai && entry.ai.routine != null) {
			local nearest = 0
			try { nearest = phoenix.npc.Routines.findNearestWaypoint(entry) } catch (eN) {}
			if (nearest < 0) nearest = 0
			entry.ai.routineIndex <- nearest
			entry.ai.routineWaitUntil <- 0
			entry.ai.routineAnimApplied <- ""
		}
		phoenix.npc.AI._resetMoveWatch(entry)
		phoenix.npc.AI._restoreHomeAngle(entry)
		phoenix.npc.AI._ensureIdle(entry, forceIdle)
	}

	function _teleportHome(entry, forceIdle = true) {
		// If NPC has a routine, teleport to nearest waypoint instead of spawn
		local tx = entry.ai.anchorX
		local ty = entry.ai.anchorY
		local tz = entry.ai.anchorZ
		try {
			if ("routine" in entry.ai && entry.ai.routine != null && "nodes" in entry.ai.routine && entry.ai.routine.nodes.len() > 0) {
				local nearest = 0
				try { nearest = phoenix.npc.Routines.findNearestWaypoint(entry) } catch (eN) {}
				if (nearest < 0) nearest = 0
				local node = entry.ai.routine.nodes[nearest]
				if (node != null && "x" in node) { tx = node.x; ty = node.y; tz = node.z }
			}
		} catch (eR) {}
		try { setPlayerPosition(entry.npcId, tx, ty, tz) } catch (e) {}
		try { setPlayerAngle(entry.npcId, entry.row.angle) } catch (e2) {}
		entry.ai.targetPid = -1
		entry.ai.warnStart = 0
		entry.ai.waitAction = -1
		entry.ai.lastAttack = 0
		entry.ai.idleApplied <- ""
		phoenix.npc.AI._finishReturn(entry, forceIdle)
	}

	function _hasLiveTarget(entry, pos, world) {
		local target = ("targetPid" in entry.ai) ? entry.ai.targetPid : -1
		if (target < 0) return false
		local info = phoenix.npc.AI._targetInfo(target, pos, world)
		if (info == null) return false
		return info.distance <= phoenix.npc.AI._leashRadius(entry.row)
	}

	function _forceReturn(entry, pos, dist, now) {
		phoenix.npc.AI._clearCombatMovement(entry)
		entry.ai.targetPid = -1
		entry.ai.warnStart = 0
		entry.ai.waitAction = -1
		entry.ai.lastAttack = 0
		entry.ai.idleApplied <- ""
		entry.ai.returning <- true
		entry.ai.lastReturnDist <- dist
		entry.ai.lastReturnAt <- now
		entry.ai.returnStartedAt <- now
		phoenix.npc.AI._resetMoveWatch(entry)
		phoenix.npc.AI._softReturn(entry, pos, now)
	}

	function _postCombatReturn(entry, pos, world, now) {
		if (!("postCombatReturn" in entry.ai) || entry.ai.postCombatReturn != true) return false
		if (phoenix.npc.AI._hasLiveTarget(entry, pos, world)) {
			entry.ai.postCombatReturn <- false
			entry.ai.postCombatSettleUntil <- 0
			return false
		}
		phoenix.npc.AI._clearCombatMovement(entry)
		local dist = phoenix.npc.AI._distFlat(pos.x, pos.z, entry.ai.anchorX, entry.ai.anchorZ)
		if (("postCombatSettleUntil" in entry.ai) && now < entry.ai.postCombatSettleUntil) {
			phoenix.npc.AI._pinPosition(entry, pos)
			phoenix.npc.AI._setAngleTo(entry.npcId, pos.x, pos.z, entry.ai.anchorX, entry.ai.anchorZ, entry.ai, now, true)
			phoenix.npc.AI._ensureIdle(entry, true)
			return true
		}
		if (dist < 80.0) {
			phoenix.npc.AI._finishReturn(entry, true)
			return true
		}
		if (dist >= phoenix.npc.AI.homeTeleportRadius) {
			phoenix.npc.AI._teleportHome(entry, true)
			return true
		}
		entry.ai.postCombatReturn <- false
		phoenix.npc.AI._softReturn(entry, pos, now)
		return true
	}

	function _superviseHome(entry, pos, world, now) {
		if (entry == null || !entry.alive || pos == null) return false
		if (("nextHomeCheckAt" in entry.ai) && now < entry.ai.nextHomeCheckAt) return false
		entry.ai.nextHomeCheckAt <- now + phoenix.npc.AI.homeCheckMs
		local hasRoutine = ("routine" in entry.ai) && entry.ai.routine != null && ("nodes" in entry.ai.routine) && entry.ai.routine.nodes.len() > 0 && entry.ai.routine.enabled == 1
		if (hasRoutine) {
			local hasTargetRoutine = phoenix.npc.AI._hasLiveTarget(entry, pos, world)
			if (!hasTargetRoutine) return false
			local leashR = phoenix.npc.AI._leashRadius(entry.row)
			local distR = phoenix.npc.AI._distFlat(pos.x, pos.z, entry.ai.anchorX, entry.ai.anchorZ)
			if (distR > leashR * 1.75) {
				phoenix.npc.AI._teleportHome(entry, true)
				return true
			}
			return false
		}
		local dist = phoenix.npc.AI._distFlat(pos.x, pos.z, entry.ai.anchorX, entry.ai.anchorZ)
		local hasTarget = phoenix.npc.AI._hasLiveTarget(entry, pos, world)
		local hasLockedTarget = (("targetPid" in entry.ai) && entry.ai.targetPid >= 0)
		local state = ("state" in entry.ai) ? entry.ai.state : "idle"
		if (dist <= 90.0) {
			if (!hasTarget && !hasLockedTarget && (state == "chase" || state == "attack" || state == "run" || state == "parade" || state == "combat" || (("returning" in entry.ai) && entry.ai.returning == true) || (("weaponSheathed" in entry.ai) && entry.ai.weaponSheathed != true))) {
				phoenix.npc.AI._finishReturn(entry, true)
				return true
			}
			if (!hasTarget) {
				if (phoenix.npc.AI._isHuman(entry.row)) {
					try {
						if (phoenix.npc.AI._angleDiff(getPlayerAngle(entry.npcId), entry.row.angle) > 5.0) {
							phoenix.npc.AI._restoreHomeAngle(entry)
							phoenix.npc.AI._ensureIdle(entry, true)
							return true
						}
					} catch (e) {}
				}
			}
			return false
		}
		local leash = phoenix.npc.AI._leashRadius(entry.row)
		if (dist >= phoenix.npc.AI.homeTeleportRadius || (hasTarget && dist > leash * 1.75)) {
			phoenix.npc.AI._teleportHome(entry, true)
			return true
		}
		if (hasTarget && dist <= leash * 1.15) return false
		local returning = ("returning" in entry.ai) && entry.ai.returning == true
		if (returning) {
			local started = ("returnStartedAt" in entry.ai) ? entry.ai.returnStartedAt : 0
			if (started > 0 && now - started > phoenix.npc.AI.homeReturnTimeoutMs && dist > 180.0) {
				phoenix.npc.AI._teleportHome(entry, true)
				return true
			}
			return false
		}
		local mustReturn = dist > phoenix.npc.AI.homeReturnRadius
		if (!hasTarget && (state == "chase" || state == "attack" || state == "run" || state == "parade" || state == "combat") && dist > 120.0) mustReturn = true
		if (!hasTarget && mustReturn) {
			phoenix.npc.AI._forceReturn(entry, pos, dist, now)
			return true
		}
		return false
	}

	function _softReturn(entry, pos, now) {
		local row = entry.row
		local dist = phoenix.npc.AI._distFlat(pos.x, pos.z, entry.ai.anchorX, entry.ai.anchorZ)
		if (dist < 80.0) {
			if (("returning" in entry.ai) && entry.ai.returning == true) {
				phoenix.npc.AI._finishReturn(entry, true)
			} else {
				try { stopAni(entry.npcId, phoenix.npc.AI._neutralWalkAnim(row)) } catch (e) {}
				try { stopAni(entry.npcId, phoenix.npc.AI._neutralRunAnim(row)) } catch (e) {}
			}
			return false
		}
		if (!("returning" in entry.ai) || entry.ai.returning != true) {
			entry.ai.returning <- true
			entry.ai.lastReturnDist <- dist
			entry.ai.lastReturnAt <- now
			entry.ai.returnStartedAt <- now
			phoenix.npc.AI._resetMoveWatch(entry)
		} else {
			local previous = ("lastReturnDist" in entry.ai) ? entry.ai.lastReturnDist : dist
			if (dist < previous - 80.0) {
				entry.ai.lastReturnDist <- dist
				entry.ai.lastReturnAt <- now
			} else if (("lastReturnAt" in entry.ai) && now - entry.ai.lastReturnAt > 4500 && dist > 150.0) {
				phoenix.npc.AI._teleportHome(entry, true)
				return true
			}
		}
		if (("detourUntil" in entry.ai) && now < entry.ai.detourUntil && ("detourX" in entry.ai)) {
			phoenix.npc.AI._runAt(entry, pos, entry.ai.detourX, entry.ai.detourZ, phoenix.npc.AI._neutralWalkAnim(row), now, "return")
			return true
		}
		local watch = phoenix.npc.AI._moveWatch(entry, pos, dist, now)
		if (watch == 2) {
			local stuck = ("stuckCount" in entry.ai) ? entry.ai.stuckCount : 0
			if (stuck >= 3 || dist > phoenix.npc.AI._leashRadius(row) * 1.35) {
				phoenix.npc.AI._teleportHome(entry, true)
				return true
			}
			phoenix.npc.AI._detourReturn(entry, pos, now)
			return true
		}
		if (watch == 1) {
			phoenix.npc.AI._kickRun(entry, pos, entry.ai.anchorX, entry.ai.anchorZ, phoenix.npc.AI._neutralWalkAnim(row), now, "return")
			return true
		}
		phoenix.npc.AI._runAt(entry, pos, entry.ai.anchorX, entry.ai.anchorZ, phoenix.npc.AI._neutralWalkAnim(row), now, "return")
		return true
	}

	function _targetInfo(target, pos, world) {
		if (target < 0) return null
		local npcEntry = phoenix.npc.AI._liveNpcEntry(target)
		local isLiveNpc = npcEntry != null && npcEntry.alive
		if (isLiveNpc && ("unconscious" in npcEntry.ai) && npcEntry.ai.unconscious == true) return null
		if (!isLiveNpc) {
			try { if (!isPlayerConnected(target)) return null } catch (e) { return null }
			try { if (target in phoenix.player.Gate.reviving) return null } catch (e) {}
		}
		local pw = ""
		try { pw = getPlayerWorld(target) } catch (e) {}
		if (world != "" && pw != "" && pw != world) return null
		if (!isLiveNpc) { try { if (phoenix.account.Auth.isVanished(target)) return null } catch (e) {} }
		local hp = 0
		try { hp = getPlayerHealth(target) } catch (e) {}
		if (hp <= 0) return null
		local tp = null
		try { tp = getPlayerPosition(target) } catch (e) {}
		if (tp == null) return null
		return { pos = tp, distance = phoenix.npc.AI._dist(pos.x, pos.y, pos.z, tp.x, tp.y, tp.z) }
	}

	function _currentTarget(entry, pos, world, now) {
		local target = ("targetPid" in entry.ai) ? entry.ai.targetPid : -1
		local info = phoenix.npc.AI._targetInfo(target, pos, world)
		if (info == null) {
			entry.ai.targetPid = -1
			entry.ai.warnStart = 0
			return null
		}
		if (info.distance <= phoenix.npc.AI._leashRadius(entry.row)) {
			entry.ai.lastSeen <- now
			return { pid = target, pos = info.pos, distance = info.distance }
		}
		local lastSeen = ("lastSeen" in entry.ai) ? entry.ai.lastSeen : 0
		if (lastSeen > 0 && now - lastSeen < 4500) return { pid = target, pos = info.pos, distance = info.distance }
		entry.ai.targetPid = -1
		entry.ai.warnStart = 0
		return null
	}

	function _ensureWeapon(entry, wm) {
		local npcId = entry.npcId
		local ai = entry.ai
		if (wm == WEAPONMODE_NONE) return true
		local cur = WEAPONMODE_NONE
		try { cur = getPlayerWeaponMode(npcId) } catch (e) {}
		if (cur == wm) return true
		phoenix.npc.AI._ensureEquipment(entry, true, true)
		try { if (wm == WEAPONMODE_MAG) readySpell(npcId, 0, 0); else drawWeapon(npcId, wm) } catch (e) {}
		phoenix.npc.AI._ensureEquipment(entry, true, true)
		ai.waitAction = phoenix.npc.AI._lastAction(npcId)
		return false
	}

	function _haltCombatMovement(entry) {
		if (entry == null) return
		local npcId = entry.npcId
		entry.ai.idleApplied <- ""
		try { clearNpcActions(npcId) } catch (e) {}
		foreach (anim in [
			"S_RUN", "S_WALK", "S_STAND",
			"S_FISTRUNL", "S_FISTWALKL",
			"S_1HRUNL", "S_1HWALKL",
			"S_2HRUNL", "S_2HWALKL",
			"S_BOWRUNL", "S_BOWWALKL",
			"S_CBOWRUNL", "S_CBOWWALKL"
		]) {
			try { stopAni(npcId, anim) } catch (e) {}
		}
	}

	function _applyDamageToTarget(attackerNpcId, target, damage) {
		if (!phoenix.features.Settings.isEnabled("npc.ai")) return false
		if (target < 0 || damage <= 0) return false
		local npcEntry = phoenix.npc.AI._liveNpcEntry(target)
		if (npcEntry != null && npcEntry.alive) {
			if (("unconscious" in npcEntry.ai) && npcEntry.ai.unconscious == true) return false
			local hp = 0
			try { hp = getPlayerHealth(target) } catch (e) {}
			if (hp <= 0) return false
			local newHp = hp - damage
			if (newHp < 0) newHp = 0
			local lethal = newHp <= 0
			local divertToKnockdown = false
			try { divertToKnockdown = lethal && phoenix.npc.AI._isHuman(npcEntry.row) } catch (eHk) {}
			if (divertToKnockdown) {
				try { setPlayerHealth(target, 1) } catch (eSh) {}
				try { phoenix.npc.AI._knockdown(npcEntry, attackerNpcId) } catch (eKd) {}
				try { phoenix.npc.Spawn.broadcastNameplates() } catch (eBc) {}
				return true
			}
			try { setPlayerHealth(target, newHp) } catch (e) {}
			try { phoenix.npc.Spawn.broadcastNameplates() } catch (e2) {}
			if (lethal) phoenix.npc.Spawn.onNpcKilled(target, attackerNpcId)
			return true
		}
		try {
			if (!isPlayerConnected(target)) return false
			local killed = phoenix.player.Gate.applyDamage(target, damage, attackerNpcId)
			if (killed) {
				local attackerEntry = phoenix.npc.AI._liveNpcEntry(attackerNpcId)
				if (attackerEntry != null) {
					attackerEntry.ai.killedPlayer <- target
					attackerEntry.ai.killedPlayerAt <- getTickCount()
				}
			}
			return killed
		} catch (e3) {}
		return false
	}

	function _doAttack(entry, target, pos, tp, now) {
		local row = entry.row
		local npcId = entry.npcId
		local dx = tp.x - pos.x; local dz = tp.z - pos.z
		local dist = sqrt(dx * dx + dz * dz)
		local wm = phoenix.npc.AI._resolveWeaponMode(row, dist)
		phoenix.npc.AI._ensureEquipment(entry, true, false)
		phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, tp.x, tp.z, entry.ai, now, true)
		if (!phoenix.npc.AI._actionFinished(npcId, entry.ai.waitAction)) return
		if (!phoenix.npc.AI._ensureWeapon(entry, wm)) return
		if (now - entry.ai.lastAttack < 1100) return
		phoenix.npc.AI._haltCombatMovement(entry)
		entry.ai.lastAttack = now
		local roll = rand() % 100
		try {
			if (roll < 25 && (wm == WEAPONMODE_1HS || wm == WEAPONMODE_2HS)) {
				local wmName = phoenix.npc.AI._wmName(wm)
				local choice = rand() % 3
				local ani = "T_" + wmName + "PARADEJUMPB"
				if (choice == 1) ani = "T_" + wmName + "RUNSTRAFEL"
				else if (choice == 2) ani = "T_" + wmName + "RUNSTRAFER"
				playAni(npcId, ani)
				entry.ai.waitAction = phoenix.npc.AI._lastAction(npcId)
				entry.ai.state = "parade"
				return
			}
			local kind = ATTACK_FORWARD
			if (wm == WEAPONMODE_1HS || wm == WEAPONMODE_2HS) {
				kind = (rand() % 3)
			}
			if (wm == WEAPONMODE_FIST) phoenix.npc.AI._play(npcId, phoenix.npc.AI._attackAnimFor(row, wm))
			if (wm == WEAPONMODE_BOW || wm == WEAPONMODE_CBOW) {
				npcAttackRanged(npcId, target, true)
			} else {
				npcAttackMelee(npcId, target, kind, -1, true)
			}
			entry.ai.waitAction = phoenix.npc.AI._lastAction(npcId)
			// Replenish ammo for ranged NPCs so they never run out
			if (wm == WEAPONMODE_BOW || wm == WEAPONMODE_CBOW) {
				local ammo = phoenix.npc.AI._rangedAmmoFor(wm)
				if (ammo != "") { try { giveItem(npcId, ammo, 50) } catch (eAmmo) {} }
			}
			local capturedNpc = npcId
			local capturedTarget = target
			local capturedDmg = row.attackDamage > 0 ? row.attackDamage : 10
			local capturedRange = row.attackRange > 0 ? row.attackRange + 60 : 310
			setTimer(function () {
				try {
					try { if (!isNpc(capturedNpc)) return } catch (eNpc) {}
					local capturedNpcTarget = phoenix.npc.AI._liveNpcEntry(capturedTarget)
					if (capturedNpcTarget == null) {
						if (!isPlayerConnected(capturedTarget)) return
						try { if (capturedTarget in phoenix.player.Gate.reviving) return } catch (e) {}
					}
					if (getPlayerHealth(capturedNpc) <= 0) return
					local victimHp = getPlayerHealth(capturedTarget)
					if (victimHp <= 0) return
					local np = getPlayerPosition(capturedNpc)
					local vp = getPlayerPosition(capturedTarget)
					if (np == null || vp == null) return
					local nw = ""; local vw = ""
					try { nw = getPlayerWorld(capturedNpc) } catch (e) {}
					try { vw = getPlayerWorld(capturedTarget) } catch (e) {}
					if (nw != vw) return
					local nvw = 0; local vvw = 0
					try { nvw = getPlayerVirtualWorld(capturedNpc) } catch (e) {}
					try { vvw = getPlayerVirtualWorld(capturedTarget) } catch (e) {}
					if (nvw != vvw) return
					local dx = vp.x - np.x; local dy = vp.y - np.y; local dz = vp.z - np.z
					local d = sqrt(dx * dx + dy * dy + dz * dz)
					if (d > capturedRange) return
					phoenix.npc.AI._applyDamageToTarget(capturedNpc, capturedTarget, capturedDmg)
				} catch (eDmg) {}
			}, 450, 1)
		} catch (e) {
			// A failed native attack must never deal invisible fallback damage.
			phoenix.npc.AI._play(npcId, phoenix.npc.AI._attackAnimFor(row, wm))
		}
		entry.ai.state = "attack"
	}


	function _onTargetLost(entry, lostTarget = -1) {
		local now = getTickCount()
		local previousTarget = lostTarget >= 0 ? lostTarget : (("targetPid" in entry.ai) ? entry.ai.targetPid : -1)
		if (phoenix.npc.AI._liveNpcEntry(previousTarget) != null) {
			phoenix.npc.AI._teleportHome(entry, true)
			entry.ai.combatCooldownUntil <- now + phoenix.npc.AI.homeReturnTimeoutMs
			return
		}
		if (previousTarget >= 0 && phoenix.npc.AI._isHuman(entry.row)) {
			try {
				if (isPlayerConnected(previousTarget) && (previousTarget in phoenix.player.Gate.reviving)) {
					phoenix.npc.AI._startLoot(entry, previousTarget, now)
					return
				}
			} catch (e) {}
		}
		local hasRoutine = ("routine" in entry.ai) && entry.ai.routine != null && ("nodes" in entry.ai.routine) && entry.ai.routine.nodes.len() > 0
		phoenix.npc.AI._clearCombatMovement(entry)
		entry.ai.targetPid = -1
		entry.ai.warnStart = 0
		entry.ai.waitAction = -1
		entry.ai.lastAttack = 0
		entry.ai.idleApplied <- ""
		if (hasRoutine) {
			entry.ai.returning <- false
			entry.ai.postCombatReturn <- false
			entry.ai.postCombatSettleUntil <- 0
			entry.ai.combatCooldownUntil <- 0
			local nearest = 0
			try { nearest = phoenix.npc.Routines.findNearestWaypoint(entry) } catch (eN) {}
			if (nearest < 0) nearest = 0
			entry.ai.routineIndex <- nearest
			entry.ai.routineWaitUntil <- 0
			entry.ai.routineAnimApplied <- ""
			entry.ai.state = "idle"
			phoenix.npc.AI._resetMoveWatch(entry)
			return
		}
		entry.ai.returning <- true
		entry.ai.postCombatReturn <- true
		entry.ai.postCombatSettleUntil <- now + phoenix.npc.AI.postCombatSettleMs
		if (phoenix.npc.AI._liveNpcEntry(previousTarget) != null) entry.ai.combatCooldownUntil <- now + phoenix.npc.AI.homeReturnTimeoutMs
		entry.ai.lastReturnDist <- 999999.0
		entry.ai.lastReturnAt <- now
		entry.ai.returnStartedAt <- entry.ai.lastReturnAt
		phoenix.npc.AI._resetMoveWatch(entry)
	}

	function _startLoot(entry, victimPid, now) {
		entry.ai.state = "loot"
		entry.ai.lootTarget <- victimPid
		entry.ai.lootPhase <- "approach"
		entry.ai.lootStart <- now
		entry.ai.lootDone <- false
		entry.ai.combatCleared <- false
		phoenix.npc.AI._sheatheWeapon(entry)
		try { clearNpcActions(entry.npcId) } catch (e) {}
		phoenix.npc.AI._stopCombatAnims(entry)
	}

	function _tickLoot(entry, pos, now) {
		if (entry.ai.state != "loot") return false
		local victimPid = ("lootTarget" in entry.ai) ? entry.ai.lootTarget : -1
		if (victimPid < 0) {
			phoenix.npc.AI._endLoot(entry, now)
			return true
		}
		try { if (!isPlayerConnected(victimPid)) { phoenix.npc.AI._endLoot(entry, now); return true } } catch (e) {}
		try { if (!(victimPid in phoenix.player.Gate.reviving)) { phoenix.npc.AI._endLoot(entry, now); return true } } catch (e) {}
		if (now - entry.ai.lootStart > 8000) {
			phoenix.npc.AI._endLoot(entry, now)
			return true
		}
		local vp = null
		try { vp = getPlayerPosition(victimPid) } catch (e) {}
		if (vp == null) { phoenix.npc.AI._endLoot(entry, now); return true }
		local npcId = entry.npcId
		local d = phoenix.npc.AI._distFlat(pos.x, pos.z, vp.x, vp.z)
		local phase = ("lootPhase" in entry.ai) ? entry.ai.lootPhase : "approach"
		if (phase == "approach") {
			if (d < 120.0) {
				entry.ai.lootPhase <- "search"
				entry.ai.lootSearchStart <- now
				phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, vp.x, vp.z, entry.ai, now, true)
				try { stopAni(npcId, phoenix.npc.AI._neutralWalkAnim(entry.row)) } catch (e) {}
				try { stopAni(npcId, "S_FISTWALKL") } catch (e) {}
				try {
					if (getPlayerWeaponMode(npcId) != WEAPONMODE_NONE) drawWeapon(npcId, WEAPONMODE_NONE)
				} catch (e) {}
				try { playAni(npcId, "T_PLUNDER") } catch (e) {}
				return true
			}
			phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, vp.x, vp.z, entry.ai, now, true)
			local walkAnim = phoenix.npc.AI._neutralWalkAnim(entry.row)
			try {
				if (getPlayerAni(npcId) != walkAnim) playAni(npcId, walkAnim)
			} catch (e) {}
			return true
		}
		if (phase == "search") {
			local elapsed = now - (("lootSearchStart" in entry.ai) ? entry.ai.lootSearchStart : now)
			if (elapsed >= 3000 && !entry.ai.lootDone) {
				entry.ai.lootDone <- true
				try {
					local gold = phoenix.social.Structure.goldOf(victimPid)
					if (gold > 0) {
						local stolen = (gold * 10) / 100
						if (stolen < 1) stolen = 1
						local newGold = gold - stolen
						if (newGold < 0) newGold = 0
						phoenix.social.Structure.setGold(victimPid, newGold)
					}
				} catch (e) {}
			}
			if (elapsed >= 4000) {
				phoenix.npc.AI._endLoot(entry, now)
				return true
			}
			return true
		}
		phoenix.npc.AI._endLoot(entry, now)
		return true
	}

	function _endLoot(entry, now) {
		entry.ai.lootTarget <- -1
		entry.ai.lootPhase <- ""
		entry.ai.lootDone <- false
		entry.ai.targetPid = -1
		entry.ai.warnStart = 0
		entry.ai.waitAction = -1
		entry.ai.lastAttack = 0
		entry.ai.idleApplied <- ""
		local hasRoutine = ("routine" in entry.ai) && entry.ai.routine != null && ("nodes" in entry.ai.routine) && entry.ai.routine.nodes.len() > 0
		if (hasRoutine) {
			entry.ai.returning <- false
			entry.ai.postCombatReturn <- false
			entry.ai.postCombatSettleUntil <- 0
			entry.ai.combatCooldownUntil <- 0
			local nearest = 0
			try { nearest = phoenix.npc.Routines.findNearestWaypoint(entry) } catch (eN) {}
			if (nearest < 0) nearest = 0
			entry.ai.routineIndex <- nearest
			entry.ai.routineWaitUntil <- 0
			entry.ai.routineAnimApplied <- ""
			entry.ai.state = "idle"
			phoenix.npc.AI._resetMoveWatch(entry)
			return
		}
		entry.ai.returning <- true
		entry.ai.postCombatReturn <- true
		entry.ai.postCombatSettleUntil <- now + phoenix.npc.AI.postCombatSettleMs
		entry.ai.lastReturnDist <- 999999.0
		entry.ai.lastReturnAt <- now
		entry.ai.returnStartedAt <- now
		entry.ai.state = "return"
		phoenix.npc.AI._resetMoveWatch(entry)
	}

	function _knockdown(entry, killerId) {
		if (entry == null || !entry.alive) return
		if (("unconscious" in entry.ai) && entry.ai.unconscious == true) return
		local now = getTickCount()
		entry.ai.unconscious <- true
		entry.ai.unconsciousUntil <- now + 20000
		entry.ai.targetPid = -1
		entry.ai.warnStart = 0
		entry.ai.waitAction = -1
		entry.ai.lastAttack = 0
		entry.ai.combatCleared <- false
		entry.ai.weaponSheathed <- false
		local npcId = entry.npcId
		try { clearNpcActions(npcId) } catch (e) {}
		try {
			if (getPlayerWeaponMode(npcId) != WEAPONMODE_NONE) drawWeapon(npcId, WEAPONMODE_NONE)
		} catch (eW) {}
		entry.ai.weaponSheathed <- true
		try { playAni(npcId, "T_DEAD") } catch (e) {}
		try { phoenix.npc.Spawn.broadcastNameplates() } catch (eN) {}
		local capturedSpawnId = -1
		foreach (sid, e2 in phoenix.npc.Spawn.live) { if (e2.npcId == npcId) { capturedSpawnId = sid; break } }
		setTimer(function () {
			try {
				if (!(capturedSpawnId in phoenix.npc.Spawn.live)) return
				phoenix.npc.AI._wakeUp(phoenix.npc.Spawn.live[capturedSpawnId])
			} catch (eT) {}
		}, 20000, 1)
	}

	function _wakeUp(entry) {
		if (entry == null || !entry.alive) return
		if (!("unconscious" in entry.ai) || entry.ai.unconscious != true) return
		entry.ai.unconscious <- false
		entry.ai.unconsciousUntil <- 0
		entry.ai.combatCleared <- false
		local npcId = entry.npcId
		local maxHp = 0
		try { maxHp = getPlayerMaxHealth(npcId) } catch (e) {}
		if (maxHp <= 0) maxHp = entry.row.hp > 0 ? entry.row.hp : 100
		try { setPlayerHealth(npcId, maxHp) } catch (e2) {}
		try { stopAni(npcId, "T_DEAD") } catch (e3) {}
		try { stopAni(npcId, "T_DEADB") } catch (e4) {}
		try { stopAni(npcId, "S_DEAD") } catch (e5) {}
		try { stopAni(npcId, "S_DEADB") } catch (e6) {}
		try { playAni(npcId, "T_LIE_2_STAND") } catch (e7) {}
		entry.ai.idleApplied <- ""
		entry.ai.state = "idle"
		try { phoenix.npc.AI._ensureIdle(entry, true) } catch (e8) {}
		try { phoenix.npc.Spawn.broadcastNameplates() } catch (eN) {}
	}

	function _tickMonster(entry, now) {
		if (("unconscious" in entry.ai) && entry.ai.unconscious == true) {
			if (now >= (("unconsciousUntil" in entry.ai) ? entry.ai.unconsciousUntil : 0)) {
				phoenix.npc.AI._wakeUp(entry)
			}
			return
		}
		local row = entry.row
		local npcId = entry.npcId
		local pos = null
		try { pos = getPlayerPosition(npcId) } catch (e) { return }
		if (pos == null) return
		local world = ""
		try { world = getPlayerWorld(npcId) } catch (e) {}
		if (phoenix.npc.AI._tickLoot(entry, pos, now)) return
		if (phoenix.npc.AI._isHuman(row) && entry.ai.state != "loot" && ("killedPlayer" in entry.ai) && entry.ai.killedPlayer >= 0) {
			local victimPid = entry.ai.killedPlayer
			entry.ai.killedPlayer <- -1
			try {
				if (isPlayerConnected(victimPid) && (victimPid in phoenix.player.Gate.reviving)) {
					phoenix.npc.AI._startLoot(entry, victimPid, now)
					return
				}
			} catch (e) {}
		}
		if (phoenix.npc.AI._postCombatReturn(entry, pos, world, now)) return
		if (phoenix.npc.AI._superviseHome(entry, pos, world, now)) return
		if (("returning" in entry.ai) && entry.ai.returning == true && (!("targetPid" in entry.ai) || entry.ai.targetPid < 0)) {
			if (phoenix.npc.AI._softReturn(entry, pos, now)) return
		}

		local hasLockedTarget = (("targetPid" in entry.ai) && entry.ai.targetPid >= 0)
		local hasLockedTargetPid = ("targetPid" in entry.ai) ? entry.ai.targetPid : -1
		local inReturn = (("returning" in entry.ai) && entry.ai.returning == true) || (("postCombatReturn" in entry.ai) && entry.ai.postCombatReturn == true)
		local inCooldown = (("combatCooldownUntil" in entry.ai) && now < entry.ai.combatCooldownUntil)
		local canAcquire = !inReturn && !inCooldown

		if (hasLockedTarget || (canAcquire && (row.hostile == 1 || phoenix.npc.AI._findNpcEnemyTarget(entry, pos, phoenix.npc.AI._effectiveAggro(row), world) >= 0))) {
			local targetData = phoenix.npc.AI._currentTarget(entry, pos, world, now)
			if (targetData == null) {
				local target = phoenix.npc.AI._findCombatTarget(entry, pos, phoenix.npc.AI._effectiveAggro(row), world)
				if (target >= 0) {
					local info = phoenix.npc.AI._targetInfo(target, pos, world)
					if (info != null) {
						entry.ai.targetPid = target
						entry.ai.lastSeen <- now
						targetData = { pid = target, pos = info.pos, distance = info.distance }
					}
				}
			}
			if (targetData != null) {
				entry.ai.returning <- false
				phoenix.npc.AI._resetMoveWatch(entry)
				entry.ai.weaponSheathed <- false
				entry.ai.combatCleared <- false
				local target = targetData.pid
				local tp = targetData.pos
				local d = targetData.distance
				local wm = phoenix.npc.AI._resolveWeaponMode(row, d)
				local human = phoenix.npc.AI._isHuman(row)
				if (human) phoenix.npc.AI._ensureEquipment(entry, true, false)
				local attackRange = phoenix.npc.AI._attackRangeFor(row, wm)

				phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, tp.x, tp.z, entry.ai, now, true)

				if (d <= attackRange) {
					if (!phoenix.npc.AI._actionFinished(npcId, entry.ai.waitAction)) {
						// If action is stuck for too long, clear it
						if (!("actionStuckSince" in entry.ai)) entry.ai.actionStuckSince <- now
						if (now - entry.ai.actionStuckSince > 1500) {
							try { clearNpcActions(npcId) } catch (eC) {}
							entry.ai.waitAction = -1
							entry.ai.actionStuckSince <- 0
						}
						return
					}
					entry.ai.actionStuckSince <- 0
					if (now - entry.ai.lastAttack < 1100) return
					phoenix.npc.AI._doAttack(entry, target, pos, tp, now)
					return
				}

				if (!phoenix.npc.AI._actionFinished(npcId, entry.ai.waitAction)) return

				local watch = phoenix.npc.AI._moveWatch(entry, pos, d, now)
				if (watch == 2) {
					phoenix.npc.AI._onTargetLost(entry)
					return
				}

				local runAnim = phoenix.npc.AI._runAnimFor(row, wm)
				if (watch == 1) {
					if (human && !phoenix.npc.AI._ensureWeapon(entry, wm)) return
					phoenix.npc.AI._kickRun(entry, pos, tp.x, tp.z, runAnim, now, "chase")
					return
				}

				if (human) {
					if (!phoenix.npc.AI._ensureWeapon(entry, wm)) return
					try {
						if (getPlayerAni(npcId) != runAnim) playAni(npcId, runAnim)
					} catch (e) {}
				} else {
					try {
						if (getPlayerAni(npcId) != runAnim) playAni(npcId, runAnim)
					} catch (e) {}
				}
				entry.ai.state = "chase"
				return
			}
			if (hasLockedTarget) {
				phoenix.npc.AI._onTargetLost(entry, hasLockedTargetPid)
				return
			}
		}

		local hasRoutine = false
		try {
			hasRoutine = ("routine" in entry.ai) && entry.ai.routine != null && entry.ai.routine.enabled == 1 && entry.ai.routine.nodes.len() > 0
			if (hasRoutine && !("postCombatReturn" in entry.ai && entry.ai.postCombatReturn == true)) entry.ai.returning <- false
			if (hasRoutine && phoenix.npc.Routines.tick(entry, now)) return
		} catch (eR) {}
		local wasReturning = ("returning" in entry.ai) && entry.ai.returning == true
		if (phoenix.npc.AI._softReturn(entry, pos, now)) return
		if (wasReturning) return
		local isMonster = !phoenix.npc.AI._isHuman(row)
		if (now >= entry.ai.nextWander) {
			local radius = isMonster ? 1000 : 800
			local wait = isMonster ? (8000 + (rand() % 7000)) : (6000 + (rand() % 6000))
			entry.ai.nextWander = now + wait
			local rx = entry.ai.anchorX + ((rand() % (radius * 2)) - radius).tofloat()
			local rz = entry.ai.anchorZ + ((rand() % (radius * 2)) - radius).tofloat()
			entry.ai.wanderTargetX <- rx
			entry.ai.wanderTargetZ <- rz
			entry.ai.wanderAngleSet <- false
			entry.ai.state = "wander"
		}
		if (entry.ai.state == "wander" && ("wanderTargetX" in entry.ai)) {
			local d = phoenix.npc.AI._distFlat(pos.x, pos.z, entry.ai.wanderTargetX, entry.ai.wanderTargetZ)
			if (d < 80.0) {
				entry.ai.state = "idle"
				try { stopAni(npcId, phoenix.npc.AI._neutralWalkAnim(entry.row)) } catch (e) {}
				try { stopAni(npcId, "S_FISTWALKL") } catch (e) {}
				phoenix.npc.AI._ensureIdle(entry, true)
				return
			}
			if (!("wanderAngleSet" in entry.ai) || entry.ai.wanderAngleSet != true) {
				phoenix.npc.AI._setAngleTo(npcId, pos.x, pos.z, entry.ai.wanderTargetX, entry.ai.wanderTargetZ, entry.ai, now, true)
				entry.ai.wanderAngleSet <- true
			}
			local walkAnim = phoenix.npc.AI._neutralWalkAnim(entry.row)
			try {
				if (getPlayerAni(npcId) != walkAnim) playAni(npcId, walkAnim)
			} catch (e) {}
		}
	}

	function _tickQuestNpc(entry, now) {
		if (("unconscious" in entry.ai) && entry.ai.unconscious == true) {
			if (now >= (("unconsciousUntil" in entry.ai) ? entry.ai.unconsciousUntil : 0)) {
				phoenix.npc.AI._wakeUp(entry)
			}
			return
		}
		if (("dialogPartner" in entry.ai) && entry.ai.dialogPartner >= 0) {
			local partner = entry.ai.dialogPartner
			local valid = false
			try {
				if (isPlayerConnected(partner)) {
					local pp = getPlayerPosition(partner)
					local np = getPlayerPosition(entry.npcId)
					if (pp != null && np != null) {
						local dx = pp.x - np.x; local dy = pp.y - np.y; local dz = pp.z - np.z
						local d = sqrt(dx * dx + dy * dy + dz * dz)
						if (d <= 800.0) valid = true
					}
				}
			} catch (eD) {}
			if (!valid) {
				entry.ai.dialogPartner <- -1
				entry.ai.dialogPaused <- false
			} else {
				if (!("dialogPaused" in entry.ai) || entry.ai.dialogPaused != true) {
					local npcId = entry.npcId
					try { clearNpcActions(npcId) } catch (eCl) {}
					try {
						foreach (anim in [
							"S_RUN", "S_WALK",
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
				}
				try {
					local npPos = getPlayerPosition(entry.npcId)
					local ppPos = getPlayerPosition(partner)
					if (npPos != null && ppPos != null) {
						phoenix.npc.AI._setAngleTo(entry.npcId, npPos.x, npPos.z, ppPos.x, ppPos.z, entry.ai, now, false)
					}
				} catch (eA2) {}
				entry.ai.state = "dialog"
				return
			}
		}
		if (("dialogPaused" in entry.ai) && entry.ai.dialogPaused == true) {
			entry.ai.dialogPaused <- false
			entry.ai.idleApplied <- ""
		}
		local row = entry.row
		local npcId = entry.npcId
		local enemyNearby = false
		try {
			local pos = getPlayerPosition(npcId)
			local world = ""
			try { world = getPlayerWorld(npcId) } catch (ew) {}
			enemyNearby = pos != null && phoenix.npc.AI._findNpcEnemyTarget(entry, pos, phoenix.npc.AI._effectiveAggro(row), world) >= 0
		} catch (eFind) {}
		if (row.hostile == 1 || enemyNearby || (("targetPid" in entry.ai) && entry.ai.targetPid >= 0) || (("returning" in entry.ai) && entry.ai.returning == true)) {
			phoenix.npc.AI._tickMonster(entry, now)
			return
		}
		local hasRoutine = false
		try { hasRoutine = phoenix.npc.Routines.tick(entry, now) } catch (eR) {}
		if (hasRoutine) return
		if (now < entry.ai.nextTick) return
		entry.ai.nextTick = now + 5000 + (rand() % 5000)
		phoenix.npc.AI._ensureIdle(entry, false)
	}

	function tickAll() {
		if (!phoenix.features.Settings.isEnabled("npc.ai")) return
		local now = getTickCount()
		foreach (sid, entry in phoenix.npc.Spawn.live) {
			if (!entry.alive) continue
			try {
				if (phoenix.npc.AI._isHuman(entry.row)) {
					phoenix.npc.AI._tickQuestNpc(entry, now)
				} else {
					phoenix.npc.AI._tickMonster(entry, now)
				}
			} catch (e) {}
		}
	}

	function stop() {
		if (phoenix.npc.AI.timer != null) {
			try { killTimer(phoenix.npc.AI.timer) } catch (e) {}
			phoenix.npc.AI.timer = null
		}
		foreach (_sid, entry in phoenix.npc.Spawn.live) {
			if (entry == null || !entry.alive) continue
			try {
				entry.ai.combatCleared <- false
				phoenix.npc.AI._clearCombatMovement(entry)
				try { stopAni(entry.npcId, phoenix.npc.AI._neutralRunAnim(entry.row)) } catch (e) {}
				try { stopAni(entry.npcId, phoenix.npc.AI._neutralWalkAnim(entry.row)) } catch (e) {}
				entry.ai.targetPid = -1
				entry.ai.warnStart = 0
				entry.ai.waitAction = -1
				entry.ai.lastAttack = 0
				entry.ai.returning <- false
				entry.ai.postCombatReturn <- false
				entry.ai.postCombatSettleUntil <- 0
				entry.ai.combatCooldownUntil <- 0
				entry.ai.killedPlayer <- -1
				entry.ai.lootTarget <- -1
				entry.ai.state = "idle"
				entry.ai.idleApplied <- ""
				phoenix.npc.AI._ensureIdle(entry, true)
			} catch (e) {}
		}
	}

	function start() {
		if (!phoenix.features.Settings.isEnabled("npc.ai")) return
		if (phoenix.npc.AI.timer != null) return
		phoenix.npc.AI.timer = setTimer(phoenix.npc.AI.tickAll, phoenix.npc.AI.tickIntervalMs, 0)
	}
}

addEventHandler("phoenix.features.OnChanged", function (key, enabled) {
	if (key != "npc.ai") return
	if (enabled) {
		try { phoenix.npc.AI.start() } catch (e) {}
	} else {
		try { phoenix.npc.AI.stop() } catch (e) {}
	}
})

addEventHandler("onInit", function () {
	setTimer(function () {
		try { phoenix.npc.AI.start() } catch (e) {}
	}, 4000, 1)
})
