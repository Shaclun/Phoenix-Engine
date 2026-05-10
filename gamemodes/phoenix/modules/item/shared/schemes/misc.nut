// =====================================================================
// phoenix.item — REAL Gothic 2 NoTR vanilla misc items.
// Verified against Main-Server/data.xml.
// =====================================================================

// ----- Pieniądze / Surowce -------------------------------------------
phoenix.item.register("ITMI_GOLD", {
	category = PhoenixItemCategory.Misc, name = "Złoto",
	description = "Sztuka złota.",
	value = 1, visual = "ITMI_GOLD.MRM", weight = 0.0, stackMax = 999999,
	flags = PhoenixItemFlag.Stackable
})
phoenix.item.register("ITMI_NUGGET", {
	category = PhoenixItemCategory.Material, name = "Bryłka rudy",
	description = "Bryłka magicznej rudy.",
	value = 25, weight = 1.0, stackMax = 999
})
phoenix.item.register("ITMI_GOLDNUGGET_ADDON", {
	category = PhoenixItemCategory.Material, name = "Bryłka złota",
	description = "Bryłka czystego złota.",
	value = 50, weight = 1.0, stackMax = 999
})
phoenix.item.register("ITMI_COAL", {
	category = PhoenixItemCategory.Material, name = "Węgiel",
	description = "Bryła węgla drzewnego.",
	value = 5, weight = 0.5, stackMax = 999
})
phoenix.item.register("ITMI_SULFUR", {
	category = PhoenixItemCategory.Material, name = "Siarka",
	description = "Grudka siarki.",
	value = 8, weight = 0.5, stackMax = 999
})
phoenix.item.register("ITMI_QUARTZ", {
	category = PhoenixItemCategory.Material, name = "Kwarc",
	description = "Bryłka kwarcu.",
	value = 15, weight = 0.5, stackMax = 999
})
phoenix.item.register("ITMI_AQUAMARINE", {
	category = PhoenixItemCategory.Material, name = "Akwamaryn",
	description = "Cenny niebieski kamień.",
	value = 100, weight = 0.3, stackMax = 999
})
phoenix.item.register("ITMI_ROCKCRYSTAL", {
	category = PhoenixItemCategory.Material, name = "Kryształ górski",
	description = "Czysty górski kryształ.",
	value = 80, weight = 0.3, stackMax = 999
})
phoenix.item.register("ITMI_DARKPEARL", {
	category = PhoenixItemCategory.Material, name = "Czarna perła",
	description = "Rzadka czarna perła.",
	value = 200, weight = 0.1, stackMax = 999
})
phoenix.item.register("ITMI_RUNEBLANK", {
	category = PhoenixItemCategory.Material, name = "Pusta runa",
	description = "Pusty kamień runiczny.",
	value = 50, weight = 0.4, stackMax = 99
})

// ----- Narzędzia -----------------------------------------------------
phoenix.item.register("ITMI_HAMMER", {
	category = PhoenixItemCategory.Misc, name = "Młotek",
	description = "Młotek kowalski.",
	value = 10, weight = 1.0
})
phoenix.item.register("ITMI_SAW", {
	category = PhoenixItemCategory.Misc, name = "Piła",
	description = "Piła do drewna.",
	value = 15, weight = 1.0
})
phoenix.item.register("ITMI_PLIERS", {
	category = PhoenixItemCategory.Misc, name = "Kleszcze",
	description = "Kleszcze kowala.",
	value = 12, weight = 0.7
})
phoenix.item.register("ITMI_PAN", {
	category = PhoenixItemCategory.Misc, name = "Patelnia",
	description = "Pusta patelnia.",
	value = 8, weight = 1.0
})
phoenix.item.register("ITMI_PANFULL", {
	category = PhoenixItemCategory.Misc, name = "Patelnia z jedzeniem",
	description = "Patelnia ze świeżym posiłkiem.",
	value = 20, weight = 1.2
})
phoenix.item.register("ITMI_BROOM", {
	category = PhoenixItemCategory.Misc, name = "Miotła",
	description = "Zwykła miotła.",
	value = 3, weight = 0.7
})
phoenix.item.register("ITMI_RAKE", {
	category = PhoenixItemCategory.Misc, name = "Grabie",
	description = "Drewniane grabie.",
	value = 4, weight = 0.8
})
phoenix.item.register("ITMI_SCOOP", {
	category = PhoenixItemCategory.Misc, name = "Łopata",
	description = "Łopata do kopania.",
	value = 6, weight = 1.0
})
phoenix.item.register("ITMI_SEXTANT", {
	category = PhoenixItemCategory.Misc, name = "Sekstans",
	description = "Sekstans nawigacyjny.",
	value = 80, weight = 0.5
})
phoenix.item.register("ITMI_FOCUS", {
	category = PhoenixItemCategory.Misc, name = "Magiczny fokus",
	description = "Pomaga skupić energię magiczną.",
	value = 60, weight = 0.3
})

