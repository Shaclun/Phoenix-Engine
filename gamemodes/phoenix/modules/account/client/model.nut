phoenix.account.Model <- {
	authenticated = false
	id = 0
	username = ""
	role = 0

	function reset() {
		phoenix.account.Model.authenticated = false
		phoenix.account.Model.id = 0
		phoenix.account.Model.username = ""
		phoenix.account.Model.role = 0
	}

	function onAfterLogin(message) {
		phoenix.account.Model.authenticated = true
		phoenix.account.Model.id = message.accountId
		phoenix.account.Model.username = message.username
		try { phoenix.account.Model.role = message.role } catch (e) { phoenix.account.Model.role = 0 }
		try { phoenix.web.Manager.emit("phoenix:account:identity", {
			id = phoenix.account.Model.id,
			username = phoenix.account.Model.username,
			role = phoenix.account.Model.role,
			isAdmin = phoenix.account.Model.role == 1
		}) } catch (e) {}
		callEvent("phoenix.account.OnAuthenticated")
	}

	function onLoginResult(message) {
		phoenix.web.Manager.emit("phoenix:account:loginResult", {
			success = message.success
			error = message.error
		})
	}

	function onRegisterResult(message) {
		phoenix.web.Manager.emit("phoenix:account:registerResult", {
			success = message.success
			error = message.error
		})
	}
}

phoenix.account.Message.AfterLogin.bind(phoenix.account.Model.onAfterLogin)
phoenix.account.Message.LoginResult.bind(phoenix.account.Model.onLoginResult)
phoenix.account.Message.RegisterResult.bind(phoenix.account.Model.onRegisterResult)
