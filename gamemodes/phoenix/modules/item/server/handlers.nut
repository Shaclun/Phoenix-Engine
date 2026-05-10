

phoenix.item.Handlers.onCharacterSelected <- function(playerId, characterId) {
	phoenix.item.Structure.loadOwner(PhoenixInventoryOwner.Player, characterId, function(items) {
		phoenix.item.Structure.applyToPlayer(playerId, characterId)
		phoenix.item.Structure.sendInventorySnapshot(playerId, characterId)
	})
}

phoenix.item.Handlers.onPlayerDisconnect <- function(playerId, _reason) {
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return
	phoenix.item.Structure.unloadOwner(PhoenixInventoryOwner.Player, active.id)
}

phoenix.item.Handlers.onUseRequest <- function(playerId, message) {
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return
	local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
	if (inv == null) return
	local rec = null
	foreach (it in inv.items) if (it.id == message.id) { rec = it; break }
	if (rec == null) return

	local s = phoenix.item.Structure.schemeOf(rec)
	if (s == null || s.onUse == null) return

	if (s.onUse == "heal" && s.effect != null && "hp" in s.effect) {
		local healMult = phoenix.item.Quality.getMultiplier(rec.quality)
		local amount = (s.effect.hp * healMult).tointeger()
		try { setPlayerHealth(playerId, getPlayerHealth(playerId) + amount) } catch (e) {}
	}
	else if (s.onUse == "mana" && s.effect != null && "mana" in s.effect) {
		local manaMult = phoenix.item.Quality.getMultiplier(rec.quality)
		local amount = (s.effect.mana * manaMult).tointeger()
		try { setPlayerMana(playerId, getPlayerMana(playerId) + amount) } catch (e) {}
	}

	phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, active.id, rec.id, 1)
}

phoenix.item.Handlers.onEquipRequest <- function(playerId, message) {
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return
	local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
	if (inv == null) return

	local rec = null
	foreach (it in inv.items) if (it.id == message.id) { rec = it; break }
	if (rec == null) return
	local instanceId = rec.instanceId
	local doEquip    = message.equip
	phoenix.item.Structure.setEquipped(PhoenixInventoryOwner.Player, active.id, message.id, doEquip, function(ok) {
		if (!ok) return

		if (doEquip) {
			try { ::giveItem(playerId, instanceId, 1) }
			catch (e) {}
			try { ::equipItem(playerId, instanceId) }
			catch (e) {}
		} else {
			try { ::unequipItem(playerId, instanceId) }
			catch (e) {}
			try { ::removeItem(playerId, instanceId, 1) }
			catch (e) {}
		}
	})
}

phoenix.item.Handlers.onUpgradeRequest <- function(playerId, message) {
	phoenix.item.Upgrader.tryUpgrade(playerId, message.id)
}

phoenix.item.Handlers.onDropRequest <- function(playerId, message) {
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return
	local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
	if (inv == null) return
	local rec = null
	foreach (it in inv.items) if (it.id == message.id) { rec = it; break }
	if (rec == null) return
	local scheme = phoenix.item.Structure.schemeOf(rec)
	if (scheme == null) return
	local amount = message.amount.tointeger()
	if (amount <= 0) amount = 1
	if (amount > rec.amount) amount = rec.amount
	if (!scheme.isStackable()) amount = 1
	if (amount <= 0) return
	if (rec.equipped == 1) {
		try { ::unequipItem(playerId, rec.instanceId) } catch (e) {}
		try { ::removeItem(playerId, rec.instanceId, 1) } catch (e2) {}
		rec.equipped = 0
		rec.slot = 0
	}
	local dropName = (message.name != null && message.name != "") ? message.name.tostring() : ""
	local dropVisual = (message.visual != null && message.visual != "") ? message.visual.tostring() : ""
	local dropData = { instanceId = rec.instanceId, amount = amount, quality = rec.quality, upgrade = rec.upgrade, name = dropName, visual = dropVisual }
	try { playAni(playerId, "T_IDROP_2_STAND") } catch (ea) {}
	phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, active.id, rec.id, amount, function(ok) {
		if (!ok) return
		try { ::removeItem(playerId, dropData.instanceId, dropData.amount) } catch (er) {}
		phoenix.item.Structure.addGroundDroppedItem(playerId, dropData, function(spawned, _error) {
			if (!spawned) {
				try {
					if ("vob" in phoenix && phoenix.vob != null && "Structure" in phoenix.vob)
						phoenix.vob.Structure.addRuntimeDroppedItem(playerId, dropData, function(vobSpawned, vobError) { spawned = vobSpawned; _error = vobError })
				} catch (ev) {}
			}
			if (!spawned) {
				phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, dropData.instanceId, { amount = dropData.amount, quality = dropData.quality, upgrade = dropData.upgrade, source = "drop-rollback" }, null)
				try { phoenix.notification.notify(playerId, "error", "Przedmiot", "Nie mozna wyrzucic przedmiotu.", 3000) } catch (e) {}
				return
			}
			local label = phoenix.item.Structure._dropLabel(scheme, dropData.amount, dropData.upgrade, dropData.name)
			try { phoenix.notification.notify(playerId, "info", "Wyrzucono", label, 2800) } catch (e2) {}
		})
	})
}

