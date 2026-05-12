local Key = PhoenixItemCategory.Key
local Stackable = PhoenixItemFlag.Stackable

local function k(value, visual, name, description = "") {
	return {
		category = Key,
		value    = value,
		stackMax = 99,
		flags    = Stackable,
		visual   = visual,
		name     = name,
		description = description
	}
}

phoenix.item.register("ITKE_LOCKPICK", k(  10, "ItKe_Lockpick.3DS",          "Wytrych",                "Wytrych"))
phoenix.item.register("ITKE_KEY_01", k(   5, "ItKe_Key_01.3DS",            "Mosiężny klucz",         "Klucz"))
phoenix.item.register("ITKE_KEY_02", k(   5, "ItKe_Key_02.3DS",            "Żelazny klucz",          "Klucz"))
phoenix.item.register("ITKE_KEY_03", k(   5, "ItKe_Key_03.3DS",            "Stary klucz",            "Klucz"))
phoenix.item.register("ITKE_KEY_CITY_01"        , k(   5, "ItKe_City_01.3DS",           "Klucz miejski",          "Klucz do bramy miejskiej."))
phoenix.item.register("ITKE_KEY_MONASTERY_01"   , k(   5, "ItKe_Monastery_01.3DS",      "Klucz klasztorny",       "Klucz do klasztoru."))
phoenix.item.register("ITKE_KEY_CASTLE_01"      , k(   5, "ItKe_Castle_01.3DS",         "Klucz zamkowy",          "Klucz do zamku górniczego."))

