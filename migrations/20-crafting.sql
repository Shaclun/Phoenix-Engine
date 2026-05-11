USE `phoenix`;

-- Legacy crafting tables had column name `instance` which collides with ORM.Model internals.
-- Drop so ORM recreates clean schema with `itemInstance` column.
DROP TABLE IF EXISTS `phoenix_crafting_outputs`;
DROP TABLE IF EXISTS `phoenix_crafting_stations`;
DROP TABLE IF EXISTS `phoenix_crafting_ingredients`;
DROP TABLE IF EXISTS `phoenix_crafting_recipes`;
