phoenix.quest.Legacy <- {
	function payload(row) {
		if (row.payload == null || row.payload.tostring() == "") return {}
		local parsed = phoenix.quest.Repository.parseContent(row.payload)
		return phoenix.quest.Schema.isTable(parsed) ? parsed : null
	}

	function analyze(row) {
		local reasons = []
		local code = row.code != null ? row.code.tostring().toupper() : ""
		if (!phoenix.quest.Schema.isKey(code)) reasons.append("INVALID_CODE")
		local payload = phoenix.quest.Legacy.payload(row)
		if (payload == null) { reasons.append("INVALID_PAYLOAD_JSON"); payload = {} }
		local legacyType = row.type != null ? row.type.tostring().tolower() : "talk"
		local objectiveType = legacyType == "fetch" ? phoenix.quest.ObjectiveType.Collect : legacyType
		if (!phoenix.quest.Validator.objectiveTypeAllowed(objectiveType)) reasons.append("UNSUPPORTED_TYPE")
		local giver = row.giverInstance != null ? row.giverInstance.tostring().toupper() : ""
		if (objectiveType == phoenix.quest.ObjectiveType.Talk && !("instance" in payload) && giver != "") payload.instance <- giver
		if (objectiveType == phoenix.quest.ObjectiveType.Talk || objectiveType == phoenix.quest.ObjectiveType.Kill) {
			if (!("spawnId" in payload) && !("presetId" in payload) && !("instance" in payload) && !("tag" in payload)) reasons.append("TARGET_REFERENCE_REQUIRED")
		}
		if (objectiveType == phoenix.quest.ObjectiveType.Collect || objectiveType == phoenix.quest.ObjectiveType.Deliver) if (!("instance" in payload) || payload.instance == null || phoenix.item.find(payload.instance.tostring().toupper()) == null) reasons.append("ITEM_NOT_FOUND")
		if (objectiveType == phoenix.quest.ObjectiveType.Reach) {
			foreach (field in ["zoneKey", "x", "y", "z", "radius"]) if (!(field in payload)) reasons.append("ZONE_FIELD_" + field.toupper())
		}
		if (objectiveType == phoenix.quest.ObjectiveType.Interact && !("targetKey" in payload) && !("instance" in payload) && !("tag" in payload)) reasons.append("INTERACT_TARGET_REQUIRED")
		if (objectiveType == phoenix.quest.ObjectiveType.CustomEvent) {
			local eventName = "eventName" in payload && payload.eventName != null ? payload.eventName.tostring() : ""
			if (!(eventName in phoenix.quest.Registry.events)) reasons.append("CUSTOM_EVENT_NOT_REGISTERED")
		}
		if (phoenix.quest.Repository.rowInt(row, "conflictingDefinitionId") > 0 && phoenix.quest.Repository.rowInt(row, "mappedDefinitionId") <= 0) reasons.append("CODE_CONFLICT")
		local goal = phoenix.quest.Repository.rowInt(row, "maxProgressGoal", 1)
		if (goal < 1) goal = 1
		return { valid = reasons.len() == 0, reasons = reasons, code = code, legacyType = legacyType, objectiveType = objectiveType, config = payload, giverInstance = giver, progressGoal = goal }
	}

	function query(callback) {
		local sql = "SELECT q.*,(SELECT COUNT(*) FROM `phoenix_quest_states` s WHERE s.`questCode`=q.`code`) AS stateCount,(SELECT COALESCE(MAX(s.`progressGoal`),1) FROM `phoenix_quest_states` s WHERE s.`questCode`=q.`code`) AS maxProgressGoal,m.`definitionId` AS mappedDefinitionId,m.`draftRevisionId` AS mappedRevisionId,d.`id` AS conflictingDefinitionId FROM `phoenix_quests` q LEFT JOIN `phoenix_quest_legacy_map` m ON m.`legacyQuestId`=q.`id` LEFT JOIN `phoenix_quest_definitions` d ON d.`code`=q.`code` ORDER BY q.`id`"
		ORM.engine.executeAsync(sql, callback)
	}

	function report(callback) {
		phoenix.quest.Legacy.query(function(rows) {
			local entries = []
			if (rows != null) foreach (row in rows) {
				local analysis = phoenix.quest.Legacy.analyze(row)
				entries.append({ id = row.id.tointeger(), code = analysis.code, title = row.title != null ? row.title.tostring() : analysis.code, type = analysis.legacyType, stateCount = phoenix.quest.Repository.rowInt(row, "stateCount"), progressGoal = analysis.progressGoal, mappedDefinitionId = phoenix.quest.Repository.rowInt(row, "mappedDefinitionId"), mappedRevisionId = phoenix.quest.Repository.rowInt(row, "mappedRevisionId"), convertible = analysis.valid, reasons = analysis.reasons })
			}
			callback(entries)
		})
	}
	function content(row, analysis) {
		local title = row.title != null && row.title.tostring() != "" ? row.title.tostring() : analysis.code
		local description = row.description != null ? row.description.tostring() : ""
		local bindings = []
		if (analysis.giverInstance != "") bindings.append({ key = "legacy_giver", role = phoenix.quest.NpcRole.Giver, refType = phoenix.quest.NpcRefType.Instance, refValue = analysis.giverInstance, markerOffset = 165.0 })
		local stage = { key = "start", title = title, type = "objectives", objectiveMode = "all", objectives = [{ key = "legacy_objective", type = analysis.objectiveType, required = analysis.progressGoal, visible = true, label = title, config = analysis.config }], transitions = [], terminal = "success", markerBindings = [] }
		if (analysis.objectiveType == phoenix.quest.ObjectiveType.Talk && bindings.len() > 0) stage.markerBindings.append({ bindingKey = "legacy_giver", markerType = "continue" })
		return { metadata = { title = title, description = description }, availability = null, startStageKey = "start", npcBindings = bindings, stages = [stage], dialogGraphs = [], rewards = [], migrationPolicy = { source = "phoenix_quests", legacyQuestId = row.id.tointeger(), legacyQuestCode = analysis.code } }
	}

	function convert(playerId, payload, correlationId, callback) {
		if (!phoenix.quest.Schema.isTable(payload) || !("confirm" in payload) || payload.confirm != true) { callback(false, "CONFIRMATION_REQUIRED", null); return }
		local legacyId = "legacyId" in payload ? phoenix.quest.Schema.integer(payload.legacyId, 0, 1) : 0
		if (legacyId <= 0) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local sql = "SELECT q.*,(SELECT COALESCE(MAX(s.`progressGoal`),1) FROM `phoenix_quest_states` s WHERE s.`questCode`=q.`code`) AS maxProgressGoal,m.`definitionId` AS mappedDefinitionId,d.`id` AS conflictingDefinitionId FROM `phoenix_quests` q LEFT JOIN `phoenix_quest_legacy_map` m ON m.`legacyQuestId`=q.`id` LEFT JOIN `phoenix_quest_definitions` d ON d.`code`=q.`code` WHERE q.`id`=" + legacyId + " LIMIT 1"
		ORM.engine.executeAsync(sql, function(rows) {
			if (rows == null || rows.len() == 0) { callback(false, phoenix.quest.Error.NotFound, null); return }
			local row = rows[0]
			local mapped = phoenix.quest.Repository.rowInt(row, "mappedDefinitionId")
			if (mapped > 0) { callback(true, "", { id = mapped, alreadyConverted = true }); return }
			local analysis = phoenix.quest.Legacy.analyze(row)
			if (!analysis.valid) { callback(false, phoenix.quest.Error.ValidationFailed, { valid = false, errors = analysis.reasons }); return }
			local content = phoenix.quest.Legacy.content(row, analysis)
			phoenix.quest.Repository.saveDraft(playerId, { id = 0, code = analysis.code, lockVersion = 0, content = content }, correlationId, function(success, error, result) {
				if (!success) { callback(false, error, result); return }
				local actor = phoenix.quest.Repository.actor(playerId)
				local reportJson = phoenix.web.Json.encode(analysis)
				try {
					ORM.engine.execute("INSERT INTO `phoenix_quest_legacy_map` (`legacyQuestId`,`legacyQuestCode`,`definitionId`,`draftRevisionId`,`conversionStatus`,`reportJson`,`convertedBy`) VALUES (" + legacyId + ",'" + phoenix.quest.Repository.escape(analysis.code) + "'," + result.id + "," + result.revisionId + ",'draft_created','" + phoenix.quest.Repository.escape(reportJson) + "'," + actor.accountId + ")")
					callback(true, "", { id = result.id, revisionId = result.revisionId, lockVersion = result.lockVersion, alreadyConverted = false })
				} catch (insertError) { callback(false, phoenix.quest.Error.Internal, null) }
			})
		})
	}
}