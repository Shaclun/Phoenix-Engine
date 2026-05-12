local Potion = PhoenixItemCategory.Potion
local Stackable = PhoenixItemFlag.Stackable

local function pot(value, visual, name, onUseKind, effectData) {
	local data = {
		category = Potion,
		value    = value,
		stackMax = 99,
		flags    = Stackable,
		visual   = visual,
		name     = name
	}
	if (onUseKind != null) {
		data.onUse <- onUseKind
		data.effect <- effectData
	}
	return data
}

phoenix.item.register("ITPO_HEALTH_01"      , pot(  25, "ItPo_Health_01.3DS",      "Esencja lecznicza",   "heal",  { hp = 50 }))
phoenix.item.register("ITPO_HEALTH_02"      , pot(  35, "ItPo_Health_02.3DS",      "Ekstrakt leczniczy",  "heal",  { hp = 70 }))
phoenix.item.register("ITPO_HEALTH_03"      , pot(  50, "ItPo_Health_03.3DS",      "Eliksir leczniczy",   "heal",  { hp = 100 }))
phoenix.item.register("ITPO_HEALTH_ADDON_04", pot( 150, "ItPo_Health_Addon_04.3DS","Eliksir zycia",       "heal",  { hp = 9999 }))
phoenix.item.register("ITPO_MANA_01"        , pot(  25, "ItPo_Mana_01.3DS",        "Esencja many",        "mana",  { mana = 50 }))
phoenix.item.register("ITPO_MANA_02"        , pot(  40, "ItPo_Mana_02.3DS",        "Ekstrakt many",       "mana",  { mana = 75 }))
phoenix.item.register("ITPO_MANA_03"        , pot(  60, "ItPo_Mana_03.3DS",        "Eliksir many",        "mana",  { mana = 100 }))
phoenix.item.register("ITPO_MANA_ADDON_04"  , pot( 200, "ItPo_Mana_Addon_04.3DS",  "Eliksir esencji",     "mana",  { mana = 9999 }))
phoenix.item.register("ITPO_PERM_HEALTH"    , pot(1500, "ItPo_Perm_Health.3DS",    "Esencja zycia",       "permHp", { hp = 20 }))
phoenix.item.register("ITPO_PERM_MANA"      , pot(1500, "ItPo_Perm_Mana.3DS",      "Esencja many+",       "permMana", { mana = 5 }))
phoenix.item.register("ITPO_PERM_LITTLEMANA", pot( 750, "ItPo_Perm_Mana.3DS",      "Mala esencja many",   "permMana", { mana = 3 }))
phoenix.item.register("ITPO_PERM_STR"       , pot( 800, "ItPo_Perm_Str.3DS",       "Esencja sily",        "permStr", { value = 3 }))
phoenix.item.register("ITPO_PERM_DEX"       , pot( 800, "ItPo_Perm_Dex.3DS",       "Esencja zrecznosci",  "permDex", { value = 3 }))
phoenix.item.register("ITPO_SPEED"          , pot( 200, "ItPo_Speed.3DS",          "Mikstura szybkosci",  "speed", { durationMs = 300000 }))
phoenix.item.register("ITPO_MEGADRINK"      , pot(1800, "ItPo_MegaDrink.3DS",      "Megadrink",           "mega",  { strOrDex = 15 }))
phoenix.item.register("ITPO_HEALTH_TRUNK"   , pot( 150, "ItPo_Health_Trunk.3DS",   "Leczniczy napoj",     "heal",  { hp = 500 }))
phoenix.item.register("ITPO_MANA_TRUNK"     , pot( 200, "ItPo_Mana_Trunk.3DS",     "Napoj many",          "mana",  { mana = 500 }))
