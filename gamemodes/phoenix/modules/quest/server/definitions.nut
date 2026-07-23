phoenix.quest.Definitions <- {
	cache = {},
	loaded = false,

	function list(callback) {
		phoenix.quest.Repository.listDefinitions(callback)
	}

	function get(id, callback) {
		phoenix.quest.Repository.getDefinition(id, callback)
	}

	function save(playerId, payload, correlationId, callback) {
		phoenix.quest.Repository.saveDraft(playerId, payload, correlationId, callback)
	}

	function publish(playerId, payload, correlationId, callback) {
		phoenix.quest.Repository.publish(playerId, payload, correlationId, callback)
	}

	function archive(playerId, payload, correlationId, callback) {
		phoenix.quest.Repository.archive(playerId, payload, correlationId, callback)
	}

	function deleteDefinition(playerId, payload, correlationId, callback) {
		phoenix.quest.Repository.deleteDefinition(playerId, payload, correlationId, callback)
	}

	function cloneDraft(playerId, payload, correlationId, callback) {
		if (!phoenix.quest.Schema.isTable(payload)) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		local sourceId = "sourceId" in payload ? phoenix.quest.Schema.integer(payload.sourceId, 0, 1) : 0
		local code = "code" in payload && payload.code != null ? payload.code.tostring().toupper() : ""
		if (sourceId <= 0 || !phoenix.quest.Schema.isKey(code) || code.len() > phoenix.quest.Schema.Limits.Code) { callback(false, phoenix.quest.Error.InvalidRequest, null); return }
		phoenix.quest.Repository.getDefinition(sourceId, function(entry) {
			if (entry == null) { callback(false, phoenix.quest.Error.NotFound, null); return }
			local source = entry.draftContent != null ? entry.draftContent : entry.publishedContent
			if (source == null) { callback(false, phoenix.quest.Error.NotFound, null); return }
			local content = phoenix.quest.Repository.parseContent(phoenix.web.Json.encode(source))
			if ("metadata" in content && phoenix.quest.Schema.isTable(content.metadata) && "title" in content.metadata) content.metadata.title = content.metadata.title.tostring() + " (kopia)"
			phoenix.quest.Repository.saveDraft(playerId, { id = 0, code = code, lockVersion = 0, content = content }, correlationId, callback)
		})
	}

	function validate(payload, publishing = false) {
		if (!phoenix.quest.Schema.isTable(payload) || !("content" in payload)) return { valid = false, errors = [{ path = "content", entityKey = "", code = "CONTENT_REQUIRED", message = "Brak definicji", severity = "error" }], warnings = [] }
		return phoenix.quest.Validator.validate(payload.content, publishing)
	}

	function catalog() {
		if (!phoenix.npc.Spawn.loaded) return null
		local npcs = phoenix.npc.Spawn.listStored()
		local presets = []
		try {
			foreach (id, preset in phoenix.npc.Preset.cache) presets.append({ id = id, code = preset.code, label = preset.label, instance = preset.instance, kind = preset.kind })
		} catch (e) {}
		local objectiveTypes = []
		foreach (key, value in phoenix.quest.ObjectiveType) objectiveTypes.append(value)
		local rewardTypes = []
		foreach (key, value in phoenix.quest.RewardType) rewardTypes.append(value)
		local refTypes = []
		foreach (key, value in phoenix.quest.NpcRefType) refTypes.append(value)
		local npcRoles = []
		foreach (key, value in phoenix.quest.NpcRole) npcRoles.append(value)
		local conditionTypes = ["all", "any", "not"]
		foreach (key, value in phoenix.quest.Registry.conditions) conditionTypes.append(key)
		local eventTypes = []
		foreach (key, value in phoenix.quest.Registry.events) eventTypes.append(key)
		return { npcs = npcs, presets = presets, objectiveTypes = objectiveTypes, rewardTypes = rewardTypes, npcRefTypes = refTypes, npcRoles = npcRoles, conditionTypes = conditionTypes, conditionOperators = ["eq", "ne", "gt", "gte", "lt", "lte"], eventTypes = eventTypes }
	}
}