phoenix.item.Message.UseRequest.bind(phoenix.item.Handlers.onUseRequest)
phoenix.item.Message.EquipRequest.bind(phoenix.item.Handlers.onEquipRequest)
phoenix.item.Message.UpgradeRequest.bind(phoenix.item.Handlers.onUpgradeRequest)
phoenix.item.Message.DropRequest.bind(phoenix.item.Handlers.onDropRequest)

local phoenixGroundTakeEvent = "onPlayer" + "TakeItem"
try { addEventHandler(phoenixGroundTakeEvent, phoenix.item.Structure.onGroundTake) } catch (e) {}

local phoenixItemSelectedEvent = "phoenix.character." + "OnSelected"
local phoenixItemDisconnectEvent = "onPlayer" + "Disconnect"
try { addEventHandler(phoenixItemSelectedEvent, phoenix.item.Handlers.onCharacterSelected) } catch (e) {}
try { addEventHandler(phoenixItemDisconnectEvent, phoenix.item.Handlers.onPlayerDisconnect) } catch (e2) {}

phoenix.item.Handlers._tryGiveAllCommand <- function(playerId, text) {
	if (text.len() < 8 || text.slice(0, 8) != "/giveall") return false
	local rest = (text.len() > 9) ? text.slice(9) : ""
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return true
	local parts   = (rest != "") ? split(rest, " ") : []
	local quality = (parts.len() > 0) ? parts[0].tointeger() : PhoenixItemQuality.Common
	local upgrade = (parts.len() > 1) ? parts[1].tointeger() : 0
	local total   = phoenix.item.count()
	try { sendMessageToPlayer(playerId, 255, 200, 0,
		"[Item] /giveall — wydawanie " + total + " przedmiotów (q=" + quality + ", +" + upgrade + ")...") } catch (e) {}
	local given = 0
	foreach (instanceId, _scheme in phoenix.item.Schemes.byInstance) {
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, instanceId, {
			amount = 1, quality = quality, upgrade = upgrade, source = "admin-giveall"
		}, null)
		given += 1
	}
	try { sendMessageToPlayer(playerId, 60, 220, 60,
		"[Item] +" + given + " przedmiotów dodanych do ekwipunku.") } catch (e) {}
	return true
}

phoenix.item.Handlers._tryClearItemsCommand <- function(playerId, text) {
	if (text != "/clearitems") return false
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return true
	local sql = "DELETE FROM `phoenix_items` WHERE `ownerType` = " +
		PhoenixInventoryOwner.Player + " AND `ownerId` = " + active.id
	ORM.engine.executeAsync(sql, function(_) {

		local key = phoenix.item.Structure.key(PhoenixInventoryOwner.Player, active.id)
		if (key in phoenix.item.Structure.cache) phoenix.item.Structure.cache.rawdelete(key)
		phoenix.item.Structure.loadOwner(PhoenixInventoryOwner.Player, active.id, function(_) {
			phoenix.item.Structure.sendInventorySnapshot(playerId, active.id)
		})
		try { sendMessageToPlayer(playerId, 60, 220, 60,
			"[Item] /clearitems — ekwipunek wyczyszczony.") } catch (e) {}
	})
	return true
}

phoenix.item.Handlers.tryAdminCommand <- function(playerId, text) {
	if (text == null) return false
	if (text.len() == 0 || text[0] != '/') return false
	local isAdminCmd = false
	if (text.len() >= 8 && text.slice(0, 8) == "/giveall") isAdminCmd = true
	else if (text == "/clearitems") isAdminCmd = true
	else if (text.len() >= 9 && text.slice(0, 9) == "/giveitem") isAdminCmd = true
	if (!isAdminCmd) return false
	if (!phoenix.account.Auth.requireAdmin(playerId)) return true
	if (phoenix.item.Handlers._tryGiveAllCommand(playerId, text)) return true
	if (phoenix.item.Handlers._tryClearItemsCommand(playerId, text)) return true
	if (text.len() < 9 || text.slice(0, 9) != "/giveitem") return false
	local rest = (text.len() > 10) ? text.slice(10) : ""
	if (rest == "") {
		try { sendMessageToPlayer(playerId, 255, 200, 0,
			"/giveitem <instance> [amt] [quality 0-5] [upgrade 0-9]") } catch (e) {}
		return true
	}
	local active = phoenix.character.Structure.getActive(playerId)
	if (active == null) return true
	local parts = split(rest, " ")
	local instance = parts[0]
	local amount   = (parts.len() > 1) ? parts[1].tointeger() : 1
	local quality  = (parts.len() > 2) ? parts[2].tointeger() : PhoenixItemQuality.Common
	local upgrade  = (parts.len() > 3) ? parts[3].tointeger() : 0
	phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, instance, {
		amount = amount, quality = quality, upgrade = upgrade, source = "admin"
	}, function(rec) {
		if (rec == null) {
			try { sendMessageToPlayer(playerId, 255, 60, 60,
				"[Item] Nieznana instancja: " + instance) } catch (e) {}
			return
		}
		try { sendMessageToPlayer(playerId, 60, 220, 60,
			"[Item] +" + amount + "x " + instance +
			" (q=" + quality + ", +" + upgrade + ")") } catch (e) {}
	})
	return true
}

