

local function bow(value, dmg, dtype, reqs) {
	return {
		category    = PhoenixItemCategory.Bow,
		slot        = PhoenixItemSlot.Ranged,
		value       = value, damage = dmg, damageType = dtype,
		requirement = reqs
	}
}
local function cb(value, dmg, dtype, reqs) {
	return {
		category    = PhoenixItemCategory.Crossbow,
		slot        = PhoenixItemSlot.Ranged,
		value       = value, damage = dmg, damageType = dtype,
		requirement = reqs
	}
}
local function ammo(value) {
	return {
		category = PhoenixItemCategory.Ammo,
		value    = value,
		stackMax = 999,
		flags    = PhoenixItemFlag.Stackable
	}
}

phoenix.item.register("ITRW_ADDON_FIREARROW"            , ammo(  1))
phoenix.item.register("ITRW_ADDON_FIREBOW"              , bow( 2000,   50, PhoenixDamageType.Magic     , [{ attr = "dexterity", value = 25 }]))
phoenix.item.register("ITRW_ADDON_MAGICARROW"           , ammo(  1))
phoenix.item.register("ITRW_ADDON_MAGICBOLT"            , ammo(  1))
phoenix.item.register("ITRW_ADDON_MAGICBOW"             , bow( 2000,  100, PhoenixDamageType.Magic     , [{ attr = "dexterity", value = 50 }]))
phoenix.item.register("ITRW_ADDON_MAGICCROSSBOW"        , cb( 2000,  200, PhoenixDamageType.Magic     , [{ attr = "strength",  value = 75 }]))
phoenix.item.register("ITRW_ARROW"                      , ammo(  1))
phoenix.item.register("ITRW_BOLT"                       , ammo(  1))
phoenix.item.register("ITRW_BOW_H_01"                   , bow( 1300,  125, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 120 }]))
phoenix.item.register("ITRW_BOW_H_02"                   , bow( 1400,  140, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 140 }]))
phoenix.item.register("ITRW_BOW_H_03"                   , bow( 1500,  150, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 150 }]))
phoenix.item.register("ITRW_BOW_H_04"                   , bow( 1600,  160, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 160 }]))
phoenix.item.register("ITRW_BOW_L_01"                   , bow(  100,   15, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 10 }]))
phoenix.item.register("ITRW_BOW_L_02"                   , bow(  150,   25, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 20 }]))
phoenix.item.register("ITRW_BOW_L_03"                   , bow(  400,   35, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 30 }]))
phoenix.item.register("ITRW_BOW_L_03_MIS"               , bow(  400,   35, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 30 }]))
phoenix.item.register("ITRW_BOW_L_04"                   , bow(  500,   50, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 50 }]))
phoenix.item.register("ITRW_BOW_M_01"                   , bow(  700,   65, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 60 }]))
phoenix.item.register("ITRW_BOW_M_02"                   , bow(  800,   80, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 80 }]))
phoenix.item.register("ITRW_BOW_M_03"                   , bow( 1000,   95, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 90 }]))
phoenix.item.register("ITRW_BOW_M_04"                   , bow( 1100,  110, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 110 }]))
phoenix.item.register("ITRW_CROSSBOW_H_01"              , cb( 2000,  150, PhoenixDamageType.Point     , [{ attr = "strength",  value = 120 }]))
phoenix.item.register("ITRW_CROSSBOW_H_02"              , cb( 2500,  180, PhoenixDamageType.Point     , [{ attr = "strength",  value = 150 }]))
phoenix.item.register("ITRW_CROSSBOW_L_01"              , cb(  500,   30, PhoenixDamageType.Point     , [{ attr = "strength",  value = 20 }]))
phoenix.item.register("ITRW_CROSSBOW_L_02"              , cb(  900,   60, PhoenixDamageType.Point     , [{ attr = "strength",  value = 40 }]))
phoenix.item.register("ITRW_CROSSBOW_M_01"              , cb( 1200,   90, PhoenixDamageType.Point     , [{ attr = "strength",  value = 60 }]))
phoenix.item.register("ITRW_CROSSBOW_M_02"              , cb( 1500,  120, PhoenixDamageType.Point     , [{ attr = "strength",  value = 90 }]))
phoenix.item.register("ITRW_DRAGOMIRSARMBRUST_MIS"      , cb(  900,   60, PhoenixDamageType.Point     , [{ attr = "strength",  value = 40 }]))
phoenix.item.register("ITRW_MIL_CROSSBOW"               , cb(  200,   45, PhoenixDamageType.Point     , [{ attr = "strength",  value = 30 }]))
phoenix.item.register("ITRW_SENGRATHSARMBRUST_MIS"      , cb(  200,   45, PhoenixDamageType.Point     , [{ attr = "strength",  value = 30 }]))
phoenix.item.register("ITRW_SLD_BOW"                    , bow(  200,   30, PhoenixDamageType.Point     , [{ attr = "dexterity", value = 25 }]))

