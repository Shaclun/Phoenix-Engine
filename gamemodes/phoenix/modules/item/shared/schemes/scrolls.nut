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

phoenix.item.register("ITSC_LIGHT"            , sc( 50, "ItSc_Light.3DS",            "Zwój: Światło",              "Jednorazowy zwój światła."))
phoenix.item.register("ITSC_FIREBOLT"         , sc( 50, "ItSc_Firebolt.3DS",         "Zwój: Pocisk Ognia",         "Jednorazowy zwój pocisku ognia."))
phoenix.item.register("ITSC_ZAP"              , sc( 50, "ItSc_Zap.3DS",              "Zwój: Iskra",                "Jednorazowy zwój iskry."))
phoenix.item.register("ITSC_LIGHTHEAL"        , sc( 50, "ItSc_LightHeal.3DS",        "Zwój: Małe Leczenie",        "Jednorazowe leczenie."))
phoenix.item.register("ITSC_SUMGOBSKEL"       , sc( 50, "ItSc_SumGobSkel.3DS",       "Zwój: Szkielet Goblin",      "Przywołuje szkielet goblina."))
phoenix.item.register("ITSC_INSTANTFIREBALL"  , sc(100, "ItSc_InstantFireball.3DS",  "Zwój: Kula Ognia",           "Jednorazowa kula ognia."))
phoenix.item.register("ITSC_ICEBOLT"          , sc(100, "ItSc_Icebolt.3DS",          "Zwój: Pocisk Lodu",          "Jednorazowy pocisk lodu."))
phoenix.item.register("ITSC_SUMWOLF"          , sc(100, "ItSc_SumWolf.3DS",          "Zwój: Przywołaj Wilka",      "Przywołuje wilka."))
phoenix.item.register("ITSC_WINDFIST"         , sc(100, "ItSc_Windfist.3DS",         "Zwój: Pięść Wiatru",         "Jednorazowy zwój pięści wiatru."))
phoenix.item.register("ITSC_SLEEP"            , sc(100, "ItSc_Sleep.3DS",            "Zwój: Sen",                  "Jednorazowy zwój uśpienia."))
phoenix.item.register("ITSC_MEDIUMHEAL"       , sc(150, "ItSc_MediumHeal.3DS",       "Zwój: Leczenie",             "Średnie leczenie."))
phoenix.item.register("ITSC_SUMSKEL"          , sc(150, "ItSc_SumSkel.3DS",          "Zwój: Przywołaj Szkielet",   "Przywołuje szkielet."))
phoenix.item.register("ITSC_FEAR"             , sc(150, "ItSc_Fear.3DS",             "Zwój: Strach",               "Jednorazowy zwój strachu."))
phoenix.item.register("ITSC_ICECUBE"          , sc(150, "ItSc_IceCube.3DS",          "Zwój: Sześcian Lodu",        "Zamraża wroga."))
phoenix.item.register("ITSC_THUNDERBALL"      , sc(150, "ItSc_ThunderBall.3DS",      "Zwój: Kula Błyskawic",       "Kula błyskawic."))
phoenix.item.register("ITSC_FIRESTORM"        , sc(150, "ItSc_Firestorm.3DS",        "Zwój: Burza Ognia",          "Jednorazowy zwój burzy ognia."))
phoenix.item.register("ITSC_SUMGOL"           , sc(200, "ItSc_SumGol.3DS",           "Zwój: Przywołaj Golema",     "Przywołuje golema."))
phoenix.item.register("ITSC_HARMUNDEAD"       , sc(200, "ItSc_HarmUndead.3DS",       "Zwój: Rażenie Nieumarłych",  "Rani nieumarłych."))
phoenix.item.register("ITSC_LIGHTNINGFLASH"   , sc(200, "ItSc_LightningFlash.3DS",   "Zwój: Błyskawica",           "Jednorazowy zwój błyskawicy."))
phoenix.item.register("ITSC_CHARGEFIREBALL"   , sc(200, "ItSc_ChargeFireball.3DS",   "Zwój: Naładowana Kula Ognia","Potężna kula ognia."))
phoenix.item.register("ITSC_ICEWAVE"          , sc(250, "ItSc_IceWave.3DS",          "Zwój: Fala Lodu",            "Fala lodu."))
phoenix.item.register("ITSC_SUMDEMON"         , sc(250, "ItSc_SumDemon.3DS",         "Zwój: Przywołaj Demona",     "Przywołuje demona."))
phoenix.item.register("ITSC_FULLHEAL"         , sc(250, "ItSc_FullHeal.3DS",         "Zwój: Pełne Leczenie",       "Jednorazowe pełne leczenie."))
phoenix.item.register("ITSC_PYROKINESIS"      , sc(250, "ItSc_Pyrokinesis.3DS",      "Zwój: Pirokineza",           "Podpala wszystko wokół."))
phoenix.item.register("ITSC_FIRERAIN"         , sc(300, "ItSc_FireRain.3DS",         "Zwój: Deszcz Ognia",         "Deszcz ognia."))
phoenix.item.register("ITSC_MASSDEATH"        , sc(300, "ItSc_MassDeath.3DS",        "Zwój: Masowa Śmierć",        "Masowa śmierć."))
phoenix.item.register("ITSC_BREATHOFDEATH"    , sc(300, "ItSc_BreathOfDeath.3DS",    "Zwój: Oddech Śmierci",       "Oddech śmierci."))
phoenix.item.register("ITSC_MASTEROFDISASTER" , sc(300, "ItSc_MasterOfDisaster.3DS", "Zwój: Mistrz Zniszczenia",   "Mistrz zniszczenia."))
phoenix.item.register("ITSC_ARMYOFDARKNESS"   , sc(300, "ItSc_ArmyOfDarkness.3DS",   "Zwój: Armia Ciemności",      "Armia nieumarłych."))
phoenix.item.register("ITSC_SHRINK"           , sc(300, "ItSc_Shrink.3DS",           "Zwój: Pomniejszenie",        "Zmniejsza wroga."))
