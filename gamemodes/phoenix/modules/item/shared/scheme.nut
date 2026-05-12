

class phoenix.item.Scheme {
	instance     = ""
	category     = 0
	name         = ""
	description  = ""
	labels       = null
	descriptions = null

	value        = 0

	visual       = null

	weight       = 0.0

	stackMax     = 1

	damage       = 0
	damageType   = 0

	protection   = null

	requirement  = null

	flags        = 0

	onUse        = null
	effect       = null

	slot         = 0

	constructor(instanceId, data = null) {
		instance    = instanceId
		category    = PhoenixItemCategory.Misc
		name        = instanceId
		description = ""
		labels      = { pl = "", en = "", de = "", ru = "" }
		descriptions = { pl = "", en = "", de = "", ru = "" }
		value       = 0
		visual      = null
		weight      = 0.0
		stackMax    = 1
		damage      = 0
		damageType  = PhoenixDamageType.Edge
		protection  = { edge = 0, blunt = 0, point = 0, fire = 0, magic = 0 }
		requirement = []
		flags       = 0
		onUse       = null
		effect      = null
		slot        = PhoenixItemSlot.None

		if (data != null) merge(data)

		if (labels == null) labels = { pl = "", en = "", de = "", ru = "" }
		if (descriptions == null) descriptions = { pl = "", en = "", de = "", ru = "" }
		if (labels.pl == "" && name != instanceId) labels.pl = name
		if (descriptions.pl == "" && description != "") descriptions.pl = description
	}

	function merge(data) {
		foreach (k, v in data) {
			if (k in this) this[k] = v
		}
	}

	function labelFor(lang) {
		if (lang != null && labels != null) {
			try {
				if (lang == "en" && labels.en != "") return labels.en
				if (lang == "de" && labels.de != "") return labels.de
				if (lang == "ru" && labels.ru != "") return labels.ru
				if (labels.pl != "") return labels.pl
			} catch (e) {}
		}
		if (name != null && name != "") return name
		return instance
	}

	function descriptionFor(lang) {
		if (lang != null && descriptions != null) {
			try {
				if (lang == "en" && descriptions.en != "") return descriptions.en
				if (lang == "de" && descriptions.de != "") return descriptions.de
				if (lang == "ru" && descriptions.ru != "") return descriptions.ru
				if (descriptions.pl != "") return descriptions.pl
			} catch (e) {}
		}
		return description != null ? description : ""
	}

	function isStackable() {
		if (stackMax > 1) return true
		return (flags & PhoenixItemFlag.Stackable) != 0
	}

	function isEquippable() {
		return slot != PhoenixItemSlot.None
	}
}

phoenix.item.Schemes.byInstance <- {}

phoenix.item.visuals <- {}

phoenix.item.lookupVisual <- function(instanceId) {
	if (instanceId == null) return null
	local up = instanceId.toupper()
	if (up in phoenix.item.visuals) return phoenix.item.visuals[up]
	return null
}

phoenix.item.register <- function(instanceId, data) {
	if (instanceId == null || instanceId == "") {
		return null
	}
	local s = phoenix.item.Scheme(instanceId, data)
	phoenix.item.Schemes.byInstance[instanceId] <- s
	return s
}

phoenix.item.find <- function(instanceId) {
	if (instanceId in phoenix.item.Schemes.byInstance)
		return phoenix.item.Schemes.byInstance[instanceId]
	local up = instanceId != null ? instanceId.toupper() : ""
	if (up in phoenix.item.Schemes.byInstance)
		return phoenix.item.Schemes.byInstance[up]
	return null
}

phoenix.item.has <- function(instanceId) {
	return instanceId in phoenix.item.Schemes.byInstance
}

phoenix.item.count <- function() {
	local n = 0
	foreach (_k, _v in phoenix.item.Schemes.byInstance) n += 1
	return n
}

phoenix.item.computeStats <- function(scheme, quality, upgradeLevel) {
	local mult = phoenix.item.Upgrade.combine(quality, upgradeLevel, scheme.category)
	local valueMult = phoenix.item.Quality.getMultiplier(quality)

	local prot = { edge = 0, blunt = 0, point = 0, fire = 0, magic = 0 }
	if (scheme.protection != null) {
		foreach (k, v in scheme.protection) {
			if (k in prot) prot[k] = (v * mult).tointeger()
		}
	}

	return {
		damage     = (scheme.damage * mult).tointeger(),
		protection = prot,
		value      = (scheme.value * valueMult).tointeger(),
		multiplier = mult
	}
}
