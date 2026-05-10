

class ItemModel extends ORM.Model
	</ table = "phoenix_items" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "TINYINT(4)", not_null = true />
	ownerType = 0

	</ type = "INT(11)", not_null = true />
	ownerId = -1

	</ type = "VARCHAR(64)", not_null = true />
	instanceId = ""

	</ type = "INT(11)", not_null = true />
	amount = 1

	</ type = "TINYINT(4)", not_null = true />
	quality = 2

	</ type = "TINYINT(4)", not_null = true />
	upgrade = 0

	</ type = "INT(11)", not_null = true />
	durability = 100

	</ type = "TINYINT(4)", not_null = true />
	equipped = 0

	</ type = "TINYINT(4)", not_null = true />
	slot = 0

	</ type = "VARCHAR(32)", not_null = true />
	source = "system"

	</ type = "TIMESTAMP", readonly = true />
	createdAt = null

	</ type = "TIMESTAMP" />
	updatedAt = null

	static function findByOwner(ownerType, ownerId, callback) {
		ItemModel.findAsync(
			@(q) q.where("ownerType", "=", ownerType).and("ownerId", "=", ownerId),
			callback
		)
	}

	static function findOneById(id, callback) {
		ItemModel.findOneAsync(@(q) q.where("id", "=", id), callback)
	}

	static function deleteByOwner(ownerType, ownerId, callback) {
		local sql = "DELETE FROM `phoenix_items` WHERE `ownerType` = " + ownerType +
		            " AND `ownerId` = " + ownerId
		ORM.engine.executeAsync(sql, callback)
	}
}
