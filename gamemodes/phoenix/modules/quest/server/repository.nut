phoenix.quest.Repository <- {
	ready = false,
	definitions = {},
	revisions = {},

	function escape(value) {
		if (value == null) return ""
		local source = value.tostring()
		local out = ""
		for (local i = 0; i < source.len(); i++) {
			local c = source[i]
			if (c == '\\') out += "\\\\"
			else if (c == '\'') out += "\\'"
			else if (c == 0) out += "\\0"
			else if (c == 10) out += "\\n"
			else if (c == 13) out += "\\r"
			else if (c == 26) out += "\\Z"
			else out += source.slice(i, i + 1)
		}
		return out
	}

	function rowInt(row, key, fallback = 0) {
		try { if (key in row && row[key] != null) return row[key].tointeger() } catch (e) {}
		return fallback
	}

	function rowString(row, key, fallback = "") {
		try { if (key in row && row[key] != null) return row[key].tostring() } catch (e) {}
		return fallback
	}

	function checksum(text) {
		return sha256(text)
	}

	function parseContent(value) {
		if (value == null) return null
		try { return phoenix.web.Json.parse(value.tostring()) } catch (e) { return null }
	}

	function actor(playerId) {
		local characterId = 0
		local accountId = 0
		try {
			local record = phoenix.character.Structure.getActive(playerId)
			if (record != null) {
				characterId = record.id
				accountId = record.accountId
			}
		} catch (e) {}
		return { accountId = accountId, characterId = characterId }
	}

	function definitionFromRow(row) {
		return {
			id = phoenix.quest.Repository.rowInt(row, "id"),
			code = phoenix.quest.Repository.rowString(row, "code"),
			status = phoenix.quest.Repository.rowString(row, "status", phoenix.quest.DefinitionStatus.Draft),
			currentDraftRevisionId = phoenix.quest.Repository.rowInt(row, "currentDraftRevisionId"),
			publishedRevisionId = phoenix.quest.Repository.rowInt(row, "publishedRevisionId"),
			lockVersion = phoenix.quest.Repository.rowInt(row, "lockVersion", 1)
		}
	}


	function loadPublished(callback = null) {
		local sql = "SELECT d.`id`,d.`code`,d.`status`,d.`lockVersion`,d.`publishedRevisionId`,r.`revisionNumber`,r.`contentJson`,r.`checksum` FROM `phoenix_quest_definitions` d INNER JOIN `phoenix_quest_revisions` r ON r.`id`=d.`publishedRevisionId` WHERE d.`status`='published'"
		ORM.engine.executeAsync(sql, function(rows) {
			phoenix.quest.Repository.definitions = {}
			phoenix.quest.Repository.revisions = {}
			if (rows != null) foreach (row in rows) {
				local content = phoenix.quest.Repository.parseContent(row.contentJson)
				if (content == null) continue
				local id = phoenix.quest.Repository.rowInt(row, "id")
				local revisionId = phoenix.quest.Repository.rowInt(row, "publishedRevisionId")
				local entry = phoenix.quest.Repository.definitionFromRow(row)
				entry.revisionId <- revisionId
				entry.revisionNumber <- phoenix.quest.Repository.rowInt(row, "revisionNumber")
				entry.checksum <- phoenix.quest.Repository.rowString(row, "checksum")
				entry.content <- content
				phoenix.quest.Repository.definitions[id] <- entry
				phoenix.quest.Repository.revisions[revisionId] <- entry
			}
			phoenix.quest.Repository.ready = true
			phoenix.quest.Definitions.cache = phoenix.quest.Repository.definitions
			phoenix.quest.Definitions.loaded = true
			if (callback != null) callback(phoenix.quest.Repository.definitions)
		})
	}

	function listDefinitions(callback) {
		local sql = "SELECT d.*,dr.`revisionNumber` AS draftRevisionNumber,dr.`contentJson` AS draftContent,pr.`revisionNumber` AS publishedRevisionNumber,pr.`contentJson` AS publishedContent FROM `phoenix_quest_definitions` d LEFT JOIN `phoenix_quest_revisions` dr ON dr.`id`=d.`currentDraftRevisionId` LEFT JOIN `phoenix_quest_revisions` pr ON pr.`id`=d.`publishedRevisionId` ORDER BY d.`updatedAt` DESC,d.`id` DESC"
		ORM.engine.executeAsync(sql, function(rows) {
			local out = []
			if (rows != null) foreach (row in rows) {
				local entry = phoenix.quest.Repository.definitionFromRow(row)
				entry.draftRevisionNumber <- phoenix.quest.Repository.rowInt(row, "draftRevisionNumber")
				entry.publishedRevisionNumber <- phoenix.quest.Repository.rowInt(row, "publishedRevisionNumber")
				local source = entry.currentDraftRevisionId > 0 ? phoenix.quest.Repository.rowString(row, "draftContent") : phoenix.quest.Repository.rowString(row, "publishedContent")
				local content = phoenix.quest.Repository.parseContent(source)
				entry.title <- ""
				if (content != null && "metadata" in content && content.metadata != null && "title" in content.metadata) entry.title = content.metadata.title.tostring()
				out.append(entry)
			}
			callback(out)
		})
	}

	function getDefinition(id, callback) {
		local sql = "SELECT d.*,dr.`revisionNumber` AS draftRevisionNumber,dr.`contentJson` AS draftContent,pr.`revisionNumber` AS publishedRevisionNumber,pr.`contentJson` AS publishedContent FROM `phoenix_quest_definitions` d LEFT JOIN `phoenix_quest_revisions` dr ON dr.`id`=d.`currentDraftRevisionId` LEFT JOIN `phoenix_quest_revisions` pr ON pr.`id`=d.`publishedRevisionId` WHERE d.`id`=" + id.tointeger() + " LIMIT 1"
		ORM.engine.executeAsync(sql, function(rows) {
			if (rows == null || rows.len() == 0) { callback(null); return }
			local row = rows[0]
			local entry = phoenix.quest.Repository.definitionFromRow(row)
			entry.draftRevisionNumber <- phoenix.quest.Repository.rowInt(row, "draftRevisionNumber")
			entry.publishedRevisionNumber <- phoenix.quest.Repository.rowInt(row, "publishedRevisionNumber")
			entry.draftContent <- phoenix.quest.Repository.parseContent(phoenix.quest.Repository.rowString(row, "draftContent"))
			entry.publishedContent <- phoenix.quest.Repository.parseContent(phoenix.quest.Repository.rowString(row, "publishedContent"))
			callback(entry)
		})
	}


	function auditSync(actor, operation, entityType, entityId, correlationId, beforeValue, afterValue) {
		local beforeJson = beforeValue == null ? "" : phoenix.web.Json.encode(beforeValue)
		local afterJson = afterValue == null ? "" : phoenix.web.Json.encode(afterValue)
		local sql = "INSERT INTO `phoenix_quest_audit` (`actorAccountId`,`actorCharacterId`,`operation`,`entityType`,`entityId`,`correlationId`,`beforeJson`,`afterJson`) VALUES (" + actor.accountId + "," + actor.characterId + ",'" + phoenix.quest.Repository.escape(operation) + "','" + phoenix.quest.Repository.escape(entityType) + "','" + phoenix.quest.Repository.escape(entityId) + "','" + phoenix.quest.Repository.escape(correlationId) + "'," + (beforeJson == "" ? "NULL" : "'" + phoenix.quest.Repository.escape(beforeJson) + "'") + "," + (afterJson == "" ? "NULL" : "'" + phoenix.quest.Repository.escape(afterJson) + "'") + ")"
		ORM.engine.execute(sql)
	}

	function saveDraft(playerId, payload, correlationId, callback) {
		if (!phoenix.quest.Schema.isTable(payload) || !("content" in payload) || !phoenix.quest.Schema.isTable(payload.content)) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local content = payload.content
		local validation = phoenix.quest.Validator.validate(content, false)
		local id = ("id" in payload) ? phoenix.quest.Schema.integer(payload.id, 0, 0) : 0
		local expectedVersion = ("lockVersion" in payload) ? phoenix.quest.Schema.integer(payload.lockVersion, 0, 0) : 0
		local code = ("code" in payload) ? payload.code.tostring().toupper() : ""
		if (!phoenix.quest.Schema.isKey(code) || code.len() > phoenix.quest.Schema.Limits.Code) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local contentJson = phoenix.web.Json.encode(content)
		if (contentJson.len() > phoenix.quest.Schema.Limits.Payload) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local contentEsc = phoenix.quest.Repository.escape(contentJson)
		local codeEsc = phoenix.quest.Repository.escape(code)
		local actor = phoenix.quest.Repository.actor(playerId)
		try {
			ORM.engine.execute("START TRANSACTION")
			if (id <= 0) {
				ORM.engine.execute("INSERT INTO `phoenix_quest_definitions` (`code`,`status`,`lockVersion`,`createdBy`,`updatedBy`) VALUES ('" + codeEsc + "','draft',1," + actor.accountId + "," + actor.accountId + ")")
				local idRows = ORM.engine.execute("SELECT LAST_INSERT_ID() AS id")
				id = idRows[0].id.tointeger()
				ORM.engine.execute("INSERT INTO `phoenix_quest_revisions` (`definitionId`,`revisionNumber`,`revisionStatus`,`schemaVersion`,`contentJson`,`checksum`,`createdBy`) VALUES (" + id + ",1,'draft',1,'" + contentEsc + "','" + phoenix.quest.Repository.checksum(contentJson) + "'," + actor.accountId + ")")
				local revisionRows = ORM.engine.execute("SELECT LAST_INSERT_ID() AS id")
				local revisionId = revisionRows[0].id.tointeger()
				ORM.engine.execute("UPDATE `phoenix_quest_definitions` SET `currentDraftRevisionId`=" + revisionId + " WHERE `id`=" + id)
				phoenix.quest.Repository.auditSync(actor, "questDraftCreate", "quest", id.tostring(), correlationId, null, content)
				ORM.engine.execute("COMMIT")
				callback(true, "", { id = id, lockVersion = 1, revisionId = revisionId, validation = validation })
				return
			}
			local rows = ORM.engine.execute("SELECT * FROM `phoenix_quest_definitions` WHERE `id`=" + id + " FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "NOT_FOUND"
			local existing = phoenix.quest.Repository.definitionFromRow(rows[0])
			if (existing.status == phoenix.quest.DefinitionStatus.Archived) throw "ARCHIVED"
			if (existing.lockVersion != expectedVersion) throw "STALE_VERSION"
			local beforeValue = { code = existing.code, status = existing.status, lockVersion = existing.lockVersion, content = null }

			local nextVersion = existing.lockVersion + 1
			local revisionId = existing.currentDraftRevisionId
			if (revisionId > 0) {
				local revisionRows = ORM.engine.execute("SELECT `revisionStatus`,`contentJson` FROM `phoenix_quest_revisions` WHERE `id`=" + revisionId + " FOR UPDATE")
				if (revisionRows == null || revisionRows.len() == 0 || phoenix.quest.Repository.rowString(revisionRows[0], "revisionStatus") != phoenix.quest.RevisionStatus.Draft) revisionId = 0
				else beforeValue.content = phoenix.quest.Repository.parseContent(revisionRows[0].contentJson)
			}
			if (revisionId <= 0 && existing.publishedRevisionId > 0) {
				local publishedRows = ORM.engine.execute("SELECT `contentJson` FROM `phoenix_quest_revisions` WHERE `id`=" + existing.publishedRevisionId + " LIMIT 1")
				if (publishedRows != null && publishedRows.len() > 0) beforeValue.content = phoenix.quest.Repository.parseContent(publishedRows[0].contentJson)
			}
			if (revisionId <= 0) {
				local numberRows = ORM.engine.execute("SELECT COALESCE(MAX(`revisionNumber`),0)+1 AS number FROM `phoenix_quest_revisions` WHERE `definitionId`=" + id)
				local revisionNumber = numberRows[0].number.tointeger()
				ORM.engine.execute("INSERT INTO `phoenix_quest_revisions` (`definitionId`,`revisionNumber`,`revisionStatus`,`schemaVersion`,`contentJson`,`checksum`,`createdBy`) VALUES (" + id + "," + revisionNumber + ",'draft',1,'" + contentEsc + "','" + phoenix.quest.Repository.checksum(contentJson) + "'," + actor.accountId + ")")
				local newRevisionRows = ORM.engine.execute("SELECT LAST_INSERT_ID() AS id")
				revisionId = newRevisionRows[0].id.tointeger()
			} else {
				ORM.engine.execute("UPDATE `phoenix_quest_revisions` SET `contentJson`='" + contentEsc + "',`checksum`='" + phoenix.quest.Repository.checksum(contentJson) + "' WHERE `id`=" + revisionId + " AND `revisionStatus`='draft'")
			}
			ORM.engine.execute("UPDATE `phoenix_quest_definitions` SET `code`='" + codeEsc + "',`currentDraftRevisionId`=" + revisionId + ",`lockVersion`=" + nextVersion + ",`updatedBy`=" + actor.accountId + " WHERE `id`=" + id + " AND `lockVersion`=" + expectedVersion)
			phoenix.quest.Repository.auditSync(actor, "questDraftSave", "quest", id.tostring(), correlationId, beforeValue, { code = code, status = existing.status, lockVersion = nextVersion, content = content })
			ORM.engine.execute("COMMIT")
			callback(true, "", { id = id, lockVersion = nextVersion, revisionId = revisionId, validation = validation })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			local codeValue = error.tostring()
			if (codeValue == "STALE_VERSION") { callback(false, phoenix.quest.Error.StaleVersion, null); return }
			if (codeValue == "NOT_FOUND") { callback(false, phoenix.quest.Error.NotFound, null); return }
			if (codeValue == "ARCHIVED") { callback(false, phoenix.quest.Error.Archived, null); return }
			print("(phoenix.quest) saveDraft failed id=" + id + " correlation=" + (correlationId == null ? "" : correlationId.tostring()) + ": " + codeValue + "\n")
			callback(false, phoenix.quest.Error.Internal, null)
		}
	}

	function rebuildIndexesSync(revisionId, content) {
		ORM.engine.execute("DELETE FROM `phoenix_quest_stage_index` WHERE `revisionId`=" + revisionId)
		ORM.engine.execute("DELETE FROM `phoenix_quest_npc_bindings` WHERE `revisionId`=" + revisionId)
		local stages = ("stages" in content && phoenix.quest.Schema.isArray(content.stages)) ? content.stages : []
		foreach (stage in stages) {
			local key = phoenix.quest.Repository.escape(stage.key)
			local stageType = ("type" in stage && stage.type != null) ? phoenix.quest.Repository.escape(stage.type) : "objectives"
			ORM.engine.execute("INSERT INTO `phoenix_quest_stage_index` (`revisionId`,`stageKey`,`stageType`) VALUES (" + revisionId + ",'" + key + "','" + stageType + "')")
		}
		local bindings = ("npcBindings" in content && phoenix.quest.Schema.isArray(content.npcBindings)) ? content.npcBindings : []
		foreach (binding in bindings) {
			local key = phoenix.quest.Repository.escape(binding.key)
			local role = ("role" in binding && binding.role != null) ? phoenix.quest.Repository.escape(binding.role) : "giver"
			local refType = phoenix.quest.Repository.escape(binding.refType)
			local refValue = phoenix.quest.Repository.escape(binding.refValue)
			local spawnId = ("spawnId" in binding && binding.spawnId != null) ? binding.spawnId.tointeger() : 0
			local offset = ("markerOffset" in binding && binding.markerOffset != null) ? binding.markerOffset.tofloat() : 145.0
			ORM.engine.execute("INSERT INTO `phoenix_quest_npc_bindings` (`revisionId`,`bindingKey`,`role`,`refType`,`refValue`,`spawnId`,`markerOffset`) VALUES (" + revisionId + ",'" + key + "','" + role + "','" + refType + "','" + refValue + "'," + (spawnId > 0 ? spawnId.tostring() : "NULL") + "," + offset + ")")
		}
	}


	function publish(playerId, payload, correlationId, callback) {
		if (!phoenix.quest.Schema.isTable(payload)) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local id = ("id" in payload) ? phoenix.quest.Schema.integer(payload.id, 0, 1) : 0
		local expectedVersion = ("lockVersion" in payload) ? phoenix.quest.Schema.integer(payload.lockVersion, 0, 0) : 0
		local actor = phoenix.quest.Repository.actor(playerId)
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT d.*,r.`contentJson`,r.`revisionStatus` FROM `phoenix_quest_definitions` d INNER JOIN `phoenix_quest_revisions` r ON r.`id`=d.`currentDraftRevisionId` WHERE d.`id`=" + id + " FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "NOT_FOUND"
			local definition = phoenix.quest.Repository.definitionFromRow(rows[0])
			if (definition.lockVersion != expectedVersion) throw "STALE_VERSION"
			if (definition.status == phoenix.quest.DefinitionStatus.Archived) throw "ARCHIVED"
			local content = phoenix.quest.Repository.parseContent(rows[0].contentJson)
			local validation = phoenix.quest.Validator.validate(content, true)
			if (!validation.valid) {
				ORM.engine.execute("ROLLBACK")
				callback(false, phoenix.quest.Error.ValidationFailed, validation)
				return
			}
			local revisionId = definition.currentDraftRevisionId
			phoenix.quest.Repository.rebuildIndexesSync(revisionId, content)
			ORM.engine.execute("UPDATE `phoenix_quest_revisions` SET `revisionStatus`='published',`publishedAt`=NOW() WHERE `id`=" + revisionId + " AND `revisionStatus`='draft'")
			ORM.engine.execute("UPDATE `phoenix_quest_definitions` SET `status`='published',`publishedRevisionId`=" + revisionId + ",`currentDraftRevisionId`=NULL,`lockVersion`=`lockVersion`+1,`updatedBy`=" + actor.accountId + " WHERE `id`=" + id + " AND `lockVersion`=" + expectedVersion)
			phoenix.quest.Repository.auditSync(actor, "questPublish", "quest", id.tostring(), correlationId, { status = definition.status, lockVersion = definition.lockVersion, currentDraftRevisionId = definition.currentDraftRevisionId, publishedRevisionId = definition.publishedRevisionId, content = content }, { status = phoenix.quest.DefinitionStatus.Published, lockVersion = expectedVersion + 1, publishedRevisionId = revisionId, content = content })
			ORM.engine.execute("COMMIT")
			phoenix.quest.Repository.loadPublished(function(cache) {})
			callback(true, "", { id = id, revisionId = revisionId, lockVersion = expectedVersion + 1, validation = validation })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			local codeValue = error.tostring()
			if (codeValue == "STALE_VERSION") { callback(false, phoenix.quest.Error.StaleVersion, null); return }
			if (codeValue == "NOT_FOUND") { callback(false, phoenix.quest.Error.NotFound, null); return }
			if (codeValue == "ARCHIVED") { callback(false, phoenix.quest.Error.Archived, null); return }
			print("(phoenix.quest) publish failed id=" + id + " correlation=" + (correlationId == null ? "" : correlationId.tostring()) + ": " + codeValue + "\n")
			callback(false, phoenix.quest.Error.Internal, null)
		}
	}

	function deleteDefinition(playerId, payload, correlationId, callback) {
		if (!phoenix.quest.Schema.isTable(payload)) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local id = ("id" in payload) ? phoenix.quest.Schema.integer(payload.id, 0, 1) : 0
		local expectedVersion = ("lockVersion" in payload) ? phoenix.quest.Schema.integer(payload.lockVersion, 0, 0) : 0
		local actor = phoenix.quest.Repository.actor(playerId)
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT * FROM `phoenix_quest_definitions` WHERE `id`=" + id + " FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "NOT_FOUND"
			local definition = phoenix.quest.Repository.definitionFromRow(rows[0])
			if (definition.lockVersion != expectedVersion) throw "STALE_VERSION"
			if (definition.status != phoenix.quest.DefinitionStatus.Archived) throw "NOT_ARCHIVED"
			ORM.engine.execute("SELECT `id` FROM `phoenix_quest_revisions` WHERE `definitionId`=" + id + " FOR UPDATE")
			local states = ORM.engine.execute("SELECT cq.`id` FROM `phoenix_character_quests` cq INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id + " LIMIT 1 FOR UPDATE")
			if (states != null && states.len() > 0) throw "QUEST_IN_USE"
			local legacy = ORM.engine.execute("SELECT `legacyQuestId` FROM `phoenix_quest_legacy_map` WHERE `definitionId`=" + id + " LIMIT 1 FOR UPDATE")
			if (legacy != null && legacy.len() > 0) throw "LEGACY_MAPPED"
			phoenix.quest.Repository.auditSync(actor, "questDelete", "quest", id.tostring(), correlationId, definition, null)
			ORM.engine.execute("UPDATE `phoenix_quest_definitions` SET `currentDraftRevisionId`=NULL,`publishedRevisionId`=NULL WHERE `id`=" + id + " AND `lockVersion`=" + expectedVersion)
			ORM.engine.execute("DELETE FROM `phoenix_quest_revisions` WHERE `definitionId`=" + id)
			ORM.engine.execute("DELETE FROM `phoenix_quest_definitions` WHERE `id`=" + id + " AND `lockVersion`=" + expectedVersion)
			ORM.engine.execute("COMMIT")
			phoenix.quest.Repository.loadPublished(function(cache) {})
			callback(true, "", { id = id })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			local codeValue = error.tostring()
			if (codeValue == "STALE_VERSION") { callback(false, phoenix.quest.Error.StaleVersion, null); return }
			if (codeValue == "NOT_FOUND") { callback(false, phoenix.quest.Error.NotFound, null); return }
			if (codeValue == "NOT_ARCHIVED") { callback(false, phoenix.quest.Error.NotArchived, null); return }
			if (codeValue == "QUEST_IN_USE") { callback(false, phoenix.quest.Error.QuestInUse, null); return }
			if (codeValue == "LEGACY_MAPPED") { callback(false, phoenix.quest.Error.LegacyMapped, null); return }
			print("(phoenix.quest) deleteDefinition failed id=" + id + " correlation=" + (correlationId == null ? "" : correlationId.tostring()) + ": " + codeValue + "\n")
			callback(false, phoenix.quest.Error.Internal, null)
		}
	}

	function forceDeleteDefinition(playerId, payload, correlationId, callback) {
		if (!phoenix.quest.Schema.isTable(payload)) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local id = ("id" in payload) ? phoenix.quest.Schema.integer(payload.id, 0, 1) : 0
		local expectedVersion = ("lockVersion" in payload) ? phoenix.quest.Schema.integer(payload.lockVersion, 0, 0) : 0
		local confirmedCode = ("code" in payload && payload.code != null) ? payload.code.tostring().toupper() : ""
		if (id <= 0 || confirmedCode == "") { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local actor = phoenix.quest.Repository.actor(playerId)
		local affectedCharacters = {}
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT * FROM `phoenix_quest_definitions` WHERE `id`=" + id + " FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "NOT_FOUND"
			local definition = phoenix.quest.Repository.definitionFromRow(rows[0])
			if (definition.lockVersion != expectedVersion) throw "STALE_VERSION"
			if (definition.status != phoenix.quest.DefinitionStatus.Archived) throw "NOT_ARCHIVED"
			if (definition.code.toupper() != confirmedCode) throw "INVALID_CONFIRMATION"
			local revisions = ORM.engine.execute("SELECT `id` FROM `phoenix_quest_revisions` WHERE `definitionId`=" + id + " FOR UPDATE")
			local states = ORM.engine.execute("SELECT cq.`id`,cq.`characterId`,cq.`status` FROM `phoenix_character_quests` cq INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id + " FOR UPDATE")
			local ledgers = ORM.engine.execute("SELECT qrl.`id` FROM `phoenix_quest_reward_ledger` qrl INNER JOIN `phoenix_character_quests` cq ON cq.`id`=qrl.`characterQuestId` INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id + " FOR UPDATE")
			local objectives = ORM.engine.execute("SELECT qo.`id` FROM `phoenix_character_quest_objectives` qo INNER JOIN `phoenix_character_quests` cq ON cq.`id`=qo.`characterQuestId` INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id + " FOR UPDATE")
			local history = ORM.engine.execute("SELECT qh.`id` FROM `phoenix_character_quest_history` qh INNER JOIN `phoenix_character_quests` cq ON cq.`id`=qh.`characterQuestId` INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id + " FOR UPDATE")
			local legacy = ORM.engine.execute("SELECT `legacyQuestId` FROM `phoenix_quest_legacy_map` WHERE `definitionId`=" + id + " FOR UPDATE")
			local rewardPending = 0
			if (states != null) foreach (state in states) {
				affectedCharacters[state.characterId.tointeger()] <- true
				if (state.status.tostring() == phoenix.quest.Status.RewardPending) rewardPending += 1
			}
			local impact = {
				force = true,
				revisions = revisions == null ? 0 : revisions.len(),
				states = states == null ? 0 : states.len(),
				objectives = objectives == null ? 0 : objectives.len(),
				history = history == null ? 0 : history.len(),
				ledger = ledgers == null ? 0 : ledgers.len(),
				legacy = legacy == null ? 0 : legacy.len(),
				rewardPending = rewardPending
			}
			phoenix.quest.Repository.auditSync(actor, "questForceDelete", "quest", id.tostring(), correlationId, definition, impact)
			ORM.engine.execute("DELETE qrl FROM `phoenix_quest_reward_ledger` qrl INNER JOIN `phoenix_character_quests` cq ON cq.`id`=qrl.`characterQuestId` INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id)
			ORM.engine.execute("DELETE qh FROM `phoenix_character_quest_history` qh INNER JOIN `phoenix_character_quests` cq ON cq.`id`=qh.`characterQuestId` INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id)
			ORM.engine.execute("DELETE qo FROM `phoenix_character_quest_objectives` qo INNER JOIN `phoenix_character_quests` cq ON cq.`id`=qo.`characterQuestId` INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id)
			ORM.engine.execute("DELETE cq FROM `phoenix_character_quests` cq INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` WHERE qr.`definitionId`=" + id)
			ORM.engine.execute("DELETE FROM `phoenix_quest_legacy_map` WHERE `definitionId`=" + id)
			ORM.engine.execute("DELETE qnb FROM `phoenix_quest_npc_bindings` qnb INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=qnb.`revisionId` WHERE qr.`definitionId`=" + id)
			ORM.engine.execute("DELETE qsi FROM `phoenix_quest_stage_index` qsi INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=qsi.`revisionId` WHERE qr.`definitionId`=" + id)
			ORM.engine.execute("UPDATE `phoenix_quest_definitions` SET `currentDraftRevisionId`=NULL,`publishedRevisionId`=NULL WHERE `id`=" + id + " AND `lockVersion`=" + expectedVersion)
			ORM.engine.execute("DELETE FROM `phoenix_quest_revisions` WHERE `definitionId`=" + id)
			ORM.engine.execute("DELETE FROM `phoenix_quest_definitions` WHERE `id`=" + id + " AND `status`='archived' AND `lockVersion`=" + expectedVersion)
			ORM.engine.execute("COMMIT")
			phoenix.quest.Repository.loadPublished(function(cache) {})
			foreach (characterId, value in affectedCharacters) phoenix.quest.State.reloadAndSync(characterId)
			callback(true, "", { id = id, impact = impact })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			local codeValue = error.tostring()
			if (codeValue == "STALE_VERSION") { callback(false, phoenix.quest.Error.StaleVersion, null); return }
			if (codeValue == "NOT_FOUND") { callback(false, phoenix.quest.Error.NotFound, null); return }
			if (codeValue == "NOT_ARCHIVED") { callback(false, phoenix.quest.Error.NotArchived, null); return }
			if (codeValue == "INVALID_CONFIRMATION") { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
			print("(phoenix.quest) forceDeleteDefinition failed id=" + id + " correlation=" + (correlationId == null ? "" : correlationId.tostring()) + ": " + codeValue + "\n")
			callback(false, phoenix.quest.Error.Internal, null)
		}
	}

	function archive(playerId, payload, correlationId, callback) {
		if (!phoenix.quest.Schema.isTable(payload)) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local id = ("id" in payload) ? phoenix.quest.Schema.integer(payload.id, 0, 1) : 0
		local expectedVersion = ("lockVersion" in payload) ? phoenix.quest.Schema.integer(payload.lockVersion, 0, 0) : 0
		local actor = phoenix.quest.Repository.actor(playerId)
		try {
			ORM.engine.execute("START TRANSACTION")
			local rows = ORM.engine.execute("SELECT * FROM `phoenix_quest_definitions` WHERE `id`=" + id + " FOR UPDATE")
			if (rows == null || rows.len() == 0) throw "NOT_FOUND"
			local definition = phoenix.quest.Repository.definitionFromRow(rows[0])
			if (definition.lockVersion != expectedVersion) throw "STALE_VERSION"
			if (definition.status == phoenix.quest.DefinitionStatus.Archived) throw "ARCHIVED"
			ORM.engine.execute("UPDATE `phoenix_quest_definitions` SET `status`='archived',`lockVersion`=`lockVersion`+1,`updatedBy`=" + actor.accountId + " WHERE `id`=" + id + " AND `lockVersion`=" + expectedVersion)
			phoenix.quest.Repository.auditSync(actor, "questArchive", "quest", id.tostring(), correlationId, definition, { id = definition.id, code = definition.code, status = phoenix.quest.DefinitionStatus.Archived, currentDraftRevisionId = definition.currentDraftRevisionId, publishedRevisionId = definition.publishedRevisionId, lockVersion = expectedVersion + 1 })
			ORM.engine.execute("COMMIT")
			phoenix.quest.Repository.loadPublished(function(cache) {})
			callback(true, "", { id = id, lockVersion = expectedVersion + 1 })
		} catch (error) {
			try { ORM.engine.execute("ROLLBACK") } catch (rollbackError) {}
			local codeValue = error.tostring()
			if (codeValue == "STALE_VERSION") { callback(false, phoenix.quest.Error.StaleVersion, null); return }
			if (codeValue == "NOT_FOUND") { callback(false, phoenix.quest.Error.NotFound, null); return }
			if (codeValue == "ARCHIVED") { callback(false, phoenix.quest.Error.Archived, null); return }
			print("(phoenix.quest) archive failed id=" + id + " correlation=" + (correlationId == null ? "" : correlationId.tostring()) + ": " + codeValue + "\n")
			callback(false, phoenix.quest.Error.Internal, null)
		}
	}
}