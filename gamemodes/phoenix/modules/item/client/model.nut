

phoenix.item.Model.items <- []
phoenix.item.Model.gold  <- 0
phoenix.item.Model.ownerType <- 0
phoenix.item.Model.ownerId   <- 0

phoenix.item.Model._byId <- function(id) {
	foreach (it in phoenix.item.Model.items) if (it.id == id) return it
	return null
}

phoenix.item.Model._isGold <- function(entry) {
	try { return entry != null && entry.instance != null && entry.instance.toupper() == "ITMI_GOLD" } catch (e) {}
	return false
}

phoenix.item.Model._emit <- function(eventName, payload) {
	try { phoenix.web.Manager.emit(eventName, payload) } catch (e) {}
}

phoenix.item.Model._enrich <- function(entry) {
	if (entry == null) return entry
	try { entry.labels <- phoenix.web.Json.parse(entry.labelsJson) } catch (e) { entry.labels <- null }
	try { entry.descriptions <- phoenix.web.Json.parse(entry.descriptionsJson) } catch (e) { entry.descriptions <- null }
	try { entry.effect <- phoenix.web.Json.parse(entry.effectJson) } catch (e) { entry.effect <- null }
	local scheme = phoenix.item.find(entry.instance)
	if (scheme == null) return entry
	local stats = phoenix.item.computeStats(scheme, entry.quality, entry.upgrade)
	entry.name        <- scheme.name
	entry.description <- scheme.description
	entry.value       <- stats.value
	entry.weight      <- scheme.weight

	entry.visual      <- phoenix.item.lookupVisual(entry.instance)
	entry.onUse       <- scheme.onUse != null
	entry.onUseKind   <- scheme.onUse != null ? scheme.onUse.tostring() : ""
	entry.category    <- scheme.category
	entry.stats       <- {
		damage     = stats.damage,
		protection = stats.protection,
		multiplier = stats.multiplier
	}
	if (entry.slot == 0 && scheme.slot != 0) entry.slot = scheme.slot

	local reqs = []
	try {
		if (scheme.requirement != null) {
			foreach (r in scheme.requirement) {
				if (r == null) continue
				local attr = ("attr" in r && r.attr != null) ? r.attr.tostring() : ""
				local value = ("value" in r) ? r.value.tointeger() : 0
				if (attr != "" && value > 0) reqs.append({ attr = attr, value = value })
			}
		}
	} catch (eR) {}
	entry.requirements <- reqs

	local effect = null
	try {
		if (scheme.effect != null) {
			effect = {}
			foreach (k, v in scheme.effect) { try { effect[k] <- v } catch (eE) {} }
		}
	} catch (eEf) {}
	entry.effect <- effect

	local spellInfo = null
	try {
		if (scheme.onUse != null && scheme.onUse.tostring() == "spell" && scheme.effect != null && "spell" in scheme.effect && scheme.effect.spell != null) {
			local cat = phoenix.item.SpellsCatalog.find(scheme.effect.spell)
			if (cat != null) {
				spellInfo = {}
				foreach (k, v in cat) { try { spellInfo[k] <- v } catch (eSc) {} }
				spellInfo.key <- scheme.effect.spell.tostring().toupper()
				local circleForReq = ("circle" in cat) ? cat.circle : 1
				local enforce = scheme.category != PhoenixItemCategory.Scroll
				spellInfo.enforceCircle <- enforce
				spellInfo.requiredLevel <- enforce ? phoenix.item.SpellsCatalog.requiredLevel(circleForReq) : 0
				spellInfo.consumable <- scheme.category == PhoenixItemCategory.Scroll
				if (scheme.category == PhoenixItemCategory.Scroll && "manaCost" in spellInfo) {
					local mc = spellInfo.manaCost.tointeger()
					local d = (mc / 3).tointeger()
					if (d < 5) d = 5
					if (d > mc && mc > 0) d = mc
					spellInfo.manaCost = d
				}
			}
		}
	} catch (eSp) {}
	entry.spell <- spellInfo
	return entry
}

phoenix.item.Model.onInventory <- function(message) {
	phoenix.item.Model.ownerType = message.ownerType
	phoenix.item.Model.ownerId   = message.ownerId
	phoenix.item.Model.gold      = message.gold
	local items = (message.items != null) ? message.items : []
	foreach (it in items) phoenix.item.Model._enrich(it)
	phoenix.item.Model.items = items
	phoenix.item.Model._emit("phoenix:item:inventory", {
		ownerType = message.ownerType,
		ownerId   = message.ownerId,
		gold      = message.gold,
		items     = phoenix.item.Model.items
	})
}

phoenix.item.Model.onAdd <- function(message) {
	if (message.item == null) return
	if (phoenix.item.Model._isGold(message.item)) {
		try { phoenix.item.Model.gold += message.item.amount } catch (e) {}
		phoenix.item.Model._emit("phoenix:item:inventory", { ownerType = phoenix.item.Model.ownerType, ownerId = phoenix.item.Model.ownerId, gold = phoenix.item.Model.gold, items = phoenix.item.Model.items })
		return
	}
	phoenix.item.Model._enrich(message.item)
	phoenix.item.Model.items.push(message.item)
	phoenix.item.Model._emit("phoenix:item:add", { item = message.item })
}

