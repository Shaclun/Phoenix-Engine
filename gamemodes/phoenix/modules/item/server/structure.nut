

phoenix.item.Structure.key <- function(ownerType, ownerId) {
	return ownerType + ":" + ownerId
}

phoenix.item.Structure.cache <- {}
phoenix.item.Structure.schemeById <- {}
phoenix.item.Structure.groundItems <- {}
phoenix.item.Structure.groundLocks <- {}

phoenix.item.Structure._groundId <- function(itemGround) {
	if (itemGround == null) return ""
	try { if ("id" in itemGround && itemGround.id != null) return itemGround.id.tostring() } catch (e) {}
	return ""
}

phoenix.item.Structure._dropPosition <- function(playerId) {
	local pos = null
	try { pos = getPlayerPosition(playerId) } catch (e) { pos = null }
	if (pos == null) pos = { x = 0.0, y = 0.0, z = 0.0 }
	local angle = 0.0
	try { angle = getPlayerAngle(playerId).tofloat() } catch (e2) {}
	local rad = angle * 3.14159 / 180.0
	return {
		x = pos.x + sin(rad) * 150.0,
		y = pos.y,
		z = pos.z + cos(rad) * 150.0,
		angle = angle
	}
}

phoenix.item.Structure._dropLabel <- function(scheme, amount, upgrade, name = "") {
	local label = name != null && name != "" ? name.tostring() : "Przedmiot"
	try { if ((name == null || name == "") && scheme != null && scheme.name != null && scheme.name != "") label = scheme.name } catch (e) {}
	if (upgrade > 0) label += " +" + upgrade
	if (amount > 1) label += " x" + amount
	return label
}

phoenix.item.Structure._removeGroundLabel <- function(groundId) {
	local vobId = "ground_" + groundId
	try {
		if ("vob" in phoenix && phoenix.vob != null && "Structure" in phoenix.vob) {
			if (vobId in phoenix.vob.Structure.entries) {
				phoenix.vob.Structure.entries.rawdelete(vobId)
				phoenix.vob.Structure.broadcastSnapshot()
			}
		}
	} catch (e) {}
}

phoenix.item.Structure._addGroundLabel <- function(groundId, payload) {
	try {
		if (!("vob" in phoenix) || phoenix.vob == null || !("Structure" in phoenix.vob)) return
		local entry = {
			vobId = "ground_" + groundId,
			name = payload.label,
			visual = payload.visual,
			world = payload.world,
			x = payload.x,
			y = payload.y,
			z = payload.z,
			rotX = 0.0,
			rotY = payload.angle,
			rotZ = 0.0,
			interactive = false,
			entryKind = "item",
			itemInstance = payload.instanceId,
			itemAmount = payload.amount,
			itemQuality = payload.quality
		}
		phoenix.vob.Structure.entries[entry.vobId] <- entry
		phoenix.vob.Structure.broadcastSnapshot()
	} catch (e) {}
}

