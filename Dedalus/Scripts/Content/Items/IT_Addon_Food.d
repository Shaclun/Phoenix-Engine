

const int Value_Rum = 30;
const int Mana_Rum = 10;
const int Value_Grog = 10;
const int HP_Grog = 1;
const int Value_SchnellerHering = 30;
const int Value_LousHammer = 30;
const int Mana_LousHammer = 1;
const int Value_SchlafHammer = 60;
const int Value_FireStew = 180;
const int STR_FireStew = 1;
const int HP_FireStew = 5;
const int STR_MeatSoup = 1;
const int Value_Shellflesh = 60;
const int HP_Shellflesh = 20;

instance ItFo_Addon_Shellflesh(C_Item)
{
	name = "Ostryga";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Shellflesh;
	visual = "ItAt_Meatbugflesh.3DS";
	material = MAT_LEATHER;
	scemeName = "FOODHUGE";
	description = name;
	text[0] = "Soczysta ostryga";
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Shellflesh;
	text[2] = "Smaczna nawet na surowo";
	text[3] = "";
	text[5] = NAME_Value;
	count[5] = value;
};



instance ItFo_Addon_Rum(C_Item)
{
	name = "Rum";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Rum;
	visual = "ItMi_Rum_02.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	description = "Bia? rum";
	text[1] = NAME_Bonus_Mana;
	count[1] = Mana_Rum;
	text[5] = NAME_Value;
	count[5] = Value_Rum;
};
/*
ITAM_ amulet
ITRI_ pierscien
ITAR_ pancerz
ITMW_ bron melee
ITRW_ bron range
ITBE_ pasy
ITFO_ jedzenie
ITPO_ poty
ITKE_ klucze
ITMI_ misk
ITSE_ ???
ITRU_ runy
ITSC_ scrole
ITAT_ animaltrophy
ITPL_ roslinki
ITSE_ secrets
ITLS torch
ITRW_ written
*/

instance ItFo_Addon_Grog(C_Item)
{
	name = "Grog";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_Grog;
	visual = "ItMi_Rum_02.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	description = "Grog prawdziwego marynarza";
	text[1] = NAME_Bonus_HP;
	count[1] = HP_Grog;
	text[5] = NAME_Value;
	count[5] = Value_Grog;
};

instance ItFo_Addon_LousHammer(C_Item)
{
	name = "M?t Lou";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_LousHammer;
	visual = "ItMi_Rum_01.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	description = "M?t Lou";
	text[1] = "Efekt           ???";
	text[5] = NAME_Value;
	count[5] = Value_LousHammer;
};


instance ItFo_Addon_SchlafHammer(C_Item)
{
	name = "Podw?ny M?t";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_SchlafHammer;
	visual = "ItMi_Rum_01.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	description = "Podw?ny M?t";
	text[1] = "Pokona nawet najtwardszego pijaka...";
	text[5] = NAME_Value;
	count[5] = Value_SchlafHammer;
};


instance ItFo_Addon_SchnellerHering(C_Item)
{
	name = "Szybki ?ed?";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_SchnellerHering;
	visual = "ItMi_Rum_01.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	description = "Szybki ?ed?";
	text[1] = "Wygl?a gro?ie!";
	text[2] = "Efekty nieznane. Bardzo mo?iwe efekty uboczne!";
	text[5] = NAME_Value;
	count[5] = Value_SchnellerHering;
};



instance ItFo_Addon_Pfeffer_01(C_Item)
{
	name = "Torebka pieprzu";
	mainflag = ITEM_KAT_NONE;
	flags = ITEM_MULTI;
	value = 100;
	visual = "ItMi_Pocket.3ds";
	material = MAT_LEATHER;
	description = "Ziarna czerwonego pieprzu";
	text[0] = "z Wysp Po?dniowych.";
	text[1] = "";
	text[2] = "";
	text[3] = "UWAGA ?OSTRE!";
	text[4] = "";
	text[5] = NAME_Value;
	count[5] = value;
};

instance ItFo_Addon_FireStew(C_Item)
{
	name = "Ognisty gulasz";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_FireStew;
	visual = "ItFo_Stew.3ds";
	material = MAT_WOOD;
	scemeName = "RICE";
	description = name;
	text[1] = NAME_Bonus_Str;
	count[1] = STR_FireStew;
	text[5] = NAME_Value;
	count[5] = Value_FireStew;
};



instance ItFo_Addon_Meatsoup(C_Item)
{
	name = "Gulasz";
	mainflag = ITEM_KAT_FOOD;
	flags = ITEM_MULTI;
	value = Value_FishSoup;
	visual = "ItFo_FishSoup.3ds";
	material = MAT_WOOD;
	scemeName = "RICE";
	description = "Paruj¹cy gulasz";
	text[1] = NAME_Bonus_Str;
	count[1] = STR_MeatSoup;
	text[5] = NAME_Value;
	count[5] = Value_FishSoup;
};


