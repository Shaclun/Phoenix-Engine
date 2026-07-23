class phoenix.quest.Message.Request extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt16 /> protocolVersion = 1
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.String /> requestId = ""
	</ type = phoenix.net.type.UInt32 /> stateVersion = 0
	</ type = phoenix.net.type.Any /> payload = null
}

class phoenix.quest.Message.Response extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.String /> requestId = ""
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.UInt32 /> stateVersion = 0
	</ type = phoenix.net.type.Any /> payload = null
}

class phoenix.quest.Message.Snapshot extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> characterId = 0
	</ type = phoenix.net.type.UInt32 /> stateVersion = 0
	</ type = phoenix.net.type.Any /> payload = null
}

class phoenix.quest.Message.Delta extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> characterId = 0
	</ type = phoenix.net.type.UInt32 /> stateVersion = 0
	</ type = phoenix.net.type.Any /> payload = null
}

class phoenix.quest.Message.Markers extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> characterId = 0
	</ type = phoenix.net.type.UInt32 /> stateVersion = 0
	</ type = phoenix.net.type.Any /> entries = null
}

class phoenix.quest.Message.Dialog extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> sessionId = ""
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.Any /> payload = null
}