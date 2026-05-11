class phoenix.crafting.Message.Open extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> vobId = ""
	</ type = phoenix.net.type.String /> stationName = ""
	</ type = phoenix.net.type.String /> recipes = ""
	</ type = phoenix.net.type.String /> playerItems = ""
	</ type = phoenix.net.type.UInt32 /> playerLevel = 1
}

class phoenix.crafting.Message.RequestOpen extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> vobId = ""
}

class phoenix.crafting.Message.Craft extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> vobId = ""
	</ type = phoenix.net.type.UInt32 /> recipeId = 0
}

class phoenix.crafting.Message.Result extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.String /> resultInstance = ""
	</ type = phoenix.net.type.UInt32 /> resultAmount = 0
	</ type = phoenix.net.type.String /> playerItems = ""
}

class phoenix.crafting.Message.Close extends phoenix.net.Message {
}

class phoenix.crafting.Message.Stations extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> visuals = ""
}
