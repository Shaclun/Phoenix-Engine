
const int Value_ItBE_Addon_Leather_01 = 250;
const int Value_ItBE_Addon_Leather_02 = 250;
const int Value_ItBE_Addon_SLD_01 = 250;
const int Value_ItBE_Addon_NOV_01 = 250;
const int Value_ItBE_Addon_MIL_01 = 250;
const int Value_ItBE_Addon_KDF_01 = 250;
const int Value_ItBE_Addon_MC = 250;
const int Value_ItBE_Addon_STR_5 = 500;
const int Value_ItBE_Addon_STR_10 = 1000;
const int Value_ItBE_Addon_DEX_5 = 500;
const int Value_ItBE_Addon_DEX_10 = 1000;
const int Value_ItBE_Addon_Prot_Edge = 500;
const int Value_ItBE_Addon_Prot_Point = 500;
const int Value_ItBE_Addon_Prot_Magic = 500;
const int Value_ItBE_Addon_Prot_Fire = 500;
const int Value_ItBE_Addon_Prot_EdgPoi = 1000;
const int Value_ItBE_Addon_Prot_Total = 2000;
const int BA_Bonus01 = 5;
const int BA_Bonus02 = 5;
const int Belt_Prot_01 = 5;
const int BeltBonus_STR01 = 5;
const int BeltBonus_STR02 = 10;
const int BeltBonus_DEX01 = 5;
const int BeltBonus_DEX02 = 10;
const int BeltBonus_ProtEdge = 10;
const int BeltBonus_ProtPoint = 10;
const int BeltBonus_ProtMagic = 10;
const int BeltBonus_ProtFire = 10;
const int BeltBonus_ProtEdgPoi = 7;
const int BeltBonus_ProtTotal = 7;

instance ItBE_Addon_Leather_01(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_Leather_01;
	visual = "ItMI_Belt_06.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Skórzany pas";
	text[1] = NAME_Prot_Edge;
	count[1] = Belt_Prot_01;
	text[2] = NAME_Prot_Point;
	count[2] = Belt_Prot_01;
	text[3] = NAME_Addon_BeArLeather;
	count[3] = BA_Bonus01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBE_Addon_SLD_01(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_SLD_01;
	visual = "ItMi_Belt_05.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas najemnika";
	text[1] = NAME_Prot_Edge;
	count[1] = Belt_Prot_01;
	text[2] = NAME_Prot_Point;
	count[2] = Belt_Prot_01;
	text[3] = NAME_Addon_BeArSLD;
	count[3] = BA_Bonus01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBE_Addon_NOV_01(C_Item)
{
	name = NAME_Addon_BeltMage;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_NOV_01;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Szarfa Gotowoœci";
	text[1] = NAME_Prot_Edge;
	count[1] = Belt_Prot_01;
	text[2] = NAME_Prot_Point;
	count[2] = Belt_Prot_01;
	text[3] = NAME_Addon_BeArNOV;
	count[3] = BA_Bonus01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBE_Addon_MIL_01(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_MIL_01;
	visual = "ItMi_Belt_03.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas stra¿y";
	text[1] = NAME_Prot_Edge;
	count[1] = Belt_Prot_01;
	text[2] = NAME_Prot_Point;
	count[2] = Belt_Prot_01;
	text[3] = NAME_Addon_BeArMIL;
	count[3] = BA_Bonus01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBE_Addon_KDF_01(C_Item)
{
	name = NAME_Addon_BeltMage;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_KDF_01;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Szarfa Ognia";
	text[1] = NAME_Prot_Edge;
	count[1] = Belt_Prot_01;
	text[2] = NAME_Prot_Point;
	count[2] = Belt_Prot_01;
	text[3] = NAME_Addon_BeArKDF;
	count[3] = BA_Bonus01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};


instance ItBE_Addon_MC(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_MC;
	visual = "ItMi_Belt_08.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Pe³zacza";
	text[1] = NAME_Prot_Edge;
	count[1] = Belt_Prot_01;
	text[2] = NAME_Prot_Point;
	count[2] = Belt_Prot_01;
	text[3] = NAME_Addon_BeArMC;
	count[3] = BA_Bonus01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};


instance ItBe_Addon_STR_5(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_STR_5;
	visual = "ItMi_Belt_08.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Si³y";
	text[2] = NAME_Bonus_Str;
	count[2] = BeltBonus_STR01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};


instance ItBe_Addon_STR_10(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_STR_10;
	visual = "ItMi_Belt_05.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Mocy";
	text[2] = NAME_Bonus_Str;
	count[2] = BeltBonus_STR02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBe_Addon_DEX_5(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_DEX_5;
	visual = "ItMi_Belt_08.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Umiejêtnoœci";
	text[2] = NAME_Bonus_Dex;
	count[2] = BeltBonus_DEX01;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBe_Addon_DEX_10(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_DEX_10;
	visual = "ItMi_Belt_05.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Zrêcznoœci";
	text[2] = NAME_Bonus_Dex;
	count[2] = BeltBonus_DEX02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBe_Addon_Prot_EDGE(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_Prot_Edge;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Ochrony";
	text[2] = NAME_Prot_Edge;
	count[2] = BeltBonus_ProtEdge;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBe_Addon_Prot_Point(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_Prot_Point;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Obrony";
	text[2] = NAME_Prot_Point;
	count[2] = BeltBonus_ProtPoint;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBe_Addon_Prot_MAGIC(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_Prot_Magic;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Magicznej Obrony";
	text[2] = NAME_Prot_Magic;
	count[2] = BeltBonus_ProtMagic;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItBe_Addon_Prot_FIRE(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_Prot_Fire;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Ognistego Biegacza";
	text[2] = NAME_Prot_Fire;
	count[2] = BeltBonus_ProtFire;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};


instance ItBe_Addon_Prot_EdgPoi(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MISSION | ITEM_MULTI;
	value = Value_ItBE_Addon_Prot_EdgPoi;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Ochrony";
	text[2] = NAME_Prot_Edge;
	count[2] = BeltBonus_ProtEdgPoi;
	text[3] = NAME_Prot_Point;
	count[3] = BeltBonus_ProtEdgPoi;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};


instance ItBe_Addon_Prot_TOTAL(C_Item)
{
	name = NAME_Addon_Belt;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_BELT | ITEM_MULTI;
	value = Value_ItBE_Addon_Prot_Total;
	visual = "ItMi_Belt_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	description = "Pas Stra¿nika";
	text[1] = NAME_Prot_Edge;
	count[1] = BeltBonus_ProtTotal;
	text[2] = NAME_Prot_Point;
	count[2] = BeltBonus_ProtTotal;
	text[3] = NAME_Prot_Magic;
	count[3] = BeltBonus_ProtTotal;
	text[4] = NAME_Prot_Fire;
	count[4] = BeltBonus_ProtTotal;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_AMULETTE_STANDARD;
	inv_rotx = INVCAM_ENTF_MISC2_STANDARD;
};
