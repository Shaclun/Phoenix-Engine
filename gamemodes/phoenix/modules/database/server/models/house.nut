class HouseModel extends ORM.Model
	</ table = "phoenix_houses" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "VARCHAR(64)", not_null = true />
	name = ""

	</ type = "VARCHAR(64)", not_null = true, unique = true />
	slug = ""

	</ type = "VARCHAR(64)", not_null = true />
	world = "NEWWORLD"

	</ type = "FLOAT", not_null = true />
	centerX = 0.0

	</ type = "FLOAT", not_null = true />
	centerY = 0.0

	</ type = "FLOAT", not_null = true />
	centerZ = 0.0

	</ type = "FLOAT", not_null = true />
	minX = 0.0

	</ type = "FLOAT", not_null = true />
	minY = 0.0

	</ type = "FLOAT", not_null = true />
	minZ = 0.0

	</ type = "FLOAT", not_null = true />
	maxX = 0.0

	</ type = "FLOAT", not_null = true />
	maxY = 0.0

	</ type = "FLOAT", not_null = true />
	maxZ = 0.0

	</ type = "TEXT" />
	cornersJson = null

	</ type = "TEXT" />
	metadataJson = null

	</ type = "FLOAT" />
	entryX = null

	</ type = "FLOAT" />
	entryY = null

	</ type = "FLOAT" />
	entryZ = null

	</ type = "FLOAT" />
	entryHeading = null

	</ type = "TINYINT(4)" />
	ownerType = null

	</ type = "INT(11)" />
	ownerId = null

	</ type = "INT(11)", not_null = true />
	priceGold = 0

	</ type = "INT(11)", not_null = true />
	weeklyRentGold = 0

	</ type = "INT(11)", not_null = true />
	rentPaidUntil = 0

	</ type = "TEXT" />
	guestAccountIds = null

	</ type = "VARCHAR(9)" />
	color = null

	</ type = "INT(11)", not_null = true />
	modeId = 0

	</ type = "TINYINT(1)", not_null = true />
	active = 1

	</ type = "INT(11)" />
	createdBy = null

	</ type = "TIMESTAMP", readonly = true />
	createdAt = null

	</ type = "TIMESTAMP" />
	updatedAt = null
}