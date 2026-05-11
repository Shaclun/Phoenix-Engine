phoenix.npc.NameplateEntry <- {
	npcId = phoenix.net.type.UInt32
	spawnId = phoenix.net.type.UInt32
	name = phoenix.net.type.String
	instance = phoenix.net.type.String
	kind = phoenix.net.type.String
	height = phoenix.net.type.UInt32
	level = phoenix.net.type.UInt16
	hp = phoenix.net.type.UInt16
	hpMax = phoenix.net.type.UInt16
	mana = phoenix.net.type.UInt16
	manaMax = phoenix.net.type.UInt16
	testPlayer = phoenix.net.type.Bool
	labelPl = phoenix.net.type.String
	labelEn = phoenix.net.type.String
	labelDe = phoenix.net.type.String
	labelRu = phoenix.net.type.String
}

class phoenix.npc.Message.Nameplates extends phoenix.net.Message {
	</ type = phoenix.net.type.Array(phoenix.net.type.Object(phoenix.npc.NameplateEntry)) /> entries = null
}

class phoenix.npc.Message.InteractRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> npcId = 0
}

class phoenix.npc.Message.Dialog extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> npcId = 0
	</ type = phoenix.net.type.String /> npcName = ""
	</ type = phoenix.net.type.String /> idleAnimation = ""
	</ type = phoenix.net.type.Bool /> hasTeacher = false
	</ type = phoenix.net.type.Bool /> hasMerchant = false
}

class phoenix.npc.Message.DialogAction extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> npcId = 0
	</ type = phoenix.net.type.String /> action = ""
}

class phoenix.npc.Message.TeacherDialog extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> npcId = 0
	</ type = phoenix.net.type.String /> npcName = ""
	</ type = phoenix.net.type.String /> skills = ""
	</ type = phoenix.net.type.UInt32 /> cost = 0
	</ type = phoenix.net.type.UInt32 /> playerGold = 0
	</ type = phoenix.net.type.UInt16 /> playerLearnPoints = 0
	</ type = phoenix.net.type.String /> weaponProgress = ""
}

class phoenix.npc.Message.TeacherTrain extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> npcId = 0
	</ type = phoenix.net.type.String /> skill = ""
}

class phoenix.npc.Message.TeacherResult extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
}

class phoenix.npc.Message.MerchantDialog extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> npcId = 0
	</ type = phoenix.net.type.String /> npcName = ""
	</ type = phoenix.net.type.String /> items = ""
	</ type = phoenix.net.type.String /> playerItems = ""
	</ type = phoenix.net.type.UInt32 /> playerGold = 0
}

class phoenix.npc.Message.MerchantTrade extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> npcId = 0
	</ type = phoenix.net.type.String /> mode = ""
	</ type = phoenix.net.type.String /> instance = ""
	</ type = phoenix.net.type.UInt32 /> itemId = 0
	</ type = phoenix.net.type.UInt32 /> amount = 1
}

class phoenix.npc.Message.MerchantResult extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.UInt32 /> playerGold = 0
}

class phoenix.npc.Message.BestiaryRequest extends phoenix.net.Message {
}

class phoenix.npc.Message.BestiarySnapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> entries = ""
}
