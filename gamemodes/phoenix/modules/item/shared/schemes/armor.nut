local Armor     = PhoenixItemCategory.Armor
local SlotArmor = PhoenixItemSlot.Armor

local function arm(value, b, e, p, f, m, visual, name) {
	return {
		category   = Armor,
		slot       = SlotArmor,
		value      = value,
		protection = { blunt = b, edge = e, point = p, fire = f, magic = m },
		visual     = visual,
		name       = name
	}
}

phoenix.item.register("ITAR_BAU_L", arm(   80,  15,  15,  15,   0,   0, "ITAR_BAU_L.ASC",             "Stroj farmera 1"))
phoenix.item.register("ITAR_BAU_M", arm(  100,  15,  15,  15,   0,   0, "ITAR_BAU_M.ASC",             "Stroj farmera 2"))
phoenix.item.register("ITAR_BAUBABE_L", arm(    0,  10,  10,  10,   0,   0, "ITAR_BAUBABE_L.ASC",         "Suknia farmerki 1"))
phoenix.item.register("ITAR_BAUBABE_M", arm(    0,  10,  10,  10,   0,   0, "ITAR_BAUBABE_M.ASC",         "Suknia farmerki 2"))
phoenix.item.register("ITAR_BARKEEPER", arm(    0,  10,  10,  10,   0,   0, "ITAR_BARKEEPER.ASC",         "Stroj ziemianina"))
phoenix.item.register("ITAR_PRISONER", arm(   10,  20,  20,  20,   0,   0, "ITAR_PRISONER.ASC",          "Lachy skazanca"))
phoenix.item.register("ITAR_VLK_L", arm(  120,  10,  10,  10,   0,   0, "ITAR_VLK_L.ASC",             "Stroj obywatela"))
phoenix.item.register("ITAR_VLK_M", arm(  120,  10,  10,  10,   0,   0, "ITAR_VLK_M.ASC",             "Stroj obywatela"))
phoenix.item.register("ITAR_VLK_H", arm(  120,  10,  10,  10,   0,   0, "ITAR_VLK_H.ASC",             "Stroj obywatela"))
phoenix.item.register("ITAR_SMITH", arm(    0,  15,  15,  15,   5,   0, "ITAR_SMITH.ASC",             "Stroj kowala"))
phoenix.item.register("ITAR_LESTER",            arm(  300,  25,  25,  25,   0,   0, "ITAR_LESTER.ASC",            "Szata Lestera"))
phoenix.item.register("ITAR_LEATHER_L", arm(  250,  25,  25,  20,   5,   0, "ITAR_LEATHER_L.ASC",         "Skorzany pancerz"))
phoenix.item.register("ITAR_DIEGO", arm(  450,  30,  30,  30,   0,   0, "ITAR_DIEGO.ASC",             "Pancerz Diega"))
phoenix.item.register("ITAR_NOV_L",             arm(  280,  25,  25,  25,   0,  10, "ITAR_NOV_L.ASC",             "Szata nowicjusza"))
phoenix.item.register("ITAR_KDF_L",             arm(  500,  40,  40,  40,  20,  20, "ITAR_KDF_L.ASC",             "Szata maga Ognia"))
phoenix.item.register("ITAR_KDF_H", arm( 3000, 100, 100, 100,  50,  50, "ITAR_KDF_H.ASC",             "Ciezka szata ognia"))
phoenix.item.register("ITAR_KDW_L_ADDON", arm( 1300,  50,  50,  50,  25,  25, "ITAR_KDW_L.ASC",             "Lekka toga Maga Wody"))
phoenix.item.register("ITAR_KDW_H", arm(  450, 100, 100, 100,  50,  50, "ITAR_KDW_H.ASC",             "Szata Maga Wody"))
phoenix.item.register("ITAR_GOVERNOR", arm( 1100,  40,  40,  40,   0,   0, "ITAR_GOVERNOR.ASC",          "Kaftan gubernatora"))
phoenix.item.register("ITAR_JUDGE",             arm(    0,  10,  10,  10,   0,   0, "ITAR_JUDGE.ASC",             "Szata sedziego"))

