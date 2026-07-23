phoenix.quest.Schema.Limits <- {
	Code = 64,
	Key = 64,
	Title = 160,
	Description = 8000,
	RequestId = 64,
	Payload = 262144,
	Stages = 128,
	ObjectivesPerStage = 32,
	DialogNodes = 256,
	ConditionDepth = 8,
	ConditionChildren = 32,
	Conditions = 256
}

phoenix.quest.Schema.string <- function(value, maxLength, fallback = "") {
	if (value == null) return fallback
	local out = ""
	try { out = value.tostring() } catch (e) { return fallback }
	if (out.len() > maxLength) return out.slice(0, maxLength)
	return out
}

phoenix.quest.Schema.integer <- function(value, fallback = 0, minimum = null, maximum = null) {
	local out = fallback
	try { out = value.tointeger() } catch (e) { return fallback }
	if (minimum != null && out < minimum) out = minimum
	if (maximum != null && out > maximum) out = maximum
	return out
}

phoenix.quest.Schema.isKey <- function(value) {
	if (value == null) return false
	local text = ""
	try { text = value.tostring() } catch (e) { return false }
	if (text.len() < 1 || text.len() > phoenix.quest.Schema.Limits.Key) return false
	local allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
	for (local i = 0; i < text.len(); i += 1) {
		if (allowed.find(text.slice(i, i + 1)) == null) return false
	}
	return true
}

phoenix.quest.Schema.isArray <- function(value) {
	return value != null && typeof value == "array"
}

phoenix.quest.Schema.isTable <- function(value) {
	return value != null && typeof value == "table"
}