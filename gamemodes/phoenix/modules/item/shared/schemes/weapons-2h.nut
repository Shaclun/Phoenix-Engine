local Edge  = PhoenixDamageType.Edge
local Blunt = PhoenixDamageType.Blunt

local function w(value, dmg, dtype, range, reqs, visual, name) {
	return {
		category    = PhoenixItemCategory.Weapon2H,
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

phoenix.item.register("ITMW_2H_AXE_L_01", w(  300,  30, Edge ,  60, str(10),  "ItMw_2h_Axe_light_01.3DS",       "Kilof"))
phoenix.item.register("ITMW_2H_BAU_AXE", w(  500,  50, Edge ,  70, str(50),  "ItMw_2h_Axe_L_01.3DS",           "Topor drwala"))
phoenix.item.register("ItMw_2H_Sword_M_01"                 , w(   50,  50, Edge , 100, str(50),  "ItMw_2H_Sword_M_01.3DS",         "Dwureczny miecz"))
phoenix.item.register("ITMW_2H_SLD_SWORD", w(   60,  60, Edge , 130, str(70),  "ItMw_2H_Sld_Sword.3DS",          "Kiepski miecz dwureczny"))
phoenix.item.register("ITMW_2H_SLD_AXE", w(   60,  60, Edge ,  80, str(70),  "ItMw_2H_Sld_Axe.3DS",            "Kiepski topor bojowy"))
phoenix.item.register("ITMW_2H_ROD"                        , w(   60,  40, Edge , 130, str(30),  "ItMw_2h_Rod_01.3DS",             "Kij"))
phoenix.item.register("ITMW_ADDON_PIR2HAXE", w(  700,  70, Edge ,  80, str(70),  "ItMw_2H_Addon_Pir_Axe.3DS",      "Miazdzydeska"))
phoenix.item.register("ITMW_ADDON_PIR2HSWORD", w(  700,  70, Edge ,  80, str(70),  "ItMw_2H_Addon_Pir_Sword.3DS",    "Miecz pokladowy"))
phoenix.item.register("ITMW_ADDON_KEULE_2H_01", w( 1150, 115, Blunt, 130, str(115), "ItMw_2H_Addon_Keule_01.3DS",     "Sluga Burzy"))
phoenix.item.register("ITMW_ADDON_HACKER_2H_01", w( 1100, 105, Edge , 105, str(100), "ItMw_2H_Addon_Hacker_01.3DS",    "Wielka maczeta"))
phoenix.item.register("ITMW_ADDON_HACKER_2H_02", w(  700,  70, Edge ,  95, str(70),  "ItMw_2H_Addon_Hacker_02.3DS",    "Wielka, stara maczeta"))
phoenix.item.register("ITMW_ADDON_STAB01", w(  900,  60, Blunt, 120, str(30),  "ItMw_2H_Addon_Stab_01.3DS",      "Kostur maga"))
phoenix.item.register("ITMW_ADDON_STAB02", w(  850,  55, Blunt, 110, [],       "ItMw_2H_Addon_Stab_02.3DS",      "Magiczna rozdzka"))
phoenix.item.register("ITMW_ADDON_STAB03", w(  950,  65, Blunt, 120, str(35),  "ItMw_2H_Addon_Stab_03.3DS",      "Wodny kostur"))
phoenix.item.register("ITMW_ADDON_STAB04", w( 1000,  70, Blunt, 130, str(40),  "ItMw_2H_Addon_Stab_04.3DS",      "Kostur Ulthara"))
phoenix.item.register("ITMW_ADDON_STAB05", w( 1050,  75, Blunt, 130, str(45),  "ItMw_2H_Addon_Stab_05.3DS",      "Tajfun"))
phoenix.item.register("ITMW_RANGERSTAFF_ADDON", w(  900,  60, Blunt, 130, str(30),  "ItMw_2H_Addon_Stab_01.3DS",      "Pika bojowa Wodnego Kregu"))
phoenix.item.register("ITMW_HELLEBARDE"                    , w(  550,  55, Edge ,  80, str(55),  "ItMw_2H_Halberd.3DS",            "Halabarda"))
phoenix.item.register("ITMW_2H_PAL_SWORD", w(  800,  80, Edge , 110, str(80),  "ItMw_2H_Pal_Sword.3DS",          "Miecz dwureczny paladyna"))
phoenix.item.register("ITMW_2H_SPECIAL_01"                 , w(  900,  80, Edge , 100, str(60),  "ItMw_2H_Special_01.3DS",         "Rzadki dwureczny miecz"))
phoenix.item.register("ITMW_2H_SPECIAL_02"                 , w( 1500, 120, Edge , 110, str(100), "ItMw_2H_Special_02.3DS",         "Specjalny dwureczny miecz"))
phoenix.item.register("ITMW_2H_SPECIAL_03"                 , w( 1800, 160, Edge , 130, str(140), "ItMw_2H_Special_03.3DS",         "Mistrzowski dwureczny miecz"))
phoenix.item.register("ITMW_2H_SPECIAL_04"                 , w( 2100, 180, Edge , 140, str(160), "ItMw_2H_Special_04.3DS",         "Legendarny dwureczny miecz"))
phoenix.item.register("ITMW_BARBARENSTREITAXT", w( 1500, 150, Edge ,  90, str(150), "ItMw_2H_Axe_Barbarian.3DS",      "Barbarzynski topor bojowy"))
phoenix.item.register("ITMW_BERSERKERAXT"                  , w( 3000, 200, Edge ,  90, str(170), "ItMw_2H_Axe_Berserk.3DS",        "Topor berserkera"))
phoenix.item.register("ITMW_DRACHENSCHNEIDE", w( 2900, 190, Edge , 120, str(160), "ItMw_2H_Sword_Drake.3DS",        "Smocza Zguba"))
phoenix.item.register("ITMW_2H_BLESSED_01", w( 2000, 120, Edge , 130, str(120), "ItMw_2H_Blessed_01.3DS",         "Kiepskie ostrze magiczne"))
phoenix.item.register("ITMW_2H_BLESSED_02", w( 3000, 140, Edge , 130, str(120), "ItMw_2H_Blessed_02.3DS",         "Miecz Zakonu"))
phoenix.item.register("ITMW_2H_BLESSED_03", w( 4000, 160, Edge , 130, str(120), "ItMw_2H_Blessed_03.3DS",         "Swiety Kat"))
phoenix.item.register("ITMW_2H_ORCAXE_01", w(   10,  50, Edge , 100, str(70),  "ItMw_2h_OrcAxe_01.3DS",          "Lekki orkowy topor"))
phoenix.item.register("ITMW_2H_ORCAXE_02", w(   15,  60, Edge , 110, str(80),  "ItMw_2h_OrcAxe_02.3DS",          "Sredni orkowy topor"))
phoenix.item.register("ITMW_2H_ORCAXE_03", w(   20,  70, Edge , 110, str(90),  "ItMw_2h_OrcAxe_03.3DS",          "Ciezki orkowy topor"))
phoenix.item.register("ITMW_2H_ORCAXE_04", w(   25,  80, Edge , 130, str(100), "ItMw_2h_OrcAxe_04.3DS",          "Ogromny orkowy topor"))
phoenix.item.register("ITMW_2H_ORCSWORD_01", w(   25,  80, Edge , 100, str(100), "ItMw_2h_OrcSword_01.3DS",        "Jaszczurzy miecz"))
phoenix.item.register("ITMW_2H_ORCSWORD_02", w(   30, 100, Edge , 140, str(120), "ItMw_2h_OrcSword_02.3DS",        "Orkowy miecz wojenny"))
phoenix.item.register("ITMW_SCHLACHTAXT", w(  600, 140, Edge , 100, str(140), "ItMw_070_2h_axe_heavy_03.3DS",   "Topor wojenny"))

