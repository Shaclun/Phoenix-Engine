phoenix.herb.Catalog <- {
	ITPL_WEED = { pl = "Chwast", en = "Weed", de = "Unkraut", ru = "Sornyak", rarity = 1, gatherMs = 6000, cooldownSec = 1800, successChance = 95 },
	ITPL_BEET = { pl = "Burak", en = "Beet", de = "Rube", ru = "Sveklak", rarity = 1, gatherMs = 6000, cooldownSec = 1800, successChance = 95 },
	ITPL_SWAMPHERB = { pl = "Bagienne ziele", en = "Swampweed", de = "Sumpfkraut", ru = "Bolotnik", rarity = 2, gatherMs = 9000, cooldownSec = 3600, successChance = 88 },
	ITPL_MANA_HERB_01 = { pl = "Ognisty korzen", en = "Fire root", de = "Feuerwurzel", ru = "Ognenny koren", rarity = 2, gatherMs = 9000, cooldownSec = 3600, successChance = 88 },
	ITPL_MANA_HERB_02 = { pl = "Szczaw krolewski", en = "King's sorrel", de = "Kronstockel", ru = "Tsarskiy shchavel", rarity = 4, gatherMs = 14000, cooldownSec = 10800, successChance = 65 },
	ITPL_MANA_HERB_03 = { pl = "Korzen many", en = "Mana root", de = "Mana-Wurzel", ru = "Koren many", rarity = 4, gatherMs = 15000, cooldownSec = 14400, successChance = 60 },
	ITPL_HEALTH_HERB_01 = { pl = "Roslina lecznicza", en = "Healing plant", de = "Heilpflanze", ru = "Lechebnoe rastenie", rarity = 1, gatherMs = 7000, cooldownSec = 3600, successChance = 92 },
	ITPL_HEALTH_HERB_02 = { pl = "Ziele lecznicze", en = "Healing herb", de = "Heilkraut", ru = "Lechebnaya trava", rarity = 2, gatherMs = 9000, cooldownSec = 5400, successChance = 85 },
	ITPL_HEALTH_HERB_03 = { pl = "Korzen leczniczy", en = "Healing root", de = "Heilwurzel", ru = "Lechebny koren", rarity = 3, gatherMs = 11000, cooldownSec = 7200, successChance = 76 },
	ITPL_DEX_HERB_01 = { pl = "Jagody goblina", en = "Goblin berries", de = "Goblinbeeren", ru = "Goblinskie yagody", rarity = 5, gatherMs = 18000, cooldownSec = 21600, successChance = 45 },
	ITPL_STRENGTH_HERB_01 = { pl = "Smoczy korzen", en = "Dragon root", de = "Drachenwurzel", ru = "Drakoniy koren", rarity = 5, gatherMs = 18000, cooldownSec = 21600, successChance = 45 },
	ITPL_SPEED_HERB_01 = { pl = "Rdest polny", en = "Field knotweed", de = "Feldknoterich", ru = "Polevoy sporysh", rarity = 3, gatherMs = 12000, cooldownSec = 7200, successChance = 72 },
	ITPL_MUSHROOM_01 = { pl = "Grzyb", en = "Mushroom", de = "Pilz", ru = "Grib", rarity = 1, gatherMs = 6000, cooldownSec = 1800, successChance = 95 },
	ITPL_MUSHROOM_02 = { pl = "Ciemny grzyb", en = "Dark mushroom", de = "Dunkelpilz", ru = "Temny grib", rarity = 2, gatherMs = 8000, cooldownSec = 3600, successChance = 88 },
	ITPL_BLUEPLANT = { pl = "Niebieski bez", en = "Blue elder", de = "Blauer Holunder", ru = "Sinyaya buzina", rarity = 2, gatherMs = 9000, cooldownSec = 3600, successChance = 86 },
	ITPL_FORESTBERRY = { pl = "Jagody lesne", en = "Forest berries", de = "Waldbeeren", ru = "Lesnye yagody", rarity = 1, gatherMs = 6000, cooldownSec = 1800, successChance = 95 },
	ITPL_PLANEBERRY = { pl = "Jagody polne", en = "Field berries", de = "Feldbeeren", ru = "Polevye yagody", rarity = 1, gatherMs = 6000, cooldownSec = 1800, successChance = 95 },
	ITPL_TEMP_HERB = { pl = "Ziele specjalne", en = "Special herb", de = "Spezialkraut", ru = "Osobaya trava", rarity = 4, gatherMs = 15000, cooldownSec = 14400, successChance = 58 },
	ITPL_PERM_HERB = { pl = "Krolewski szczaw", en = "King's sorrel", de = "Kronstockel", ru = "Tsarskiy shchavel", rarity = 5, gatherMs = 20000, cooldownSec = 28800, successChance = 40 },
	ITPL_SAGITTA_HERB_MIS = { pl = "Ziele Sagitty", en = "Sagitta's herb", de = "Sagittas Kraut", ru = "Trava Sagitty", rarity = 5, gatherMs = 20000, cooldownSec = 28800, successChance = 40 }
}

phoenix.herb.catalogOf <- function(instance) {
	local key = instance == null ? "" : instance.tostring().toupper()
	if (key in phoenix.herb.Catalog) return phoenix.herb.Catalog[key]
	return null
}

phoenix.herb.labelOf <- function(instance, lang = "pl") {
	local row = phoenix.herb.catalogOf(instance)
	if (row == null) return instance
	if (lang in row && row[lang] != "") return row[lang]
	return row.pl
}