phoenix.item.Model.onRemove <- function(message) {
	for (local i = 0; i < phoenix.item.Model.items.len(); i += 1) {
		if (phoenix.item.Model.items[i].id == message.id) {
			if (phoenix.item.Model._isGold(phoenix.item.Model.items[i])) {
				try { phoenix.item.Model.gold -= phoenix.item.Model.items[i].amount } catch (e) {}
				if (phoenix.item.Model.gold < 0) phoenix.item.Model.gold = 0
			}
			phoenix.item.Model.items.remove(i)
			phoenix.item.Model._emit("phoenix:item:remove", { id = message.id })
			return
		}
	}
}

phoenix.item.Model.onUpdate <- function(message) {
	if (message.item == null) return
	if (phoenix.item.Model._isGold(message.item)) {
		local previous = phoenix.item.Model._byId(message.item.id)
		if (previous != null) {
			try { phoenix.item.Model.gold += message.item.amount - previous.amount } catch (e) {}
			if (phoenix.item.Model.gold < 0) phoenix.item.Model.gold = 0
			for (local gi = 0; gi < phoenix.item.Model.items.len(); gi += 1) {
				if (phoenix.item.Model.items[gi].id == message.item.id) { phoenix.item.Model.items.remove(gi); break }
			}
		} else {
			try { phoenix.item.Model.gold += message.item.amount } catch (e2) {}
		}
		phoenix.item.Model._emit("phoenix:item:inventory", { ownerType = phoenix.item.Model.ownerType, ownerId = phoenix.item.Model.ownerId, gold = phoenix.item.Model.gold, items = phoenix.item.Model.items })
		return
	}
	phoenix.item.Model._enrich(message.item)
	for (local i = 0; i < phoenix.item.Model.items.len(); i += 1) {
		if (phoenix.item.Model.items[i].id == message.item.id) {
			phoenix.item.Model.items[i] = message.item
			phoenix.item.Model._emit("phoenix:item:update", { item = message.item })
			return
		}
	}

	phoenix.item.Model.items.push(message.item)
	phoenix.item.Model._emit("phoenix:item:add", { item = message.item })
}

phoenix.item.Model.onUpgradeResult <- function(message) {
	phoenix.item.Model._emit("phoenix:item:upgradeResult", {
		id      = message.id,
		success = message.success,
		upgrade = message.upgrade,
		error   = message.error
	})
}

phoenix.item.Model.requestUse <- function(itemId, source = "inventory") {
	try {
		local m = phoenix.item.Message.UseRequest()
		m.id = itemId
		m.source = source
		m.serialize().send(RELIABLE)
	} catch (e) {}
}

phoenix.item.Model.requestEquip <- function(itemId, equip) {
	try {
		local m = phoenix.item.Message.EquipRequest()
		m.id = itemId
		m.equip = (equip == true)
		m.serialize().send(RELIABLE)
	} catch (e) {}
}

phoenix.item.Model.requestUpgrade <- function(itemId) {
	try {
		local m = phoenix.item.Message.UpgradeRequest()
		m.id = itemId
		m.serialize().send(RELIABLE)
	} catch (e) {}
}

phoenix.item.Model.requestDrop <- function(itemId, amount, name = "", visual = "") {
	try {
		local m = phoenix.item.Message.DropRequest()
		m.id = itemId
		m.amount = amount
		m.name = name
		m.visual = visual
		m.serialize().send(RELIABLE)
	} catch (e) {}
}

phoenix.item.Model.onRenderConfig <- function(message) {
	local raw = ""
	try { raw = message.entries.tostring() } catch (e) { raw = "" }
	local entries = []
	if (raw != null && raw != "") {
		local lines = split(raw, "\n")
		foreach (line in lines) {
			if (line == "") continue
			local parts = split(line, "|")
			if (parts.len() < 6) continue
			entries.append({
				instance = parts[0],
				rotX = parts[1].tofloat(),
				rotY = parts[2].tofloat(),
				rotZ = parts[3].tofloat(),
				scaleValue = parts[4].tofloat(),
				lightIntensity = parts[5].tofloat()
			})
		}
	}
	phoenix.item.Model._emit("phoenix:item:renderConfig", { entries = entries })
}

phoenix.item.Model.onDocumentOpen <- function(message) {
	local source = "inventory"
	try { if (message.source != null) source = message.source.tostring() } catch (e) {}
	if (source == "hotbar") {
		try { phoenix.item.Interface.open() } catch (e) {}
	} else {
		local inventoryVisible = false
		try { inventoryVisible = phoenix.item.Interface.visible == true } catch (e) {}
		if (!inventoryVisible) return
	}
	local titles = {}; local contents = {}
	try { titles = phoenix.web.Json.parse(message.titleJson) } catch (e) {}
	try { contents = phoenix.web.Json.parse(message.contentJson) } catch (e) {}
	phoenix.item.Model._emit("phoenix:item:document", { titles = titles, contents = contents, source = source })
}

phoenix.item.Message.Inventory.bind(phoenix.item.Model.onInventory)
phoenix.item.Message.Add.bind(phoenix.item.Model.onAdd)
phoenix.item.Message.Remove.bind(phoenix.item.Model.onRemove)
phoenix.item.Message.Update.bind(phoenix.item.Model.onUpdate)
phoenix.item.Message.UpgradeResult.bind(phoenix.item.Model.onUpgradeResult)
phoenix.item.Message.DocumentOpen.bind(phoenix.item.Model.onDocumentOpen)
phoenix.item.Message.RenderConfig.bind(phoenix.item.Model.onRenderConfig)
