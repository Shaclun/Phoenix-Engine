phoenix.npc.Teacher <- {
	skillToStat = {
		strength = "strength",
		dexterity = "dexterity",
		oneHand = "oneHand",
		twoHand = "twoHand",
		bow = "bow",
		crossbow = "crossbow",
		manaMax = "manaMax",
		hpMax = "hpMax"
	}

	function _findByNpcId(npcId) {
		foreach (spawnId, entry in phoenix.npc.Spawn.live) {
			if (entry.npcId == npcId) return entry
		}
		return null
	}

	function _sessionValid(playerId, npcId, requireOwner = true) {
		local entry = phoenix.npc.Teacher._findByNpcId(npcId)
		if (entry == null || !entry.alive) return false
		try {
			if (!isPlayerConnected(playerId) || getPlayerHealth(playerId) <= 0 || getPlayerHealth(npcId) <= 0) return false
			if (getPlayerWorld(playerId) != getPlayerWorld(npcId)) return false
			if (getPlayerVirtualWorld(playerId) != getPlayerVirtualWorld(npcId)) return false
			if (requireOwner && (!("dialogPartner" in entry.ai) || entry.ai.dialogPartner != playerId)) return false
			local playerPosition = getPlayerPosition(playerId)
			local npcPosition = getPlayerPosition(npcId)
			if (playerPosition == null || npcPosition == null) return false
			local dx = playerPosition.x - npcPosition.x
			local dy = playerPosition.y - npcPosition.y
			local dz = playerPosition.z - npcPosition.z
			return sqrt(dx * dx + dy * dy + dz * dz) <= 600.0
		} catch (error) { return false }
	}

	function _csvHas(csv, key) {
		if (csv == null || csv == "") return false
		local parts = split(csv, ",")
		foreach (p in parts) { if (p.tolower() == key.tolower()) return true }
		return false
	}

	function _playerGold(playerId) {
		try {
			local rec = phoenix.character.Structure.getActive(playerId)
			if (rec != null) return phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, rec.id, "ITMI_GOLD")
		} catch (e) {}
		return 0
	}

	function _takePlayerGold(playerId, amount, callback) {
		try {
			local rec = phoenix.character.Structure.getActive(playerId)
			if (rec == null) { if (callback != null) callback(false); return }
			if (amount <= 0) { if (callback != null) callback(true); return }
			phoenix.item.Structure.takeInstance(PhoenixInventoryOwner.Player, rec.id, "ITMI_GOLD", amount, function(ok) {
				if (callback != null) callback(ok)
			})
		} catch (e) { if (callback != null) callback(false) }
	}

	function _givePlayerGold(playerId, amount, callback = null) {
		try {
			local rec = phoenix.character.Structure.getActive(playerId)
			if (rec == null) { if (callback != null) callback(false); return }
			if (amount <= 0) { if (callback != null) callback(true); return }
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, rec.id, "ITMI_GOLD", { amount = amount, source = "merchant" }, function(item) {
				if (callback != null) callback(item != null)
			})
		} catch (e) { if (callback != null) callback(false) }
	}

	function _hasTeacher(row) {
		local skills = ("teacherSkills" in row) ? row.teacherSkills : ""
		return skills != null && skills != ""
	}

	function _merchantItems(row) {
		local items = ""
		try { items = phoenix.npc.Spawn._metadataValue(row.metadata, "merchantItems") } catch (e) {}
		return items == null ? "" : items
	}

	function _hasMerchant(row) {
		if (phoenix.npc.Teacher._merchantItems(row) != "") return true
		try { if (row.kind == "merchant") return true } catch (e) {}
		return false
	}

	function _isWeaponSkill(skill) {
		return skill == "oneHand" || skill == "twoHand" || skill == "bow" || skill == "crossbow"
	}

	function _gesture(playerId, npcId) {
		try { setPlayerAngle(playerId, getVectorAngle(getPlayerPosition(playerId).x, getPlayerPosition(playerId).z, getPlayerPosition(npcId).x, getPlayerPosition(npcId).z), true) } catch (e) {}
		try { setPlayerAngle(npcId, getVectorAngle(getPlayerPosition(npcId).x, getPlayerPosition(npcId).z, getPlayerPosition(playerId).x, getPlayerPosition(playerId).z), true) } catch (e) {}
	}

	function _dialogName(row) {
		return row.name != "" ? row.name : row.instance
	}

	function _safeIdleAnimation(value) {
		if (value == null || value == "") return "S_STAND"
		local up = value.tostring().toupper()
		if (up == "S_RUN" || up.find("RUN") != null || up.find("WALK") != null || up.find("ATTACK") != null || up.find("WARN") != null) return "S_STAND"
		return value
	}

	function openRootDialog(playerId, npcId) {
		if (!phoenix.features.Settings.isEnabled("npc.interaction")) return
		local entry = phoenix.npc.Teacher._findByNpcId(npcId)
		if (entry == null) return
		local row = entry.row
		local hasTeacher = phoenix.features.Settings.isEnabled("npc.teachers") && phoenix.npc.Teacher._hasTeacher(row)
		local hasMerchant = phoenix.features.Settings.isEnabled("npc.merchants") && phoenix.npc.Teacher._hasMerchant(row)
		if (!hasTeacher && !hasMerchant) return
		phoenix.npc.Teacher._gesture(playerId, npcId)
		local m = phoenix.npc.Message.Dialog()
		m.npcId = npcId
		m.npcName = phoenix.npc.Teacher._dialogName(row)
		m.idleAnimation = phoenix.npc.Teacher._safeIdleAnimation(row.idleAnimation)
		m.hasTeacher = hasTeacher
		m.hasMerchant = hasMerchant
		try { m.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function openDialog(playerId, npcId) {
		if (!phoenix.features.Settings.isEnabled("npc.interaction")) return
		if (!phoenix.features.Settings.isEnabled("npc.teachers")) return
		local entry = phoenix.npc.Teacher._findByNpcId(npcId)
		if (entry == null) return
		local row = entry.row
		local skills = ("teacherSkills" in row) ? row.teacherSkills : ""
		if (skills == null || skills == "") return
		phoenix.npc.Teacher._gesture(playerId, npcId)
		local rec = null
		try { rec = phoenix.character.Structure.getActive(playerId) } catch (e) {}
		local m = phoenix.npc.Message.TeacherDialog()
		m.npcId = npcId
		m.npcName = phoenix.npc.Teacher._dialogName(row)
		m.skills = skills
		m.cost = ("teachCost" in row) ? row.teachCost : 100
		m.playerGold = phoenix.npc.Teacher._playerGold(playerId)
		m.playerLearnPoints = rec != null ? rec.learnPoints : 0
		try { m.weaponProgress = phoenix.player.WeaponProgression.progressString(playerId) } catch (e) { m.weaponProgress = "" }
		try { m.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function _reply(playerId, ok, err) {
		local r = phoenix.npc.Message.TeacherResult()
		r.success = ok
		r.error = err == null ? "" : err
		try { r.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function onTrain(playerId, message) {
		if (!phoenix.features.Settings.isEnabled("npc.interaction")) return
		if (!phoenix.features.Settings.isEnabled("npc.teachers")) return
		local npcId = message.npcId
		if (!phoenix.npc.Teacher._sessionValid(playerId, npcId, true)) { phoenix.npc.Teacher._reply(playerId, false, "tooFar"); return }
		local skill = message.skill
		local entry = phoenix.npc.Teacher._findByNpcId(npcId)
		if (entry == null) { phoenix.npc.Teacher._reply(playerId, false, "noTeacher"); return }
		local row = entry.row
		local skills = ("teacherSkills" in row) ? row.teacherSkills : ""
		if (!phoenix.npc.Teacher._csvHas(skills, skill)) { phoenix.npc.Teacher._reply(playerId, false, "skillUnavailable"); return }
		try {
			local p1 = getPlayerPosition(playerId)
			local p2 = getPlayerPosition(npcId)
			if (p1 != null && p2 != null) {
				local dx = p1.x - p2.x, dy = p1.y - p2.y, dz = p1.z - p2.z
				local dist = sqrt(dx * dx + dy * dy + dz * dz)
				if (dist > 600) { phoenix.npc.Teacher._reply(playerId, false, "tooFar"); return }
			}
		} catch (e) {}
		local gold = phoenix.npc.Teacher._playerGold(playerId)
		local cost = ("teachCost" in row) ? row.teachCost : 100
		if (phoenix.npc.Teacher._isWeaponSkill(skill)) cost = 0
		if (gold < cost) { phoenix.npc.Teacher._reply(playerId, false, "noGold"); return }
		local stat = (skill in phoenix.npc.Teacher.skillToStat) ? phoenix.npc.Teacher.skillToStat[skill] : null
		if (stat == null) { phoenix.npc.Teacher._reply(playerId, false, "skillUnavailable"); return }
		if (phoenix.npc.Teacher._isWeaponSkill(skill)) {
			if (!phoenix.features.Settings.isEnabled("progression.weaponExperience")) {
				phoenix.npc.Teacher._reply(playerId, false, "skillUnavailable")
				return
			}
			local errKey = null
			try { errKey = phoenix.player.WeaponProgression.unlockCap(playerId, stat) } catch (e) { errKey = "internal" }
			if (errKey != null) { phoenix.npc.Teacher._reply(playerId, false, errKey); return }
			phoenix.npc.Teacher._reply(playerId, true, "")
			try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e) {}
			phoenix.npc.Teacher.openDialog(playerId, npcId)
			return
		}
		if (!phoenix.features.Settings.isEnabled("progression.statsSpending")) {
			phoenix.npc.Teacher._reply(playerId, false, "skillUnavailable")
			return
		}
		phoenix.npc.Teacher._takePlayerGold(playerId, cost, function(goldOk) {
			if (!goldOk) { phoenix.npc.Teacher._reply(playerId, false, "noGold"); return }
			local errKey = null
			try { errKey = phoenix.player.Stats.spend(playerId, stat, 1) } catch (e2) { errKey = "internal" }
			if (errKey != null) {
				phoenix.npc.Teacher._givePlayerGold(playerId, cost, function(_) {})
				phoenix.npc.Teacher._reply(playerId, false, errKey)
				return
			}
			phoenix.npc.Teacher._refreshInventory(playerId)
			phoenix.npc.Teacher._reply(playerId, true, "")
			try { phoenix.player.Stats.pushSnapshot(playerId) } catch (e) {}
			phoenix.npc.Teacher.openDialog(playerId, npcId)
		})
	}

	function onInteract(playerId, message) {
		if (!phoenix.features.Settings.isEnabled("npc.interaction")) return
		if (!phoenix.npc.Teacher._sessionValid(playerId, message.npcId, false)) return
		try { if (phoenix.quest.Dialog.openForNpc(playerId, message.npcId)) return } catch (eQuest) {}
		phoenix.npc.Teacher.openRootDialog(playerId, message.npcId)
		try {
			local entry = phoenix.npc.Teacher._findByNpcId(message.npcId)
			if (entry != null) {
				entry.ai.dialogPartner <- playerId
				entry.ai.dialogPartnerSince <- getTickCount()
				entry.ai.routineWaitUntil <- 0
			}
		} catch (e) {}
	}

	function onAction(playerId, message) {
		if (message.action != "close" && !phoenix.features.Settings.isEnabled("npc.interaction")) return
		if (message.action != "close" && !phoenix.npc.Teacher._sessionValid(playerId, message.npcId, true)) return
		if (message.action == "teacher") { phoenix.npc.Teacher.openDialog(playerId, message.npcId); return }
		if (message.action == "merchant") { phoenix.npc.Teacher.openMerchant(playerId, message.npcId); return }
		if (message.action == "close") {
			try { phoenix.quest.Dialog.close(playerId, false) } catch (eQuest) {}
			try {
				local entry = phoenix.npc.Teacher._findByNpcId(message.npcId)
				if (entry != null && ("dialogPartner" in entry.ai) && entry.ai.dialogPartner == playerId) {
					entry.ai.dialogPartner <- -1
				}
			} catch (e) {}
			return
		}
		phoenix.npc.Teacher.openRootDialog(playerId, message.npcId)
	}

	function _stock(text) {
		local out = {}
		if (text == null || text == "") return out
		local parts = split(text, ",")
		foreach (part in parts) {
			local p = split(part, ":")
			if (p.len() == 0 || p[0] == "") continue
			local amount = p.len() > 1 ? p[1].tointeger() : 1
			if (amount < 1) amount = 1
			out[p[0]] <- amount
		}
		return out
	}

	function _stockString(stock) {
		local parts = []
		foreach (instance, amount in stock) {
			if (amount > 0) parts.push(instance + ":" + amount)
		}
		local result = ""
		for (local i = 0; i < parts.len(); i += 1) {
			if (i > 0) result += ","
			result += parts[i]
		}
		return result
	}

	function _metadataSetValue(text, key, value) {
		local source = text == null ? "" : text
		local needle = "\"" + key + "\":\""
		local start = source.find(needle)
		if (start == null) {
			if (source == "" || source == "{}") return "{\"" + key + "\":\"" + value + "\"}"
			local cut = source.len() - 1
			if (cut < 0 || source.slice(cut) != "}") return "{\"" + key + "\":\"" + value + "\"}"
			local prefix = source.slice(0, cut)
			if (prefix.len() > 1) prefix += ","
			return prefix + "\"" + key + "\":\"" + value + "\"}"
		}
		local valueStart = start + needle.len()
		local rest = source.slice(valueStart)
		local rel = rest.find("\"")
		if (rel == null) return source
		local valueEnd = valueStart + rel
		return source.slice(0, valueStart) + value + source.slice(valueEnd)
	}

	function _saveMerchantItems(row, items) {
		row.metadata = phoenix.npc.Teacher._metadataSetValue(row.metadata, "merchantItems", items)
		local sql = "UPDATE `phoenix_npc_spawns` SET `metadata` = '" + phoenix.npc.Spawn._esc(row.metadata) + "' WHERE `id` = " + row.id
		try { ORM.engine.executeAsync(sql, function(_) {}) } catch (e) {}
	}

	function _itemVisual(instance, scheme = null) {
		local visual = ""
		try { if (scheme != null && scheme.visual != null) visual = scheme.visual } catch (e) {}
		if (visual == null || visual == "") {
			try {
				local looked = phoenix.item.lookupVisual(instance)
				if (looked != null) visual = looked
			} catch (e) {}
		}
		return visual == null ? "" : visual
	}

	function _merchantPacketItems(stock) {
		local parts = []
		foreach (instance, amount in stock) {
			local scheme = phoenix.item.find(instance)
			if (scheme == null) continue
			local visual = phoenix.npc.Teacher._itemVisual(instance, scheme)
			local category = 0
			try { category = scheme.category } catch (e) {}
			local slot = 0
			try { slot = scheme.slot } catch (e) {}
			parts.push(instance + "|" + amount + "|" + scheme.value + "|" + visual + "|" + category + "|" + slot)
		}
		local result = ""
		for (local i = 0; i < parts.len(); i += 1) {
			if (i > 0) result += ","
			result += parts[i]
		}
		return result
	}

	function _playerPacketItems(playerId) {
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return ""
		local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
		if (inv == null) return ""
		local parts = []
		foreach (rec in inv.items) {
			try { if (rec.instanceId != null && rec.instanceId.toupper() == "ITMI_GOLD") continue } catch (eg) {}
			local scheme = phoenix.item.Structure.schemeOf(rec)
			if (scheme == null) continue
			local visual = phoenix.npc.Teacher._itemVisual(rec.instanceId, scheme)
			local category = 0
			try { category = scheme.category } catch (e) {}
			local slot = 0
			try { slot = scheme.slot } catch (e) {}
			local quality = 2
			try { quality = rec.quality } catch (e) {}
			local upgrade = 0
			try { upgrade = rec.upgrade } catch (e) {}
			parts.push(rec.id + "|" + rec.instanceId + "|" + rec.amount + "|" + scheme.value + "|" + visual + "|" + category + "|" + slot + "|" + quality + "|" + upgrade)
		}
		local result = ""
		for (local i = 0; i < parts.len(); i += 1) {
			if (i > 0) result += ","
			result += parts[i]
		}
		return result
	}

	function openMerchant(playerId, npcId) {
		if (!phoenix.features.Settings.isEnabled("npc.interaction")) return
		if (!phoenix.features.Settings.isEnabled("npc.merchants")) return
		local entry = phoenix.npc.Teacher._findByNpcId(npcId)
		if (entry == null) return
		local row = entry.row
		local stock = phoenix.npc.Teacher._stock(phoenix.npc.Teacher._merchantItems(row))
		if (!phoenix.npc.Teacher._hasMerchant(row)) return
		phoenix.npc.Teacher._gesture(playerId, npcId)
		local m = phoenix.npc.Message.MerchantDialog()
		m.npcId = npcId
		m.npcName = phoenix.npc.Teacher._dialogName(row)
		m.items = phoenix.npc.Teacher._merchantPacketItems(stock)
		m.playerItems = phoenix.npc.Teacher._playerPacketItems(playerId)
		m.playerGold = phoenix.npc.Teacher._playerGold(playerId)
		try { m.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function _merchantReply(playerId, ok, err) {
		local r = phoenix.npc.Message.MerchantResult()
		r.success = ok
		r.error = err == null ? "" : err
		r.playerGold = phoenix.npc.Teacher._playerGold(playerId)
		try { r.serialize().send(playerId, RELIABLE_ORDERED) } catch (e) {}
	}

	function _refreshInventory(playerId) {
		local active = phoenix.character.Structure.getActive(playerId)
		if (active != null) phoenix.item.Structure.sendInventorySnapshot(playerId, active.id)
	}

	function onTrade(playerId, message) {
		if (!phoenix.features.Settings.isEnabled("npc.interaction")) return
		if (!phoenix.features.Settings.isEnabled("npc.merchants")) return
		if (!phoenix.npc.Teacher._sessionValid(playerId, message.npcId, true)) { phoenix.npc.Teacher._merchantReply(playerId, false, "tooFar"); return }
		local entry = phoenix.npc.Teacher._findByNpcId(message.npcId)
		if (entry == null) { phoenix.npc.Teacher._merchantReply(playerId, false, "noMerchant"); return }
		local row = entry.row
		local amount = message.amount < 1 ? 1 : message.amount
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) { phoenix.npc.Teacher._merchantReply(playerId, false, "noCharacter"); return }
		if (message.mode == "buy") {
			local stock = phoenix.npc.Teacher._stock(phoenix.npc.Teacher._merchantItems(row))
			if (!(message.instance in stock) || stock[message.instance] < amount) { phoenix.npc.Teacher._merchantReply(playerId, false, "noStock"); return }
			local scheme = phoenix.item.find(message.instance)
			if (scheme == null) { phoenix.npc.Teacher._merchantReply(playerId, false, "badItem"); return }
			local price = scheme.value * amount
			local gold = phoenix.npc.Teacher._playerGold(playerId)
			if (gold < price) { phoenix.npc.Teacher._merchantReply(playerId, false, "noGold"); return }
			phoenix.npc.Teacher._takePlayerGold(playerId, price, function(goldOk) {
				if (!goldOk) { phoenix.npc.Teacher._merchantReply(playerId, false, "noGold"); return }
				stock[message.instance] = stock[message.instance] - amount
				phoenix.npc.Teacher._saveMerchantItems(row, phoenix.npc.Teacher._stockString(stock))
				phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, message.instance, { amount = amount, source = "merchant" }, function(_) {
					phoenix.npc.Teacher._refreshInventory(playerId)
					phoenix.npc.Teacher._merchantReply(playerId, true, "")
					phoenix.npc.Teacher.openMerchant(playerId, message.npcId)
				})
			})
			return
		}
		if (message.mode == "sell") {
			local inv = phoenix.item.Structure.getInventory(PhoenixInventoryOwner.Player, active.id)
			if (inv == null) { phoenix.npc.Teacher._merchantReply(playerId, false, "noItem"); return }
			local rec = null
			foreach (it in inv.items) if (it.id == message.itemId) { rec = it; break }
			if (rec == null || rec.amount < amount) { phoenix.npc.Teacher._merchantReply(playerId, false, "noItem"); return }
			local scheme = phoenix.item.Structure.schemeOf(rec)
			if (scheme == null) { phoenix.npc.Teacher._merchantReply(playerId, false, "badItem"); return }
			local gain = ((scheme.value * amount) * 30 / 100).tointeger()
			phoenix.item.Structure.takeItem(PhoenixInventoryOwner.Player, active.id, rec.id, amount, function(ok) {
				if (!ok) { phoenix.npc.Teacher._merchantReply(playerId, false, "noItem"); return }
				phoenix.npc.Teacher._givePlayerGold(playerId, gain, function(goldOk) {
					if (!goldOk) { phoenix.npc.Teacher._merchantReply(playerId, false, "internal"); return }
					phoenix.npc.Teacher._refreshInventory(playerId)
					phoenix.npc.Teacher._merchantReply(playerId, true, "")
					phoenix.npc.Teacher.openMerchant(playerId, message.npcId)
				})
			})
		}
	}
}

phoenix.npc.Message.InteractRequest.bind(phoenix.npc.Teacher.onInteract)
phoenix.npc.Message.DialogAction.bind(phoenix.npc.Teacher.onAction)
phoenix.npc.Message.TeacherTrain.bind(phoenix.npc.Teacher.onTrain)
phoenix.npc.Message.MerchantTrade.bind(phoenix.npc.Teacher.onTrade)
