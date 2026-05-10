
class phoenix.chat.Message.Submit extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt8 /> channel = 0
	</ type = phoenix.net.type.String /> text = ""
}

class phoenix.chat.Message.Broadcast extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> playerId = 0
	</ type = phoenix.net.type.UInt8 /> channel = 0
	</ type = phoenix.net.type.String /> name = ""
	</ type = phoenix.net.type.String /> text = ""
}

class phoenix.chat.Message.Typing extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> playerId = 0
	</ type = phoenix.net.type.Bool /> typing = false
	</ type = phoenix.net.type.UInt8 /> channel = 0
}