phoenix.item.Structure.addGroundDroppedItem <- function(playerId, data, callback = null) {
	if (data == null) { if (callback != null) callback(false, "badData"); return }
	if (!("ItemsGround" in getroottable())) { if (callback != null) callback(false, "missingItemsGround"); return }
	local instanceId = ("instanceId" in data) ? data.instanceId.tostring().toupper() : ""
	local scheme = phoenix.item.find(instanceId)
	local amount = ("amount" in data) ? data.amount.tointeger() : 1
	local quality = PhoenixItemQuality.Common
	local upgrade = 0
	try { if ("quality" in data && data.quality != null) quality = data.quality.tointeger() } catch (eq0) { quality = PhoenixItemQuality.Common }
	try { if ("upgrade" in data && data.upgrade != null) upgrade = data.upgrade.tointeger() } catch (eu0) { upgrade = 0 }
	if (scheme == null || amount <= 0) { if (callback != null) callback(false, "badItem"); return }

	local visual = ""
	try { if ("visual" in data && data.visual != null && data.visual != "") visual = data.visual.tostring().toupper() } catch (ev) {}
	if (visual == "") { try { visual = phoenix.item.lookupVisual(instanceId) } catch (ev2) {} }
	local label = phoenix.item.Structure._dropLabel(scheme, amount, upgrade, ("name" in data) ? data.name : "")
	local drop = phoenix.item.Structure._dropPosition(playerId)
	local world = "NEWWORLD"
	try { local currentWorld = getPlayerWorld(playerId); if (currentWorld != null && currentWorld != "") world = currentWorld } catch (ew) {}
	local tab = {
		instance = instanceId,
		amount = amount,
		physicsEnabled = true,
		position = { x = drop.x, y = drop.y, z = drop.z },
		rotation = { x = 0, y = rand() % 350, z = 0 },
		world = world
	}
	try { tab.quality <- quality } catch (eq) {}

	local groundId = null
	try { groundId = ItemsGround.create(tab) } catch (e) { groundId = null }
	if (groundId == null) { if (callback != null) callback(false, "createFailed"); return }

	local groundKey = groundId.tostring()
	phoenix.item.Structure.groundItems[groundKey] <- {
		instanceId = instanceId,
		amount = amount,
		quality = quality,
		upgrade = upgrade,
		label = label,
		visual = visual
	}
	phoenix.item.Structure._addGroundLabel(groundKey, { instanceId = instanceId, amount = amount, quality = quality, label = label, visual = visual, world = world, x = drop.x, y = drop.y, z = drop.z, angle = drop.angle })
	try {
		if ("GarbageCollector" in getroottable() && "GarbageCollectorType" in getroottable())
			GarbageCollector.add(GarbageCollectorType.ItemGround, groundId, 600)
	} catch (eg) {}
	try {
		local itemGround = ItemsGround.getById(groundId)
		if (itemGround != null) callEvent("onPlayerLeftOnGround", itemGround)
	} catch (ec) {}
	if (callback != null) callback(true, "")
}

phoenix.item.Structure.onGroundTake <- function(playerId, itemGround) {
	local groundId = phoenix.item.Structure._groundId(itemGround)
	if (groundId == "") return
	if (!(groundId in phoenix.item.Structure.groundItems)) return
	if (groundId in phoenix.item.Structure.groundLocks) return
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return
	local payload = phoenix.item.Structure.groundItems[groundId]
	phoenix.item.Structure.groundLocks[groundId] <- true
	try { ::removeItem(playerId, payload.instanceId, payload.amount) } catch (er) {}
	phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, payload.instanceId, { amount = payload.amount, quality = payload.quality, upgrade = payload.upgrade, source = "ground" }, function(rec) {
		if (groundId in phoenix.item.Structure.groundItems) phoenix.item.Structure.groundItems.rawdelete(groundId)
		if (groundId in phoenix.item.Structure.groundLocks) phoenix.item.Structure.groundLocks.rawdelete(groundId)
		phoenix.item.Structure._removeGroundLabel(groundId)
		if (rec == null) {
			try { phoenix.notification.notify(playerId, "error", "Przedmiot", "Nie mozna podniesc przedmiotu.", 3000) } catch (e) {}
			return
		}
		try { phoenix.notification.notify(playerId, "success", "Podniesiono", payload.label, 2800) } catch (en) {}
	})
}

phoenix.item.Structure.schemeOf <- function(rec) {
	if (rec == null) return null
	if (rec.id in phoenix.item.Structure.schemeById)
		return phoenix.item.Structure.schemeById[rec.id]
	local s = phoenix.item.find(rec.instanceId)
	if (s != null) phoenix.item.Structure.schemeById[rec.id] <- s
	return s
}

phoenix.item.Structure.loadOwner <- function(ownerType, ownerId, callback = null) {
	ItemModel.findByOwner(ownerType, ownerId, function(records) {
		local list = []
		if (records != null) {
			foreach (rec in records) {
				local scheme = phoenix.item.find(rec.instanceId)
				if (scheme == null) {
					continue
				}
				phoenix.item.Structure.schemeById[rec.id] <- scheme
				list.push(rec)
			}
		}
		local cacheKey = phoenix.item.Structure.key(ownerType, ownerId)
		phoenix.item.Structure.cache[cacheKey] <- {
			ownerType = ownerType,
			ownerId   = ownerId,
			items     = list
		}
		if (callback != null) callback(list)
	})
}

phoenix.item.Structure.unloadOwner <- function(ownerType, ownerId) {
	local cacheKey = phoenix.item.Structure.key(ownerType, ownerId)
	if (cacheKey in phoenix.item.Structure.cache) {
		local entry = phoenix.item.Structure.cache[cacheKey]
		foreach (rec in entry.items) {
			if (rec.id in phoenix.item.Structure.schemeById)
				phoenix.item.Structure.schemeById.rawdelete(rec.id)
		}
		phoenix.item.Structure.cache.rawdelete(cacheKey)
	}
}

