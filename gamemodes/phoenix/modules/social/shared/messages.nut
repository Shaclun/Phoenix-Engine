class phoenix.social.Message.Request extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.UInt32 /> targetId = 0
	</ type = phoenix.net.type.UInt32 /> itemId = 0
	</ type = phoenix.net.type.UInt32 /> amount = 0
	</ type = phoenix.net.type.UInt32 /> gold = 0
	</ type = phoenix.net.type.UInt32 /> inviteId = 0
	</ type = phoenix.net.type.String /> text = ""
	</ type = phoenix.net.type.Any /> payload = null
}

class phoenix.social.Message.State extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.Bool /> success = true
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.Any /> payload = null
}
