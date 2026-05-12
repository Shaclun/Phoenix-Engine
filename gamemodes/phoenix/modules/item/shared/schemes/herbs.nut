local Stackable = PhoenixItemFlag.Stackable
local Food = PhoenixItemCategory.Food
local Material = PhoenixItemCategory.Material

local function herb(value, stackMax, category, visual, name, effect = null, description = "") {
	local data = {
		category = category,
		value = value,
		weight = 0.1,
		stackMax = stackMax,
		flags = Stackable,
		visual = visual,
		name = name,
		description = description
	}
	if (effect != null) {
		data.onUse <- effect.kind
		data.effect <- effect.data
	}
	return data
}

phoenix.item.register("ITPL_WEED", herb(  1, 100, Material, "ItPl_Weed.3DS",              "Chwast",                null,                                       "Chwasty"))
phoenix.item.register("ITPL_BEET", herb(  2, 100, Food    , "ItPl_Beet.3DS",              "Burak",                 { kind = "heal", data = { hp = 3 } },      "Rzepa"))
phoenix.item.register("ITPL_SWAMPHERB", herb( 10, 100, Material, "ItPl_Swampherb.3DS",         "Bagienne ziele",        null,                                       "Bagienne ziele"))
phoenix.item.register("ITPL_MANA_HERB_01", herb( 10, 100, Food    , "ItPl_Mana_Herb_01.3DS",      "Magiczne ziele",        { kind = "mana", data = { mana = 5 } },    "Ognista pokrzywa"))
phoenix.item.register("ITPL_MANA_HERB_02", herb( 25, 100, Food    , "ItPl_Mana_Herb_02.3DS",      "Eteryczne ziele",       { kind = "mana", data = { mana = 10 } },   "Ogniste ziele"))
phoenix.item.register("ITPL_MANA_HERB_03", herb( 60, 100, Food    , "ItPl_Mana_Herb_03.3DS",      "Boskie ziele many",     { kind = "mana", data = { mana = 20 } },   "Ognisty korzen"))
phoenix.item.register("ITPL_HEALTH_HERB_01", herb( 10, 100, Food    , "ItPl_Health_Herb_01.3DS",    "Krwawnik",              { kind = "heal", data = { hp = 5 } },      "Roslina lecznicza"))
phoenix.item.register("ITPL_HEALTH_HERB_02", herb( 25, 100, Food    , "ItPl_Health_Herb_02.3DS",    "Pole leczące",          { kind = "heal", data = { hp = 10 } },     "Ziele lecznicze"))
phoenix.item.register("ITPL_HEALTH_HERB_03", herb( 60, 100, Food    , "ItPl_Health_Herb_03.3DS",    "Królewski korzeń",      { kind = "heal", data = { hp = 20 } },     "Korzen leczniczy"))
phoenix.item.register("ITPL_DEX_HERB_01", herb(350,  50, Material, "ItPl_Dex_Herb_01.3DS",       "Zręczność leśna",       null,                                       "Goblinie jagody"))
phoenix.item.register("ITPL_STRENGTH_HERB_01", herb(350,  50, Material, "ItPl_Strength_Herb_01.3DS",  "Siłak",                 null,                                       "Smoczy korzen"))
phoenix.item.register("ITPL_SPEED_HERB_01", herb(100,  50, Material, "ItPl_Speed_Herb_01.3DS",     "Wiatrówka",             null,                                       "Zebate ziele"))
phoenix.item.register("ITPL_MUSHROOM_01", herb(  5, 100, Food    , "ItPl_Mushroom_01.3DS",       "Czerwony grzyb",        { kind = "heal", data = { hp = 5 } },      "Ciemny grzyb"))
phoenix.item.register("ITPL_MUSHROOM_02", herb(  5, 100, Food    , "ItPl_Mushroom_02.3DS",       "Ciemny grzyb",          { kind = "heal", data = { hp = 5 } },      "Mieso kopacza"))
phoenix.item.register("ITPL_BLUEPLANT", herb( 20, 100, Material, "ItPl_BluePlant.3DS",         "Niebieskie ziele",      null,                                       "Niebieski bez"))
phoenix.item.register("ITPL_FORESTBERRY", herb(  5, 100, Food    , "ItPl_Forestberry.3DS",       "Leśne jagody",          { kind = "heal", data = { hp = 5 } },      "Lesna jagoda"))
phoenix.item.register("ITPL_PLANEBERRY", herb(  5, 100, Food    , "ItPl_Planeberry.3DS",        "Polne jagody",          { kind = "heal", data = { hp = 5 } },      "Polna jagoda"))
phoenix.item.register("ITPL_TEMP_HERB", herb(250,  50, Material, "ItPl_Temp_Herb.3DS",         "Ziele temperancji",     null,                                       "Rdest polny"))
phoenix.item.register("ITPL_PERM_HERB", herb(500,  50, Material, "ItPl_Perm_Herb.3DS",         "Boskie ziele",          null,                                       "Szczaw krolewski"))
phoenix.item.register("ITPL_SAGITTA_HERB_MIS"  , herb(500,  50, Material, "ItPl_Sagitta_Herb.3DS",      "Zioło Sagitty",         null,                                       "Rzadkie zioło Sagitty."))

