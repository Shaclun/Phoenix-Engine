phoenix.house.NetEntry <- {
	id = phoenix.net.type.UInt32
	name = phoenix.net.type.String
	world = phoenix.net.type.String
	points = phoenix.net.type.String
	entryX = phoenix.net.type.Float
	entryY = phoenix.net.type.Float
	entryZ = phoenix.net.type.Float
	entryHeading = phoenix.net.type.Float
	priceGold = phoenix.net.type.UInt32
	weeklyRentGold = phoenix.net.type.UInt32
	ownerType = phoenix.net.type.UInt16
	ownerId = phoenix.net.type.UInt32
	rentPaidUntil = phoenix.net.type.UInt32
	color = phoenix.net.type.String
}

class phoenix.house.Message.Snapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.Array(phoenix.net.type.Object(phoenix.house.NetEntry)) /> entries = null
}

class phoenix.house.Message.InteractRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> houseId = 0
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.UInt16 /> weeks = 0
	</ type = phoenix.net.type.String /> target = ""
}

class phoenix.house.Message.InteractResult extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.Bool /> canEnter = false
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.String /> access = ""
	</ type = phoenix.net.type.UInt32 /> houseId = 0
	</ type = phoenix.net.type.String /> mode = ""
	</ type = phoenix.net.type.String /> name = ""
	</ type = phoenix.net.type.UInt32 /> priceGold = 0
	</ type = phoenix.net.type.UInt32 /> weeklyRentGold = 0
	</ type = phoenix.net.type.UInt32 /> rentPaidUntil = 0
	</ type = phoenix.net.type.UInt32 /> ownerId = 0
	</ type = phoenix.net.type.UInt32 /> playerGold = 0
	</ type = phoenix.net.type.String /> guests = ""
	</ type = phoenix.net.type.String /> guestsData = ""
	</ type = phoenix.net.type.String /> ownerName = ""
	</ type = phoenix.net.type.String /> friends = ""
	</ type = phoenix.net.type.String /> requests = ""
	</ type = phoenix.net.type.UInt16 /> maxExtendWeeks = 12
}

class phoenix.house.Message.PanelRequest extends phoenix.net.Message {}