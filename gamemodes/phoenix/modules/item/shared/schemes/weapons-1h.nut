local Edge  = PhoenixDamageType.Edge
local Blunt = PhoenixDamageType.Blunt

local function w(value, dmg, dtype, range, reqs, visual, name) {
	return {
		category    = PhoenixItemCategory.Weapon1H,
		slot        = PhoenixItemSlot.MainHand,
		value       = value,
		damage      = dmg,
		damageType  = dtype,
		requirement = reqs,
		visual      = visual,
		name        = name
	}
}
local function str(v) { return [{ attr = "strength", value = v }] }
local function dex(v) { return [{ attr = "dexterity", value = v }] }

phoenix.item.register("ITMW_1H_VLK_DAGGER"                 , w(    5,   5, Edge , 50, str(5),   "Itmw_005_1h_dagger_01.3DS",       "Sztylet"))
phoenix.item.register("ITMW_1H_MACE_L_01"                  , w(    5,   5, Edge , 50, str(5),   "Itmw_005_1h_poker_01.3DS",        "Pogrzebacz"))
phoenix.item.register("ITMW_1H_BAU_AXE"                    , w(   10,   7, Edge , 50, str(5),   "Itmw_007_1h_sickle_01.3DS",       "Sierp"))
phoenix.item.register("ITMW_1H_VLK_MACE"                   , w(   10,   8, Blunt, 70, str(5),   "Itmw_008_1h_pole_01.3DS",         "Laska"))
phoenix.item.register("ITMW_1H_MACE_L_03"                  , w(    5,   8, Blunt, 70, str(10),  "ItMw_008_1h_mace_light_01.3DS",   "Palka"))
phoenix.item.register("ITMW_1H_BAU_MACE"                   , w(    1,  10, Blunt, 70, str(10),  "ItMw_010_1h_Club_01.3DS",         "Laga"))
phoenix.item.register("ITMW_1H_VLK_AXE"                    , w(  200,  20, Edge , 50, str(10),  "ItMw_011_1h_axe_01.3DS",          "Topor"))
phoenix.item.register("ITMW_1H_SWORD_L_03", w(  250,  20, Edge , 30, str(10),  "ItMw_1h_Sword_short_01.3DS",      "Noz na wilki"))
phoenix.item.register("ITMW_1H_MACE_L_04", w(  200,  20, Blunt, 30, str(10),  "ItMw_1h_Mace_war_01.3DS",         "Mlot kowalski"))
phoenix.item.register("ITMW_SHORTSWORD1", w(  250,  20, Edge , 50, str(10),  "ItMw_1h_Common_01.3DS",           "Krotki miecz strazy"))
phoenix.item.register("ITMW_SHORTSWORD2", w(  250,  20, Edge , 50, str(10),  "ItMw_1h_Misc_Sword_01.3DS",       "Kiepski krotki miecz"))
phoenix.item.register("ITMW_NAGELKNUEPPEL", w(   50,  25, Blunt, 60, str(10),  "ItMw_1h_Misc_Club_01.3DS",        "Maczuga z kolcami"))
phoenix.item.register("ITMW_SENSE", w(  250,  25, Edge , 60, str(10),  "ItMw_Scythe_01.3DS",              "Mala kosa"))
phoenix.item.register("ITMW_ALRIKSSWORD_MIS"               , w(   50,  30, Edge , 70, str(30),  "ItMw_1h_Common_02.3DS",           "Miecz Alrika"))
phoenix.item.register("ITMW_1H_MISC_SWORD", w(   30,  30, Edge , 70, str(30),  "ItMw_1h_Misc_Sword.3DS",          "Zardzewialy krotki miecz"))
phoenix.item.register("ITMW_ADDON_KNIFE01", w(  350,  30, Edge , 30, str(10),  "ItMw_1h_Addon_Knife_01.3DS",      "Noz na wilki"))
phoenix.item.register("ITMW_ADDON_KEULE_1H_01", w(   25,  15, Blunt, 65, str(25),  "ItMw_1h_Addon_Keule_01.3DS",      "Sluga Wiatru"))
phoenix.item.register("ITMW_1H_MISC_AXE", w(   40,  40, Edge , 80, str(40),  "ItMw_1h_Misc_Axe.3DS",            "Zardzewialy topor"))
phoenix.item.register("ITMW_1H_MIL_SWORD", w(   50,  40, Edge , 90, str(40),  "ItMw_1h_Mil_Sword.3DS",           "Kiepski szeroki miecz"))
phoenix.item.register("ITMW_1H_SLD_AXE", w(   40,  40, Edge , 70, str(50),  "ItMw_1h_Sld_Axe.3DS",             "Kiepski tasak"))
phoenix.item.register("ITMW_1H_SLD_SWORD", w(   40,  40, Edge , 70, str(50),  "ItMw_1h_Sld_Sword.3DS",           "Kiepski miecz"))
phoenix.item.register("ITMW_SHORTSWORD3", w(  500,  40, Edge , 50, str(20),  "ItMw_1h_Nov_Mace.3DS",            "Krotki miecz"))
phoenix.item.register("ITMW_NAGELKEULE", w(  450,  40, Blunt, 70, str(30),  "ItMw_1h_Bau_Mace.3DS",            "Palka z kolcami"))
phoenix.item.register("ITMW_ADDON_BANDITTRADER", w(  250,  40, Edge , 70, dex(20),  "ItMw_1H_Special_02.3DS",          "Palasz bandytow"))
phoenix.item.register("ITMW_1H_VLK_SWORD", w(  500,  40, Edge , 70, dex(20),  "ItMw_1h_Vlk_Sword.3DS",           "Miecz"))
phoenix.item.register("ITMW_1H_COMMON_01"                  , w(  450,  40, Edge , 90, str(30),  "ItMw_1h_Common_01.3DS",           "Prosty miecz"))
phoenix.item.register("ITMW_SHORTSWORD4", w(  550,  45, Edge , 50, str(22),  "ItMw_1h_Misc_Sword.3DS",          "Wilczy kiel"))
phoenix.item.register("ITMW_1H_NOV_MACE", w(  500,  30, Blunt,130, str(15),  "ItMw_1h_Nov_Mace.3DS",            "Pika bojowa"))
phoenix.item.register("ITMW_KRIEGSKEULE", w(  500,  50, Blunt, 50, str(50),  "ItMw_1h_Misc_Mace.3DS",           "Palka bojowa"))
phoenix.item.register("ITMW_SHORTSWORD5", w(  750,  50, Edge , 50, str(25),  "ItMw_1h_Special_02.3DS",          "Dobry krotki miecz"))
phoenix.item.register("ITMW_KRIEGSHAMMER1", w(  550,  55, Blunt, 40, str(55),  "ItMw_1h_Misc_War_Hammer.3DS",     "Mlot wojenny"))
phoenix.item.register("ITMW_SCHIFFSAXT", w(  600,  60, Edge , 70, str(60),  "ItMw_1h_Sld_Axe.3DS",             "Topor marynarski"))
phoenix.item.register("ITMW_PIRATENSAEBEL", w(  700,  65, Edge , 70, str(60),  "ItMw_1H_Special_04.3DS",          "Piracki kordelas"))
phoenix.item.register("ITMW_ADDON_PIR1HAXE", w(  600,  60, Edge , 60, str(60),  "ItMw_1H_Addon_PIR_1H_01.3DS",     "Topor pokladowy"))
phoenix.item.register("ITMW_ADDON_PIR1HSWORD", w(  600,  60, Edge , 70, str(60),  "ItMw_1H_Addon_PIR_1H_02.3DS",     "Kordelas"))
phoenix.item.register("ITMW_1H_PAL_SWORD"                  , w(  600,  60, Edge , 70, str(60),  "ItMw_1h_Pal_Sword.3DS",           "Miecz paladyna"))
phoenix.item.register("ITMW_NAGELKEULE2", w(  600,  60, Blunt, 60, str(60),  "ItMw_1h_Misc_Mace.3DS",           "Ciezka palka z kolcami"))
phoenix.item.register("ITMW_ADDON_HACKER_1H_02", w(  600,  60, Edge , 70, str(60),  "ItMw_1h_MISC_Sword.3DS",          "Stara maczeta"))
phoenix.item.register("ITMW_SCHWERT", w(  650,  65, Edge , 90, str(65),  "ItMw_1h_Vlk_Sword.3DS",           "Kiepski dlugi miecz"))
phoenix.item.register("ITMW_1H_SPECIAL_01"                 , w(  750,  60, Edge , 90, str(40),  "ItMw_1H_Special_01.3DS",          "Rzadki miecz"))
phoenix.item.register("ITMW_SCHWERT1", w(  750,  60, Edge , 70, str(50),  "ItMw_1H_Special_03.3DS",          "Dobry miecz"))
phoenix.item.register("ITMW_SPICKER", w(  700,  70, Blunt, 60, str(70),  "ItMw_1h_Spicker.3DS",             "Rebiczerep"))
phoenix.item.register("ITMW_STEINBRECHER", w(  800,  80, Blunt, 50, str(80),  "ItMw_1h_Misc_War_Hammer.3DS",     "Oskard"))
phoenix.item.register("ITMW_SCHWERT2", w(  850,  85, Edge , 90, str(85),  "ItMw_1H_Special_04.3DS",          "Dlugi miecz"))
phoenix.item.register("ITMW_SCHWERT3", w(  850,  90, Edge ,100, str(95),  "ItMw_1h_Special_02.3DS",          "Kiepski miecz poltorareczny"))
phoenix.item.register("ITMW_BARTAXT", w(  900,  90, Edge , 70, str(90),  "ItMw_1h_Misc_Axe.3DS",            "Wielki topor"))
phoenix.item.register("ITMW_DOPPELAXT", w(  900,  90, Edge , 70, str(90),  "ItMw_1h_Misc_Axe.3DS",            "Topor obosieczny"))
phoenix.item.register("ITMW_MORGENSTERN", w(  900,  90, Blunt, 60, str(90),  "ItMw_1H_Special_03.3DS",          "Bulawa i lancuch"))
phoenix.item.register("ITMW_SCHWERT4", w(  900,  80, Edge , 90, str(70),  "ItMw_1H_Special_04.3DS",          "Dobry dlugi miecz"))
phoenix.item.register("ITMW_ADDON_HACKER_1H_01", w( 1100, 100, Edge , 75, str(90),  "ItMw_1h_MISC_Sword.3DS",          "Maczeta"))
phoenix.item.register("ITMW_STREITKOLBEN", w( 1000, 100, Blunt, 60, str(100), "ItMw_1h_Misc_Mace.3DS",           "Bulawa"))
phoenix.item.register("ITMW_RUBINKLINGE"                   , w( 1200, 100, Edge , 70, str(90),  "ItMw_1h_Special_02.3DS",          "Rubinowe ostrze"))
phoenix.item.register("ITMW_1H_FERROSSWORD_MIS"            , w( 1200, 100, Edge , 90, str(80),  "ItMw_1H_Special_03.3DS",          "Miecz Ferrosa"))
phoenix.item.register("ITMW_1H_SPECIAL_02"                 , w( 1200, 100, Edge , 90, str(80),  "ItMw_1H_Special_02.3DS",          "Cenny miecz"))
phoenix.item.register("ITMW_1H_BLESSED_01", w( 2000, 100, Edge ,100, str(100), "ItMw_1h_Blessed_01.3DS",          "Kiepskie ostrze magiczne"))
phoenix.item.register("ITMW_RAPIER"                        , w( 2000, 100, Edge , 70, dex(50),  "ItMw_1h_Special_03.3DS",          "Rapier"))
phoenix.item.register("ITMW_INQUISITOR"                    , w( 1100, 110, Edge , 60, str(110), "ItMw_1H_Special_04.3DS",          "Inkwizytor"))
phoenix.item.register("ITMW_RABENSCHNABEL", w( 1100, 110, Blunt, 60, str(110), "ItMw_1h_Misc_War_Hammer.3DS",     "Kruczy Dziob"))
phoenix.item.register("ITMW_SCHWERT5", w( 1100, 110, Edge ,100, str(110), "ItMw_1h_Special_02.3DS",          "Dobry miecz poltorareczny"))
phoenix.item.register("ITMW_RUNENSCHWERT", w( 1100, 110, Edge , 90, str(110), "ItMw_1h_Misc_Sword.3DS",          "Miecz runiczny"))
phoenix.item.register("ITMW_KRIEGSHAMMER2", w( 1200, 120, Blunt, 60, str(120), "ItMw_1H_Special_01.3DS",          "Ciezki mlot wojenny"))
phoenix.item.register("ITMW_FOLTERAXT", w( 1250, 125, Edge , 80, str(125), "ItMw_1h_Misc_Axe.3DS",            "Katowski topor"))
phoenix.item.register("ITMW_MEISTERDEGEN", w( 2400, 120, Edge ,100, dex(60),  "ItMw_1h_Special_02.3DS",          "Miecz mistrzowski"))
phoenix.item.register("ITMW_ELBASTARDO"                    , w( 1300, 120, Edge ,100, str(110), "ItMw_1H_Special_04.3DS",          "El Bastardo"))
phoenix.item.register("ITMW_ADDON_BETTY"                   , w( 1300, 130, Edge ,100, dex(110), "ItMw_1H_Addon_Betty.3DS",         "Betty"))
phoenix.item.register("ITMW_ORKSCHLAECHTER", w( 1300, 130, Edge ,100, str(130), "ItMw_1h_Misc_Sword.3DS",          "Orkowa Zguba"))
phoenix.item.register("ITMW_KRUMMSCHWERT", w( 1450, 145, Edge ,120, str(145), "ItMw_1h_Special_02.3DS",          "Kordelas"))
phoenix.item.register("ITMW_1H_SPECIAL_03"                 , w( 1500, 140, Edge ,100, str(120), "ItMw_1H_Special_03.3DS",          "Mistrzowski miecz"))
phoenix.item.register("ITMW_1H_SPECIAL_04"                 , w( 1800, 160, Edge ,100, str(140), "ItMw_1H_Special_04.3DS",          "Klinga mistrza"))
phoenix.item.register("ITMW_1H_BLESSED_02", w( 3000, 120, Edge ,100, str(100), "ItMw_1h_Blessed_02.3DS",          "Blogoslawione ostrze magiczne"))
phoenix.item.register("ITMW_1H_BLESSED_03", w( 4000, 140, Edge ,100, str(100), "ItMw_1h_Blessed_03.3DS",          "Gniew Innosa"))
phoenix.item.register("ITMW_FRANCISDAGGER_MIS", w(    0,   5, Edge , 50, str(5),   "Itmw_005_1h_dagger_01.3DS",       "Zloty sztylet"))
phoenix.item.register("ITMW_MALETHSGEHSTOCK_MIS"           , w(   10,   8, Blunt, 70, str(5),   "Itmw_008_1h_pole_01.3DS",         "Laska Maletha"))

