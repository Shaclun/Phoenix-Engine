phoenix.herb.GroundEntry <- {
	plantId = phoenix.net.type.String
	instance = phoenix.net.type.String
	visual = phoenix.net.type.String
	namePl = phoenix.net.type.String
	nameEn = phoenix.net.type.String
	nameDe = phoenix.net.type.String
	nameRu = phoenix.net.type.String
	world = phoenix.net.type.String
	x = phoenix.net.type.Float
	y = phoenix.net.type.Float
	z = phoenix.net.type.Float
	gatherMs = phoenix.net.type.UInt32
	cooldownSec = phoenix.net.type.UInt32
	cooldownLeftSec = phoenix.net.type.UInt32
	successChance = phoenix.net.type.UInt8
}

class phoenix.herb.Message.Snapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.Array(phoenix.net.type.Object(phoenix.herb.GroundEntry)) /> entries = null
}

class phoenix.herb.Message.StartRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> plantId = ""
}

class phoenix.herb.Message.CancelRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> plantId = ""
}

class phoenix.herb.Message.Started extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> plantId = ""
	</ type = phoenix.net.type.String /> label = ""
	</ type = phoenix.net.type.UInt32 /> gatherMs = 0
}

class phoenix.herb.Message.Result extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> plantId = ""
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> instance = ""
	</ type = phoenix.net.type.String /> label = ""
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.UInt32 /> cooldownSec = 0
}