
const int VALUE_BELIARW_1H_01 = 600;
const int DAMAGE_BELIARW_1H_01 = 90;
const int VALUE_BELIARW_2H_01 = 600;
const int DAMAGE_BELIARW_2H_01 = 100;


prototype BeliarWeaponPrototype_1H(C_Item)
{
	name = NAME_ADDON_BELIARSWEAPON;
	mainflag = ITEM_KAT_NF;
	flags = ITEM_SWD;
	material = MAT_METAL;
	damagetype = DAM_EDGE;
	range = Range_Orkschlaechter;
	cond_atr[2] = ATR_STRENGTH;
	cond_value[2] = 0;
	visual = "ItMw_BeliarWeapon_1H.3DS";
	effect = "SPELLFX_FIRESWORDBLACK";
	description = name;
	text[2] = NAME_OneHanded;
	text[3] = NAME_Damage;
	count[3] = damageTotal;
	text[4] = NAME_ADDON_ONEHANDED_BELIAR;
	text[5] = NAME_Value;
	count[5] = value;
};

instance ItMw_BeliarWeapon_1H(BeliarWeaponPrototype_1H)
{
	value = Value_BeliarW_1H_01;
	damageTotal = Damage_BeliarW_1H_01;
	count[5] = value;
	count[3] = damageTotal;
};

prototype BeliarWeaponPrototype_2H(C_Item)
{
	name = NAME_ADDON_BELIARSWEAPON;
	mainflag = ITEM_KAT_NF;
	flags = ITEM_2HD_SWD;
	material = MAT_METAL;
	damagetype = DAM_EDGE;
	range = Range_Drachenschneide;
	effect = "SPELLFX_FIRESWORDBLACK";
	cond_atr[2] = ATR_STRENGTH;
	cond_value[2] = 0;
	visual = "ItMw_BeliarWeapon_2H.3DS";
	description = name;
	text[2] = NAME_TwoHanded;
	text[3] = NAME_Damage;
	count[3] = damageTotal;
	text[4] = NAME_ADDON_TWOHANDED_BELIAR;
	text[5] = NAME_Value;
	count[5] = value;
};

instance ItMw_BeliarWeapon_2H(BeliarWeaponPrototype_2H)
{
	value = Value_BeliarW_2H_01;
	damageTotal = Damage_BeliarW_2H_01;
	count[5] = value;
	count[3] = damageTotal;
};