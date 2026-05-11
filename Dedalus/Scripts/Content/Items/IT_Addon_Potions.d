
instance ItPo_Addon_Geist_01(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = 300;
	visual = "ItPo_Perm_STR.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Mikstura przemiany duszy";
	text[2] = "ZASTANÓW siê przed jej u¿yciem!";
	text[3] = "Mo¿e uszkodziæ umys³,";
	text[4] = "a nawet zabiæ tego, kto jej u¿yje.";
	text[5] = NAME_Value;
	count[5] = Value_ManaEssenz;
};

instance ItPo_Addon_Geist_02(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = 300;
	visual = "ItPo_Perm_STR.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_ITEMGLIMMER";
	description = "Mikstura przemiany duszy";
	text[2] = "ZASTANÓW siê przed jej u¿yciem!";
	text[3] = "Mo¿e uszkodziæ umys³,";
	text[4] = "a nawet zabiæ tego, kto jej u¿yje.";
	text[5] = NAME_Value;
	count[5] = Value_ManaEssenz;
};

instance ItPo_Health_Addon_04(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_HpTrunk;
	visual = "ItPo_Health_03.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_HEALTHPOTION";
	description = "Pe³nia ¿ycia";
	text[2] = "Ca³kowita regeneracja energii ¿yciowej";
	text[5] = NAME_Value;
	count[5] = Value_HpTrunk;
};

instance ItPo_Mana_Addon_04(C_Item)
{
	name = NAME_Trank;
	mainflag = ITEM_KAT_POTIONS;
	flags = ITEM_MULTI;
	value = Value_ManaTrunk;
	visual = "ItPo_Mana_03.3ds";
	material = MAT_GLAS;
	scemeName = "POTIONFAST";
	wear = WEAR_EFFECT;
	effect = "SPELLFX_MANAPOTION";
	description = "Pe³nia many";
	text[2] = "Ca³kowita regeneracja many";
	text[5] = NAME_Value;
	count[5] = Value_ManaTrunk;
};


