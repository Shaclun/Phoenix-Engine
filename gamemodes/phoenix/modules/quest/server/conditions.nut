phoenix.quest.Conditions <- {
	function register(typeName, validator, evaluator) {
		if (!phoenix.quest.Schema.isKey(typeName)) return false
		phoenix.quest.Registry.conditions[typeName] <- { validate = validator, evaluate = evaluator }
		return true
	}

	function compare(actual, operator, expected) {
		if (operator == "eq" || operator == "=") return actual == expected
		if (operator == "ne" || operator == "!=") return actual != expected
		if (operator == "gt" || operator == ">") return actual > expected
		if (operator == "gte" || operator == ">=") return actual >= expected
		if (operator == "lt" || operator == "<") return actual < expected
		if (operator == "lte" || operator == "<=") return actual <= expected
		return false
	}

	function evaluate(condition, context) {
		if (condition == null) return true
		if (!phoenix.quest.Schema.isTable(condition)) return false
		local typeName = ("type" in condition && condition.type != null) ? condition.type.tostring() : ""
		if (typeName == "all" || typeName == "any") {
			local children = ("conditions" in condition && phoenix.quest.Schema.isArray(condition.conditions)) ? condition.conditions : []
			if (typeName == "all") {
				foreach (child in children) if (!phoenix.quest.Conditions.evaluate(child, context)) return false
				return true
			}
			foreach (child in children) if (phoenix.quest.Conditions.evaluate(child, context)) return true
			return false
		}
		if (typeName == "not") return !("condition" in condition) || !phoenix.quest.Conditions.evaluate(condition.condition, context)
		if (!(typeName in phoenix.quest.Registry.conditions)) return false
		try { return phoenix.quest.Registry.conditions[typeName].evaluate(condition, context) == true } catch (e) { return false }
	}

	function numericField(condition, context, field) {
		if (context.record == null || !(field in context.record)) return false
		local expected = ("value" in condition) ? condition.value.tointeger() : 0
		local operator = ("operator" in condition) ? condition.operator.tostring() : "gte"
		return phoenix.quest.Conditions.compare(context.record[field].tointeger(), operator, expected)
	}

	function flagValue(characterId, key) {
		local escaped = phoenix.quest.Repository.escape(key)
		local rows = ORM.engine.execute("SELECT `flagValue` FROM `phoenix_character_flags` WHERE `characterId`=" + characterId + " AND `flagKey`='" + escaped + "' LIMIT 1")
		if (rows == null || rows.len() == 0) return null
		return rows[0].flagValue
	}
}

foreach (field in ["level", "race", "klass", "strength", "dexterity", "magicLevel"]) {
	local captured = field
	phoenix.quest.Conditions.register(field == "klass" ? "class" : field, null, function(condition, context) {
		return phoenix.quest.Conditions.numericField(condition, context, captured)
	})
}

phoenix.quest.Conditions.register("item", null, function(condition, context) {
	if (!("instance" in condition) || condition.instance == null || context.record == null) return false
	local required = ("amount" in condition) ? condition.amount.tointeger() : 1
	local amount = phoenix.item.Structure.countInstance(PhoenixInventoryOwner.Player, context.record.id, condition.instance.tostring().toupper())
	return phoenix.quest.Conditions.compare(amount, ("operator" in condition) ? condition.operator.tostring() : "gte", required)
})

phoenix.quest.Conditions.register("flag", null, function(condition, context) {
	if (!("key" in condition) || context.record == null) return false
	local current = phoenix.quest.Conditions.flagValue(context.record.id, condition.key.tostring())
	local expected = ("value" in condition && condition.value != null) ? condition.value.tostring() : "1"
	return phoenix.quest.Conditions.compare(current, ("operator" in condition) ? condition.operator.tostring() : "eq", expected)
})

phoenix.quest.Conditions.register("quest", null, function(condition, context) {
	if (!("code" in condition) || context.record == null) return false
	local code = phoenix.quest.Repository.escape(condition.code.tostring().toupper())
	local expected = ("status" in condition) ? condition.status.tostring() : phoenix.quest.Status.Completed
	local rows = ORM.engine.execute("SELECT cq.`status` FROM `phoenix_character_quests` cq INNER JOIN `phoenix_quest_revisions` qr ON qr.`id`=cq.`revisionId` INNER JOIN `phoenix_quest_definitions` qd ON qd.`id`=qr.`definitionId` WHERE cq.`characterId`=" + context.record.id + " AND qd.`code`='" + code + "' ORDER BY cq.`id` DESC LIMIT 1")
	return rows != null && rows.len() > 0 && rows[0].status.tostring() == expected
})