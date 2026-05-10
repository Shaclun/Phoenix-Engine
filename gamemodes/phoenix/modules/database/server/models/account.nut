class AccountModel extends ORM.Model
	</ table = "phoenix_accounts" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "VARCHAR(32)", not_null = true, unique = true />
	username = ""

	</ type = "VARCHAR(32)", not_null = true />
	normalizedUsername = ""

	</ type = "VARCHAR(96)", not_null = true />
	email = ""

	</ type = "VARCHAR(64)", not_null = true />
	passwordHash = ""

	</ type = "VARCHAR(64)", not_null = true />
	passwordSalt = ""

	</ type = "VARCHAR(64)", not_null = true />
	serial = ""

	</ type = "TINYINT(4)", not_null = true />
	status = 1

	</ type = "TINYINT(4)", not_null = true />
	role = 0

	</ type = "TINYINT(4)", not_null = true />
	online = 0

	</ type = "TIMESTAMP", readonly = true />
	createdAt = null

	</ type = "TIMESTAMP" />
	updatedAt = null

	function beforeModelInsert() {
		if (normalizedUsername == "" && username != "")
			normalizedUsername = username.tolower()
	}

	function beforeModelSave() {
		if (typeof online == "bool")
			online = online ? 1 : 0
	}

	function afterModelLoad() {
		online = online != 0
	}

	static function findByUsername(value, callback) {
		findOneAsync(@(q) q.where("normalizedUsername", "=", value.tolower()), callback)
	}
}
