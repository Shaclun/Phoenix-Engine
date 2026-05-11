
instance StandardBrief(C_Item)
{
	name = "List";
	mainflag = ITEM_KAT_DOCS;
	flags = ITEM_MISSION;
	value = 0;
	visual = "ItWr_Scroll_01.3DS";
	material = MAT_LEATHER;
	scemeName = "MAP";
	description = "TypowyList";
};


instance StandardBuch(C_Item)
{
	name = "TypowaKsi¹¿ka";
	mainflag = ITEM_KAT_DOCS;
	flags = 0;
	value = 100;
	visual = "ItWr_Book_02_05.3ds";
	material = MAT_LEATHER;
	scemeName = "MAP";
	description = "TypowaKsi¹¿ka";
	text[5] = NAME_Value;
	count[5] = value;
};

instance ItWr_Map_NewWorld(C_Item)
{
	name = "Mapa terenów Khorinis";
	mainflag = ITEM_KAT_DOCS;
	flags = ITEM_MISSION | ITEM_MULTI;
	value = 250;
	visual = "ItWr_Map_01.3DS";
	material = MAT_LEATHER;
	scemeName = "MAP";
	description = name;
	text[0] = "";
	text[1] = "";
	text[5] = NAME_Value;
	count[5] = value;
};

instance ItWr_Map_NewWorld_City(C_Item)
{
	name = "Mapa miasta Khorinis";
	mainflag = ITEM_KAT_DOCS;
	flags = ITEM_MISSION | ITEM_MULTI;
	value = 50;
	visual = "ItWr_Map_01.3DS";
	material = MAT_LEATHER;
	scemeName = "MAP";
	description = name;
	text[0] = "";
	text[1] = "";
	text[5] = NAME_Value;
	count[5] = value;
};


instance ItWr_Map_OldWorld(C_Item)
{
	name = "Mapa Górniczej Doliny";
	mainflag = ITEM_KAT_DOCS;
	flags = ITEM_MISSION | ITEM_MULTI;
	value = 350;
	visual = "ItWr_Map_01.3DS";
	material = MAT_LEATHER;
	scemeName = "MAP";
	description = name;
	text[0] = "";
	text[1] = "";
	text[5] = NAME_Value;
	count[5] = value;
};



instance ItWr_EinhandBuch(C_Item)
{
	name = "Sztuka walki";
	mainflag = ITEM_KAT_DOCS;
	flags = 0;
	value = 5000;
	visual = "ItWr_Book_02_04.3ds";
	material = MAT_LEATHER;
	scemeName = "MAP";
	description = "Kunszt obronny po³udniowców";
	text[2] = "Ksi¹¿ka opisuj¹ca sztukê";
	text[3] = "walki broniami jednorêcznymi.";
	text[5] = NAME_Value;
	count[5] = value;
};



instance ItWr_ZweihandBuch(C_Item)
{
	name = "Taktyka walki";
	mainflag = ITEM_KAT_DOCS;
	flags = 0;
	value = 5000;
	visual = "ItWr_Book_02_03.3ds";
	material = MAT_LEATHER;
	scemeName = "MAP";
	description = "Bloki dwurêczne";
	text[2] = "Ksi¹¿ka opisuj¹ca sztukê";
	text[3] = "walki broniami dwurêcznymi.";
	text[5] = NAME_Value;
	count[5] = value;
};



