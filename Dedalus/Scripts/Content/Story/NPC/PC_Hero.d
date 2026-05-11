
INSTANCE PC_HERO (NPC_DEFAULT)
{
	name[0] = "Player";
	guild = GIL_NONE;
	id = 0;
	voice = 15;
	level = 0;
	bodystateinterruptableoverride = TRUE;
	npcType = npctype_main;
	exp = 0;
	exp_next = 1;
	lp = 0;
	attribute[ATR_STRENGTH] = 1;
	attribute[ATR_DEXTERITY] = 1;
	attribute[ATR_MANA_MAX] = 1;
	attribute[ATR_MANA] = 1;
	attribute[ATR_HITPOINTS_MAX] = 1;
	attribute[ATR_HITPOINTS] = 1;
	Mdl_SetVisual(self,"HUMANS.MDS");
	Mdl_SetVisualBody(self,"hum_body_Naked0",9,0,"Hum_Head_Pony",Face_N_Player,0,NO_ARMOR);
};

