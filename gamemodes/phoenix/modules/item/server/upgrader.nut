

phoenix.item.Upgrader.tryUpgrade <- function(playerId, itemId, callback = null) {
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, 0, "no.character")
		if (callback != null) callback(false)
		return
	}

	local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
	if (inv == null) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, 0, "no.inventory")
		if (callback != null) callback(false)
		return
	}

	local rec = null
	foreach (it in inv.items) if (it.id == itemId) { rec = it; break }
	if (rec == null) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, 0, "item.not.owned")
		if (callback != null) callback(false)
		return
	}

	local scheme = phoenix.item.Structure.schemeOf(rec)
	if (scheme == null) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, rec.upgrade, "scheme.missing")
		if (callback != null) callback(false)
		return
	}
	if (!phoenix.item.Upgrade.canUpgrade(scheme.category)) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, rec.upgrade, "category.locked")
		if (callback != null) callback(false)
		return
	}
	if ((scheme.flags & PhoenixItemFlag.NoUpgrade) != 0) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, rec.upgrade, "flag.locked")
		if (callback != null) callback(false)
		return
	}
	if (phoenix.item.Upgrade.isMaxed(rec.upgrade)) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, rec.upgrade, "already.maxed")
		if (callback != null) callback(false)
		return
	}

	local cost = phoenix.item.Upgrade.getCost(rec.upgrade)
	local gold = phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, active.id, "ITMI_GOLD")
	if (gold < cost) {
		phoenix.item.Upgrader._reply(playerId, itemId, false, rec.upgrade, "no.gold")
		if (callback != null) callback(false)
		return
	}

	phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, active.id, "ITMI_GOLD", cost, function(goldOk) {
		if (!goldOk) {
			phoenix.item.Upgrader._reply(playerId, itemId, false, rec.upgrade, "no.gold")
			if (callback != null) callback(false)
			return
		}
		local chance = phoenix.item.Upgrade.getSuccessChance(rec.upgrade)
		local roll   = rand() % 100
		local success = (roll < chance)

		if (success) {
			rec.upgrade += 1
		} else if (rec.upgrade > 5) {
			rec.upgrade -= 1
		}

		rec.saveAsync(function(_) {
			phoenix.item.Structure._notifyUpdate(PhoenixInventoryOwner.Player, active.id, rec)
			phoenix.item.Structure.sendInventorySnapshot(playerId, active.id)
			phoenix.item.Upgrader._reply(playerId, itemId, success, rec.upgrade, "")
			if (callback != null) callback(success)
		})
	})
}

phoenix.item.Upgrader._reply <- function(playerId, itemId, success, upgrade, error) {
	try {
		local msg = phoenix.item.Message.UpgradeResult()
		msg.id      = itemId
		msg.success = success
		msg.upgrade = upgrade
		msg.error   = error
		msg.serialize().send(playerId, RELIABLE_ORDERED)
	} catch (e) {}
}
