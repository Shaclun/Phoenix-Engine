phoenix.player.Animations <- {
	active = {}
	lastRequestAt = {}
	cooldownMs = 600
	combatLockMs = 5000

	function enabled() {
		return phoenix.features.Settings.effectiveEnabled("player.animations")
	}

	function sendResult(playerId, success, error = "", id = "", active = false) {
		local message = phoenix.player.Message.AnimationResult()
		message.success = success
		message.error = error
		message.id = id
		message.active = active
		try { message.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function hasDialog(playerId) {
		try { if (playerId in phoenix.quest.Dialog.sessions) return true } catch (e) {}
		try {
			foreach (_spawnId, entry in phoenix.npc.Spawn.live) {
				if (entry != null && entry.ai != null && "dialogPartner" in entry.ai && entry.ai.dialogPartner == playerId) return true
			}
		} catch (e2) {}
		return false
	}

	function hasOperation(playerId) {
		try { if (playerId in phoenix.crafting.Crafter.jobs || playerId in phoenix.crafting.Crafter.activeByPlayer) return true } catch (e) {}
		try { if (playerId in phoenix.herb.Structure.active) return true } catch (e2) {}
		try { if (playerId in phoenix.profession.Hunting.jobs) return true } catch (e3) {}
		return false
	}

	function blockReason(playerId, entry = null) {
		if (!phoenix.player.Animations.enabled()) return "disabled"
		if (entry != null && !entry.playable) return "unsafe"
		local record = null
		try { record = phoenix.character.Structure.getActive(playerId) } catch (e) {}
		if (record == null) return "noCharacter"
		try { if (!isPlayerConnected(playerId)) return "disconnected" } catch (e2) { return "disconnected" }
		try { if (playerId in phoenix.player.Gate.pending || playerId in phoenix.player.Gate.reviving || playerId in phoenix.player.Gate.applying) return "dead" } catch (e3) {}
		try { if (getPlayerHealth(playerId) <= 0) return "dead" } catch (e4) { return "dead" }
		try { if (getPlayerWeaponMode(playerId) != WEAPONMODE_NONE) return "weapon" } catch (e5) {}
		try {
			if (playerId in phoenix.social.Structure.recentCombat && getTickCount() - phoenix.social.Structure.recentCombat[playerId] < phoenix.player.Animations.combatLockMs) return "combat"
		} catch (e6) {}
		if (phoenix.player.Animations.hasDialog(playerId)) return "dialog"
		if (phoenix.player.Animations.hasOperation(playerId)) return "operation"
		return ""
	}

	function stop(playerId, notify = false, reason = "") {
		if (!(playerId in phoenix.player.Animations.active)) {
			if (notify && reason == "") phoenix.player.Animations.sendResult(playerId, true, "", "", false)
			return
		}
		local state = phoenix.player.Animations.active[playerId]
		phoenix.player.Animations.active.rawdelete(playerId)
		try { stopAni(playerId, state.instance) } catch (e) {}
		if (notify) phoenix.player.Animations.sendResult(playerId, true, reason, state.id, false)
	}

	function stopAll(reason = "disabled") {
		local players = []
		foreach (playerId, _state in phoenix.player.Animations.active) players.append(playerId)
		foreach (playerId in players) phoenix.player.Animations.stop(playerId, true, reason)
	}

	function onPlayRequest(playerId, message) {
		local id = message != null && message.id != null ? message.id.tostring() : ""
		local entry = phoenix.player.AnimationsCatalog.find(id)
		if (entry == null) { phoenix.player.Animations.sendResult(playerId, false, "invalidAnimation", id, false); return }
		local now = getTickCount()
		if (playerId in phoenix.player.Animations.lastRequestAt && now - phoenix.player.Animations.lastRequestAt[playerId] < phoenix.player.Animations.cooldownMs) {
			phoenix.player.Animations.sendResult(playerId, false, "cooldown", id, false)
			return
		}
		phoenix.player.Animations.lastRequestAt[playerId] <- now
		local blocked = phoenix.player.Animations.blockReason(playerId, entry)
		if (blocked != "") { phoenix.player.Animations.sendResult(playerId, false, blocked, id, false); return }
		phoenix.player.Animations.stop(playerId)
		local played = true
		try { playAni(playerId, entry.instance) } catch (e) { played = false }
		if (!played) { phoenix.player.Animations.sendResult(playerId, false, "playFailed", id, false); return }
		phoenix.player.Animations.active[playerId] <- { id = entry.id, instance = entry.instance, startedAt = now }
		phoenix.player.Animations.sendResult(playerId, true, "", entry.id, true)
	}

	function onStopRequest(playerId, _message) {
		phoenix.player.Animations.stop(playerId, true, "")
	}

	function guardTick() {
		if (!phoenix.player.Animations.enabled()) { phoenix.player.Animations.stopAll("disabled"); return }
		local players = []
		foreach (playerId, _state in phoenix.player.Animations.active) players.append(playerId)
		foreach (playerId in players) {
			local reason = phoenix.player.Animations.blockReason(playerId)
			if (reason != "") phoenix.player.Animations.stop(playerId, true, reason)
		}
	}

	function onDamage(victimId, attackerId, _desc) {
		if (victimId != null && victimId >= 0) phoenix.player.Animations.stop(victimId, true, "combat")
		if (attackerId != null && attackerId >= 0) phoenix.player.Animations.stop(attackerId, true, "combat")
	}

	function cleanup(playerId) {
		phoenix.player.Animations.stop(playerId)
		if (playerId in phoenix.player.Animations.lastRequestAt) phoenix.player.Animations.lastRequestAt.rawdelete(playerId)
	}
}
phoenix.player.Message.AnimationPlayRequest.bind(phoenix.player.Animations.onPlayRequest)
phoenix.player.Message.AnimationStopRequest.bind(phoenix.player.Animations.onStopRequest)
addEventHandler("onPlayerDamage", function(victimId, attackerId, desc) { phoenix.player.Animations.onDamage(victimId, attackerId, desc) })
addEventHandler("onPlayerDead", function(playerId, _killerId) { phoenix.player.Animations.stop(playerId, true, "dead") })
addEventHandler("onPlayerDisconnect", function(playerId, _reason) { phoenix.player.Animations.cleanup(playerId) })
local phoenixAnimationsSelectedEvent = "phoenix.character." + "OnSelected"
local phoenixAnimationsFeatureEvent = "phoenix.features." + "OnChanged"
addEventHandler(phoenixAnimationsSelectedEvent, function(playerId, _characterId) { phoenix.player.Animations.cleanup(playerId) })
addEventHandler(phoenixAnimationsFeatureEvent, function(key, enabled) {
	if (key == "player.animations" && !enabled) phoenix.player.Animations.stopAll("disabled")
})
setTimer(phoenix.player.Animations.guardTick, 250, 0)