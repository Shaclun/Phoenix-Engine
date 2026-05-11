
const int Value_HpEssenz = 25;
const int HP_Essenz = 50;
const int Value_HpExtrakt = 35;
const int HP_Extrakt = 70;
const int Value_HpElixier = 50;
const int HP_Elixier = 100;
const int Value_ManaEssenz = 25;
const int Mana_Essenz = 50;
const int Value_ManaExtrakt = 40;
const int Mana_Extrakt = 75;
const int Value_ManaElixier = 60;
const int Mana_Elixier = 100;
const int Value_StrElixier = 800;
const int STR_Elixier = 3;
const int Value_DexElixier = 800;
const int DEX_Elixier = 3;
const int Value_HpMaxElixier = 1500;
const int HPMax_Elixier = 20;
const int Value_ManaMaxElixier = 1500;
const int ManaMax_Elixier = 5;
const int Value_MegaDrink = 1800;
const int STRorDEX_MegaDrink = 15;
const int Value_Speed = 200;
const int Time_Speed = 300000;
const int Value_ManaTrunk = 200;
const int Value_HpTrunk = 150;

instance ItPo_Mana_01(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_ManaEssenz;
	visual = "ItPo_Mana_01.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_MANAPOTION";
	description = "Esencja many";
	text[1] = NAME_Bonus_Mana;
	count[1] = Mana_Essenz;
	text[5] = NAME_Value;
	count[5] = Value_ManaEssenz;
};


instance ItPo_Mana_02(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_ManaExtrakt;
	visual = "ItPo_Mana_02.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_MANAPOTION";
	description = "Ekstrakt many";
	text[1] = NAME_Bonus_Mana;
	count[1] = Mana_Extrakt;
	text[5] = NAME_Value;
	count[5] = Value_ManaExtrakt;
};


instance ItPo_Mana_03(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_ManaElixier;
	visual = "ItPo_Mana_03.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_MANAPOTION";
	description = "Eliksir many";
	text[1] = NAME_Bonus_Mana;
	count[1] = Mana_Elixier;
	text[5] = NAME_Value;
	count[5] = Value_ManaElixier;
};

instance ItPo_Health_01(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_HpEssenz;
	visual = "ItPo_Health_01.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_HEALTHPOTION";
	description = "Esencja lecznicza";
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Essenz;
	text[5] = NAME_Value;
	count[5] = Value_HpEssenz;
};

instance ItPo_Health_02(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_HpExtrakt;
	visual = "ItPo_Health_02.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_HEALTHPOTION";
	description = "Ekstrakt leczniczy";
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Extrakt;
	text[5] = NAME_Value;
	count[5] = Value_HpExtrakt;
};

instance ItPo_Health_03(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_HpElixier;
	visual = "ItPo_Health_03.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_HEALTHPOTION";
	description = "Eliksir leczniczy";
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Elixier;
	text[5] = NAME_Value;
	count[5] = Value_HpElixier;
};

instance ItPo_Perm_STR(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_StrElixier;
	visual = "ItPo_Perm_STR.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Eliksir si˜y";
	text[1] = NAME_Bonus_Str;
	count[1] = STR_Elixier;
	text[5] = NAME_Value;
	count[5] = Value_StrElixier;
};

instance ItPo_Perm_DEX(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_DexElixier;
	visual = "ItPo_Perm_DEX.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Eliksir zr˜czno˜ci";
	text[1] = NAME_Bonus_Dex;
	count[1] = DEX_Elixier;
	text[5] = NAME_Value;
	count[5] = Value_DexElixier;
};



instance ItPo_Perm_Health(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_HpMaxElixier;
	visual = "ItPo_Perm_Health.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_HEALTHPOTION";
	description = "Eliksir ˜ycia";
	text[1] = NAME_Bonus_HpMax;
	count[1] = HPMax_Elixier;
	text[5] = NAME_Value;
	count[5] = Value_HpMaxElixier;
};

instance ItPo_Perm_Mana(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_ManaMaxElixier;
	visual = "ItPo_Perm_Mana.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_MANAPOTION";
	description = "Eliksir ducha";
	text[1] = NAME_Bonus_ManaMax;
	count[1] = ManaMax_Elixier;
	text[5] = NAME_Value;
	count[5] = Value_ManaMaxElixier;
};


instance ItPo_Speed(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_Speed;
	visual = "ItPo_Speed.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Mikstura szybko˜ci";
	text[1] = "Tymczasowo zwi˜ksza twoj˜ szybko˜˜.";
	text[3] = NAME_Duration;
	count[3] = Time_Speed / 60000;
	text[5] = NAME_Value;
	count[5] = value;
};

instance ItPo_MegaDrink(C_Item)
{
	name = "Embarla Firgasto";
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_MegaDrink;
	visual = "ItPo_Perm_Mana.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = name;
	text[3] = "Skutki nieznane.";
	text[5] = NAME_Value;
	count[5] = value;
};