phoenix.item.Structure.getInventory <- function(ownerType, ownerId) {
	local cacheKey = phoenix.item.Structure.key(ownerType, ownerId)
	if (cacheKey in phoenix.item.Structure.cache)
		return phoenix.item.Structure.cache[cacheKey]
	return null
}

phoenix.item.Structure.countInstance <- function(ownerType, ownerId, instanceId) {
	local inv = phoenix.item.Structure.getInventory(ownerType, ownerId)
	if (inv == null) return 0
	local wanted = instanceId != null ? instanceId.toupper() : ""
	local total = 0
	foreach (rec in inv.items) {
		local current = rec.instanceId != null ? rec.instanceId.toupper() : ""
		if (current == wanted && rec.equipped == 0) total += rec.amount
	}
	return total
}

phoenix.item.Structure.takeInstance <- function(ownerType, ownerId, instanceId, amount, callback = null) {
	if (amount <= 0) { if (callback != null) callback(true); return }
	local inv = phoenix.item.Structure.getInventory(ownerType, ownerId)
	if (inv == null) { if (callback != null) callback(false); return }
	local wanted = instanceId != null ? instanceId.toupper() : ""
	local target = null
	foreach (rec in inv.items) {
		local current = rec.instanceId != null ? rec.instanceId.toupper() : ""
		if (current == wanted && rec.equipped == 0) { target = rec; break }
	}
	if (target == null) { if (callback != null) callback(false); return }
	local take = amount
	if (take > target.amount) take = target.amount
	phoenix.item.Structure.takeItem(ownerType, ownerId, target.id, take, function(ok) {
		if (!ok) { if (callback != null) callback(false); return }
		phoenix.item.Structure.takeInstance(ownerType, ownerId, instanceId, amount - take, callback)
	})
}

phoenix.item.Structure.giveItem <- function(ownerType, ownerId, instanceId, options = null, callback = null) {
	local scheme = phoenix.item.find(instanceId)
	if (scheme == null) {
		if (callback != null) callback(null)
		return
	}

	local opts = options != null ? options : {}
	local amount  = ("amount"  in opts) ? opts.amount  : 1
	local quality = ("quality" in opts) ? opts.quality : phoenix.item.Quality.roll()
	local upgrade = ("upgrade" in opts) ? opts.upgrade : 0
	local source  = ("source"  in opts) ? opts.source  : "system"

	if (!phoenix.item.Quality.isValid(quality)) quality = PhoenixItemQuality.Common
	if (!phoenix.item.Upgrade.canUpgrade(scheme.category)) upgrade = 0
	if (upgrade < 0) upgrade = 0
	if (upgrade > phoenix.item.MAX_UPGRADE) upgrade = phoenix.item.MAX_UPGRADE

	local inv = phoenix.item.Structure.getInventory(ownerType, ownerId)

	if (inv != null && scheme.isStackable()) {
		foreach (existing in inv.items) {
			if (existing.instanceId == instanceId &&
			    existing.quality == quality &&
			    existing.upgrade == upgrade &&
			    existing.equipped == 0) {
				existing.amount += amount
				existing.saveAsync(function(_) {
					phoenix.item.Structure._notifyUpdate(ownerType, ownerId, existing)
					phoenix.item.Structure._applyToWorld(ownerType, ownerId, instanceId, amount)
					try { phoenix.quest.Events.itemGranted(ownerType, ownerId, instanceId, amount, source, existing.id) } catch (eQuest) {}
					if (callback != null) callback(existing)
				})
				return
			}
		}
	}

	local rec       = ItemModel()
	rec.ownerType   = ownerType
	rec.ownerId     = ownerId
	rec.instanceId  = instanceId
	rec.amount      = amount
	rec.quality     = quality
	rec.upgrade     = upgrade
	rec.durability  = 100
	rec.equipped    = 0
	rec.slot        = 0
	rec.source      = source
	rec.insertAsync(function(_) {
		phoenix.item.Structure.schemeById[rec.id] <- scheme
		if (inv != null) inv.items.push(rec)
		phoenix.item.Structure._notifyAdd(ownerType, ownerId, rec)
		phoenix.item.Structure._applyToWorld(ownerType, ownerId, instanceId, amount)
		try { phoenix.quest.Events.itemGranted(ownerType, ownerId, instanceId, amount, source, rec.id) } catch (eQuest) {}
		if (callback != null) callback(rec)
	})
}

