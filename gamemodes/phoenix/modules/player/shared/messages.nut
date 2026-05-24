class phoenix.player.Message.HudSnapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> name = ""
	</ type = phoenix.net.type.UInt16 /> level = 1
	</ type = phoenix.net.type.UInt32 /> experience = 0
	</ type = phoenix.net.type.UInt32 /> experienceNext = 500
	</ type = phoenix.net.type.UInt16 /> hp = 100
	</ type = phoenix.net.type.UInt16 /> hpMax = 100
	</ type = phoenix.net.type.UInt16 /> mana = 0
	</ type = phoenix.net.type.UInt16 /> manaMax = 0
	</ type = phoenix.net.type.UInt16 /> stamina = 100
	</ type = phoenix.net.type.UInt16 /> staminaMax = 100
	</ type = phoenix.net.type.String /> weaponProgress = ""
}

class phoenix.player.Message.KnockedDown extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt16 /> secondsRemaining = 10
}

class phoenix.player.Message.Revived extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt16 /> hp = 0
	</ type = phoenix.net.type.UInt16 /> hpMax = 100
}

class phoenix.player.Message.RespawnChoice extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> mode = "here"
}

class phoenix.player.Message.StatsRequest extends phoenix.net.Message {
}

class phoenix.player.Message.CombatText extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> targetId = 0
	</ type = phoenix.net.type.UInt16 /> amount = 0
	</ type = phoenix.net.type.String /> kind = "damage"
}

class phoenix.player.Message.StatsSnapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt16 /> level = 1
	</ type = phoenix.net.type.UInt32 /> experience = 0
	</ type = phoenix.net.type.UInt32 /> experienceNext = 500
	</ type = phoenix.net.type.UInt16 /> learnPoints = 0
	</ type = phoenix.net.type.UInt16 /> hp = 100
	</ type = phoenix.net.type.UInt16 /> hpMax = 100
	</ type = phoenix.net.type.UInt16 /> mana = 0
	</ type = phoenix.net.type.UInt16 /> manaMax = 0
	</ type = phoenix.net.type.UInt16 /> stamina = 100
	</ type = phoenix.net.type.UInt16 /> staminaMax = 100
	</ type = phoenix.net.type.UInt16 /> strength = 10
	</ type = phoenix.net.type.UInt16 /> dexterity = 10
	</ type = phoenix.net.type.UInt16 /> oneHand = 0
	</ type = phoenix.net.type.UInt16 /> twoHand = 0
	</ type = phoenix.net.type.UInt16 /> bow = 0
	</ type = phoenix.net.type.UInt16 /> crossbow = 0
	</ type = phoenix.net.type.UInt32 /> gold = 0
	</ type = phoenix.net.type.String /> weaponProgress = ""
}

class phoenix.player.Message.StatsSpend extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> stat = ""
	</ type = phoenix.net.type.UInt16 /> amount = 1
}

class phoenix.player.Message.StatsResult extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
}

class phoenix.player.Message.Sit extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> sitting = false
}

class phoenix.player.Message.HotbarSnapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> data = ""
}

class phoenix.player.Message.HotbarUpdate extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> data = ""
}

class phoenix.player.Message.HotbarActivate extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt8 /> slot = 0
}

class phoenix.player.Message.DrawWeaponRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt8 /> mode = 0
}


class phoenix.player.Message.LobbyConfig extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> lobbyCameras = ""
	</ type = phoenix.net.type.String /> characterDefaultSpawn = ""
	</ type = phoenix.net.type.String /> characterScenarios = ""
}
