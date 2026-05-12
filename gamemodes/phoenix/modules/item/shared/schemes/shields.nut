local Shield = PhoenixItemCategory.Shield
local SlotOff = PhoenixItemSlot.OffHand

local function sh(value, b, e, p, f, m, visual, name, reqs) {
	return {
		category   = Shield,
		slot       = SlotOff,
		value      = value,
		protection = { blunt = b, edge = e, point = p, fire = f, magic = m },
		visual     = visual,
		name       = name,
		requirement = reqs
	}
}
local function str(v) { return [{ attr = "strength", value = v }] }

phoenix.item.register("ITSH_WOOD_01"        , sh( 100, 10, 10, 10,  0,  0, "ItSh_Wood_01.3DS",        "Drewniany puklerz",     str(20)))
phoenix.item.register("ITSH_WOOD_02"        , sh( 250, 20, 20, 20,  0,  0, "ItSh_Wood_02.3DS",        "Drewniana tarcza",      str(40)))
phoenix.item.register("ITSH_METAL_01"       , sh( 500, 30, 30, 30,  0,  0, "ItSh_Metal_01.3DS",       "Zelazna tarcza",        str(60)))
phoenix.item.register("ITSH_METAL_02"       , sh( 800, 50, 50, 50,  5,  0, "ItSh_Metal_02.3DS",       "Stalowa tarcza",        str(80)))
phoenix.item.register("ITSH_PAL_SHIELD"     , sh(1500, 70, 70, 70, 20, 10, "ItSh_Pal_Shield.3DS",     "Tarcza paladyna",       str(100)))
