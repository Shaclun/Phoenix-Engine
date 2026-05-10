phoenix.account.Validator <- {
	MIN_USERNAME_LEN = 4
	MAX_USERNAME_LEN = 24
	MIN_PASSWORD_LEN = 6
	MAX_PASSWORD_LEN = 64
	MIN_EMAIL_LEN = 5
	MAX_EMAIL_LEN = 96

	USERNAME_PATTERN = "^[a-zA-Z0-9_]+$"
	EMAIL_PATTERN = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"

	function username(value) {
		if (typeof value != "string") return "phoenix.account.error.username.format"
		if (value.len() < MIN_USERNAME_LEN) return "phoenix.account.error.username.tooShort"
		if (value.len() > MAX_USERNAME_LEN) return "phoenix.account.error.username.tooLong"
		if (!regexp(USERNAME_PATTERN).match(value)) return "phoenix.account.error.username.format"
		return null
	}

	function password(value) {
		if (typeof value != "string") return "phoenix.account.error.password.format"
		if (value.len() < MIN_PASSWORD_LEN) return "phoenix.account.error.password.tooShort"
		if (value.len() > MAX_PASSWORD_LEN) return "phoenix.account.error.password.tooLong"
		return null
	}

	function email(value, optional = false) {
		if (typeof value != "string") return "phoenix.account.error.email.format"
		if (optional && value.len() == 0) return null
		if (value.len() < MIN_EMAIL_LEN) return "phoenix.account.error.email.tooShort"
		if (value.len() > MAX_EMAIL_LEN) return "phoenix.account.error.email.tooLong"
		if (!regexp(EMAIL_PATTERN).match(value)) return "phoenix.account.error.email.format"
		return null
	}
}
