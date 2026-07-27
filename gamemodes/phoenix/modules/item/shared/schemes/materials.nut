local Material = PhoenixItemCategory.Material
local Stackable = PhoenixItemFlag.Stackable

local function m(value, stackMax, visual, name, description = "") {
	return {
		category = Material,
		value    = value,
		stackMax = stackMax,
		flags    = Stackable,
		visual   = visual,
		name     = name,
		description = description
	}
}

phoenix.item.register("ITMI_GOLD"               , { category = PhoenixItemCategory.Misc, name = "Zloto", description = "Sztuka zlota.", value = 1, visual = "ItMi_Gold.3DS", weight = 0.0, stackMax = 999999, flags = Stackable })
phoenix.item.register("ITMI_NUGGET", m(  25, 999, "ItMi_Nugget.3DS",             "Brylka rudy",         "Brylka rudy"))
phoenix.item.register("ITMI_GOLDNUGGET_ADDON", m(  50, 999, "ItMi_Goldnugget.3DS",         "Brylka zlota",        "Brylka zlota"))
phoenix.item.register("ITMI_COAL", m(   5, 999, "ItMi_Coal.3DS",               "Wegiel",              "Wegiel"))
phoenix.item.register("ITMI_SULFUR", m(   8, 999, "ItMi_Sulfur.3DS",             "Siarka",              "Siarka"))
phoenix.item.register("ITMI_QUARTZ", m(  15, 999, "ItMi_Quartz.3DS",             "Kwarc",               "Kwarcyt"))
phoenix.item.register("ITMI_AQUAMARINE", m( 100, 999, "ItMi_Aquamarine.3DS",         "Akwamaryn",           "Akwamaryn"))
phoenix.item.register("ITMI_ROCKCRYSTAL", m(  80, 999, "ItMi_Rockcrystal.3DS",        "Krysztal gorski",     "Skala krystaliczna"))
phoenix.item.register("ITMI_DARKPEARL", m( 200, 999, "ItMi_Darkpearl.3DS",          "Czarna perla",        "Czarna perla"))
phoenix.item.register("ITMI_RUNEBLANK", m(  50,  99, "ItMi_Runeblank.3DS",          "Pusta runa",          "Runa"))
phoenix.item.register("ITMI_LEATHER"            , m(   5, 999, "ItMi_Leather.3DS",            "Skóra",               "Surowa skóra."))
phoenix.item.register("ITMI_FUR"                , m(  10, 999, "ItMi_Fur.3DS",                "Futro",               "Gęste futro."))
phoenix.item.register("ITMI_BONE"               , m(   3, 999, "ItMi_Bone.3DS",               "Kość",                "Kawałek kości."))
phoenix.item.register("ITMI_TEETH"              , m(   8, 999, "ItMi_Teeth.3DS",              "Zęby",                "Ostre zęby."))
phoenix.item.register("ITMI_CLAW"               , m(  10, 999, "ItMi_Claw.3DS",               "Pazur",               "Ostry pazur."))
phoenix.item.register("ITMI_STOMACH"            , m(   5, 999, "ItMi_Stomach.3DS",            "Zoladek",             "Zoladek potwora."))
phoenix.item.register("ITMI_TONGUE"             , m(   5, 999, "ItMi_Tongue.3DS",             "Jezyk",               "Jezyk potwora."))
phoenix.item.register("ITMI_EYE"                , m(  15, 999, "ItMi_Eye.3DS",                "Oko",                 "Oko potwora."))
phoenix.item.register("ITMI_HEART"              , m(  25, 999, "ItMi_Heart.3DS",              "Serce",               "Serce potwora."))
phoenix.item.register("ITMI_DRAGONSCALE"        , m( 100, 999, "ItMi_Dragonscale.3DS",        "Luska smoka",         "Twarda luska smoka."))
phoenix.item.register("ITMI_DRAGONBLOOD"        , m( 200, 999, "ItMi_Dragonblood.3DS",        "Krew smoka",          "Krew smoka w fiolce."))
phoenix.item.register("ITMI_HAMMER"             , { category = PhoenixItemCategory.Misc, name = "Mlotek", description = "Mlotek kowalski.", value = 10, weight = 1.0, visual = "ItMi_Hammer.3DS" })
phoenix.item.register("ITMI_SAW"                , { category = PhoenixItemCategory.Misc, name = "Pila", description = "Pila do drewna.", value = 15, weight = 1.0, visual = "ItMi_Saw.3DS" })
phoenix.item.register("ITMI_PLIERS"             , { category = PhoenixItemCategory.Misc, name = "Kleszcze", description = "Kleszcze kowala.", value = 12, weight = 0.7, visual = "ItMi_Pliers.3DS" })
phoenix.item.register("ITMI_PAN"                , { category = PhoenixItemCategory.Misc, name = "Patelnia", description = "Pusta patelnia.", value = 8, weight = 1.0, visual = "ItMi_Pan.3DS" })
phoenix.item.register("ITMI_PANFULL"            , { category = PhoenixItemCategory.Misc, name = "Patelnia z jedzeniem", description = "Patelnia ze swiezym posilkiem.", value = 20, weight = 1.2, visual = "ItMi_PanFull.3DS" })
phoenix.item.register("ITMI_BROOM"              , { category = PhoenixItemCategory.Misc, name = "Miotla", description = "Zwykla miotla.", value = 3, weight = 0.7, visual = "ItMi_Broom.3DS" })
phoenix.item.register("ITMI_RAKE"               , { category = PhoenixItemCategory.Misc, name = "Grabie", description = "Drewniane grabie.", value = 4, weight = 0.8, visual = "ItMi_Rake.3DS" })
phoenix.item.register("ITMI_SCOOP"              , { category = PhoenixItemCategory.Misc, name = "Lopata", description = "Lopata do kopania.", value = 6, weight = 1.0, visual = "ItMi_Scoop.3DS" })
phoenix.item.register("ITMI_SEXTANT"            , { category = PhoenixItemCategory.Misc, name = "Sekstans", description = "Sekstans nawigacyjny.", value = 80, weight = 0.5, visual = "ItMi_Sextant.3DS" })
phoenix.item.register("ITMI_FOCUS"              , { category = PhoenixItemCategory.Misc, name = "Magiczny fokus", description = "Pomaga skupic energie magiczna.", value = 60, weight = 0.3, visual = "ItMi_Focus.3DS" })
phoenix.item.register("ITMI_TORCH"              , { category = PhoenixItemCategory.Misc, name = "Pochodnia", description = "Pochodnia oswietlajaca droge.", value = 5, weight = 0.5, visual = "ItLsTorch.3DS" })
