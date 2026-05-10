

phoenix.item.InstanceScheme <- {
	id           = phoenix.net.type.UInt32
	instance     = phoenix.net.type.String
	amount       = phoenix.net.type.UInt32
	quality      = phoenix.net.type.UInt8
	upgrade      = phoenix.net.type.UInt8
	durability   = phoenix.net.type.UInt16
	equipped     = phoenix.net.type.Bool
	slot         = phoenix.net.type.UInt8
}

class phoenix.item.Message.Inventory extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> ownerId = 0
	</ type = phoenix.net.type.UInt8  /> ownerType = 0
	</ type = phoenix.net.type.UInt32 /> gold = 0
	</ type = phoenix.net.type.Array(phoenix.net.type.Object(phoenix.item.InstanceScheme)) /> items = null
}

class phoenix.item.Message.Add extends phoenix.net.Message {
	</ type = phoenix.net.type.Object(phoenix.item.InstanceScheme) /> item = null
}

class phoenix.item.Message.Remove extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> id = 0
}

class phoenix.item.Message.Update extends phoenix.net.Message {
	</ type = phoenix.net.type.Object(phoenix.item.InstanceScheme) /> item = null
}

class phoenix.item.Message.UpgradeResult extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> id = 0
	</ type = phoenix.net.type.Bool   /> success = false
	</ type = phoenix.net.type.UInt8  /> upgrade = 0
	</ type = phoenix.net.type.String /> error = ""
}

class phoenix.item.Message.UseRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> id = 0
}

class phoenix.item.Message.EquipRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> id = 0
	</ type = phoenix.net.type.Bool   /> equip = true
}

class phoenix.item.Message.UpgradeRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> id = 0
}

class phoenix.item.Message.DropRequest extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> id = 0
	</ type = phoenix.net.type.UInt32 /> amount = 1
	</ type = phoenix.net.type.String /> name = ""
	</ type = phoenix.net.type.String /> visual = ""
}
