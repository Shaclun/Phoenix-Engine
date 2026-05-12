local Helmet = PhoenixItemCategory.Helmet
local SlotHelmet = PhoenixItemSlot.Helmet

local function he(value, b, e, p, f, m, visual, name) {
	return {
		category   = Helmet,
		slot       = SlotHelmet,
		value      = value,
		protection = { blunt = b, edge = e, point = p, fire = f, magic = m },
		visual     = visual,
		name       = name
	}
}

phoenix.item.register("ITAR_BAU_HELM"       , he(  50,  5,  5,  5,  0,  0, "ItAr_Bau_Helm.3DS",        "Slomiany kapelusz"))
phoenix.item.register("ITAR_MIL_HELM"       , he( 250, 15, 15, 15,  0,  0, "ItAr_Mil_Helm.3DS",        "Helm milicji"))
phoenix.item.register("ITAR_PAL_HELM"       , he(1000, 30, 30, 30, 20,  5, "ItAr_Pal_Helm.3DS",        "Helm paladyna"))
phoenix.item.register("ITAR_SLD_HELM"       , he( 400, 20, 20, 20,  0,  5, "ItAr_Sld_Helm.3DS",        "Helm najemnika"))
phoenix.item.register("ITAR_BDT_HELM"       , he( 300, 15, 15, 15,  0,  0, "ItAr_Bdt_Helm.3DS",        "Helm bandyty"))
phoenix.item.register("ITAR_PIR_HELM"       , he( 300, 15, 15, 15,  0,  0, "ItAr_Pir_Helm.3DS",        "Bandana pirata"))
phoenix.item.register("ITAR_NOV_HOOD"       , he( 100, 10, 10, 10,  0,  5, "ItAr_Nov_Hood.3DS",        "Kaptur nowicjusza"))
phoenix.item.register("ITAR_KDF_HOOD"       , he( 250, 20, 20, 20, 10, 10, "ItAr_Kdf_Hood.3DS",        "Kaptur Maga Ognia"))
phoenix.item.register("ITAR_KDW_HOOD"       , he( 250, 20, 20, 20, 10, 10, "ItAr_Kdw_Hood.3DS",        "Kaptur Maga Wody"))