addEventHandler("phoenix.database.OnReady", function() {
	phoenix.quest.Repository.loadPublished(function(cache) {})
})


phoenix.quest.Admin <- {
	permissions = {
		questList = "quest.read",
		questGet = "quest.read",
		questCatalog = "quest.read",
		questSave = "quest.edit",
		questValidate = "quest.edit",
		questPublish = "quest.publish",
		questArchive = "quest.archive",
		questDelete = "quest.delete",
		questClone = "quest.edit",
		questLegacyReport = "quest.migrate",
		questLegacyConvert = "quest.migrate"
	},
	lastRequestAt = {},

	function authorized(playerId, action) {
		if (!(action in phoenix.quest.Admin.permissions)) return false
		local account = phoenix.account.Structure.get(playerId)
		if (account == null || account.record == null) return false
		try {
			local rows = ORM.engine.execute("SELECT `granted` FROM `phoenix_account_permissions` WHERE `accountId`=" + account.record.id + " AND `permissionKey`='" + phoenix.quest.Repository.escape(phoenix.quest.Admin.permissions[action]) + "' LIMIT 1")
			if (rows != null && rows.len() > 0) return rows[0].granted.tointeger() == 1
		} catch (error) {}
		return phoenix.account.Auth.isAdmin(playerId)
	}

	function guard(playerId, action, payload) {
		if (!phoenix.quest.Admin.authorized(playerId, action)) { phoenix.admin.Server.reply(playerId, action, false, "denied", null); return false }
		try {
			if (payload != null && phoenix.web.Json.encode(payload).len() > phoenix.quest.Schema.Limits.Payload) { phoenix.admin.Server.reply(playerId, action, false, "badPayload", null); return false }
		} catch (error) { phoenix.admin.Server.reply(playerId, action, false, "badPayload", null); return false }
		local now = getTickCount()
		local key = playerId + ":" + action
		local interval = action == "questList" || action == "questGet" || action == "questCatalog" ? 100 : 500
		if (key in phoenix.quest.Admin.lastRequestAt && now - phoenix.quest.Admin.lastRequestAt[key] < interval) { phoenix.admin.Server.reply(playerId, action, false, "rateLimited", null); return false }
		phoenix.quest.Admin.lastRequestAt[key] <- now
		return true
	}

	function correlation(payload) {
		if (payload != null && typeof payload == "table" && "requestId" in payload && payload.requestId != null) return phoenix.quest.Schema.string(payload.requestId, phoenix.quest.Schema.Limits.RequestId)
		return getTickCount().tostring()
	}

	function list(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questList", payload)) return
		local offset = phoenix.quest.Schema.isTable(payload) && "offset" in payload ? phoenix.quest.Schema.integer(payload.offset, 0, 0) : 0
		local limit = phoenix.quest.Schema.isTable(payload) && "limit" in payload ? phoenix.quest.Schema.integer(payload.limit, 50, 1, 100) : 50
		local filter = phoenix.quest.Schema.isTable(payload) && "filter" in payload && payload.filter != null ? phoenix.quest.Schema.string(payload.filter, 64).tolower() : ""
		local status = phoenix.quest.Schema.isTable(payload) && "status" in payload && payload.status != null ? phoenix.quest.Schema.string(payload.status, 16).tolower() : ""
		phoenix.quest.Definitions.list(function(entries) {
			local filtered = []
			foreach (entry in entries) {
				if (status != "" && entry.status.tolower() != status) continue
				if (filter != "" && entry.code.tolower().find(filter) == null && entry.title.tolower().find(filter) == null) continue
				filtered.append(entry)
			}
			local page = []
			for (local index = offset; index < filtered.len() && index < offset + limit; index += 1) page.append(filtered[index])
			phoenix.admin.Server.reply(playerId, "questList", true, "", { entries = page, total = filtered.len(), offset = offset, limit = limit })
		})
	}

	function get(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questGet", payload)) return
		local id = payload != null && typeof payload == "table" && "id" in payload ? phoenix.quest.Schema.integer(payload.id, 0, 1) : 0
		if (id <= 0) { phoenix.admin.Server.reply(playerId, "questGet", false, "badPayload", null); return }
		phoenix.quest.Definitions.get(id, function(entry) {
			if (entry == null) phoenix.admin.Server.reply(playerId, "questGet", false, "notFound", null)
			else phoenix.admin.Server.reply(playerId, "questGet", true, "", entry)
		})
	}

	function save(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questSave", payload)) return
		phoenix.quest.Definitions.save(playerId, payload, phoenix.quest.Admin.correlation(payload), function(success, error, result) {
			phoenix.admin.Server.reply(playerId, "questSave", success, error, result)
		})
	}

	function cloneQuest(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questClone", payload)) return
		phoenix.quest.Definitions.cloneDraft(playerId, payload, phoenix.quest.Admin.correlation(payload), function(success, error, result) {
			phoenix.admin.Server.reply(playerId, "questClone", success, error, result)
		})
	}

	function validate(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questValidate", payload)) return
		local publishing = payload != null && typeof payload == "table" && "publishing" in payload && payload.publishing == true
		local result = phoenix.quest.Definitions.validate(payload, publishing)
		phoenix.admin.Server.reply(playerId, "questValidate", result.valid, result.valid ? "" : phoenix.quest.Error.ValidationFailed, result)
	}

	function publish(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questPublish", payload)) return
		phoenix.quest.Definitions.publish(playerId, payload, phoenix.quest.Admin.correlation(payload), function(success, error, result) {
			phoenix.admin.Server.reply(playerId, "questPublish", success, error, result)
		})
	}

	function archive(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questArchive", payload)) return
		if (!phoenix.quest.Schema.isTable(payload) || !("confirm" in payload) || payload.confirm != true) { phoenix.admin.Server.reply(playerId, "questArchive", false, "confirmationRequired", null); return }
		phoenix.quest.Definitions.archive(playerId, payload, phoenix.quest.Admin.correlation(payload), function(success, error, result) {
			phoenix.admin.Server.reply(playerId, "questArchive", success, error, result)
		})
	}

	function deleteDefinition(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questDelete", payload)) return
		if (!phoenix.quest.Schema.isTable(payload) || !("confirm" in payload) || payload.confirm != true) { phoenix.admin.Server.reply(playerId, "questDelete", false, "confirmationRequired", null); return }
		phoenix.quest.Definitions.deleteDefinition(playerId, payload, phoenix.quest.Admin.correlation(payload), function(success, error, result) {
			phoenix.admin.Server.reply(playerId, "questDelete", success, error, result)
		})
	}

	function legacyReport(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questLegacyReport", payload)) return
		phoenix.quest.Legacy.report(function(entries) { phoenix.admin.Server.reply(playerId, "questLegacyReport", true, "", { entries = entries }) })
	}

	function legacyConvert(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questLegacyConvert", payload)) return
		phoenix.quest.Legacy.convert(playerId, payload, phoenix.quest.Admin.correlation(payload), function(success, error, result) { phoenix.admin.Server.reply(playerId, "questLegacyConvert", success, error, result) })
	}

	function catalog(playerId, payload) {
		if (!phoenix.quest.Admin.guard(playerId, "questCatalog", payload)) return
		local result = phoenix.quest.Definitions.catalog()
		if (result == null) { phoenix.admin.Server.reply(playerId, "questCatalog", false, "npcCatalogNotReady", { retryAfter = 1000 }); return }
		phoenix.admin.Server.reply(playerId, "questCatalog", true, "", result)
	}
}