// ----- Klucze / Wytrychy --------------------------------------------
phoenix.item.register("ITKE_LOCKPICK", {
	category = PhoenixItemCategory.Key, name = "Wytrych",
	description = "Cienki wytrych.",
	value = 10, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITKE_KEY_01", {
	category = PhoenixItemCategory.Key, name = "Mosiężny klucz",
	description = "Drobny mosiężny klucz.",
	value = 5, weight = 0.1
})
phoenix.item.register("ITKE_KEY_02", {
	category = PhoenixItemCategory.Key, name = "Żelazny klucz",
	description = "Solidny żelazny klucz.",
	value = 5, weight = 0.1
})
phoenix.item.register("ITKE_KEY_03", {
	category = PhoenixItemCategory.Key, name = "Stary klucz",
	description = "Pordzewiały stary klucz.",
	value = 5, weight = 0.1
})

// ----- Mapy / Dokumenty ---------------------------------------------
phoenix.item.register("ITWR_MAP_NEWWORLD", {
	category = PhoenixItemCategory.Document, name = "Mapa: Khorinis",
	description = "Mapa wyspy Khorinis.",
	value = 50, weight = 0.1
})
phoenix.item.register("ITWR_MAP_OLDWORLD", {
	category = PhoenixItemCategory.Document, name = "Mapa: Górnicza Dolina",
	description = "Mapa Górniczej Doliny.",
	value = 50, weight = 0.1
})
phoenix.item.register("ITWR_MAP_ADDONWORLD", {
	category = PhoenixItemCategory.Document, name = "Mapa: Jharkendar",
	description = "Mapa Jharkendaru.",
	value = 80, weight = 0.1
})
phoenix.item.register("ITWR_MAP_NEWWORLD_CITY", {
	category = PhoenixItemCategory.Document, name = "Mapa: Miasto Khorinis",
	description = "Plan miasta Khorinis.",
	value = 30, weight = 0.1
})
phoenix.item.register("ITWR_EINHANDBUCH", {
	category = PhoenixItemCategory.Document, name = "Księga: Walka jednoręczna",
	description = "Trening walki jednoręcznej.",
	value = 1000, weight = 0.5
})
phoenix.item.register("ITWR_ZWEIHANDBUCH", {
	category = PhoenixItemCategory.Document, name = "Księga: Walka dwuręczna",
	description = "Trening walki dwuręcznej.",
	value = 1000, weight = 0.5
})
phoenix.item.register("ITWR_KRAEUTERLISTE", {
	category = PhoenixItemCategory.Document, name = "Lista ziół",
	description = "Lista znanych ziół.",
	value = 50, weight = 0.1
})
phoenix.item.register("ITWR_MANAREZEPT", {
	category = PhoenixItemCategory.Document, name = "Receptura: mikstura many",
	description = "Receptura warzenia eliksiru many.",
	value = 200, weight = 0.1
})

// ----- Zioła --------------------------------------------------------
phoenix.item.register("ITPL_HEALTH_HERB_01", {
	category = PhoenixItemCategory.Material, name = "Krwawnik",
	description = "Lecznicze zioło.",
	value = 5, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_HEALTH_HERB_02", {
	category = PhoenixItemCategory.Material, name = "Pole leczące",
	description = "Średniej mocy zioło lecznicze.",
	value = 12, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_HEALTH_HERB_03", {
	category = PhoenixItemCategory.Material, name = "Królewski korzeń",
	description = "Najsilniejsze zioło lecznicze.",
	value = 25, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_MANA_HERB_01", {
	category = PhoenixItemCategory.Material, name = "Magiczne ziele",
	description = "Zioło wzmacniające manę.",
	value = 5, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_MANA_HERB_02", {
	category = PhoenixItemCategory.Material, name = "Eteryczne ziele",
	description = "Średniej mocy zioło many.",
	value = 12, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_MANA_HERB_03", {
	category = PhoenixItemCategory.Material, name = "Boskie ziele",
	description = "Najsilniejsze zioło many.",
	value = 25, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_STRENGTH_HERB_01", {
	category = PhoenixItemCategory.Material, name = "Siłak",
	description = "Zioło dodające siły.",
	value = 50, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_DEX_HERB_01", {
	category = PhoenixItemCategory.Material, name = "Zręczność leśna",
	description = "Zioło dodające zręczności.",
	value = 50, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_SPEED_HERB_01", {
	category = PhoenixItemCategory.Material, name = "Wiatrówka",
	description = "Zioło zwiększające szybkość.",
	value = 30, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_PERM_HERB", {
	category = PhoenixItemCategory.Material, name = "Boskie ziele",
	description = "Trwale wzmacniające zioło.",
	value = 200, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_FORESTBERRY", {
	category = PhoenixItemCategory.Food, name = "Leśne jagody",
	description = "Soczyste leśne jagody.",
	value = 2, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_BLUEPLANT", {
	category = PhoenixItemCategory.Material, name = "Niebieskie ziele",
	description = "Tajemnicze niebieskie ziele.",
	value = 8, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_SWAMPHERB", {
	category = PhoenixItemCategory.Material, name = "Bagienne ziele",
	description = "Zioło z mokradeł.",
	value = 6, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_MUSHROOM_01", {
	category = PhoenixItemCategory.Food, name = "Czerwony grzyb",
	description = "Smaczny czerwony grzyb.",
	value = 4, weight = 0.05, stackMax = 99
})
phoenix.item.register("ITPL_MUSHROOM_02", {
	category = PhoenixItemCategory.Food, name = "Ciemny grzyb",
	description = "Mięsisty ciemny grzyb.",
	value = 4, weight = 0.05, stackMax = 99
})
