phoenix.npc.Hostility <- {
	Peaceful = 0,
	Aggressive = 1,
	Trader = 2
}

phoenix.npc.Catalog <- [
	{ instance = "WOLF",                label = "Wilk",                  category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "YWOLF",               label = "Mlody wilk",            category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "WARG",                label = "Warg",                  category = "monster",  defaultHostile = 1, tier = 3 },
	{ instance = "ICEWOLF",             label = "Lodowy wilk",           category = "monster",  defaultHostile = 1, tier = 3 },

	{ instance = "KEILER",              label = "Dzik",                  category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "GIANT_RAT",           label = "Olbrzymi szczur",       category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "GIANT_BUG",           label = "Olbrzymi robal",        category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "MEATBUG",             label = "Miesny robak",          category = "monster",  defaultHostile = 0, tier = 1 },
	{ instance = "MOLERAT",             label = "Kretoszczur",           category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "SCAVENGER",           label = "Sciezor",               category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "BLOODHOUND",          label = "Krwawy ogar",           category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "BLOODFLY",            label = "Krwiopijka",            category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "YBLOODFLY",           label = "Mloda krwiopijka",      category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "MINECRAWLER",         label = "Pelzacz kopalniany",    category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "MINECRAWLER_PRIEST",  label = "Krolowa pelzaczy",      category = "boss",     defaultHostile = 1, tier = 4 },

	{ instance = "WARAN",               label = "Waran",                 category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "FIREWARAN",           label = "Ognisty waran",         category = "monster",  defaultHostile = 1, tier = 3 },
	{ instance = "LURKER",              label = "Czyhacz",               category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "SNAPPER",             label = "Zjadacz",               category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "DRAGONSNAPPER",       label = "Smokowy zjadacz",       category = "boss",     defaultHostile = 1, tier = 5 },
	{ instance = "SWAMPSHARK",          label = "Bagienny rekin",        category = "monster",  defaultHostile = 1, tier = 3 },

	{ instance = "ZOMBIE",              label = "Zombie",                category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "SWAMPZOMBIE",         label = "Bagienny zombie",       category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "SKELETON",            label = "Szkielet",              category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "LESSER_SKELETON",     label = "Maly szkielet",         category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "GOBBO_SKELETON",      label = "Szkielet goblin",       category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "SHADOWBEAST",         label = "Cienista bestia",       category = "monster",  defaultHostile = 1, tier = 4 },
	{ instance = "SHADOWBEAST_SKELETON",label = "Cienisty kosciotrup",   category = "monster",  defaultHostile = 1, tier = 4 },

	{ instance = "TROLL",               label = "Troll",                 category = "boss",     defaultHostile = 1, tier = 5 },
	{ instance = "TROLL_BLACK",         label = "Czarny troll",          category = "boss",     defaultHostile = 1, tier = 5 },
	{ instance = "ORCWARRIOR_REST",     label = "Ork (odpoczywa)",       category = "humanoid", defaultHostile = 1, tier = 3 },
	{ instance = "ORCWARRIOR_ROAM",     label = "Ork (patrol)",          category = "humanoid", defaultHostile = 1, tier = 3 },
	{ instance = "ORCBITER",            label = "Ozarek",                category = "monster",  defaultHostile = 1, tier = 2 },
	{ instance = "ORCSHAMAN_SIT",       label = "Szaman orkow",          category = "humanoid", defaultHostile = 1, tier = 4 },
	{ instance = "ORCELITE_REST",       label = "Elitarny ork",          category = "humanoid", defaultHostile = 1, tier = 4 },
	{ instance = "GOBBO_GREEN",         label = "Goblin",                category = "monster",  defaultHostile = 1, tier = 1 },
	{ instance = "GOBBO_BLACK",         label = "Czarny goblin",         category = "monster",  defaultHostile = 1, tier = 2 },

	{ instance = "DRAGON_FIRE",         label = "Smok ognia",            category = "boss",     defaultHostile = 1, tier = 5 },
	{ instance = "DRAGON_ICE",          label = "Smok lodu",             category = "boss",     defaultHostile = 1, tier = 5 },
	{ instance = "DRAGON_ROCK",         label = "Smok skalny",           category = "boss",     defaultHostile = 1, tier = 5 },
	{ instance = "DRAGON_SWAMP",        label = "Smok bagien",           category = "boss",     defaultHostile = 1, tier = 5 },
	{ instance = "DRAGON_UNDEAD",       label = "Smok nieumarlych",      category = "boss",     defaultHostile = 1, tier = 5 },

	{ instance = "PC_HERO",             label = "Bohater (template)",    category = "humanoid", defaultHostile = 0, tier = 1 },
	{ instance = "VLK_NORMAL",          label = "Wiesniak",              category = "humanoid", defaultHostile = 0, tier = 1 },
	{ instance = "BAU_NORMAL",          label = "Chlop",                 category = "humanoid", defaultHostile = 0, tier = 1 },
	{ instance = "MIL_NORMAL",          label = "Milicjant",             category = "humanoid", defaultHostile = 0, tier = 2 },
	{ instance = "PAL_NORMAL",          label = "Paladyn",               category = "humanoid", defaultHostile = 0, tier = 3 },
	{ instance = "KDF_NORMAL",          label = "Mag Ognia",             category = "humanoid", defaultHostile = 0, tier = 3 },
	{ instance = "SLD_NORMAL",          label = "Najemnik",              category = "humanoid", defaultHostile = 0, tier = 2 },
	{ instance = "ORG_NORMAL",          label = "Bandyta",               category = "humanoid", defaultHostile = 1, tier = 2 },
	{ instance = "STT_NORMAL",          label = "Strazik",               category = "humanoid", defaultHostile = 0, tier = 2 }
]

phoenix.npc.baseExperienceFor <- function (tier, category) {
	local t = tier == null ? 1 : tier.tointeger()
	if (t < 1) t = 1
	local value = 20 + t * t * 18
	if (category == "boss") value *= 3
	else if (category == "humanoid") value = (value * 13) / 10
	return value
}

foreach (e in phoenix.npc.Catalog) {
	if (!("baseExperience" in e)) e.baseExperience <- phoenix.npc.baseExperienceFor(e.tier, e.category)
}

phoenix.npc.byInstance <- {}
foreach (e in phoenix.npc.Catalog) phoenix.npc.byInstance[e.instance] <- e

phoenix.npc.findCatalog <- function (instance) {
	if (instance == null) return null
	if (instance in phoenix.npc.byInstance) return phoenix.npc.byInstance[instance]
	return null
}

phoenix.npc.isHostileByInstance <- function (instance) {
	local c = phoenix.npc.findCatalog(instance)
	return c != null && c.defaultHostile == 1
}
