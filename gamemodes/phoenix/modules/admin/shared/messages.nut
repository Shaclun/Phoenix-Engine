phoenix.admin <- {}
phoenix.admin.Message <- {}

class phoenix.admin.Message.Request extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.Any /> payload = null
}

class phoenix.admin.Message.Response extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> action = ""
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
	</ type = phoenix.net.type.Any /> payload = null
}
