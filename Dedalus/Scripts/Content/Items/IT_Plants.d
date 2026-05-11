
const int Value_Weed = 0;
const int Value_Beet = 3;
const int HP_Beet = 2;
const int Value_SwampHerb = 10;
const int Value_Mana_Herb_01 = 10;
const int Mana_Mana_Herb_01 = 10;
const int Value_Mana_Herb_02 = 20;
const int Mana_Mana_Herb_02 = 15;
const int Value_Mana_Herb_03 = 40;
const int Mana_Mana_Herb_03 = 20;
const int Value_Health_Herb_01 = 20;
const int HP_Health_Herb_01 = 10;
const int Value_Health_Herb_02 = 40;
const int HP_Health_Herb_02 = 20;
const int Value_Health_Herb_03 = 60;
const int HP_Health_Herb_03 = 30;
const int Value_Dex_Herb_01 = 250;
const int Value_Strength_Herb_01 = 500;
const int Value_Speed_Herb_01 = 100;
const int Speed_Boost = 15000;
const int Value_Mushroom_01 = 10;
const int HP_Mushroom_01 = 5;
const int Value_Mushroom_02 = 30;
const int HP_Mushroom_02 = 15;
const int Value_Forestberry = 10;
const int HP_Forestberry = 5;
const int Value_Blueplant = 10;
const int HP_Blueplant = 5;
const int Mana_Blueplant = 5;
const int Value_Planeberry = 10;
const int HP_Planeberry = 5;
const int Value_Temp_Herb = 100;
const int HP_Temp_Herb = 5;
const int Value_Perm_Herb = 500;
const int HP_Perm_Herb = 5;

instance ItPl_Weed(C_Item)
{
	name = "Chwasty";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Weed;
	visual = "ItPl_Weed.3ds";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[5] = NAME_Value;
	count[5] = Value_Weed;
};

instance ItPl_Beet(C_Item)
{
	name = "Rzepa";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Beet;
	visual = "ItPl_Beet.3ds";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[5] = NAME_Value;
	count[5] = Value_Beet;
};

instance ItPl_SwampHerb(C_Item)
{
	name = "Bagienne ziele";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_SwampHerb;
	visual = "ItPl_SwampHerb.3ds";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[5] = NAME_Value;
	count[5] = Value_SwampHerb;
};

instance ItPl_Mana_Herb_01(C_Item)
{
	name = "Ognista pokrzywa";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Mana_Herb_01;
	visual = "ItPl_Mana_Herb_01.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_Mana;
	count[1] = Mana_Mana_Herb_01;
	text[5] = NAME_Value;
	count[5] = Value_Mana_Herb_01;
};

instance ItPl_Mana_Herb_02(C_Item)
{
	name = "Ogniste ziele";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Mana_Herb_02;
	visual = "ItPl_Mana_Herb_02.3ds";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_Mana;
	count[1] = Mana_Mana_Herb_02;
	text[5] = NAME_Value;
	count[5] = Value_Mana_Herb_02;
};


instance ItPl_Mana_Herb_03(C_Item)
{
	name = "Ognisty korzeñ";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Mana_Herb_03;
	visual = "ItPl_Mana_Herb_03.3ds";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_Mana;
	count[1] = Mana_Mana_Herb_03;
	text[5] = NAME_Value;
	count[5] = Value_Mana_Herb_03;
};


instance ItPl_Health_Herb_01(C_Item)
{
	name = "Roœlina lecznicza";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Health_Herb_01;
	visual = "ItPl_Health_Herb_01.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Health_Herb_01;
	text[5] = NAME_Value;
	count[5] = Value_Health_Herb_01;
};


instance ItPl_Health_Herb_02(C_Item)
{
	name = "Ziele lecznicze";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Health_Herb_02;
	visual = "ItPl_Health_Herb_02.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Health_Herb_02;
	text[5] = NAME_Value;
	count[5] = Value_Health_Herb_02;
};


instance ItPl_Health_Herb_03(C_Item)
{
	name = "Korzeñ leczniczy";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Health_Herb_03;
	visual = "ItPl_Health_Herb_03.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Health_Herb_03;
	text[5] = NAME_Value;
	count[5] = Value_Health_Herb_03;
};


instance ItPl_Dex_Herb_01(C_Item)
{
	name = "Goblinie jagody";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Dex_Herb_01;
	visual = "ItPl_Dex_Herb_01.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_Dex;
	count[1] = 1;
	text[5] = NAME_Value;
	count[5] = Value_Dex_Herb_01;
};


instance ItPl_Strength_Herb_01(C_Item)
{
	name = "Smoczy korzeñ";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Strength_Herb_01;
	visual = "ItPl_Strength_Herb_01.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_Str;
	count[1] = 1;
	text[5] = NAME_Value;
	count[5] = Value_Strength_Herb_01;
};

instance ItPl_Speed_Herb_01(C_Item)
{
	name = "Zêbate ziele";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Speed_Herb_01;
	visual = "ItPl_Speed_Herb_01.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	text[3] = NAME_Sec_Duration;
	count[3] = Speed_Boost / 1000;
	description = name;
	text[5] = NAME_Value;
	count[5] = Value_Speed_Herb_01;
};


instance ItPl_Mushroom_01(C_Item)
{
	name = "Ciemny grzyb";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Mushroom_01;
	visual = "ItPl_Mushroom_01.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Mushroom_01;
	text[5] = NAME_Value;
	count[5] = Value_Mushroom_01;
};


instance ItPl_Mushroom_02(C_Item)
{
	name = "Miêso kopacza";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Mushroom_02;
	visual = "ItPl_Mushroom_02.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Mushroom_02;
	text[5] = NAME_Value;
	count[5] = Value_Mushroom_02;
};

instance ItPl_Blueplant(C_Item)
{
	name = "Niebieski bez";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Blueplant;
	visual = "ItPl_Blueplant.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Blueplant;
	text[2] = NAME_Bonus_Mana;
	count[2] = Mana_Blueplant;
	text[5] = NAME_Value;
	count[5] = Value_Blueplant;
};

instance ItPl_Forestberry(C_Item)
{
	name = "Leœna jagoda";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Forestberry;
	visual = "ItPl_Forestberry.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Forestberry;
	text[5] = NAME_Value;
	count[5] = Value_Forestberry;
};

instance ItPl_Planeberry(C_Item)
{
	name = "Polna jagoda";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Planeberry;
	visual = "ItPl_Planeberry.3DS";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Planeberry;
	text[5] = NAME_Value;
	count[5] = Value_Planeberry;
};

instance ItPl_Temp_Herb(C_Item)
{
	name = "Rdest polny";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI | ITEM_MISSION;
	value = Value_Temp_Herb;
	visual = "ItPl_Temp_Herb.3ds";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Temp_Herb;
	text[5] = NAME_Value;
	count[5] = Value_Temp_Herb;
};

instance ItPl_Perm_Herb(C_Item)
{
	name = "Szczaw królewski";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI | ITEM_MISSION;
	value = Value_Perm_Herb;
	visual = "ItPl_Perm_Herb.3ds";
	material = MAT_LEATHER;
	scemeName = "FOOD";
	description = name;
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Perm_Herb;
	text[5] = NAME_Value;
	count[5] = Value_Perm_Herb;
};