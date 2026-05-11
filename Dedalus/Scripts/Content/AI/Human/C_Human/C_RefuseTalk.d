
func int C_RefuseTalk(var C_Npc slf,var C_Npc oth)
{
	if((Npc_RefuseTalk(slf) == TRUE) && C_NpcIsGateGuard(slf) && (slf.aivar[AIV_Guardpassage_Status] == GP_NONE))
	{
		return TRUE;
	};
	if(C_PlayerHasFakeGuild(slf,oth) && (self.flags != NPC_FLAG_IMMORTAL))
	{
		return TRUE;
	};
	return FALSE;
};

