class CharacterModel extends ORM.Model
	</ table = "phoenix_characters" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "INT(11)", not_null = true, foreign_key = { table = "phoenix_accounts", column = "id", on_delete = "CASCADE" } />
	accountId = -1

	</ type = "VARCHAR(20)", not_null = true, unique = true />
	name = ""

	</ type = "VARCHAR(20)", not_null = true />
	normalizedName = ""

	</ type = "TINYINT(4)", not_null = true />
	gender = 1

	</ type = "TINYINT(4)", not_null = true />
	klass = 3

	</ type = "TINYINT(4)", not_null = true />
	race = 0

	</ type = "TINYINT(4)", not_null = true />
	fatness = 1

	</ type = "TINYINT(4)", not_null = true />
	walking = 0

	</ type = "TINYINT(4)", not_null = true />
	weapon = 0

	</ type = "TINYINT(4)", not_null = true />
	outfit = 0

	</ type = "TINYINT(4)", not_null = true />
	scenario = 0

	</ type = "VARCHAR(48)", not_null = true />
	bodyModel = "Hum_Body_Naked0"

	</ type = "VARCHAR(48)", not_null = true />
	headModel = "Hum_Head_Pony"

	</ type = "INT(11)", not_null = true />
	bodyTexIndex = 1

	</ type = "INT(11)", not_null = true />
	face = 0

	</ type = "TINYINT(4)", not_null = true />
	voice = 0

	</ type = "INT(11)", not_null = true />
	level = 1

	</ type = "BIGINT(20)", not_null = true />
	experience = 0

	</ type = "BIGINT(20)", not_null = true />
	experienceNext = 500

	</ type = "INT(11)", not_null = true />
	learnPoints = 10

	</ type = "INT(11)", not_null = true />
	hp = 40

	</ type = "INT(11)", not_null = true />
	hpMax = 40

	</ type = "INT(11)", not_null = true />
	mana = 0

	</ type = "INT(11)", not_null = true />
	manaMax = 0

	</ type = "INT(11)", not_null = true />
	stamina = 100

	</ type = "INT(11)", not_null = true />
	staminaMax = 100

	</ type = "INT(11)", not_null = true />
	strength = 10

	</ type = "INT(11)", not_null = true />
	dexterity = 10

	</ type = "INT(11)", not_null = true />
	oneHand = 0

	</ type = "INT(11)", not_null = true />
	twoHand = 0

	</ type = "INT(11)", not_null = true />
	bow = 0

	</ type = "INT(11)", not_null = true />
	crossbow = 0

	</ type = "INT(11)", not_null = true />
	magicLevel = 0

	</ type = "INT(11)", not_null = true />
	magicXp = 0

	</ type = "BIGINT(20)", not_null = true />
	gold = 0

	</ type = "TEXT" />
	equipment = null

	</ type = "TEXT" />
	inventory = null

	</ type = "INT(11)", not_null = true />
	playTimeSec = 0

	</ type = "TINYINT(4)", not_null = true />
	status = 1

	</ type = "VARCHAR(64)", not_null = true />
	world = "NEWWORLD.ZEN"

	</ type = "FLOAT", not_null = true />
	positionX = 0.0

	</ type = "FLOAT", not_null = true />
	positionY = 0.0

	</ type = "FLOAT", not_null = true />
	positionZ = 0.0

	</ type = "FLOAT", not_null = true />
	angle = 0.0

	</ type = "TIMESTAMP", readonly = true />
	createdAt = null

	</ type = "TIMESTAMP", readonly = true />
	lastPlayedAt = null

	</ type = "TIMESTAMP" />
	updatedAt = null

	</ type = "TEXT" />
	hotbar = null

	</ type = "TEXT" />
	uiSettings = null

	function beforeModelInsert() {
		if (normalizedName == "" && name != "")
			normalizedName = name.tolower()
	}

	static function findByAccount(accountId, callback) {
		findAsync(@(q) q.where("accountId", "=", accountId).orderBy("id").asc(), callback)
	}

	static function findByNormalizedName(value, callback) {
		findOneAsync(@(q) q.where("normalizedName", "=", value.tolower()), callback)
	}

	static function countByAccount(accountId, callback) {
		countAsync(@(q) q.where("accountId", "=", accountId), callback)
	}
}
