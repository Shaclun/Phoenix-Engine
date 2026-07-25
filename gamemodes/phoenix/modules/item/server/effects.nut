phoenix.item.Effects <- {
	active = {},
	useLocks = {},
	tickMs = 250,

	function _key(playerId, itemId) { return playerId + ":" + itemId }

	function modifier(playerId, target) {
		if (!(playerId in phoenix.item.Effects.active)) return 0
		local total = 0
		foreach (effect in phoenix.item.Effects.active[playerId]) {
			if (effect.kind == "buff" && effect.target == target) total += effect.amount
		}
		return total
	}

	function hasModifier(playerId, target) {
		return phoenix.item.Effects.modifier(playerId, target) != 0
	}

	function _normalizeEffect(raw) {
		if (raw == null) return null
		local kind = ("kind" in raw && raw.kind != null) ? raw.kind.tostring() : ""
		local target = ("target" in raw && raw.target != null) ? raw.target.tostring() : ""
		local allowedKind = kind == "instant" || kind == "regen" || kind == "buff"
		local allowedTarget = target == "hp" || target == "mana" || target == "strength" || target == "dexterity" || target == "hpMax" || target == "manaMax"
		if (!allowedKind || !allowedTarget) return null
		if (kind != "buff" && target != "hp" && target != "mana") return null
		local amount = 0.0; local durationMs = 0; local intervalMs = 1000; local stacking = "refresh"
		try { amount = raw.amount.tofloat() } catch (e) {}
		try { if ("durationMs" in raw) durationMs = raw.durationMs.tointeger() } catch (e) {}
		try { if ("intervalMs" in raw) intervalMs = raw.intervalMs.tointeger() } catch (e) {}
		try { if ("stacking" in raw && raw.stacking != null) stacking = raw.stacking.tostring() } catch (e) {}
		if (amount == 0.0) return null
		if (durationMs < 0) durationMs = 0
		if (durationMs > 86400000) durationMs = 86400000
		if (kind != "instant" && durationMs <= 0) return null
		if (intervalMs < 100) intervalMs = 100
		if (stacking != "replace" && stacking != "refresh") stacking = "refresh"
		return { kind = kind, target = target, amount = amount, durationMs = durationMs, intervalMs = intervalMs, stacking = stacking }
	}

	function _legacyEffects(scheme) {
		local out = []
		if (scheme == null || scheme.effect == null) return out
		try { if ("hp" in scheme.effect) out.append({ kind = "instant", target = "hp", amount = scheme.effect.hp, durationMs = 0, intervalMs = 1000, stacking = "refresh" }) } catch (e) {}
		try { if ("mana" in scheme.effect) out.append({ kind = "instant", target = "mana", amount = scheme.effect.mana, durationMs = 0, intervalMs = 1000, stacking = "refresh" }) } catch (e) {}
		return out
	}

	function _effectsOf(scheme) {
		local source = []
		try { if (scheme.effects != null) source = scheme.effects } catch (e) {}
		if (source == null || source.len() == 0) source = phoenix.item.Effects._legacyEffects(scheme)
		local out = []
		foreach (raw in source) {
			local normalized = phoenix.item.Effects._normalizeEffect(raw)
			if (normalized != null) out.append(normalized)
		}
		return out
	}

	function _applyRuntime(playerId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null) return
		local strength = record.strength + phoenix.item.Effects.modifier(playerId, "strength")
		local dexterity = record.dexterity + phoenix.item.Effects.modifier(playerId, "dexterity")
		if (strength < 0) strength = 0
		if (dexterity < 0) dexterity = 0
		try { setPlayerStrength(playerId, strength.tointeger()) } catch (e) {}
		try { setPlayerDexterity(playerId, dexterity.tointeger()) } catch (e) {}
		try { phoenix.player.Resources.syncMaximums(playerId, record) } catch (e) {}
		try { phoenix.player.Hud.pushSnapshot(playerId) } catch (e) {}
		try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e) {}
	}

	function apply(playerId, characterId, scheme, quality) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || record.id != characterId) return false
		local effects = phoenix.item.Effects._effectsOf(scheme)
		local multiplier = phoenix.item.Quality.getMultiplier(quality)
		local now = getTickCount()
		if (!(playerId in phoenix.item.Effects.active)) phoenix.item.Effects.active[playerId] <- []
		foreach (effect in effects) {
			local amount = effect.amount * multiplier
			if (effect.kind == "instant") {
				phoenix.player.Resources.add(playerId, record, effect.target, amount)
				continue
			}
			if (effect.durationMs <= 0) continue
			local key = scheme.instance + ":" + effect.kind + ":" + effect.target
			local list = phoenix.item.Effects.active[playerId]
			local replaced = false
			for (local i = list.len() - 1; i >= 0; i -= 1) {
				if (list[i].key != key) continue
				if (effect.stacking == "refresh") {
					list[i].expiresAt = now + effect.durationMs
					list[i].amount = amount
					list[i].lastTick = now
					list[i].accumulator = 0.0
					replaced = true
				} else list.remove(i)
			}
			if (!replaced) list.append({ key = key, characterId = characterId, kind = effect.kind, target = effect.target, amount = amount, expiresAt = now + effect.durationMs, intervalMs = effect.intervalMs, lastTick = now, accumulator = 0.0 })
		}
		phoenix.item.Effects._applyRuntime(playerId)
		return true
	}

	function _openDocument(playerId, scheme, source = "inventory") {
		local title = { pl = scheme.name, en = "", de = "", ru = "" }
		local content = { pl = scheme.description, en = "", de = "", ru = "" }
		try { if (scheme.labels != null) title = scheme.labels } catch (e) {}
		try { if (scheme.content != null) content = scheme.content } catch (e) {}
		try {
			local msg = phoenix.item.Message.DocumentOpen()
			msg.titleJson = phoenix.web.Json.encode(title)
			msg.contentJson = phoenix.web.Json.encode(content)
			msg.source = source
			msg.serialize().send(playerId, RELIABLE_ORDERED)
		} catch (e) {}
	}

	function use(playerId, active, rec, scheme, source = "inventory") {
		if (active == null || rec == null || scheme == null) return false
		local key = phoenix.item.Effects._key(playerId, rec.id)
		if (key in phoenix.item.Effects.useLocks) return true
		local kind = ""
		try { if (scheme.onUse != null) kind = scheme.onUse.tostring() } catch (e) {}
		if (kind == "document") {
			phoenix.item.Effects._openDocument(playerId, scheme, source)
			return true
		}
		if (kind != "heal" && kind != "mana" && kind != "consumable") return false
		local effects = phoenix.item.Effects._effectsOf(scheme)
		if (effects.len() == 0) return true
		local hp = 0
		try { hp = getPlayerHealth(playerId) } catch (e) {}
		if (hp <= 0) return true
		phoenix.item.Effects.useLocks[key] <- true
		local characterId = active.id
		local itemId = rec.id
		local quality = rec.quality
		phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, characterId, itemId, 1, function(ok) {
			if (key in phoenix.item.Effects.useLocks) phoenix.item.Effects.useLocks.rawdelete(key)
			if (!ok || !isPlayerConnected(playerId)) return
			local current = phoenix.character.Structure.getActive(playerId)
			if (current == null || current.id != characterId) return
			phoenix.item.Effects.apply(playerId, characterId, scheme, quality)
		})
		return true
	}

	function tick() {
		local now = getTickCount()
		local emptyPlayers = []
		foreach (playerId, list in phoenix.item.Effects.active) {
			local record = phoenix.character.Structure.getActive(playerId)
			local changed = false
			for (local i = list.len() - 1; i >= 0; i -= 1) {
				local effect = list[i]
				if (!isPlayerConnected(playerId) || record == null || record.id != effect.characterId || now >= effect.expiresAt) {
					list.remove(i); changed = true; continue
				}
				if (effect.kind != "regen") continue
				local dt = (now - effect.lastTick) / 1000.0
				if (dt < 0.0) dt = 0.0
				if (dt > 2.0) dt = 2.0
				effect.lastTick = now
				effect.accumulator += effect.amount * (dt * 1000.0 / effect.intervalMs)
				local whole = effect.accumulator.tointeger()
				if (whole != 0) {
					effect.accumulator -= whole
					phoenix.player.Resources.add(playerId, record, effect.target, whole)
					changed = true
				}
			}
			if (list.len() == 0) emptyPlayers.append(playerId)
			if (changed) phoenix.item.Effects._applyRuntime(playerId)
		}
		foreach (playerId in emptyPlayers) if (playerId in phoenix.item.Effects.active) phoenix.item.Effects.active.rawdelete(playerId)
	}

	function clear(playerId) {
		if (playerId in phoenix.item.Effects.active) phoenix.item.Effects.active.rawdelete(playerId)
		local prefix = playerId + ":"
		local remove = []
		foreach (key, _ in phoenix.item.Effects.useLocks) if (key.find(prefix) == 0) remove.append(key)
		foreach (key in remove) phoenix.item.Effects.useLocks.rawdelete(key)
		try { phoenix.item.Effects._applyRuntime(playerId) } catch (e) {}
	}
}

addEventHandler("onInit", function() { setTimer(phoenix.item.Effects.tick, phoenix.item.Effects.tickMs, 0) })
addEventHandler("onPlayerDisconnect", function(playerId, _reason) { phoenix.item.Effects.clear(playerId) })
addEventHandler("phoenix.character.OnSelected", function(playerId, _characterId) { phoenix.item.Effects.clear(playerId) })
