local Amulet = PhoenixItemCategory.Amulet
local SlotAmulet = PhoenixItemSlot.Amulet

local function am(value, prot, visual, name, effect = null) {
	local data = {
		category   = Amulet,
		slot       = SlotAmulet,
		value      = value,
		protection = prot,
		visual     = visual,
		name       = name
	}
	if (effect != null) data.effect <- effect
	return data
}
local function p(b, e, po, f, m) { return { blunt = b, edge = e, point = po, fire = f, magic = m } }

phoenix.item.register("ITAM_PROT_EDGE_01"          , am( 800, p( 0, 10,  0,  0,  0), "ItAm_Prot_Edge_01.3DS",    "Amulet pancerza"))
phoenix.item.register("ITAM_PROT_POINT_01"         , am( 500, p( 0,  0, 10,  0,  0), "ItAm_Prot_Point_01.3DS",   "Amulet debowej skory"))
phoenix.item.register("ITAM_PROT_FIRE_01"          , am( 600, p( 0,  0,  0, 10,  0), "ItAm_Prot_Fire_01.3DS",    "Amulet ognia"))
phoenix.item.register("ITAM_PROT_MAGE_01"          , am( 700, p( 0,  0,  0,  0, 10), "ItAm_Prot_Mage_01.3DS",    "Amulet duchowej sily"))
phoenix.item.register("ITAM_PROT_TOTAL_01"         , am(1000, p( 0,  8,  8,  8,  8), "ItAm_Prot_Total_01.3DS",   "Amulet zywiolow"))
phoenix.item.register("ITAM_DEX_01"                , am(1000, p( 0,  0,  0,  0,  0), "ItAm_Dex_01.3DS",          "Amulet zrecznosci",     { attribute = "dexterity", value = 10 }))
phoenix.item.register("ITAM_STRG_01"               , am(1000, p( 0,  0,  0,  0,  0), "ItAm_Strg_01.3DS",         "Amulet sily",           { attribute = "strength",  value = 10 }))
phoenix.item.register("ITAM_MANA_01"               , am(1000, p( 0,  0,  0,  0,  0), "ItAm_Mana_01.3DS",         "Amulet koncentracji",   { attribute = "manaMax",   value = 10 }))
phoenix.item.register("ITAM_HP_01"                 , am( 400, p( 0,  0,  0,  0,  0), "ItAm_Hp_01.3DS",           "Amulet zdrowia",        { attribute = "hpMax",     value = 40 }))
phoenix.item.register("ITAM_HP_MANA_01"            , am(1300, p( 0,  0,  0,  0,  0), "ItAm_Hp_Mana_01.3DS",      "Amulet zycia i many",   { hpMax = 30, manaMax = 10 }))
phoenix.item.register("ITAM_DEX_STRG_01"           , am(1600, p( 0,  0,  0,  0,  0), "ItAm_Dex_Strg_01.3DS",     "Amulet mocy",           { strength = 8, dexterity = 8 }))
phoenix.item.register("ITAM_ADDON_RAVENSGEBETBUCH" , am(3000, p( 0,  0,  0,  0, 15), "ItAm_Addon_Raven.3DS",     "Modlitewnik Kruka"))
