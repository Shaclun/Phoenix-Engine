
const int Value_ItAm_Addon_Franco = 1200;
const int HP_ItAm_Addon_Franco = 40;
const int STR_Franco = 4;
const int DEX_Franco = 4;
const int Value_ItRi_Addon_Health_01 = 400;
const int Value_ItAm_Addon_Health = 800;
const int Value_ItRi_Addon_Mana_01 = 1000;
const int Value_ItAm_Addon_Mana = 2000;
const int Value_ItRi_Addon_STR_01 = 500;
const int Value_ItAm_Addon_STR = 1000;
const int HP_Ring_Solo_Bonus = 20;
const int HP_Ring_Double_Bonus = 60;
const int HP_Amulett_Solo_Bonus = 40;
const int HP_Amulett_EinRing_Bonus = 80;
const int HP_Amulett_Artefakt_Bonus = 160;
const int MA_Ring_Solo_Bonus = 5;
const int MA_Ring_Double_Bonus = 15;
const int MA_Amulett_Solo_Bonus = 10;
const int MA_Amulett_EinRing_Bonus = 20;
const int MA_Amulett_Artefakt_Bonus = 40;
const int STR_Ring_Solo_Bonus = 5;
const int STR_Ring_Double_Bonus = 15;
const int STR_Amulett_Solo_Bonus = 10;
const int STR_Amulett_EinRing_Bonus = 20;
const int STR_Amulett_Artefakt_Bonus = 40;

instance ItAm_Addon_Franco(C_Item)
{
	name = NAME_Amulett;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_AMULET;
	value = Value_ItAm_Addon_Franco;
	visual = "ItAm_Hp_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Amulet Franka";
	text[2] = NAME_Bonus_Str;
	count[2] = STR_Franco;
	text[3] = NAME_Bonus_Dex;
	count[3] = DEX_Franco;
	text[4] = NAME_Bonus_HP;
	count[4] = HP_ItAm_Addon_Franco;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
};


instance ItAm_Addon_Health(C_Item)
{
	name = NAME_Amulett;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_AMULET;
	value = Value_ItAm_Addon_Health;
	visual = "ItAm_Hp_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Amulet Uzdrowiciela";
	text[2] = NAME_Bonus_HP;
	count[2] = HP_Amulett_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
};

instance ItRi_Addon_Health_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_ItRi_Addon_Health_01;
	visual = "ItRi_Prot_Total_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ Uzdrowiciela";
	text[2] = NAME_Bonus_HP;
	count[2] = HP_Ring_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Addon_Health_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_ItRi_Addon_Health_01;
	visual = "ItRi_Prot_Total_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ Uzdrowiciela";
	text[2] = NAME_Bonus_HP;
	count[2] = HP_Ring_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItAm_Addon_MANA(C_Item)
{
	name = NAME_Amulett;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_AMULET;
	value = Value_ItAm_Addon_Mana;
	visual = "ItAm_Hp_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Amulet Kap³ana";
	text[2] = NAME_Bonus_Mana;
	count[2] = MA_Amulett_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
};


instance ItRi_Addon_MANA_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_ItRi_Addon_Mana_01;
	visual = "ItRi_Prot_Total_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ Kap³ana";
	text[2] = NAME_Bonus_Mana;
	count[2] = MA_Ring_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Addon_MANA_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_ItRi_Addon_Mana_01;
	visual = "ItRi_Prot_Total_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ Kap³ana";
	text[2] = NAME_Bonus_Mana;
	count[2] = MA_Ring_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItAm_Addon_STR(C_Item)
{
	name = NAME_Amulett;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_AMULET;
	value = Value_ItAm_Addon_STR;
	visual = "ItAm_Hp_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Amulet Wojownika";
	text[2] = NAME_Prot_Edge;
	count[2] = STR_Amulett_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
};

instance ItRi_Addon_STR_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_ItRi_Addon_STR_01;
	visual = "ItRi_Prot_Total_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ Wojownika";
	text[2] = NAME_Prot_Edge;
	count[2] = STR_Ring_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Addon_STR_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_ItRi_Addon_STR_01;
	visual = "ItRi_Prot_Total_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ Wojownika";
	text[2] = NAME_Prot_Edge;
	count[2] = STR_Ring_Solo_Bonus;
	text[3] = PRINT_Addon_KUMU_01;
	text[4] = PRINT_Addon_KUMU_02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

