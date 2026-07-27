phoenix.database.Connector <- {
	asyncConnected = false
	schemaReady = false
	readyEmitted = false

	function loadEnv() {
		if (!("_initialized" in dotenv) || !dotenv._initialized) {
			dotenv.init()
			dotenv._initialized <- true
		}
	}

	function readConfig() {
		return {
			host = dotenv.get("DATABASE_HOST")
			user = dotenv.get("DATABASE_USERNAME")
			password = dotenv.get("DATABASE_PASSWORD")
			dbname = dotenv.get("DATABASE_DBNAME")
			port = dotenv.get("DATABASE_PORT")
		}
	}

	function isComplete(cfg) {
		if (cfg.host == null || cfg.user == null || cfg.password == null || cfg.dbname == null) return false
		return true
	}

	function notifyReady() {
		if (readyEmitted || !asyncConnected || !schemaReady) return
		readyEmitted = true
		phoenix.database.ready = true
		callEvent("phoenix.database.OnReady")
	}

	function bootstrap() {
		loadEnv()
		// Schema changes are owned by versioned SQL migrations. The ORM migrator
		// cannot introspect named composite indexes and may rebuild constrained tables.
		ORM.migration_enabled = false

		local cfg = readConfig()
		if (!isComplete(cfg))
			throw "ORM: Missing DATABASE_* values in .env"

		ORM.onSyncConnect = function(connection) {
			callEvent("phoenix.database.OnSyncReady")
		}

		ORM.onAsyncConnect = function(connection) {
			phoenix.database.Connector.asyncConnected = true
			phoenix.database.Connector.notifyReady()
		}

		local port = cfg.port == null ? 3306 : cfg.port.tointeger()
		ORM.engine = ORM.MySQL(cfg.host, cfg.user, cfg.password, cfg.dbname, port)

		addEventHandler("onInit", function() {
			ORM.Migration.createNewTables = function() {
				foreach (c, class_data in ORM.Model.classes) {
					local q = ORM.Query(c).createTable().build()
					ORM.engine.execute(q)
				}
			}
			ORM.init()
			phoenix.database.Migrations.apply()
			phoenix.database.Connector.schemaReady = true
			phoenix.database.Connector.notifyReady()
		})
	}
}

phoenix.database.Connector.bootstrap()
