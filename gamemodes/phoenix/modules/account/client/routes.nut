phoenix.web.Router.on("phoenix:account:login", function(payload) {
	if (payload == null) return
	local message = phoenix.account.Message.Login()
	message.username = "username" in payload ? payload.username : ""
	message.password = "password" in payload ? payload.password : ""
	message.serialize().send(RELIABLE_ORDERED)
})

phoenix.web.Router.on("phoenix:account:register", function(payload) {
	if (payload == null) return
	local message = phoenix.account.Message.Register()
	message.username = "username" in payload ? payload.username : ""
	message.password = "password" in payload ? payload.password : ""
	message.email = "email" in payload ? payload.email : ""
	message.serialize().send(RELIABLE_ORDERED)
})