phoenix.item.Structure.takeItem <- function(ownerType, ownerId, itemId, amount = -1, callback = null) {
	local inv = phoenix.item.Structure.getInventory(ownerType, ownerId)
	if (inv == null) { if (callback != null) callback(false); return }

	local idx = -1
	for (local i = 0; i < inv.items.len(); i += 1) {
		if (inv.items[i].id == itemId) { idx = i; break }
	}
	if (idx == -1) { if (callback != null) callback(false); return }

	local rec = inv.items[idx]
	local removeAll = (amount < 0 || amount >= rec.amount)
	if (removeAll) {
		local sql = "DELETE FROM `phoenix_items` WHERE `id` = " + rec.id
		ORM.engine.executeAsync(sql, function(_) {
			inv.items.remove(idx)
			phoenix.item.Structure._notifyRemove(ownerType, ownerId, rec)
			phoenix.item.Structure._removeFromWorld(ownerType, ownerId, rec.instanceId, rec.amount)
			if (callback != null) callback(true)
		})
	} else {
		rec.amount -= amount
		rec.saveAsync(function(_) {
			phoenix.item.Structure._notifyUpdate(ownerType, ownerId, rec)
			phoenix.item.Structure._removeFromWorld(ownerType, ownerId, rec.instanceId, amount)
			if (callback != null) callback(true)
		})
	}
}

phoenix.item.Structure.setEquipped <- function(ownerType, ownerId, itemId, equip, callback = null) {
	local inv = phoenix.item.Structure.getInventory(ownerType, ownerId)
	if (inv == null) { if (callback != null) callback(false); return }
	local rec = null
	foreach (it in inv.items) if (it.id == itemId) { rec = it; break }
	if (rec == null) { if (callback != null) callback(false); return }
	local scheme = phoenix.item.Structure.schemeOf(rec)
	if (scheme == null) { if (callback != null) callback(false); return }
	if (!scheme.isEquippable()) { if (callback != null) callback(false); return }

	if (equip) {

		local pid = phoenix.item.Structure._resolvePlayerId(ownerType, ownerId)
		foreach (other in inv.items) {
			if (other.id == rec.id) continue
			if (other.equipped == 1 && other.slot == scheme.slot) {
				other.equipped = 0
				other.slot     = 0
				local displaced = other
				displaced.saveAsync(function(_) {
					phoenix.item.Structure._notifyUpdate(ownerType, ownerId, displaced)
				})
				if (pid >= 0) {
					try { ::unequipItem(pid, displaced.instanceId) }
					catch (e) {}
					try { ::removeItem(pid, displaced.instanceId, 1) }
					catch (e) {}
				}
			}
		}
	}

	rec.equipped = equip ? 1 : 0
	rec.slot     = equip ? scheme.slot : 0
	rec.saveAsync(function(_) {
		phoenix.item.Structure._notifyUpdate(ownerType, ownerId, rec)
		if (callback != null) callback(true)
	})
}

phoenix.item.Structure._resolvePlayerId <- function(ownerType, ownerId) {
	if (ownerType != PhoenixInventoryOwner.Player) return -1

	if (!("active" in phoenix.character.Structure)) return -1
	foreach (pid, rec in phoenix.character.Structure.active) {
		if (rec.id == ownerId) return pid
	}
	return -1
}

phoenix.item.Structure._applyToWorld <- function(ownerType, ownerId, instanceId, amount) {

}

phoenix.item.Structure._removeFromWorld <- function(ownerType, ownerId, instanceId, amount) {

}

phoenix.item.Structure.applyToPlayer <- function(playerId, characterId) {
	local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, characterId)
	if (inv == null) return
	foreach (rec in inv.items) {
		try { ::giveItem(playerId, rec.instanceId, rec.amount) } catch (e) {}
		if (rec.equipped == 1) {
			try { ::equipItem(playerId, rec.instanceId) } catch (e) {}
		}
	}
}

