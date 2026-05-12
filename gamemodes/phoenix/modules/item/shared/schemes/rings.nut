local Ring = PhoenixItemCategory.Ring
local SlotRing1 = PhoenixItemSlot.Ring1

local function ri(value, prot, visual, name, effect = null) {
	local data = {
		category   = Ring,
		slot       = SlotRing1,
		value      = value,
		protection = prot,
		visual     = visual,
		name       = name
	}
	if (effect != null) data.effect <- effect
	return data
}
local function p(b, e, po, f, m) { return { blunt = b, edge = e, point = po, fire = f, magic = m } }

phoenix.item.register("ITRI_PROT_EDGE_01"    , ri( 250, p(0, 3, 0, 0, 0), "ItRi_Prot_Edge_01.3DS",    "Pierscien pancerza"))
phoenix.item.register("ITRI_PROT_EDGE_02"    , ri( 500, p(0, 5, 0, 0, 0), "ItRi_Prot_Edge_02.3DS",    "Pierscien pancerza II"))
phoenix.item.register("ITRI_PROT_POINT_01"   , ri( 250, p(0, 0, 3, 0, 0), "ItRi_Prot_Point_01.3DS",   "Pierscien ochrony"))
phoenix.item.register("ITRI_PROT_POINT_02"   , ri( 500, p(0, 0, 5, 0, 0), "ItRi_Prot_Point_02.3DS",   "Pierscien ochrony II"))
phoenix.item.register("ITRI_PROT_FIRE_01"    , ri( 250, p(0, 0, 0, 3, 0), "ItRi_Prot_Fire_01.3DS",    "Pierscien ognia"))
phoenix.item.register("ITRI_PROT_FIRE_02"    , ri( 500, p(0, 0, 0, 5, 0), "ItRi_Prot_Fire_02.3DS",    "Pierscien ognia II"))
phoenix.item.register("ITRI_PROT_MAGE_01"    , ri( 250, p(0, 0, 0, 0, 3), "ItRi_Prot_Mage_01.3DS",    "Pierscien magii"))
phoenix.item.register("ITRI_PROT_MAGE_02"    , ri( 500, p(0, 0, 0, 0, 5), "ItRi_Prot_Mage_02.3DS",    "Pierscien magii II"))
phoenix.item.register("ITRI_PROT_TOTAL_01"   , ri( 600, p(0, 3, 3, 2, 2), "ItRi_Prot_Total_01.3DS",   "Pierscien zywiolow"))
phoenix.item.register("ITRI_PROT_TOTAL_02"   , ri(1000, p(0, 5, 5, 3, 3), "ItRi_Prot_Total_02.3DS",   "Pierscien zywiolow II"))
phoenix.item.register("ITRI_DEX_01"          , ri( 300, p(0, 0, 0, 0, 0), "ItRi_Dex_01.3DS",          "Pierscien zrecznosci",    { attribute = "dexterity", value = 3 }))
phoenix.item.register("ITRI_DEX_02"          , ri( 500, p(0, 0, 0, 0, 0), "ItRi_Dex_02.3DS",          "Pierscien zrecznosci II", { attribute = "dexterity", value = 5 }))
phoenix.item.register("ITRI_STRG_01"         , ri( 300, p(0, 0, 0, 0, 0), "ItRi_Strg_01.3DS",         "Pierscien sily",          { attribute = "strength",  value = 3 }))
phoenix.item.register("ITRI_STRG_02"         , ri( 500, p(0, 0, 0, 0, 0), "ItRi_Strg_02.3DS",         "Pierscien sily II",       { attribute = "strength",  value = 5 }))
phoenix.item.register("ITRI_MANA_01"         , ri( 500, p(0, 0, 0, 0, 0), "ItRi_Mana_01.3DS",         "Pierscien many",          { attribute = "manaMax",   value = 5 }))
phoenix.item.register("ITRI_MANA_02"         , ri(1000, p(0, 0, 0, 0, 0), "ItRi_Mana_02.3DS",         "Pierscien many II",       { attribute = "manaMax",   value = 10 }))
phoenix.item.register("ITRI_HP_01"           , ri( 200, p(0, 0, 0, 0, 0), "ItRi_Hp_01.3DS",           "Pierscien zdrowia",       { attribute = "hpMax",     value = 20 }))
phoenix.item.register("ITRI_HP_02"           , ri( 400, p(0, 0, 0, 0, 0), "ItRi_Hp_02.3DS",           "Pierscien zdrowia II",    { attribute = "hpMax",     value = 40 }))
phoenix.item.register("ITRI_HP_MANA_01"      , ri(1300, p(0, 0, 0, 0, 0), "ItRi_Hp_Mana_01.3DS",      "Pierscien zycia i many",  { hpMax = 30, manaMax = 10 }))
phoenix.item.register("ITRI_DEX_STRG_01"     , ri( 800, p(0, 0, 0, 0, 0), "ItRi_Dex_Strg_01.3DS",     "Pierscien mocy",          { strength = 4, dexterity = 4 }))
