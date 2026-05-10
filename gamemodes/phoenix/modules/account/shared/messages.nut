class phoenix.account.Message.Login extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> username = ""
	</ type = phoenix.net.type.String /> password = ""
}

class phoenix.account.Message.Register extends phoenix.net.Message {
	</ type = phoenix.net.type.String /> username = ""
	</ type = phoenix.net.type.String /> password = ""
	</ type = phoenix.net.type.String /> email = ""
}

class phoenix.account.Message.LoginResult extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
}

class phoenix.account.Message.RegisterResult extends phoenix.net.Message {
	</ type = phoenix.net.type.Bool /> success = false
	</ type = phoenix.net.type.String /> error = ""
}

class phoenix.account.Message.AfterLogin extends phoenix.net.Message {
	</ type = phoenix.net.type.UInt32 /> accountId = 0
	</ type = phoenix.net.type.String /> username = ""
	</ type = phoenix.net.type.UInt8 /> role = 0
}

class phoenix.account.Message.Logout extends phoenix.net.Message {
}
