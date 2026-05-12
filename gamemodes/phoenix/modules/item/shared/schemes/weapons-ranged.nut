local Point = PhoenixDamageType.Point
local Magic = PhoenixDamageType.Magic
local Stackable = PhoenixItemFlag.Stackable

local function bow(value, dmg, dtype, reqs, visual, name) {
	return {
		category    = PhoenixItemCategory.Bow,
		slot        = PhoenixItemSlot.Ranged,
		value       = value, damage = dmg, damageType = dtype,
		requirement = reqs,
		visual      = visual,
		name        = name
	}
}
local function cb(value, dmg, dtype, reqs, visual, name) {
	return {
		category    = PhoenixItemCategory.Crossbow,
		slot        = PhoenixItemSlot.Ranged,
		value       = value, damage = dmg, damageType = dtype,
		requirement = reqs,
		visual      = visual,
		name        = name
	}
}
local function ammo(value, visual, name) {
	return {
		category = PhoenixItemCategory.Ammo,
		value    = value,
		stackMax = 999,
		flags    = Stackable,
		visual   = visual,
		name     = name
	}
}
local function dex(v) { return [{ attr = "dexterity", value = v }] }
local function str(v) { return [{ attr = "strength", value = v }] }

phoenix.item.register("ITRW_ARROW",                          ammo( 1, "ItAm_Arrow.3DS",                 "Strzala"))
phoenix.item.register("ITRW_BOLT",                           ammo( 1, "ItAm_Bolt.3DS",                  "Belt"))
phoenix.item.register("ITRW_ADDON_FIREARROW",                ammo( 1, "ItAm_Arrow.3DS",                 "Ognista strzala"))
phoenix.item.register("ITRW_ADDON_MAGICARROW",               ammo( 1, "ItAm_Arrow.3DS",                 "Magiczna strzala"))
phoenix.item.register("ITRW_ADDON_MAGICBOLT",                ammo( 1, "ItAm_Bolt.3DS",                  "Magiczny belt"))

phoenix.item.register("ITRW_BOW_L_01", bow(  100,  15, Point, dex( 10), "ItRw_Bow_L_01.3DS",                "Krotki luk"))
phoenix.item.register("ITRW_BOW_L_02", bow(  150,  25, Point, dex( 20), "ItRw_Bow_L_02.3DS",                "Luk wierzbowy"))
phoenix.item.register("ITRW_BOW_L_03", bow(  400,  35, Point, dex( 30), "ItRw_Bow_L_03.3DS",                "Luk mysliwski"))
phoenix.item.register("ITRW_BOW_L_03_MIS",                   bow(  400,  35, Point, dex( 30), "ItRw_Bow_L_03.3DS",                "Mysliwski luk"))
phoenix.item.register("ITRW_BOW_L_04", bow(  500,  50, Point, dex( 50), "ItRw_Bow_L_04.3DS",                "Luk z wiazu"))
phoenix.item.register("ITRW_BOW_M_01", bow(  700,  65, Point, dex( 60), "ItRw_Bow_M_01.3DS",                "Luk kompozytowy"))
phoenix.item.register("ITRW_BOW_M_02", bow(  800,  80, Point, dex( 80), "ItRw_Bow_M_02.3DS",                "Luk jesionowy"))
phoenix.item.register("ITRW_BOW_M_03", bow( 1000,  95, Point, dex( 90), "ItRw_Bow_M_03.3DS",                "Dlugi luk"))
phoenix.item.register("ITRW_BOW_M_04", bow( 1100, 110, Point, dex(110), "ItRw_Bow_M_04.3DS",                "Luk bukowy"))
phoenix.item.register("ITRW_BOW_H_01", bow( 1300, 125, Point, dex(120), "ItRw_Bow_H_01.3DS",                "Kosciany luk"))
phoenix.item.register("ITRW_BOW_H_02", bow( 1400, 140, Point, dex(140), "ItRw_Bow_H_02.3DS",                "Luk debowy"))
phoenix.item.register("ITRW_BOW_H_03", bow( 1500, 150, Point, dex(150), "ItRw_Bow_H_03.3DS",                "Luk wojenny"))
phoenix.item.register("ITRW_BOW_H_04", bow( 1600, 160, Point, dex(160), "ItRw_Bow_H_04.3DS",                "Smoczy luk"))
phoenix.item.register("ITRW_SLD_BOW", bow(  200,  30, Point, dex( 25), "ItRw_Bow_L_02.3DS",                "Luk"))
phoenix.item.register("ITRW_ADDON_FIREBOW",                  bow( 2000,  50, Magic, dex( 25), "ItRw_Bow_L_04.3DS",                "Ognisty luk"))
phoenix.item.register("ITRW_ADDON_MAGICBOW",                 bow( 2000, 100, Magic, dex( 50), "ItRw_Bow_H_02.3DS",                "Magiczny luk"))

phoenix.item.register("ITRW_MIL_CROSSBOW", cb(   200,  45, Point, str( 30), "ItRw_Crossbow_L_01.3DS",           "Kusza"))
phoenix.item.register("ITRW_CROSSBOW_L_01", cb(   500,  30, Point, str( 20), "ItRw_Crossbow_L_01.3DS",           "Kusza mysliwska"))
phoenix.item.register("ITRW_CROSSBOW_L_02", cb(   900,  60, Point, str( 40), "ItRw_Crossbow_L_02.3DS",           "Lekka kusza"))
phoenix.item.register("ITRW_CROSSBOW_M_01", cb(  1200,  90, Point, str( 60), "ItRw_Crossbow_M_01.3DS",           "Kusza"))
phoenix.item.register("ITRW_CROSSBOW_M_02",                  cb(  1500, 120, Point, str( 90), "ItRw_Crossbow_M_02.3DS",           "Kusza bojowa"))
phoenix.item.register("ITRW_CROSSBOW_H_01", cb(  2000, 150, Point, str(120), "ItRw_Crossbow_H_01.3DS",           "Ciezka kusza"))
phoenix.item.register("ITRW_CROSSBOW_H_02", cb(  2500, 180, Point, str(150), "ItRw_Crossbow_H_02.3DS",           "Kusza lowcy smokow"))
phoenix.item.register("ITRW_DRAGOMIRSARMBRUST_MIS",          cb(   900,  60, Point, str( 40), "ItRw_Crossbow_L_02.3DS",           "Kusza Dragomira"))
phoenix.item.register("ITRW_SENGRATHSARMBRUST_MIS",          cb(   200,  45, Point, str( 30), "ItRw_Crossbow_L_01.3DS",           "Kusza Sengratha"))
phoenix.item.register("ITRW_ADDON_MAGICCROSSBOW",            cb(  2000, 200, Magic, str( 75), "ItRw_Crossbow_H_02.3DS",           "Magiczna kusza"))

