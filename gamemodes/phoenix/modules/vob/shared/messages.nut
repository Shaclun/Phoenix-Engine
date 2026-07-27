phoenix.vob.Entry <- {
	vobId = phoenix.net.type.String
	name = phoenix.net.type.String
	visual = phoenix.net.type.String
	world = phoenix.net.type.String
	x = phoenix.net.type.Float
	y = phoenix.net.type.Float
	z = phoenix.net.type.Float
	rotX = phoenix.net.type.Float
	rotY = phoenix.net.type.Float
	rotZ = phoenix.net.type.Float
	interactive = phoenix.net.type.Bool
	noCollision = phoenix.net.type.Bool
	craftInteraction = phoenix.net.type.Bool
	entryKind = phoenix.net.type.String
	itemInstance = phoenix.net.type.String
	itemAmount = phoenix.net.type.UInt32
	itemQuality = phoenix.net.type.UInt8
}

class phoenix.vob.Message.Snapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.Array(phoenix.net.type.Object(phoenix.vob.Entry)) /> entries = null
}

class phoenix.vob.Message.InteractRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> vobId = ""
}
