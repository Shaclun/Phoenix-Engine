phoenix.profession.Entry <- {
	id = phoenix.net.type.UInt32
	code = phoenix.net.type.String
	name = phoenix.net.type.String
	description = phoenix.net.type.String
	namePl = phoenix.net.type.String
	nameEn = phoenix.net.type.String
	nameDe = phoenix.net.type.String
	nameRu = phoenix.net.type.String
	descriptionPl = phoenix.net.type.String
	descriptionEn = phoenix.net.type.String
	descriptionDe = phoenix.net.type.String
	descriptionRu = phoenix.net.type.String
	level = phoenix.net.type.UInt32
	tier = phoenix.net.type.UInt32
	xp = phoenix.net.type.UInt32
	xpNext = phoenix.net.type.UInt32
	progressPct = phoenix.net.type.UInt8
}

class phoenix.profession.Message.Request extends phoenix.net.Message {}

class phoenix.profession.Message.Snapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.Array(phoenix.net.type.Object(phoenix.profession.Entry)) /> entries = null
}

class phoenix.profession.Message.HuntingStarted extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> vobId = ""
	</ type = phoenix.net.type.String /> label = ""
	</ type = phoenix.net.type.UInt32 /> durationMs = 0
}

class phoenix.profession.Message.HuntingResult extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> vobId = ""
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.String /> drops = ""
	</ type = phoenix.net.type.UInt32 /> xp = 0
}
