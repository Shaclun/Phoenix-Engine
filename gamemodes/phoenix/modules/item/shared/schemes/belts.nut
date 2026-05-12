local Belt = PhoenixItemCategory.Belt
local SlotBelt = PhoenixItemSlot.Belt

local function be(value, prot, visual, name, effect = null) {
	local data = {
		category   = Belt,
		slot       = SlotBelt,
		value      = value,
		protection = prot,
		visual     = visual,
		name       = name
	}
	if (effect != null) data.effect <- effect
	return data
}
local function p(b, e, po, f, m) { return { blunt = b, edge = e, point = po, fire = f, magic = m } }

phoenix.item.register("ITBE_ADDON_LEATHER_01"      , be( 400, p( 0, 10, 10,  0,  0), "ItBe_Addon_Leather_01.3DS",  "Skorzany pas"))
phoenix.item.register("ITBE_ADDON_LEATHER_02"      , be( 600, p( 0, 15, 15,  0,  0), "ItBe_Addon_Leather_02.3DS",  "Wzmocniony pas"))
phoenix.item.register("ITBE_ADDON_STT_01"          , be( 700, p( 0, 15, 15,  5,  5), "ItBe_Addon_Stt_01.3DS",      "Pas straznika"))
phoenix.item.register("ITBE_ADDON_PAL_01"          , be(1500, p( 0, 25, 25, 15, 10), "ItBe_Addon_Pal_01.3DS",      "Pas paladyna"))
phoenix.item.register("ITBE_ADDON_MIL_01"          , be( 500, p( 0, 15, 15,  0,  0), "ItBe_Addon_Mil_01.3DS",      "Pas milicji"))
phoenix.item.register("ITBE_ADDON_SLD_01"          , be( 500, p( 0, 15, 15,  0,  0), "ItBe_Addon_Sld_01.3DS",      "Pas najemnika"))
phoenix.item.register("ITBE_ADDON_BDT_01"          , be( 500, p( 0, 15, 15,  0,  0), "ItBe_Addon_Bdt_01.3DS",      "Pas bandyty"))
phoenix.item.register("ITBE_ADDON_PIR_01"          , be( 400, p( 0, 10, 10,  0,  0), "ItBe_Addon_Pir_01.3DS",      "Pas pirata"))
phoenix.item.register("ITBE_ADDON_DEX"             , be(1000, p( 0,  0,  0,  0,  0), "ItBe_Addon_Dex.3DS",         "Pas zrecznosci",       { attribute = "dexterity", value = 5 }))
phoenix.item.register("ITBE_ADDON_STRG"            , be(1000, p( 0,  0,  0,  0,  0), "ItBe_Addon_Strg.3DS",        "Pas sily",             { attribute = "strength",  value = 5 }))
phoenix.item.register("ITBE_ADDON_MANA"            , be(1200, p( 0,  0,  0,  0,  0), "ItBe_Addon_Mana.3DS",        "Pas many",             { attribute = "manaMax",   value = 10 }))
phoenix.item.register("ITBE_ADDON_HP"              , be( 800, p( 0,  0,  0,  0,  0), "ItBe_Addon_Hp.3DS",          "Pas zdrowia",          { attribute = "hpMax",     value = 30 }))
