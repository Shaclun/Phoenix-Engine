class CraftingRecipeModel extends ORM.Model
	</ table = "phoenix_crafting_recipes" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "VARCHAR(96)", not_null = true />
	name = ""

	</ type = "VARCHAR(64)", not_null = true />
	resultInstance = ""

	</ type = "INT(11)", not_null = true />
	resultAmount = 1

	</ type = "VARCHAR(32)", not_null = true />
	category = "misc"

	</ type = "INT(11)", not_null = true />
	craftTimeMs = 1500

	</ type = "INT(11)", not_null = true />
	requiredLevel = 0

	</ type = "TEXT" />
	description = null

	</ type = "TIMESTAMP", readonly = true />
	createdAt = null

	</ type = "TIMESTAMP" />
	updatedAt = null
}

class CraftingIngredientModel extends ORM.Model
	</ table = "phoenix_crafting_ingredients" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "INT(11)", not_null = true />
	recipeId = 0

	</ type = "VARCHAR(16)", not_null = true />
	role = "consume"

	</ type = "VARCHAR(64)", not_null = true />
	itemInstance = ""

	</ type = "INT(11)", not_null = true />
	amount = 1

	</ type = "INT(11)", not_null = true />
	position = 0
}

class CraftingOutputModel extends ORM.Model
	</ table = "phoenix_crafting_outputs" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "INT(11)", not_null = true />
	recipeId = 0

	</ type = "VARCHAR(64)", not_null = true />
	itemInstance = ""

	</ type = "INT(11)", not_null = true />
	amount = 1

	</ type = "INT(11)", not_null = true />
	position = 0
}

class CraftingStationModel extends ORM.Model
	</ table = "phoenix_crafting_stations" />
{
	</ primary_key = true, auto_increment = true, not_null = true />
	id = -1

	</ type = "VARCHAR(96)", not_null = true />
	visual = ""

	</ type = "INT(11)", not_null = true />
	recipeId = 0

	</ type = "INT(11)", not_null = true />
	position = 0
}
