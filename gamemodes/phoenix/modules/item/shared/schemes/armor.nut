

local Armor = PhoenixItemCategory.Armor
local SlotArmor = PhoenixItemSlot.Armor

local function arm(value, b, e, p, f, m) {
	return {
		category   = Armor,
		slot       = SlotArmor,
		value      = value,
		protection = { blunt = b, edge = e, point = p, fire = f, magic = m }
	}
}

phoenix.item.register("ITAR_BARKEEPER",         arm(0,     10,  10,  10,   0,   0))
phoenix.item.register("ITAR_BAU_L",             arm(80,    15,  15,  15,   0,   0))
phoenix.item.register("ITAR_BAU_M",             arm(100,   15,  15,  15,   0,   0))
phoenix.item.register("ITAR_BAUBABE_L",         arm(0,     10,  10,  10,   0,   0))
phoenix.item.register("ITAR_BAUBABE_M",         arm(0,     10,  10,  10,   0,   0))
phoenix.item.register("ITAR_BDT_H",             arm(2100,  50,  50,  50,   0,   0))
phoenix.item.register("ITAR_BDT_M",             arm(550,   35,  35,  35,   0,   0))
phoenix.item.register("ITAR_BLOODWYN_ADDON",    arm(1300,  70,  70,  70,   0,   0))
phoenix.item.register("ITAR_CORANGAR",          arm(600,  100, 100, 100,  50,  25))
phoenix.item.register("ITAR_DEMENTOR",          arm(500,  130, 130, 130,  65,  65))
phoenix.item.register("ITAR_DIEGO",             arm(450,   30,  30,  30,   0,   0))
phoenix.item.register("ITAR_DJG_BABE",          arm(0,     60,  60,  60,  30,   0))
phoenix.item.register("ITAR_DJG_CRAWLER",       arm(1500,  70,  70,  70,  15,   0))
phoenix.item.register("ITAR_DJG_H",             arm(20000,150, 150, 150, 100,  50))
phoenix.item.register("ITAR_DJG_L",             arm(3000, 100, 100, 100,  50,  25))
phoenix.item.register("ITAR_DJG_M",             arm(12000,120, 120, 120,  75,  35))
phoenix.item.register("ITAR_FAKE_RANGER",       arm(1300,   0,   0,   0,   0,   0))
phoenix.item.register("ITAR_FIREARMOR_ADDON",   arm(15000,100, 100, 100,  50,  50))
phoenix.item.register("ITAR_GOVERNOR",          arm(1100,  40,  40,  40,   0,   0))
phoenix.item.register("ITAR_JUDGE",             arm(0,     10,  10,  10,   0,   0))
phoenix.item.register("ITAR_KDF_H",             arm(3000, 100, 100, 100,  50,  50))
phoenix.item.register("ITAR_KDF_L",             arm(500,   40,  40,  40,  20,  20))
phoenix.item.register("ITAR_KDW_H",             arm(450,  100, 100, 100,  50,  50))
phoenix.item.register("ITAR_KDW_L_ADDON",       arm(1300,  50,  50,  50,  25,  25))
phoenix.item.register("ITAR_LEATHER_L",         arm(250,   25,  25,  20,   5,   0))
phoenix.item.register("ITAR_LESTER",            arm(300,   25,  25,  25,   0,   0))
phoenix.item.register("ITAR_MAYAZOMBIE_ADDON",  arm(0,     50,  50,  50,  50,  50))
phoenix.item.register("ITAR_MIL_L",             arm(600,   40,  40,  40,   0,   0))
phoenix.item.register("ITAR_MIL_M",             arm(2500,  70,  70,  70,  10,  10))
phoenix.item.register("ITAR_NOV_L",             arm(280,   25,  25,  25,   0,  10))
phoenix.item.register("ITAR_OREBARON_ADDON",    arm(1300,  70,  70,  70,   0,   0))
phoenix.item.register("ITAR_PAL_H",             arm(20000,150, 150, 150, 100,  50))
phoenix.item.register("ITAR_PAL_M",             arm(5000, 100, 100, 100,  50,  25))
phoenix.item.register("ITAR_PAL_SKEL",          arm(500,  100, 100, 100,  50,  50))
phoenix.item.register("ITAR_PIR_H_ADDON",       arm(1500,  60,  60,  60,   0,   0))
phoenix.item.register("ITAR_PIR_L_ADDON",       arm(1100,  40,  40,  40,   0,   0))
phoenix.item.register("ITAR_PIR_M_ADDON",       arm(1300,  55,  55,  55,   0,   0))
phoenix.item.register("ITAR_PRISONER",          arm(10,    20,  20,  20,   0,   0))
phoenix.item.register("ITAR_RANGER_ADDON",      arm(1300,  50,  50,  50,   0,  10))
phoenix.item.register("ITAR_RAVEN_ADDON",       arm(1300, 100, 100, 100, 100, 100))
phoenix.item.register("ITAR_SLD_H",             arm(2500,  80,  80,  80,   5,  10))
phoenix.item.register("ITAR_SLD_L",             arm(500,   30,  30,  30,   0,   0))
phoenix.item.register("ITAR_SLD_M",             arm(1000,  50,  50,  50,   0,   5))
phoenix.item.register("ITAR_SMITH",             arm(0,     15,  15,  15,   5,   0))
phoenix.item.register("ITAR_THORUS_ADDON",      arm(1300,  70,  70,  70,   0,   0))
phoenix.item.register("ITAR_VLK_H",             arm(120,   10,  10,  10,   0,   0))
phoenix.item.register("ITAR_VLK_L",             arm(120,   10,  10,  10,   0,   0))
phoenix.item.register("ITAR_VLK_M",             arm(120,   10,  10,  10,   0,   0))

phoenix.item.register("ITAR_XARDAS",            arm(15000,100, 100, 100,  50,  50))
