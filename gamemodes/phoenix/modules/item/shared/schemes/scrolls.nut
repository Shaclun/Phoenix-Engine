local Scroll = PhoenixItemCategory.Scroll
local Stackable = PhoenixItemFlag.Stackable

local function sc(value, visual, name, description = "") {
	return {
		category = Scroll,
		value    = value,
		stackMax = 99,
		flags    = Stackable,
		visual   = visual,
		name     = name,
		description = description
	}
}

phoenix.item.register("ITSC_LIGHT"            , sc( 50, "ItSc_Light.3DS",            "Zwoj: Swiatlo",              "Jednorazowy zwoj swiatla."))
phoenix.item.register("ITSC_FIREBOLT"         , sc( 50, "ItSc_Firebolt.3DS",         "Zwoj: Pocisk Ognia",         "Jednorazowy zwoj pocisku ognia."))
phoenix.item.register("ITSC_ZAP"              , sc( 50, "ItSc_Zap.3DS",              "Zwoj: Iskra",                "Jednorazowy zwoj iskry."))
phoenix.item.register("ITSC_LIGHTHEAL"        , sc( 50, "ItSc_LightHeal.3DS",        "Zwoj: Male Leczenie",        "Jednorazowe leczenie."))
phoenix.item.register("ITSC_SUMGOBSKEL"       , sc( 50, "ItSc_SumGobSkel.3DS",       "Zwoj: Szkielet Goblin",      "Przywoluje szkielet goblina."))
phoenix.item.register("ITSC_INSTANTFIREBALL"  , sc(100, "ItSc_InstantFireball.3DS",  "Zwoj: Kula Ognia",           "Jednorazowa kula ognia."))
phoenix.item.register("ITSC_ICEBOLT"          , sc(100, "ItSc_Icebolt.3DS",          "Zwoj: Pocisk Lodu",          "Jednorazowy pocisk lodu."))
phoenix.item.register("ITSC_SUMWOLF"          , sc(100, "ItSc_SumWolf.3DS",          "Zwoj: Przywolaj Wilka",      "Przywoluje wilka."))
phoenix.item.register("ITSC_WINDFIST"         , sc(100, "ItSc_Windfist.3DS",         "Zwoj: Piesc Wiatru",         "Jednorazowy zwoj piesci wiatru."))
phoenix.item.register("ITSC_SLEEP"            , sc(100, "ItSc_Sleep.3DS",            "Zwoj: Sen",                  "Jednorazowy zwoj uspienia."))
phoenix.item.register("ITSC_MEDIUMHEAL"       , sc(150, "ItSc_MediumHeal.3DS",       "Zwoj: Leczenie",             "Srednie leczenie."))
phoenix.item.register("ITSC_SUMSKEL"          , sc(150, "ItSc_SumSkel.3DS",          "Zwoj: Przywolaj Szkielet",   "Przywoluje szkielet."))
phoenix.item.register("ITSC_FEAR"             , sc(150, "ItSc_Fear.3DS",             "Zwoj: Strach",               "Jednorazowy zwoj strachu."))
phoenix.item.register("ITSC_ICECUBE"          , sc(150, "ItSc_IceCube.3DS",          "Zwoj: Szescian Lodu",        "Zamraza wroga."))
phoenix.item.register("ITSC_THUNDERBALL"      , sc(150, "ItSc_ThunderBall.3DS",      "Zwoj: Kula Blyskawic",       "Kula blyskawic."))
phoenix.item.register("ITSC_FIRESTORM"        , sc(150, "ItSc_Firestorm.3DS",        "Zwoj: Burza Ognia",          "Jednorazowy zwoj burzy ognia."))
phoenix.item.register("ITSC_SUMGOL"           , sc(200, "ItSc_SumGol.3DS",           "Zwoj: Przywolaj Golema",     "Przywoluje golema."))
phoenix.item.register("ITSC_HARMUNDEAD"       , sc(200, "ItSc_HarmUndead.3DS",       "Zwoj: Razenie Nieumarych",   "Rani nieumarych."))
phoenix.item.register("ITSC_LIGHTNINGFLASH"   , sc(200, "ItSc_LightningFlash.3DS",   "Zwoj: Blyskawica",           "Jednorazowy zwoj blyskawicy."))
phoenix.item.register("ITSC_CHARGEFIREBALL"   , sc(200, "ItSc_ChargeFireball.3DS",   "Zwoj: Naladowana Kula Ognia","Potezna kula ognia."))
phoenix.item.register("ITSC_ICEWAVE"          , sc(250, "ItSc_IceWave.3DS",          "Zwoj: Fala Lodu",            "Fala lodu."))
phoenix.item.register("ITSC_SUMDEMON"         , sc(250, "ItSc_SumDemon.3DS",         "Zwoj: Przywolaj Demona",     "Przywoluje demona."))
phoenix.item.register("ITSC_FULLHEAL"         , sc(250, "ItSc_FullHeal.3DS",         "Zwoj: Pelne Leczenie",       "Jednorazowe pelne leczenie."))
phoenix.item.register("ITSC_PYROKINESIS"      , sc(250, "ItSc_Pyrokinesis.3DS",      "Zwoj: Pirokineza",           "Podpala wszystko wokol."))
phoenix.item.register("ITSC_FIRERAIN"         , sc(300, "ItSc_FireRain.3DS",         "Zwoj: Deszcz Ognia",         "Deszcz ognia."))
phoenix.item.register("ITSC_MASSDEATH"        , sc(300, "ItSc_MassDeath.3DS",        "Zwoj: Masowa Smierc",        "Masowa smierc."))
phoenix.item.register("ITSC_BREATHOFDEATH"    , sc(300, "ItSc_BreathOfDeath.3DS",    "Zwoj: Oddech Smierci",       "Oddech smierci."))
phoenix.item.register("ITSC_MASTEROFDISASTER" , sc(300, "ItSc_MasterOfDisaster.3DS", "Zwoj: Mistrz Zniszczenia",   "Mistrz zniszczenia."))
phoenix.item.register("ITSC_ARMYOFDARKNESS"   , sc(300, "ItSc_ArmyOfDarkness.3DS",   "Zwoj: Armia Ciemnosci",      "Armia nieumarych."))
phoenix.item.register("ITSC_SHRINK"           , sc(300, "ItSc_Shrink.3DS",           "Zwoj: Pomniejszenie",        "Zmniejsza wroga."))
