

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
	if (doEquip) {
		local scheme = phoenix.item.Structure.schemeOf(rec)
		if (scheme != null && scheme.requirement != null) {
			local missing = ""
			local need = 0
			foreach (r in scheme.requirement) {
				if (r == null) continue
				local attr = ("attr" in r && r.attr != null) ? r.attr.tostring() : ""
				local val = ("value" in r) ? r.value.tointeger() : 0
				if (attr == "" || val <= 0) continue
				local cur = 0
				try {
					if (attr == "strength") cur = getPlayerStrength(playerId)
					else if (attr == "dexterity") cur = getPlayerDexterity(playerId)
				} catch (e) {}
				if (cur < val) { missing = attr; need = val; break }
			}
			if (missing != "") {
				try { phoenix.notification.notify(playerId, "error", "Wymagania", "Brak " + missing + " " + need, 2800) } catch (e2) {}
				return
			}
		}
	}
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
