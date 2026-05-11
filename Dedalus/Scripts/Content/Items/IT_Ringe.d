
const int Value_Ri_ProtFire = 250;
const int Ri_ProtFire = 3;
const int Value_Ri_ProtEdge = 250;
const int Ri_ProtEdge = 3;
const int Value_Ri_ProtMage = 250;
const int Ri_ProtMage = 3;
const int Value_Ri_ProtPoint = 250;
const int Ri_ProtPoint = 3;
const int Value_Ri_ProtFire02 = 500;
const int Ri_ProtFire02 = 5;
const int Value_Ri_ProtEdge02 = 500;
const int Ri_ProtEdge02 = 5;
const int Value_Ri_ProtMage02 = 500;
const int Ri_ProtMage02 = 5;
const int Value_Ri_ProtPoint02 = 500;
const int Ri_ProtPoint02 = 5;
const int Value_Ri_ProtTotal = 600;
const int Ri_TProtFire = 2;
const int Ri_TProtEdge = 3;
const int Ri_TProtMage = 2;
const int Ri_TProtPoint = 3;
const int Value_Ri_ProtTotal02 = 1000;
const int Ri_TProtFire02 = 3;
const int Ri_TProtEdge02 = 5;
const int Ri_TProtMage02 = 3;
const int Ri_TProtPoint02 = 5;
const int Value_Ri_Dex = 300;
const int Ri_Dex = 3;
const int Value_Ri_Dex02 = 500;
const int Ri_Dex02 = 5;
const int Value_Ri_Mana = 500;
const int Ri_Mana = 5;
const int Value_Ri_Mana02 = 1000;
const int Ri_Mana02 = 10;
const int Value_Ri_Strg = 300;
const int Ri_Strg = 3;
const int Value_Ri_Strg02 = 500;
const int Ri_Strg02 = 5;
const int Value_Ri_Hp = 200;
const int Ri_Hp = 20;
const int Value_Ri_Hp02 = 400;
const int Ri_Hp02 = 40;
const int Value_Ri_HpMana = 1300;
const int Ri_HpMana_Hp = 30;
const int Ri_HpMana_Mana = 10;
const int Value_Ri_DexStrg = 800;
const int Ri_DexStrg_Dex = 4;
const int Ri_DexStrg_Strg = 4;

instance ItRi_Prot_Fire_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtFire;
	visual = "ItRi_Prot_Fire_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ ochrony przed ogniem";
	text[2] = NAME_Prot_Fire;
	count[2] = Ri_ProtFire;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Prot_Fire_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtFire02;
	visual = "ItRi_Prot_Fire_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ ognia";
	text[2] = NAME_Prot_Fire;
	count[2] = Ri_ProtFire02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Prot_Point_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtPoint;
	visual = "ItRi_Prot_Point_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ drewnianej skóry";
	text[2] = NAME_Prot_Point;
	count[2] = Ri_ProtPoint;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Prot_Point_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtPoint02;
	visual = "ItRi_Prot_Point_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ kamiennej skóry";
	text[2] = NAME_Prot_Point;
	count[2] = Ri_ProtPoint02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Prot_Edge_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtEdge;
	visual = "ItRi_Prot_Edge_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ ¿elaznej skóry";
	text[2] = NAME_Prot_Edge;
	count[2] = Ri_ProtEdge;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Prot_Edge_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtEdge02;
	visual = "ItRi_Prot_Edge_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ magicznego pancerza";
	text[2] = NAME_Prot_Edge;
	count[2] = Ri_ProtEdge02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Prot_Mage_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtMage;
	visual = "ItRi_Prot_Mage_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ ducha";
	text[2] = NAME_Prot_Magic;
	count[2] = Ri_ProtMage;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};



instance ItRi_Prot_Mage_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtMage02;
	visual = "ItRi_Prot_Mage_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ obrony";
	text[2] = NAME_Prot_Magic;
	count[2] = Ri_ProtMage02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Prot_Total_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtTotal;
	visual = "ItRi_Prot_Total_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ wiecznych zwyciêstw";
	text[1] = NAME_Prot_Magic;
	count[1] = Ri_TProtMage;
	text[2] = NAME_Prot_Fire;
	count[2] = Ri_TProtFire;
	text[3] = NAME_Prot_Point;
	count[3] = Ri_TProtPoint;
	text[4] = NAME_Prot_Edge;
	count[4] = Ri_TProtEdge;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Prot_Total_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_ProtTotal02;
	visual = "ItRi_Prot_Total_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ nietykalnoœci";
	text[1] = NAME_Prot_Magic;
	count[1] = Ri_TProtMage02;
	text[2] = NAME_Prot_Fire;
	count[2] = Ri_TProtFire02;
	text[3] = NAME_Prot_Point;
	count[3] = Ri_TProtPoint02;
	text[4] = NAME_Prot_Edge;
	count[4] = Ri_TProtEdge02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Dex_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Dex;
	visual = "ItRi_Dex_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ zdolnoœci";
	text[2] = NAME_Bonus_Dex;
	count[2] = Ri_Dex;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Dex_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Dex02;
	visual = "ItRi_Dex_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ zrêcznoœci";
	text[2] = NAME_Bonus_Dex;
	count[2] = Ri_Dex02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_HP_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Hp;
	visual = "ItRi_Hp_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ ¿ycia";
	text[2] = NAME_Bonus_HP;
	count[2] = Ri_Hp;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Hp_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Hp02;
	visual = "ItRi_Hp_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ ¿ywotnoœci";
	text[2] = NAME_Bonus_HP;
	count[2] = Ri_Hp02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Str_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Strg;
	visual = "ItRi_Str_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ mocy";
	text[2] = NAME_Bonus_Str;
	count[2] = Ri_Strg;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Str_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Strg02;
	visual = "ItRi_Str_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ si³y";
	text[2] = NAME_Bonus_Str;
	count[2] = Ri_Strg02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};

instance ItRi_Mana_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Mana;
	visual = "ItRi_Mana_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ magii";
	text[2] = NAME_Bonus_Mana;
	count[2] = Ri_Mana;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Mana_02(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_Mana02;
	visual = "ItRi_Mana_02.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ gwiezdnej mocy";
	text[2] = NAME_Bonus_Mana;
	count[2] = Ri_Mana02;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Hp_Mana_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_HpMana;
	visual = "ItRi_Hp_Mana_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ oœwiecenia";
	text[2] = NAME_Bonus_Mana;
	count[2] = Ri_HpMana_Mana;
	text[3] = NAME_Bonus_HP;
	count[3] = Ri_HpMana_Hp;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};


instance ItRi_Dex_Strg_01(C_Item)
{
	name = NAME_Ring;
	mainflag = ITEM_KAT_MAGIC;
	flags = ITEM_RING;
	value = Value_Ri_DexStrg;
	visual = "ItRi_Dex_Strg_01.3ds";
	visual_skin = 0;
	material = MAT_METAL;
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Pierœcieñ mocy";
	text[2] = NAME_Bonus_Str;
	count[2] = 4;
	text[3] = NAME_Bonus_Dex;
	count[3] = 4;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_RING_STANDARD;
	inv_rotz = INVCAM_Z_RING_STANDARD;
	inv_rotx = INVCAM_X_RING_STANDARD;
};
