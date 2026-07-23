phoenix.quest.Rewards <- {
	function register(typeName, validator) {
		if (!phoenix.quest.Schema.isKey(typeName)) return false
		phoenix.quest.Registry.rewards[typeName] <- { validate = validator }
		return true
	}

	function effectKey(stateId, completionKey, rewardKey) {
		return stateId + ":" + completionKey + ":" + rewardKey
	}

	function choiceOptions(state) {
		local choices = []
		if (state == null || state.content == null || !("rewards" in state.content) || !phoenix.quest.Schema.isArray(state.content.rewards)) return choices
		foreach (reward in state.content.rewards) if (phoenix.quest.Schema.isTable(reward) && "choiceGroup" in reward && reward.choiceGroup != null && reward.choiceGroup.tostring() != "") choices.append(reward)
		return choices
	}

	function rewardsFor(state, choiceKey = null) {
		if (state == null || state.content == null || !("rewards" in state.content) || !phoenix.quest.Schema.isArray(state.content.rewards)) return []
		local selectedKey = choiceKey != null ? choiceKey.tostring() : (("rewardChoiceKey" in state && state.rewardChoiceKey != null) ? state.rewardChoiceKey.tostring() : "")
		local rewards = []
		local choices = []
		foreach (reward in state.content.rewards) {
			if (phoenix.quest.Schema.isTable(reward) && "choiceGroup" in reward && reward.choiceGroup != null && reward.choiceGroup.tostring() != "") choices.append(reward)
			else rewards.append(reward)
		}
		if (choices.len() == 0) return selectedKey == "" ? rewards : null
		if (selectedKey == "") return null
		local selected = null
		foreach (reward in choices) if ("key" in reward && reward.key.tostring() == selectedKey) selected = reward
		if (selected == null) return null
		rewards.append(selected)
		return rewards
	}

	function prepareSync(stateId, rewards) {
		foreach (index, reward in rewards) {
			if (!phoenix.quest.Schema.isTable(reward) || !("type" in reward) || !(reward.type in phoenix.quest.Registry.rewards)) throw "INVALID_REWARD"
			local rewardKey = ("key" in reward) ? reward.key.tostring() : index.tostring()
			local key = phoenix.quest.Rewards.effectKey(stateId, "complete", rewardKey)
			ORM.engine.execute("INSERT IGNORE INTO `phoenix_quest_reward_ledger` (`characterQuestId`,`effectKey`,`rewardType`,`status`,`attempts`) VALUES (" + stateId + ",'" + phoenix.quest.Repository.escape(key) + "','" + phoenix.quest.Repository.escape(reward.type) + "','pending',0)")
		}
	}

	function normalizeExperience(row, amount) {
		local level = row.level.tointeger()
		local experience = row.experience.tointeger() + amount
		local learnPoints = row.learnPoints.tointeger()
		local hp = row.hp.tointeger()
		local hpMax = row.hpMax.tointeger()
		local mana = row.mana.tointeger()
		local manaMax = row.manaMax.tointeger()
		local stamina = row.stamina.tointeger()
		local staminaMax = row.staminaMax.tointeger()
		local klass = row.klass.tointeger()
		local magicLevel = row.magicLevel.tointeger()
		local expectedHp = 100 + (level - 1) * 10
		local expectedMana = (klass == 1 ? 50 : 10) + (level - 1) * (klass == 1 ? 8 : 2) + magicLevel * phoenix.player.Progression.manaPerMagicLevel
		local expectedStamina = 100 + (level - 1) * 5
		if (hpMax < expectedHp) { local old = hpMax > 0 ? hpMax : 100; hpMax = expectedHp; if (hp <= 0 || hp >= old) hp = hpMax }
		if (manaMax < expectedMana) { local old = manaMax > 0 ? manaMax : (klass == 1 ? 50 : 10); manaMax = expectedMana; if (mana < 0 || mana >= old) mana = manaMax }
		if (staminaMax < expectedStamina) { local old = staminaMax > 0 ? staminaMax : 100; staminaMax = expectedStamina; if (stamina <= 0 || stamina >= old) stamina = staminaMax }
		while (level < phoenix.player.Progression.maxLevel && experience >= phoenix.player.Progression.expForLevel(level + 1)) {
			level += 1
			hpMax += 10
			staminaMax += 5
			manaMax += klass == 1 ? 8 : 2
			learnPoints += 10
			hp = hpMax
			mana = manaMax
			stamina = staminaMax
		}
		if (level >= phoenix.player.Progression.maxLevel) experience = phoenix.player.Progression.expForLevel(phoenix.player.Progression.maxLevel)
		return { level = level, experience = experience, experienceNext = phoenix.player.Progression.expForLevel(level + 1), learnPoints = learnPoints, hp = hp, hpMax = hpMax, mana = mana, manaMax = manaMax, stamina = stamina, staminaMax = staminaMax }
	}
	function applyExperience(record, reward) {
		local amount = "amount" in reward ? reward.amount.tointeger() : 0
		if (amount <= 0) throw "INVALID_REWARD"
		local rows = ORM.engine.execute("SELECT `level`,`experience`,`learnPoints`,`hp`,`hpMax`,`mana`,`manaMax`,`stamina`,`staminaMax`,`klass`,`magicLevel` FROM `phoenix_characters` WHERE `id`=" + record.id + " FOR UPDATE")
		if (rows == null || rows.len() == 0) throw "CHARACTER_NOT_FOUND"
		local value = phoenix.quest.Rewards.normalizeExperience(rows[0], amount)
		ORM.engine.execute("UPDATE `phoenix_characters` SET `level`=" + value.level + ",`experience`=" + value.experience + ",`experienceNext`=" + value.experienceNext + ",`learnPoints`=" + value.learnPoints + ",`hp`=" + value.hp + ",`hpMax`=" + value.hpMax + ",`mana`=" + value.mana + ",`manaMax`=" + value.manaMax + ",`stamina`=" + value.stamina + ",`staminaMax`=" + value.staminaMax + " WHERE `id`=" + record.id)
		return { result = { amount = amount }, character = true, inventory = false }
	}

	function applyItem(record, reward, effectKey, currency = false) {
		local instance = currency ? "ITMI_GOLD" : (("instance" in reward && reward.instance != null) ? reward.instance.tostring().toupper() : "")
		local amount = "amount" in reward ? reward.amount.tointeger() : 0
		local scheme = phoenix.item.find(instance)
		if (scheme == null || amount <= 0) throw "INVALID_REWARD"
		local quality = "quality" in reward ? reward.quality.tointeger() : PhoenixItemQuality.Common
		local upgrade = "upgrade" in reward ? reward.upgrade.tointeger() : 0
		if (!phoenix.item.Quality.isValid(quality)) quality = PhoenixItemQuality.Common
		if (!phoenix.item.Upgrade.canUpgrade(scheme.category)) upgrade = 0
		if (upgrade < 0) upgrade = 0
		if (upgrade > phoenix.item.MAX_UPGRADE) upgrade = phoenix.item.MAX_UPGRADE
		ORM.engine.execute("INSERT INTO `phoenix_items` (`ownerType`,`ownerId`,`instanceId`,`amount`,`quality`,`upgrade`,`durability`,`equipped`,`slot`,`source`,`effectKey`) VALUES (" + PhoenixInventoryOwner.Player + "," + record.id + ",'" + phoenix.quest.Repository.escape(instance) + "'," + amount + "," + quality + "," + upgrade + ",100,0,0,'quest','" + phoenix.quest.Repository.escape(effectKey) + "')")
		return { result = { instance = instance, amount = amount }, character = false, inventory = true }
	}

	function applyStatistic(record, reward) {
		if (!("stat" in reward) || !("amount" in reward)) throw "INVALID_REWARD"
		local stat = reward.stat.tostring()
		local allowed = { strength = true, dexterity = true, learnPoints = true, hpMax = true, manaMax = true }
		local amount = reward.amount.tointeger()
		if (!(stat in allowed) || amount <= 0) throw "INVALID_REWARD"
		ORM.engine.execute("UPDATE `phoenix_characters` SET `" + stat + "`=`" + stat + "`+" + amount + " WHERE `id`=" + record.id)
		return { result = { stat = stat, amount = amount }, character = true, inventory = false }
	}

	function applyFlag(record, reward) {
		if (!("key" in reward) || !phoenix.quest.Schema.isKey(reward.key)) throw "INVALID_REWARD"
		local key = reward.key.tostring()
		local value = ("value" in reward && reward.value != null) ? reward.value.tostring() : "1"
		ORM.engine.execute("INSERT INTO `phoenix_character_flags` (`characterId`,`flagKey`,`flagValue`) VALUES (" + record.id + ",'" + phoenix.quest.Repository.escape(key) + "','" + phoenix.quest.Repository.escape(value) + "') ON DUPLICATE KEY UPDATE `flagValue`=VALUES(`flagValue`)")
		return { result = { key = key, value = value }, character = false, inventory = false }
	}

	function executeAtomic(record, stateId, reward, index) {
		local rewardKey = "key" in reward ? reward.key.tostring() : index.tostring()
		local effectKey = phoenix.quest.Rewards.effectKey(stateId, "complete", rewardKey)
		local escapedKey = phoenix.quest.Repository.escape(effectKey)
		try {
			ORM.engine.execute("START TRANSACTION")
			ORM.engine.execute("INSERT IGNORE INTO `phoenix_quest_reward_ledger` (`characterQuestId`,`effectKey`,`rewardType`,`status`,`attempts`) VALUES (" + stateId + ",'" + escapedKey + "','" + phoenix.quest.Repository.escape(reward.type) + "','pending',0)")
			local rows = ORM.engine.execute("SELECT `status` FROM `phoenix_quest_reward_ledger` WHERE `effectKey`='" + escapedKey + "' FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "LEDGER_NOT_FOUND"
			if (rows[0].status.tostring() == "completed") {
				ORM.engine.execute("COMMIT")
				return { success = true, character = false, inventory = false }
			}
			ORM.engine.execute("UPDATE `phoenix_quest_reward_ledger` SET `status`='processing',`attempts`=`attempts`+1 WHERE `effectKey`='" + escapedKey + "'")
			local applied = null
			if (reward.type == phoenix.quest.RewardType.Experience) applied = phoenix.quest.Rewards.applyExperience(record, reward)
			else if (reward.type == phoenix.quest.RewardType.Currency) applied = phoenix.quest.Rewards.applyItem(record, reward, effectKey, true)
			else if (reward.type == phoenix.quest.RewardType.Item) applied = phoenix.quest.Rewards.applyItem(record, reward, effectKey, false)
			else if (reward.type == phoenix.quest.RewardType.Statistic) applied = phoenix.quest.Rewards.applyStatistic(record, reward)
			else if (reward.type == phoenix.quest.RewardType.Flag) applied = phoenix.quest.Rewards.applyFlag(record, reward)
			else throw "INVALID_REWARD"
			local resultJson = phoenix.web.Json.encode(applied.result)
			ORM.engine.execute("UPDATE `phoenix_quest_reward_ledger` SET `status`='completed',`resultJson`='" + phoenix.quest.Repository.escape(resultJson) + "',`completedAt`=NOW() WHERE `effectKey`='" + escapedKey + "'")
			ORM.engine.execute("COMMIT")
			return { success = true, character = applied.character, inventory = applied.inventory }
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			return { success = false, character = false, inventory = false }
		}
	}
	function finalizeSync(stateId) {
		try {
			ORM.engine.execute("START TRANSACTION")
			local stateRows = ORM.engine.execute("SELECT `status`,`currentStageKey` FROM `phoenix_character_quests` WHERE `id`=" + stateId + " FOR UPDATE")
			if (stateRows == null || stateRows.len() == 0) throw "STATE_NOT_FOUND"
			if (stateRows[0].status.tostring() == phoenix.quest.Status.Completed) { ORM.engine.execute("COMMIT"); return true }
			if (stateRows[0].status.tostring() != phoenix.quest.Status.RewardPending) throw "INVALID_STATE"
			local pendingRows = ORM.engine.execute("SELECT COUNT(*) AS total FROM `phoenix_quest_reward_ledger` WHERE `characterQuestId`=" + stateId + " AND `status`<>'completed'")
			if (pendingRows[0].total.tointeger() > 0) throw "PENDING_EFFECTS"
			local sequenceRows = ORM.engine.execute("SELECT COALESCE(MAX(`sequenceNo`),0)+1 AS sequenceNo FROM `phoenix_character_quest_history` WHERE `characterQuestId`=" + stateId)
			local stageKey = phoenix.quest.Repository.escape(stateRows[0].currentStageKey)
			ORM.engine.execute("UPDATE `phoenix_character_quests` SET `status`='completed',`completedAt`=NOW(),`stateVersion`=`stateVersion`+1 WHERE `id`=" + stateId + " AND `status`='reward_pending'")
			ORM.engine.execute("INSERT INTO `phoenix_character_quest_history` (`characterQuestId`,`sequenceNo`,`fromStageKey`,`toStageKey`,`eventType`) VALUES (" + stateId + "," + sequenceRows[0].sequenceNo.tointeger() + ",'" + stageKey + "','" + stageKey + "','completed')")
			ORM.engine.execute("COMMIT")
			return true
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			return false
		}
	}

	function refresh(playerId, characterId, refreshCharacter, refreshInventory) {
		if (refreshCharacter) phoenix.character.Structure.reloadActive(playerId)
		if (refreshInventory) {
			phoenix.item.Structure.loadOwner(PhoenixInventoryOwner.Player, characterId, function(records) {
				phoenix.item.Structure.sendInventorySnapshot(playerId, characterId)
			})
		}
		phoenix.quest.State.reloadAndSync(characterId)
	}

	function complete(playerId, stateId) {
		local record = phoenix.character.Structure.getActive(playerId)
		if (record == null || !(record.id in phoenix.quest.State.byCharacter) || !(stateId in phoenix.quest.State.byCharacter[record.id])) return false
		local state = phoenix.quest.State.byCharacter[record.id][stateId]
		local statusRows = ORM.engine.execute("SELECT `status`,`rewardChoiceKey` FROM `phoenix_character_quests` WHERE `id`=" + stateId + " AND `characterId`=" + record.id + " LIMIT 1")
		if (statusRows == null || statusRows.len() == 0) return false
		local persistedStatus = statusRows[0].status.tostring()
		state.status = persistedStatus
		state.rewardChoiceKey = statusRows[0].rewardChoiceKey != null ? statusRows[0].rewardChoiceKey.tostring() : ""
		if (persistedStatus != phoenix.quest.Status.RewardPending && persistedStatus != phoenix.quest.Status.Completed) return false
		if (persistedStatus == phoenix.quest.Status.Completed) return true
		local rewards = phoenix.quest.Rewards.rewardsFor(state)
		if (rewards == null) return false
		local refreshCharacter = false
		local refreshInventory = false
		foreach (index, reward in rewards) {
			if (!phoenix.quest.Schema.isTable(reward) || !("type" in reward) || !(reward.type in phoenix.quest.Registry.rewards)) return false
			local outcome = phoenix.quest.Rewards.executeAtomic(record, stateId, reward, index)
			if (!outcome.success) return false
			if (outcome.character) refreshCharacter = true
			if (outcome.inventory) refreshInventory = true
		}
		if (!phoenix.quest.Rewards.finalizeSync(stateId)) return false
		phoenix.quest.Rewards.refresh(playerId, record.id, refreshCharacter, refreshInventory)
		return true
	}

	function recoverCharacter(playerId, characterId) {
		if (!(characterId in phoenix.quest.State.byCharacter)) return
		local pending = []
		foreach (stateId, state in phoenix.quest.State.byCharacter[characterId]) if (state.status == phoenix.quest.Status.RewardPending) pending.append(stateId)
		foreach (stateId in pending) phoenix.quest.Rewards.complete(playerId, stateId)
	}
}

phoenix.quest.Rewards.register(phoenix.quest.RewardType.Experience, null)
phoenix.quest.Rewards.register(phoenix.quest.RewardType.Currency, null)
phoenix.quest.Rewards.register(phoenix.quest.RewardType.Item, null)
phoenix.quest.Rewards.register(phoenix.quest.RewardType.Statistic, null)
phoenix.quest.Rewards.register(phoenix.quest.RewardType.Flag, null)

addEventHandler("phoenix.database.OnReady", function() {
	ORM.engine.execute("UPDATE `phoenix_quest_reward_ledger` SET `status`='pending' WHERE `status`='processing'")
})