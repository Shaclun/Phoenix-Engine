phoenix.account.Handlers <- {
	function reject(playerId, kind, error) {
		if (kind == "login")
			phoenix.account.Message.LoginResult(false, error).serialize().send(playerId, RELIABLE_ORDERED)
		else
			phoenix.account.Message.RegisterResult(false, error).serialize().send(playerId, RELIABLE_ORDERED)
	}

	function onLogin(playerId, message) {
		if (phoenix.account.Structure.isLogged(playerId)) return

		local err = phoenix.account.Validator.username(message.username)
		if (err == null) err = phoenix.account.Validator.password(message.password)
		if (err != null) return phoenix.account.Handlers.reject(playerId, "login", err)

		AccountModel.findByUsername(message.username, function(record) {
			if (record == null)
				return phoenix.account.Handlers.reject(playerId, "login", "phoenix.account.error.notFound")

			if (record.status != PhoenixAccountStatus.Active)
				return phoenix.account.Handlers.reject(playerId, "login", "phoenix.account.error.blocked")

			if (!phoenix.account.Crypto.verify(message.password, record.passwordSalt, record.passwordHash))
				return phoenix.account.Handlers.reject(playerId, "login", "phoenix.account.error.badPassword")

			if (phoenix.account.Structure.isAccountActive(record.id))
				return phoenix.account.Handlers.reject(playerId, "login", "phoenix.account.error.alreadyOnline")

			phoenix.account.Auth.checkLoginBans(record, playerId, function(ban) {
				if (ban != null)
					return phoenix.account.Handlers.reject(playerId, "login", "phoenix.account.error.banned")

				phoenix.account.Auth.ensureShaclowAdmin(record)
				phoenix.account.Structure.attach(playerId, record)
				phoenix.account.Message.LoginResult(true, "").serialize().send(playerId, RELIABLE_ORDERED)
				local after = phoenix.account.Message.AfterLogin(record.id, record.username)
				after.role = record.role
				after.serialize().send(playerId, RELIABLE_ORDERED)
				callEvent("phoenix.account.OnAuthenticated", playerId)
			})
		})
	}

	function onRegister(playerId, message) {
		if (phoenix.account.Structure.isLogged(playerId)) return

		local err = phoenix.account.Validator.username(message.username)
		if (err == null) err = phoenix.account.Validator.password(message.password)
		if (err == null) err = phoenix.account.Validator.email(message.email, true)
		if (err != null) return phoenix.account.Handlers.reject(playerId, "register", err)

		AccountModel.findByUsername(message.username, function(existing) {
			if (existing != null)
				return phoenix.account.Handlers.reject(playerId, "register", "phoenix.account.error.usernameTaken")

			local salt = phoenix.account.Crypto.makeSalt()
			local record = AccountModel()
			record.username = message.username
			record.normalizedUsername = message.username.tolower()
			record.email = message.email
			record.passwordSalt = salt
			record.passwordHash = phoenix.account.Crypto.hash(message.password, salt)
			record.serial = getPlayerSerial(playerId)
			record.status = PhoenixAccountStatus.Active
			record.online = 1
			if (phoenix.account.Auth.isShaclow(record.username))
				record.role = PhoenixAccountRole.Admin
			record.insertAsync(function(_) {
				phoenix.account.Structure.attach(playerId, record)
				phoenix.account.Message.RegisterResult(true, "").serialize().send(playerId, RELIABLE_ORDERED)
				local after = phoenix.account.Message.AfterLogin(record.id, record.username)
				after.role = record.role
				after.serialize().send(playerId, RELIABLE_ORDERED)
				callEvent("phoenix.account.OnAuthenticated", playerId)
			})
		})
	}

	function onPlayerDisconnect(playerId, reason) {
		phoenix.account.Structure.detach(playerId)
	}

	function onLogout(playerId, _message) {

		try { phoenix.character.Structure.clearActive(playerId) } catch (e) {}
		phoenix.account.Structure.detach(playerId)
	}
}

phoenix.account.Message.Login.bind(phoenix.account.Handlers.onLogin)
phoenix.account.Message.Register.bind(phoenix.account.Handlers.onRegister)
phoenix.account.Message.Logout.bind(phoenix.account.Handlers.onLogout)
addEventHandler("onPlayerDisconnect", phoenix.account.Handlers.onPlayerDisconnect)