phoenix.item.register("ITAR_MIL_L", arm(  600,  40,  40,  40,   0,   0, "ITAR_MIL_L.ASC",             "Lekki pancerz strazy"))
phoenix.item.register("ITAR_MIL_M", arm( 2500,  70,  70,  70,  10,  10, "ITAR_MIL_M.ASC",             "Ciezki pancerz strazy"))
phoenix.item.register("ITAR_PAL_M", arm( 5000, 100, 100, 100,  50,  25, "ITAR_PAL_M.ASC",             "Pancerz rycerza"))
phoenix.item.register("ITAR_PAL_H", arm(20000, 150, 150, 150, 100,  50, "ITAR_PAL_H.ASC",             "Pancerz paladyna"))
phoenix.item.register("ITAR_SLD_L", arm(  500,  30,  30,  30,   0,   0, "ITAR_SLD_L.ASC",             "Lekki pancerz najemnika"))
phoenix.item.register("ITAR_SLD_M", arm( 1000,  50,  50,  50,   0,   5, "ITAR_SLD_M.ASC",             "Sredni pancerz najemnika"))
phoenix.item.register("ITAR_SLD_H", arm( 2500,  80,  80,  80,   5,  10, "ITAR_SLD_H.ASC",             "Ciezki pancerz najemnika"))
phoenix.item.register("ITAR_DJG_L", arm( 3000, 100, 100, 100,  50,  25, "ITAR_DJG_L.ASC",             "Lekki pancerz lowcy smokow"))
phoenix.item.register("ITAR_DJG_M", arm(12000, 120, 120, 120,  75,  35, "ITAR_DJG_M.ASC",             "Sredni pancerz lowcy smokow"))
phoenix.item.register("ITAR_DJG_H", arm(20000, 150, 150, 150, 100,  50, "ITAR_DJG_H.ASC",             "Ciezki pancerz lowcy smokow"))
phoenix.item.register("ITAR_DJG_CRAWLER", arm( 1500,  70,  70,  70,  15,   0, "ITAR_DJG_CRAWLER.ASC",       "Zbroja z pancerzy pelzaczy"))
phoenix.item.register("ITAR_DJG_BABE", arm(    0,  60,  60,  60,  30,   0, "ITAR_DJG_BABE.ASC",          "Kobiecy pancerz lowcy smokow"))
phoenix.item.register("ITAR_BDT_M", arm(  550,  35,  35,  35,   0,   0, "ITAR_BDT_M.ASC",             "Sredni pancerz bandyty"))
phoenix.item.register("ITAR_BDT_H", arm( 2100,  50,  50,  50,   0,   0, "ITAR_BDT_H.ASC",             "Ciezki pancerz bandyty"))
phoenix.item.register("ITAR_PIR_L_ADDON", arm( 1100,  40,  40,  40,   0,   0, "ITAR_PIR_L.ASC",             "Pirackie ubranie"))
phoenix.item.register("ITAR_PIR_M_ADDON", arm( 1300,  55,  55,  55,   0,   0, "ITAR_PIR_M.ASC",             "Piracka zbroja"))
phoenix.item.register("ITAR_PIR_H_ADDON", arm( 1500,  60,  60,  60,   0,   0, "ITAR_PIR_H.ASC",             "Ubranie kapitana"))
phoenix.item.register("ITAR_RANGER_ADDON", arm( 1300,  50,  50,  50,   0,  10, "ITAR_RANGER.ASC",            "Zbroja Wodnego Kregu"))
phoenix.item.register("ITAR_FAKE_RANGER", arm( 1300,   0,   0,   0,   0,   0, "ITAR_RANGER.ASC",            "Zniszczona zbroja"))
phoenix.item.register("ITAR_OREBARON_ADDON", arm( 1300,  70,  70,  70,   0,   0, "ITAR_OREBARON.ASC",          "Zbroja magnata"))
phoenix.item.register("ITAR_THORUS_ADDON", arm( 1300,  70,  70,  70,   0,   0, "ITAR_THORUS.ASC",            "Ciezka zbroja gwardzisty"))
phoenix.item.register("ITAR_BLOODWYN_ADDON",    arm( 1300,  70,  70,  70,   0,   0, "ITAR_BLOODWYN.ASC",          "Zbroja Bloodwyna"))
phoenix.item.register("ITAR_RAVEN_ADDON",       arm( 1300, 100, 100, 100, 100, 100, "ITAR_RAVEN.ASC",             "Zbroja Kruka"))
phoenix.item.register("ITAR_FIREARMOR_ADDON", arm(15000, 100, 100, 100,  50,  50, "ITAR_FIREARMOR.ASC",         "Magiczna zbroja"))
phoenix.item.register("ITAR_MAYAZOMBIE_ADDON", arm(    0,  50,  50,  50,  50,  50, "ITAR_MAYAZOMBIE.ASC",        "Stara zbroja"))
phoenix.item.register("ITAR_PAL_SKEL", arm(  500, 100, 100, 100,  50,  50, "ITAR_PAL_SKEL.ASC",          "Stara rycerska zbroja"))
phoenix.item.register("ITAR_DEMENTOR", arm(  500, 130, 130, 130,  65,  65, "ITAR_DEMENTOR.ASC",          "Mroczny plaszcz"))
phoenix.item.register("ITAR_CORANGAR", arm(  600, 100, 100, 100,  50,  25, "ITAR_CORANGAR.ASC",          "Pancerz Cor Angara"))
phoenix.item.register("ITAR_XARDAS", arm(15000, 100, 100, 100,  50,  50, "ITAR_XARDAS.ASC",            "Szata Mrocznej Magii"))