phoenix.item.Structure._packetEntry <- function(rec) {

	local scheme = phoenix.item.find(rec.instanceId)
	local stats  = (scheme != null)
		? phoenix.item.computeStats(scheme, rec.quality, rec.upgrade)
		: null
	local requirements = []
	try {
		if (scheme != null && scheme.requirement != null) {
			foreach (r in scheme.requirement) {
				if (r == null) continue
				local attr = ("attr" in r && r.attr != null) ? r.attr.tostring() : ""
				local value = ("value" in r) ? r.value.tointeger() : 0
				if (attr != "" && value > 0) requirements.append({ attr = attr, value = value })
			}
		}
	} catch (eReq) {}
	local effect = null
	try {
		if (scheme != null && scheme.effect != null) {
			effect = {}
			foreach (k, v in scheme.effect) {
				try { effect[k] <- v } catch (eE) {}
			}
		}
	} catch (eEff) {}
	local onUseKind = ""
	try {
		if (scheme != null && scheme.onUse != null) onUseKind = scheme.onUse.tostring()
	} catch (eK) {}
	local entry  = {
		id          = rec.id,
		instance    = rec.instanceId,
		amount      = rec.amount,
		quality     = rec.quality,
		upgrade     = rec.upgrade,
		durability  = rec.durability,
		equipped    = (rec.equipped == 1),

		slot        = (scheme != null) ? scheme.slot : 0,
		name        = (scheme != null) ? scheme.name        : rec.instanceId,
		description = (scheme != null) ? scheme.description : "",
		category    = (scheme != null) ? scheme.category    : 0,
		value       = (scheme != null) ? scheme.value       : 0,
		weight      = (scheme != null) ? scheme.weight      : 0,
		visual      = (scheme != null && ("visual" in scheme)) ? scheme.visual : null,
		onUse       = (scheme != null && scheme.onUse != null),
		onUseKind   = onUseKind,
		stats       = stats,
		requirements = requirements,
		effect      = effect
	}
	return entry
}

phoenix.item.Structure._notifyAdd <- function(ownerType, ownerId, rec) {
	local pid = phoenix.item.Structure._resolvePlayerId(ownerType, ownerId)
	if (pid < 0) return
	try {
		if (rec.instanceId != null && rec.instanceId.toupper() == "ITMI_GOLD") {
			phoenix.item.Structure.sendInventorySnapshot(pid, ownerId)
			return
		}
	} catch (eg) {}
	try {
		local msg = phoenix.item.Message.Add()
		msg.item = phoenix.item.Structure._packetEntry(rec)
		msg.serialize().send(pid, RELIABLE_ORDERED)
	} catch (e) {}
}

phoenix.item.Structure._notifyRemove <- function(ownerType, ownerId, rec) {
	local pid = phoenix.item.Structure._resolvePlayerId(ownerType, ownerId)
	if (pid < 0) return
	try {
		if (rec.instanceId != null && rec.instanceId.toupper() == "ITMI_GOLD") {
			phoenix.item.Structure.sendInventorySnapshot(pid, ownerId)
			return
		}
	} catch (eg) {}
	try {
		local msg = phoenix.item.Message.Remove()
		msg.id = rec.id
		msg.serialize().send(pid, RELIABLE_ORDERED)
	} catch (e) {}
}

phoenix.item.Structure._notifyUpdate <- function(ownerType, ownerId, rec) {
	local pid = phoenix.item.Structure._resolvePlayerId(ownerType, ownerId)
	if (pid < 0) return
	try {
		if (rec.instanceId != null && rec.instanceId.toupper() == "ITMI_GOLD") {
			phoenix.item.Structure.sendInventorySnapshot(pid, ownerId)
			return
		}
	} catch (eg) {}
	try {
		local msg = phoenix.item.Message.Update()
		msg.item = phoenix.item.Structure._packetEntry(rec)
		msg.serialize().send(pid, RELIABLE_ORDERED)
	} catch (e) {}
}

phoenix.item.Structure.sendInventorySnapshot <- function(playerId, characterId) {
	local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, characterId)
	local entries = []
	if (inv != null) {
		foreach (rec in inv.items) {
			try { if (rec.instanceId != null && rec.instanceId.toupper() == "ITMI_GOLD") continue } catch (eg) {}
			entries.push(phoenix.item.Structure._packetEntry(rec))
		}
	}
	try {
		local msg = phoenix.item.Message.Inventory()
		msg.ownerId   = characterId
		msg.ownerType = PhoenixInventoryOwner.Player
		msg.gold      = phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, characterId, "ITMI_GOLD")
		msg.items     = entries
		msg.serialize().send(playerId, RELIABLE_ORDERED)
	} catch (e) {}
}
