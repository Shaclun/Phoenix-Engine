phoenix.database.Migrations <- {
	files = [
		"01-init.sql",
		"02-character-visual-fields.sql",
		"03-character-stats.sql",
		"04-items.sql",
		"05-admin-and-bans.sql",
		"06-admin-extras.sql",
		"06-stamina-and-progression.sql",
		"07-npc-quests.sql",
		"08-npc-presets.sql",
		"09-npc-ai.sql",
		"10-ground-herbs.sql",
		"11-character-meta.sql",
		"12-world-vobs.sql",
		"13-weapon-progression.sql",
		"14-npc-base-experience.sql",
		"15-houses.sql",
		"16-social.sql",
		"17-npc-routines.sql",
		"18-world-clock.sql",
		"19-bestiary-extension.sql",
		"20-crafting.sql",
		"21-admin-config.sql",
		"22-character-created-at.sql",
		"23-bestiary-render.sql",
		"24-item-render.sql",
		"25-magic-progression.sql",
		"26-advanced-quests.sql",
		"27-hud-portrait-default.sql",
		"28-hud-portrait-scale.sql",
		"29-custom-consumables-effects.sql",
		"30-advanced-crafting.sql",
		"31-professions.sql",
		"32-server-feature-settings.sql",
		"33-server-feature-registry.sql",
		"34-rp-daily-development.sql"
	]

	function readStatements(path) {
		local stream = null
		local statements = []
		local statement = ""
		local delimiter = ";"
		try {
			stream = file(path, "r")
			local raw = null
			while (raw = stream.read()) {
				local line = strip(raw)
				if (line.len() == 0) continue
				if (line.len() >= 2 && line.slice(0, 2) == "--") continue
				if (line.len() >= 1 && line.slice(0, 1) == "#") continue
				if (line.len() >= 9 && line.slice(0, 9).toupper() == "DELIMITER") {
					delimiter = strip(line.slice(9))
					if (delimiter.len() == 0) throw "empty DELIMITER"
					continue
				}
				local finished = line.len() >= delimiter.len() && line.slice(line.len() - delimiter.len()) == delimiter
				local content = finished ? line.slice(0, line.len() - delimiter.len()) : line
				statement += content + "\n"
				if (!finished) continue
				local sql = strip(statement)
				if (sql.len() != 0) statements.push(sql)
				statement = ""
			}
			stream.close()
		} catch (error) {
			if (stream != null) try { stream.close() } catch (closeError) {}
			throw "cannot read migration '" + path + "': " + error
		}
		if (strip(statement).len() != 0) throw "unterminated statement in migration '" + path + "'"
		return statements
	}

	function releaseLock() {
		try { ORM.engine.execute("SELECT RELEASE_LOCK('phoenix_schema_migrations')") } catch (error) {}
	}

	function applyOne(filename) {
		local version = filename.slice(0, filename.len() - 4)
		local path = "migrations/" + filename
		local rows = ORM.engine.execute("SELECT `version` FROM `phoenix_schema_migrations` WHERE `version`='" + version + "' LIMIT 1")
		if (rows.len() != 0) return
		foreach (statement in readStatements(path))
			ORM.engine.execute(statement)
		ORM.engine.execute("INSERT INTO `phoenix_schema_migrations` (`version`,`fileName`) VALUES ('" + version + "','" + path + "')")
		print("ORM: Migrating '" + version + "' Succeeded!")
	}

	function apply() {
		ORM.engine.execute("CREATE TABLE IF NOT EXISTS `phoenix_schema_migrations` (`version` VARCHAR(96) NOT NULL,`fileName` VARCHAR(255) NOT NULL,`appliedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY (`version`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")
		local lockRows = ORM.engine.execute("SELECT GET_LOCK('phoenix_schema_migrations', 30) AS `acquired`")
		if (lockRows.len() == 0 || lockRows[0].acquired == null || lockRows[0].acquired.tointeger() != 1)
			throw "ORM: Cannot acquire schema migration lock"
		print("ORM: SQL migration started")
		try {
			foreach (filename in files)
				applyOne(filename)
		} catch (error) {
			releaseLock()
			throw "ORM: SQL migration failed: " + error
		}
		releaseLock()
		print("ORM: SQL migration completed successfully")
	}
}