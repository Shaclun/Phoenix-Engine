class phoenix.character.Message.RequestList extends phoenix.net.Message {
}

phoenix.character.ListEntryScheme <- {
	id = phoenix.net.type.UInt32
	name = phoenix.net.type.String
	klass = phoenix.net.type.UInt8
	gender = phoenix.net.type.UInt8
	level = phoenix.net.type.UInt16
	bodyModel = phoenix.net.type.String
	headModel = phoenix.net.type.String
	bodyTexIndex = phoenix.net.type.Int32
	face = phoenix.net.type.Int32
	fatness = phoenix.net.type.UInt8
	equipment = phoenix.net.type.String
	playTimeSec = phoenix.net.type.UInt32
	lastPlayedAt = phoenix.net.type.UInt32
	createdAt = phoenix.net.type.UInt32
	status = phoenix.net.type.UInt8
}

class phoenix.character.Message.List extends phoenix.net.Message {
	</ type = phoenix.net.type.Array(phoenix.net.type.Object(phoenix.character.ListEntryScheme)) /> characters = null
}

class phoenix.character.Message.Select extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> characterId = 0
}

class phoenix.character.Message.Create extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> name = ""
	</ type = phoenix.net.type.UInt8 /> gender = 0
	</ type = phoenix.net.type.UInt8 /> klass = 0
	</ type = phoenix.net.type.UInt8 /> race = 0
	</ type = phoenix.net.type.UInt8 /> fatness = 1
	</ type = phoenix.net.type.UInt8 /> walking = 0
	</ type = phoenix.net.type.UInt8 /> weapon = 0
	</ type = phoenix.net.type.UInt8 /> ranged = 0
	</ type = phoenix.net.type.UInt8 /> outfit = 0
	</ type = phoenix.net.type.UInt8 /> scenario = 0
	</ type = phoenix.net.type.String /> bodyModel = ""
	</ type = phoenix.net.type.String /> headModel = ""
	</ type = phoenix.net.type.Int32 /> bodyTexIndex = 0
	</ type = phoenix.net.type.Int32 /> face = 0
	</ type = phoenix.net.type.UInt8 /> voice = 0
}

class phoenix.character.Message.CreateResult extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
}

class phoenix.character.Message.Delete extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> characterId = 0
}

class phoenix.character.Message.AfterSelect extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> characterId = 0
	</ type = phoenix.net.type.String /> name = ""
}

class phoenix.character.Message.PreviewRestore extends phoenix.net.Message {
}
