USE `phoenix`;

-- Remove only the known legacy layout. Replaying this migration must never
-- drop current crafting tables merely because they already exist.
SET @legacy_crafting = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'phoenix_crafting_ingredients'
      AND COLUMN_NAME = 'instance'
);
SET @drop_legacy_crafting = IF(
    @legacy_crafting > 0,
    'DROP TABLE IF EXISTS `phoenix_crafting_outputs`, `phoenix_crafting_stations`, `phoenix_crafting_ingredients`, `phoenix_crafting_recipes`',
    'SELECT 1'
);
PREPARE crafting_stmt FROM @drop_legacy_crafting;
EXECUTE crafting_stmt;
DEALLOCATE PREPARE crafting_stmt;