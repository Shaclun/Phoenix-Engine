

local function w(value, dmg, dtype, range, reqs) {
	return {
		category    = PhoenixItemCategory.Weapon2H,
		slot        = PhoenixItemSlot.MainHand,
		value       = value,
		damage      = dmg,
		damageType  = dtype,
		requirement = reqs
	}
}

phoenix.item.register("ITMW_2H_AXE_L_01"                    , w(  300,   30, PhoenixDamageType.Edge      ,   60, [{ attr = "strength",  value = 10 }]))
phoenix.item.register("ITMW_2H_BAU_AXE"                     , w(  500,   50, PhoenixDamageType.Edge      ,   70, [{ attr = "strength",  value = 50 }]))
phoenix.item.register("ITMW_2H_BLESSED_01"                  , w( 2000,  120, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 120 }]))
phoenix.item.register("ITMW_2H_BLESSED_02"                  , w( 3000,  140, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 120 }]))
phoenix.item.register("ITMW_2H_BLESSED_03"                  , w( 4000,  160, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 120 }]))
phoenix.item.register("ITMW_2H_ORCAXE_01"                   , w(   10,   50, PhoenixDamageType.Edge      ,  100, [{ attr = "strength",  value = 70 }]))
phoenix.item.register("ITMW_2H_ORCAXE_02"                   , w(   15,   60, PhoenixDamageType.Edge      ,  110, [{ attr = "strength",  value = 80 }]))
phoenix.item.register("ITMW_2H_ORCAXE_03"                   , w(   20,   70, PhoenixDamageType.Edge      ,  110, [{ attr = "strength",  value = 90 }]))
phoenix.item.register("ITMW_2H_ORCAXE_04"                   , w(   25,   80, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 100 }]))
phoenix.item.register("ITMW_2H_ORCSWORD_01"                 , w(   25,   80, PhoenixDamageType.Edge      ,  100, [{ attr = "strength",  value = 100 }]))
phoenix.item.register("ITMW_2H_ORCSWORD_02"                 , w(   30,  100, PhoenixDamageType.Edge      ,  140, [{ attr = "strength",  value = 120 }]))
phoenix.item.register("ITMW_2H_PAL_SWORD"                   , w(  800,   80, PhoenixDamageType.Edge      ,  110, [{ attr = "strength",  value = 80 }]))
phoenix.item.register("ITMW_2H_ROD"                         , w(   60,   40, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 30 }]))
phoenix.item.register("ITMW_2H_SLD_AXE"                     , w(   60,   60, PhoenixDamageType.Edge      ,   80, [{ attr = "strength",  value = 70 }]))
phoenix.item.register("ITMW_2H_SLD_SWORD"                   , w(   60,   60, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 70 }]))
phoenix.item.register("ITMW_2H_SPECIAL_01"                  , w(  900,   80, PhoenixDamageType.Edge      ,  100, [{ attr = "strength",  value = 60 }]))
phoenix.item.register("ITMW_2H_SPECIAL_02"                  , w( 1500,  120, PhoenixDamageType.Edge      ,  110, [{ attr = "strength",  value = 100 }]))
phoenix.item.register("ITMW_2H_SPECIAL_03"                  , w( 1800,  160, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 140 }]))
phoenix.item.register("ITMW_2H_SPECIAL_04"                  , w( 2100,  180, PhoenixDamageType.Edge      ,  140, [{ attr = "strength",  value = 160 }]))
phoenix.item.register("ITMW_2H_SWORD_M_01"                  , w(   50,   50, PhoenixDamageType.Edge      ,  100, [{ attr = "strength",  value = 50 }]))
phoenix.item.register("ITMW_ADDON_HACKER_2H_01"             , w( 1100,  105, PhoenixDamageType.Edge      ,  105, [{ attr = "strength",  value = 100 }]))
phoenix.item.register("ITMW_ADDON_HACKER_2H_02"             , w(  700,   70, PhoenixDamageType.Edge      ,   95, [{ attr = "strength",  value = 70 }]))
phoenix.item.register("ITMW_ADDON_KEULE_2H_01"              , w( 1150,  115, PhoenixDamageType.Blunt     ,  130, [{ attr = "strength",  value = 115 }]))
phoenix.item.register("ITMW_ADDON_PIR2HAXE"                 , w(  700,   70, PhoenixDamageType.Edge      ,   80, [{ attr = "strength",  value = 70 }]))
phoenix.item.register("ITMW_ADDON_PIR2HSWORD"               , w(  700,   70, PhoenixDamageType.Edge      ,   80, [{ attr = "strength",  value = 70 }]))
phoenix.item.register("ITMW_ADDON_STAB01"                   , w(  900,   60, PhoenixDamageType.Blunt     ,  120, [{ attr = "strength",  value = 30 }]))
phoenix.item.register("ITMW_ADDON_STAB02"                   , w(  850,   55, PhoenixDamageType.Blunt     ,  110, []))
phoenix.item.register("ITMW_ADDON_STAB03"                   , w(  950,   65, PhoenixDamageType.Blunt     ,  120, [{ attr = "strength",  value = 35 }]))
phoenix.item.register("ITMW_ADDON_STAB04"                   , w( 1000,   70, PhoenixDamageType.Blunt     ,  130, [{ attr = "strength",  value = 40 }]))
phoenix.item.register("ITMW_ADDON_STAB05"                   , w( 1050,   75, PhoenixDamageType.Blunt     ,  130, [{ attr = "strength",  value = 45 }]))
phoenix.item.register("ITMW_BARBARENSTREITAXT"              , w( 1500,  150, PhoenixDamageType.Edge      ,   90, [{ attr = "strength",  value = 150 }]))
phoenix.item.register("ITMW_BERSERKERAXT"                   , w( 3000,  200, PhoenixDamageType.Edge      ,   90, [{ attr = "strength",  value = 170 }]))
phoenix.item.register("ITMW_DRACHENSCHNEIDE"                , w( 2900,  190, PhoenixDamageType.Edge      ,  120, [{ attr = "strength",  value = 160 }]))
phoenix.item.register("ITMW_HELLEBARDE"                     , w(  550,   55, PhoenixDamageType.Edge      ,   80, [{ attr = "strength",  value = 55 }]))
phoenix.item.register("ITMW_KRUMMSCHWERT"                   , w( 1450,  145, PhoenixDamageType.Edge      ,  120, [{ attr = "strength",  value = 145 }]))
phoenix.item.register("ITMW_RANGERSTAFF_ADDON"              , w(  900,   60, PhoenixDamageType.Blunt     ,  130, [{ attr = "strength",  value = 30 }]))
phoenix.item.register("ITMW_RICHTSTAB"                      , w(  600,   50, PhoenixDamageType.Edge      ,  110, [{ attr = "strength",  value = 35 }]))
phoenix.item.register("ITMW_SCHLACHTAXT"                    , w( 1400,  140, PhoenixDamageType.Edge      ,  100, [{ attr = "strength",  value = 140 }]))
phoenix.item.register("ITMW_STABKEULE"                      , w(  700,   70, PhoenixDamageType.Blunt     ,  130, [{ attr = "strength",  value = 70 }]))
phoenix.item.register("ITMW_STREITAXT1"                     , w(  800,   80, PhoenixDamageType.Edge      ,   70, [{ attr = "strength",  value = 80 }]))
phoenix.item.register("ITMW_STREITAXT2"                     , w( 1100,  110, PhoenixDamageType.Edge      ,  100, [{ attr = "strength",  value = 110 }]))
phoenix.item.register("ITMW_STURMBRINGER"                   , w( 1500,  150, PhoenixDamageType.Edge      ,  130, [{ attr = "strength",  value = 150 }]))
phoenix.item.register("ITMW_ZWEIHAENDER1"                   , w(  750,   75, PhoenixDamageType.Edge      ,  110, [{ attr = "strength",  value = 75 }]))
phoenix.item.register("ITMW_ZWEIHAENDER2"                   , w( 1050,  105, PhoenixDamageType.Edge      ,  100, [{ attr = "strength",  value = 105 }]))
phoenix.item.register("ITMW_ZWEIHAENDER3"                   , w( 1150,  115, PhoenixDamageType.Edge      ,  120, [{ attr = "strength",  value = 115 }]))
phoenix.item.register("ITMW_ZWEIHAENDER4"                   , w( 1350,  135, PhoenixDamageType.Edge      ,  120, [{ attr = "strength",  value = 135 }]))

