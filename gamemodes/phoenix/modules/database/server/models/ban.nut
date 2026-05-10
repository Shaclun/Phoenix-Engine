class BanModel extends ORM.Model
	</ table = "phoenix_bans" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "TINYINT(4)", not_null = true />
	scope = 0

	</ type = "INT(11)" />
	accountId = null

	</ type = "INT(11)" />
	characterId = null

	</ type = "VARCHAR(45)", not_null = true />
	ipAddress = ""

	</ type = "VARCHAR(64)", not_null = true />
	serial = ""

	</ type = "VARCHAR(255)", not_null = true />
	reason = ""

	</ type = "INT(11)" />
	issuedBy = null

	</ type = "TIMESTAMP", readonly = true />
	issuedAt = null

	</ type = "TIMESTAMP" />
	expiresAt = null

	</ type = "TINYINT(1)", not_null = true />
	active = 1

	function beforeModelSave() {
		if (typeof active == "bool") active = active ? 1 : 0
	}

	function afterModelLoad() {
		active = active != 0
	}

	static function _runWhereAsync(filter_callback, callback) {
		local self = BanModel
		local query = ORM.Query(self).select()
		query = filter_callback(query)
		ORM.engine.executeAsync(query.build(), function(rows) {
			local out = []
			foreach (row in rows) out.push(self.convert_to_instance(row))
			callback(out)
		})
	}

	static function findActiveForAccount(accountId, callback) {
		BanModel._runWhereAsync(@(q) q.where("accountId", "=", accountId).and("active", "=", 1), callback)
	}

	static function findActiveForIp(ip, callback) {
		if (ip == null || ip == "") return callback([])
		BanModel._runWhereAsync(@(q) q.where("ipAddress", "=", ip).and("active", "=", 1), callback)
	}

	static function findActiveForSerial(serial, callback) {
		if (serial == null || serial == "") return callback([])
		BanModel._runWhereAsync(@(q) q.where("serial", "=", serial).and("active", "=", 1), callback)
	}

	static function findActiveForCharacter(characterId, callback) {
		BanModel._runWhereAsync(@(q) q.where("characterId", "=", characterId).and("active", "=", 1), callback)
	}
}
