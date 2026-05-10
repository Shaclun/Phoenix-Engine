

phoenix.item.Upgrade.BONUS <- [
	0.00,
	0.03,
	0.06,
	0.09,
	0.13,
	0.17,
	0.22,
	0.28,
	0.35,
	0.45
]

phoenix.item.Upgrade.SUCCESS_CHANCE <- [
	100,
	95,
	90,
	80,
	70,
	55,
	40,
	28,
	18
]

phoenix.item.Upgrade.GOLD_COST <- [
	100,
	250,
	600,
	1200,
	2400,
	5000,
	10000,
	20000,
	40000
]

phoenix.item.Upgrade.UPGRADABLE_CATEGORIES <- {
	[PhoenixItemCategory.Weapon1H] = true,
	[PhoenixItemCategory.Weapon2H] = true,
	[PhoenixItemCategory.Bow]      = true,
	[PhoenixItemCategory.Crossbow] = true,
	[PhoenixItemCategory.Shield]   = true,
	[PhoenixItemCategory.Armor]    = true,
	[PhoenixItemCategory.Helmet]   = true
}

phoenix.item.Upgrade.canUpgrade <- function(category) {
	if (!(category in phoenix.item.Upgrade.UPGRADABLE_CATEGORIES)) return false
	return phoenix.item.Upgrade.UPGRADABLE_CATEGORIES[category]
}

phoenix.item.Upgrade.getBonus <- function(level) {
	if (level < 0) return 0.0
	if (level >= phoenix.item.Upgrade.BONUS.len()) level = phoenix.item.Upgrade.BONUS.len() - 1
	return phoenix.item.Upgrade.BONUS[level]
}

phoenix.item.Upgrade.getSuccessChance <- function(level) {
	if (level < 0 || level >= phoenix.item.Upgrade.SUCCESS_CHANCE.len()) return 0
	return phoenix.item.Upgrade.SUCCESS_CHANCE[level]
}

phoenix.item.Upgrade.getCost <- function(level) {
	if (level < 0 || level >= phoenix.item.Upgrade.GOLD_COST.len()) return 0
	return phoenix.item.Upgrade.GOLD_COST[level]
}

phoenix.item.Upgrade.isMaxed <- function(level) {
	return level >= phoenix.item.MAX_UPGRADE
}

phoenix.item.Upgrade.combine <- function(quality, upgradeLevel, category) {
	local q = phoenix.item.Quality.getMultiplier(quality)
	if (!phoenix.item.Upgrade.canUpgrade(category)) return q
	local u = phoenix.item.Upgrade.getBonus(upgradeLevel)
	return q * (1.0 + u)
}
