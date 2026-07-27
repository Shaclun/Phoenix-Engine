local Food = PhoenixItemCategory.Food
local Stackable = PhoenixItemFlag.Stackable

local function fo(value, stackMax, visual, name, effect = null) {
	local data = {
		category = Food,
		value    = value,
		stackMax = stackMax,
		flags    = Stackable,
		visual   = visual,
		name     = name
	}
	if (effect != null) {
		data.onUse <- effect.kind
		data.effect <- effect.data
	}
	return data
}

phoenix.item.register("ITFO_APPLE"            , fo(   4,  99, "ItFo_Apple.3DS",            "Jablko",                 { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITFO_BACON"            , fo(  15,  99, "ItFo_Bacon.3DS",            "Bekon",                  { kind = "heal", data = { hp = 10 } }))
phoenix.item.register("ITFO_BEER"             , fo(  10,  99, "ItFo_Beer.3DS",             "Piwo",                   { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITFO_BOOZE"            , fo(  25,  99, "ItFo_Booze.3DS",            "Gorzala",                { kind = "heal", data = { hp = 10 } }))
phoenix.item.register("ITFO_BREAD"            , fo(   5,  99, "ItFo_Bread.3DS",            "Chleb",                  { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITFO_CHEESE"           , fo(  10,  99, "ItFo_Cheese.3DS",           "Ser",                    { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITFO_FISH"             , fo(  10,  99, "ItFo_Fish.3DS",             "Ryba",                   { kind = "heal", data = { hp = 8 } }))
phoenix.item.register("ITFO_FISHSOUP"         , fo(  30,  99, "ItFo_FishSoup.3DS",         "Zupa rybna",             { kind = "heal", data = { hp = 15 } }))
phoenix.item.register("ITFO_HONEY"            , fo(  10,  99, "ItFo_Honey.3DS",            "Miod",                   { kind = "heal", data = { hp = 8 } }))
phoenix.item.register("ITFO_MILK"             , fo(   5,  99, "ItFo_Milk.3DS",             "Mleko",                  { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITFO_MUTTON"           , fo(  15,  99, "ItFo_Mutton.3DS",           "Smażone mięso",           { kind = "heal", data = { hp = 12 } }))
phoenix.item.register("ITFO_MUTTONRAW"        , fo(   5,  99, "ItFo_MuttonRaw.3DS",        "Surowe mięso",            { kind = "heal", data = { hp = 3 } }))
phoenix.item.register("ITFO_SAUSAGE"          , fo(  15,  99, "ItFo_Sausage.3DS",          "Kielbasa",               { kind = "heal", data = { hp = 10 } }))
phoenix.item.register("ITFO_STEW"             , fo(  30,  99, "ItFo_Stew.3DS",             "Gulasz",                 { kind = "heal", data = { hp = 15 } }))
phoenix.item.register("ITFO_WATER"            , fo(   5,  99, "ItFo_Water.3DS",            "Woda",                   { kind = "heal", data = { hp = 2 } }))
phoenix.item.register("ITFO_WINE"             , fo(  15,  99, "ItFo_Wine.3DS",             "Wino",                   { kind = "heal", data = { hp = 8 } }))
phoenix.item.register("ITFO_EGG"              , fo(   5,  99, "ItFo_Egg.3DS",              "Jajko",                  { kind = "heal", data = { hp = 3 } }))
phoenix.item.register("ITFO_ADDON_RUM"        , fo(  30,  99, "ItFo_Addon_Rum.3DS",        "Rum",                    { kind = "heal", data = { hp = 15 } }))
phoenix.item.register("ITFO_ADDON_GROG"       , fo(  25,  99, "ItFo_Addon_Grog.3DS",       "Grog",                   { kind = "heal", data = { hp = 10 } }))
phoenix.item.register("ITFO_ADDON_FIRESTEW"   , fo(  40,  99, "ItFo_Addon_FireStew.3DS",   "Ognisty gulasz",         { kind = "heal", data = { hp = 20 } }))
phoenix.item.register("ITFO_ADDON_MEATSOUP"   , fo(  30,  99, "ItFo_Addon_MeatSoup.3DS",   "Zupa miesna",            { kind = "heal", data = { hp = 15 } }))
phoenix.item.register("ITFO_ADDON_SHELLFLESH" , fo(  15,  99, "ItFo_Addon_ShellFlesh.3DS", "Mieso muszli",           { kind = "heal", data = { hp = 8 } }))
