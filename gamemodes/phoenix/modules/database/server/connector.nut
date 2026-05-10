phoenix.database.Connector <- {
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

	function bootstrap() {
		loadEnv()
		ORM.migration_enabled = true

		local cfg = readConfig()
		if (!isComplete(cfg))
			throw "(phoenix.database) missing DATABASE_* values in .env"

		ORM.onSyncConnect = function(connection) {
			callEvent("phoenix.database.OnSyncReady")
		}

		ORM.onAsyncConnect = function(connection) {
			phoenix.database.ready = true
			callEvent("phoenix.database.OnReady")
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
		})
	}
}

phoenix.database.Connector.bootstrap()
