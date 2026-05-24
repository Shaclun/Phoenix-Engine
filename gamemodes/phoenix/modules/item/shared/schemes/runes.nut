local Rune = PhoenixItemCategory.Rune
local SpellSlot = PhoenixItemSlot.Spell

local function ru(value, visual, name, spell) {
	local data = {
		category = Rune,
		value    = value,
		visual   = visual,
		name     = name,
		slot     = SpellSlot
	}
	if (spell != null && spell != "") {
		data.onUse <- "spell"
		data.effect <- { spell = spell }
	}
	return data
}

phoenix.item.register("ITRU_LIGHT"             , ru( 500, "ItRu_Light.3DS",             "Runa: Swiatlo",                "LIGHT"))
phoenix.item.register("ITRU_FIREBOLT"          , ru( 500, "ItRu_FireBolt.3DS",          "Runa: Pocisk Ognia",           "FIREBOLT"))
phoenix.item.register("ITRU_ZAP"               , ru( 500, "ItRu_Zap.3DS",               "Runa: Iskra",                  "ZAP"))
phoenix.item.register("ITRU_LIGHTHEAL"         , ru( 500, "ItRu_LightHeal.3DS",         "Runa: Male Leczenie",          "LIGHTHEAL"))
phoenix.item.register("ITRU_SUMGOBSKEL"        , ru( 500, "ItRu_SumGobSkel.3DS",        "Runa: Szkielet Goblina",       "SUMGOBSKEL"))
phoenix.item.register("ITRU_INSTANTFIREBALL"   , ru(1000, "ItRu_InstantFireball.3DS",   "Runa: Kula Ognia",             "INSTANTFIREBALL"))
phoenix.item.register("ITRU_ICEBOLT"           , ru(1000, "ItRu_IceBolt.3DS",           "Runa: Pocisk Lodu",            "ICEBOLT"))
phoenix.item.register("ITRU_SUMWOLF"           , ru(1000, "ItRu_SumWolf.3DS",           "Runa: Przywolaj Wilka",        "SUMWOLF"))
phoenix.item.register("ITRU_WINDFIST"          , ru(1000, "ItRu_Windfist.3DS",          "Runa: Piesc Wiatru",           "WINDFIST"))
phoenix.item.register("ITRU_SLEEP"             , ru(1000, "ItRu_Sleep.3DS",             "Runa: Sen",                    "SLEEP"))
phoenix.item.register("ITRU_MEDIUMHEAL"        , ru(1500, "ItRu_MediumHeal.3DS",        "Runa: Leczenie",               "MEDIUMHEAL"))
phoenix.item.register("ITRU_SUMSKEL"           , ru(1500, "ItRu_SumSkel.3DS",           "Runa: Przywolaj Szkielet",     "SUMSKEL"))
phoenix.item.register("ITRU_FEAR"              , ru(1500, "ItRu_Fear.3DS",              "Runa: Strach",                 "FEAR"))
phoenix.item.register("ITRU_ICECUBE"           , ru(1500, "ItRu_IceCube.3DS",           "Runa: Szescian Lodu",          "ICECUBE"))
phoenix.item.register("ITRU_THUNDERBALL"       , ru(1500, "ItRu_Thunderball.3DS",       "Runa: Kula Blyskawic",         "THUNDERBALL"))
phoenix.item.register("ITRU_FIRESTORM"         , ru(1500, "ItRu_Firestorm.3DS",         "Runa: Burza Ognia",            "FIRESTORM"))
phoenix.item.register("ITRU_SUMGOL"            , ru(2000, "ItRu_SumGol.3DS",            "Runa: Przywolaj Golema",       "SUMGOL"))
phoenix.item.register("ITRU_HARMUNDEAD"        , ru(2000, "ItRu_HarmUndead.3DS",        "Runa: Razenie Nieumarlych",    "HARMUNDEAD"))
phoenix.item.register("ITRU_LIGHTNINGFLASH"    , ru(2000, "ItRu_LightningFlash.3DS",    "Runa: Blyskawica",             "LIGHTNINGFLASH"))
phoenix.item.register("ITRU_CHARGEFIREBALL"    , ru(2000, "ItRu_ChargeFireball.3DS",    "Runa: Naladowana Kula Ognia",  "CHARGEFIREBALL"))
phoenix.item.register("ITRU_ICEWAVE"           , ru(2500, "ItRu_IceWave.3DS",           "Runa: Fala Lodu",              "ICEWAVE"))
phoenix.item.register("ITRU_SUMDEMON"          , ru(2500, "ItRu_SumDemon.3DS",          "Runa: Przywolaj Demona",       "SUMDEMON"))
phoenix.item.register("ITRU_FULLHEAL"          , ru(2500, "ItRu_FullHeal.3DS",          "Runa: Pelne Leczenie",         "FULLHEAL"))
phoenix.item.register("ITRU_PYROKINESIS"       , ru(2500, "ItRu_Pyrokinesis.3DS",       "Runa: Pirokineza",             "PYROKINESIS"))
phoenix.item.register("ITRU_FIRERAIN"          , ru(3000, "ItRu_FireRain.3DS",          "Runa: Deszcz Ognia",           "FIRERAIN"))
phoenix.item.register("ITRU_BREATHOFDEATH"     , ru(3000, "ItRu_BreathOfDeath.3DS",     "Runa: Oddech Smierci",         "BREATHOFDEATH"))
phoenix.item.register("ITRU_MASSDEATH"         , ru(3000, "ItRu_MassDeath.3DS",         "Runa: Masowa Smierc",          "MASSDEATH"))
phoenix.item.register("ITRU_MASTEROFDISASTER"  , ru(3000, "ItRu_MasterOfDisaster.3DS",  "Runa: Mistrz Zniszczenia",     "MASTEROFDISASTER"))
phoenix.item.register("ITRU_ARMYOFDARKNESS"    , ru(3000, "ItRu_ArmyOfDarkness.3DS",    "Runa: Armia Ciemnosci",        "ARMYOFDARKNESS"))
phoenix.item.register("ITRU_SHRINK"            , ru(3000, "ItRu_Shrink.3DS",            "Runa: Pomniejszenie",          "SHRINK"))
phoenix.item.register("ITRU_PALLIGHT"          , ru( 500, "ItRu_PalLight.3DS",          "Runa: Swiatlo Paladyna",       "PALLIGHT"))
phoenix.item.register("ITRU_PALLIGHTHEAL"      , ru( 500, "ItRu_PalLightHeal.3DS",      "Runa: Male Leczenie Paladyna", "PALLIGHTHEAL"))
phoenix.item.register("ITRU_PALHOLYBOLT"       , ru( 500, "ItRu_PalHolyBolt.3DS",       "Runa: Swiety Pocisk",          "PALHOLYBOLT"))
phoenix.item.register("ITRU_PALMEDIUMHEAL"     , ru(2000, "ItRu_PalMediumHeal.3DS",     "Runa: Srednie Leczenie Paladyna","PALMEDIUMHEAL"))
phoenix.item.register("ITRU_PALREPELEVIL"      , ru(2000, "ItRu_PalRepelEvil.3DS",      "Runa: Odpedzenie Zla",         "PALREPELEVIL"))
phoenix.item.register("ITRU_PALFULLHEAL"       , ru(3000, "ItRu_PalFullHeal.3DS",       "Runa: Pelne Leczenie Paladyna","PALFULLHEAL"))
phoenix.item.register("ITRU_PALDESTROYEVIL"    , ru(3000, "ItRu_PalDestroyEvil.3DS",    "Runa: Niszcz Zlo",             "PALDESTROYEVIL"))
phoenix.item.register("ITRU_PALTELEPORTSECRET" , ru( 500, "ItRu_PalTeleportSecret.3DS", "Runa: Teleport Paladyna",      null))
phoenix.item.register("ITRU_TELEPORTSEAPORT"   , ru( 500, "ItRu_TeleportSeaport.3DS",   "Runa: Teleport Port",          null))
phoenix.item.register("ITRU_TELEPORTMONASTERY" , ru( 500, "ItRu_TeleportMonastery.3DS", "Runa: Teleport Klasztor",      null))
phoenix.item.register("ITRU_TELEPORTFARM"      , ru( 500, "ItRu_TeleportFarm.3DS",      "Runa: Teleport Farma",         null))
phoenix.item.register("ITRU_TELEPORTXARDAS"    , ru( 500, "ItRu_TeleportXardas.3DS",    "Runa: Teleport Xardas",        null))
phoenix.item.register("ITRU_TELEPORTPASSNW"    , ru( 500, "ItRu_TeleportPassNW.3DS",    "Runa: Teleport Przelecz NW",   null))
phoenix.item.register("ITRU_TELEPORTPASSOW"    , ru( 500, "ItRu_TeleportPassOW.3DS",    "Runa: Teleport Przelecz OW",   null))
phoenix.item.register("ITRU_TELEPORTOC"        , ru( 500, "ItRu_TeleportOC.3DS",        "Runa: Teleport Zamek",         null))
phoenix.item.register("ITRU_TELEPORTOWDEMONTOWER", ru(500, "ItRu_TeleportOWDemonTower.3DS", "Runa: Teleport Wieza Demona", null))
phoenix.item.register("ITRU_TELEPORTTAVERNE"   , ru( 500, "ItRu_TeleportTaverne.3DS",   "Runa: Teleport Karczma",       null))
phoenix.item.register("ITRU_TELEPORT_3"        , ru( 500, "ItRu_Teleport_3.3DS",        "Runa: Teleport dodatkowy",     null))
