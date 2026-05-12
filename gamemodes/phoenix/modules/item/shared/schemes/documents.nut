local Doc = PhoenixItemCategory.Document

local function d(value, visual, name, description = "") {
	return {
		category = Doc,
		value    = value,
		visual   = visual,
		name     = name,
		description = description
	}
}

phoenix.item.register("ITWR_MAP_NEWWORLD", d(  50, "ItWr_Map_Newworld.3DS",         "Mapa: Khorinis",              "Mapa terenow Khorinis"))
phoenix.item.register("ITWR_MAP_NEWWORLD_CITY", d(  30, "ItWr_Map_Newworld_City.3DS",    "Mapa: Miasto Khorinis",       "Mapa miasta Khorinis"))
phoenix.item.register("ITWR_MAP_OLDWORLD", d(  50, "ItWr_Map_Oldworld.3DS",         "Mapa: Górnicza Dolina",       "Mapa Gorniczej Doliny"))
phoenix.item.register("ITWR_MAP_ADDONWORLD"       , d(  80, "ItWr_Map_Addonworld.3DS",       "Mapa: Jharkendar",            "Mapa Jharkendaru."))
phoenix.item.register("ITWR_EINHANDBUCH", d(1000, "ItWr_Book_01.3DS",              "Księga walki jednoręcznej",   "Sztuka walki"))
phoenix.item.register("ITWR_ZWEIHANDBUCH", d(1000, "ItWr_Book_01.3DS",              "Księga walki dwuręcznej",     "Taktyka walki"))
phoenix.item.register("ITWR_BOGENBUCH"            , d(1000, "ItWr_Book_01.3DS",              "Księga łucznictwa",           "Trening strzelania z łuku."))
phoenix.item.register("ITWR_ARMBRUSTBUCH"         , d(1000, "ItWr_Book_01.3DS",              "Księga kuszy",                "Trening strzelania z kuszy."))
phoenix.item.register("ITWR_KRAEUTERLISTE"        , d(  50, "ItWr_Note_01.3DS",              "Lista ziół",                  "Spis znanych ziół."))
phoenix.item.register("ITWR_MANAREZEPT"           , d( 200, "ItWr_Recipe_01.3DS",            "Receptura: mikstura many",    "Receptura warzenia eliksiru many."))
phoenix.item.register("ITWR_HEALINGREZEPT"        , d( 200, "ItWr_Recipe_01.3DS",            "Receptura: mikstura leczenia","Receptura warzenia eliksiru leczenia."))
phoenix.item.register("ITWR_STRREZEPT"            , d( 800, "ItWr_Recipe_01.3DS",            "Receptura: eliksir siły",     "Receptura warzenia eliksiru siły."))
phoenix.item.register("ITWR_DEXREZEPT"            , d( 800, "ItWr_Recipe_01.3DS",            "Receptura: eliksir zręczności","Receptura warzenia eliksiru zręczności."))
phoenix.item.register("ITWR_PERM_HPREZEPT"        , d(1500, "ItWr_Recipe_01.3DS",            "Receptura: esencja życia",    "Receptura warzenia esencji życia."))
phoenix.item.register("ITWR_PERM_MANAREZEPT"      , d(1500, "ItWr_Recipe_01.3DS",            "Receptura: esencja many",     "Receptura warzenia esencji many."))

