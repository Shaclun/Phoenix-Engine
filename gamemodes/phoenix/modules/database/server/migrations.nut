phoenix.database.Migrations <- {
	files = [
		{ version = "26-advanced-quests", path = "migrations/26-advanced-quests.sql" }
	]

	function readStatements(path) {
		local stream = null
		local statements = []
		local statement = ""
		try {
			stream = file(path, "r")
			local line = null
			while (line = stream.read()) {
				line = strip(line)
				if (line.len() == 0) continue
				statement += (statement.len() == 0 ? "" : " ") + line
				if (line[line.len() - 1] != ';') continue
				statements.push(statement.slice(0, statement.len() - 1))
				statement = ""
			}
			stream.close()
		} catch (error) {
			if (stream != null) try { stream.close() } catch (closeError) {}
			throw "(phoenix.database) cannot read migration '" + path + "': " + error
		}
		if (statement.len() != 0)
			throw "(phoenix.database) unterminated statement in migration '" + path + "'"
		return statements
	}

	function releaseLock() {
		try { ORM.engine.execute("SELECT RELEASE_LOCK('phoenix_schema_migrations')") } catch (error) {}
	}

	function applyOne(migration) {
		local rows = ORM.engine.execute("SELECT `version` FROM `phoenix_schema_migrations` WHERE `version`='" + migration.version + "' LIMIT 1")
		if (rows.len() != 0) return
		local statements = readStatements(migration.path)
		foreach (statement in statements)
			ORM.engine.execute(statement)
		ORM.engine.execute("INSERT INTO `phoenix_schema_migrations` (`version`,`fileName`) VALUES ('" + migration.version + "','" + migration.path + "')")
		print("(phoenix.database) applied migration " + migration.version)
	}
	function apply() {
		ORM.engine.execute("CREATE TABLE IF NOT EXISTS `phoenix_schema_migrations` (`version` VARCHAR(96) NOT NULL,`fileName` VARCHAR(255) NOT NULL,`appliedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY (`version`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
		local lockRows = ORM.engine.execute("SELECT GET_LOCK('phoenix_schema_migrations', 30) AS `acquired`")
		if (lockRows.len() == 0 || lockRows[0].acquired == null || lockRows[0].acquired.tointeger() != 1)
			throw "(phoenix.database) cannot acquire schema migration lock"
		try {
			foreach (migration in files)
				applyOne(migration)
		} catch (error) {
			releaseLock()
			throw "(phoenix.database) migration failed: " + error
		}
		releaseLock()
	}
}
