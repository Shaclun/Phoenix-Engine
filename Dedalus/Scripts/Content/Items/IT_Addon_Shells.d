
const int Value_Shell_01 = 30;
const int Value_Shell_02 = 60;


instance ItMi_Addon_Shell_01(C_Item)
{
	name = "Otwierana muszla";
	mainflag = ITEM_KAT_NONE;
	flags = ITEM_MULTI;
	value = Value_Shell_01;
	visual = "ItMi_Shell_01.3ds";
	material = MAT_STONE;
	scemeName = "MAPSEALED";
	description = name;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_MISC2_STANDARD;
};

instance ItMi_Addon_Shell_02(C_Item)
{
	name = "Rogowa muszla";
	mainflag = ITEM_KAT_NONE;
	flags = ITEM_MULTI;
	value = Value_Shell_02;
	visual = "ItMi_Shell_02.3ds";
	material = MAT_STONE;
	scemeName = "MAPSEALED";
	description = name;
	text[5] = NAME_Value;
	count[5] = value;
	inv_zbias = INVCAM_ENTF_MISC2_STANDARD;
};

