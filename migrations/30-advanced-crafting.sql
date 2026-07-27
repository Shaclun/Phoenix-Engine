USE `phoenix`;

-- Normalize legacy rows before enforcing the invariants used by advanced crafting.
DELETE i FROM `phoenix_crafting_ingredients` i LEFT JOIN `phoenix_crafting_recipes` r ON r.id=i.recipeId WHERE r.id IS NULL;
DELETE o FROM `phoenix_crafting_outputs` o LEFT JOIN `phoenix_crafting_recipes` r ON r.id=o.recipeId WHERE r.id IS NULL;
DELETE s FROM `phoenix_crafting_stations` s LEFT JOIN `phoenix_crafting_recipes` r ON r.id=s.recipeId WHERE r.id IS NULL;
UPDATE `phoenix_crafting_ingredients` SET role='consume' WHERE role NOT IN ('consume','tool');
DELETE a FROM `phoenix_crafting_ingredients` a JOIN `phoenix_crafting_ingredients` b ON a.recipeId=b.recipeId AND a.role=b.role AND a.itemInstance=b.itemInstance AND a.id>b.id;
DELETE a FROM `phoenix_crafting_outputs` a JOIN `phoenix_crafting_outputs` b ON a.recipeId=b.recipeId AND a.itemInstance=b.itemInstance AND a.id>b.id;
DELETE a FROM `phoenix_crafting_stations` a JOIN `phoenix_crafting_stations` b ON a.recipeId=b.recipeId AND a.visual=b.visual AND a.id>b.id;
UPDATE `phoenix_crafting_recipes` SET craftTimeMs=1500 WHERE craftTimeMs<100 OR craftTimeMs>600000;

DROP PROCEDURE IF EXISTS `phoenix_crafting_add_index`;
DROP PROCEDURE IF EXISTS `phoenix_crafting_add_fk`;
DELIMITER $$
CREATE PROCEDURE `phoenix_crafting_add_index`(IN p_table VARCHAR(64), IN p_index VARCHAR(64), IN p_ddl TEXT)
BEGIN
 IF NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND INDEX_NAME=p_index) THEN
  SET @crafting_ddl=p_ddl; PREPARE crafting_stmt FROM @crafting_ddl; EXECUTE crafting_stmt; DEALLOCATE PREPARE crafting_stmt;
 END IF;
END$$
CREATE PROCEDURE `phoenix_crafting_add_fk`(IN p_constraint VARCHAR(64), IN p_ddl TEXT)
BEGIN
 IF NOT EXISTS (SELECT 1 FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_NAME=p_constraint) THEN
  SET @crafting_ddl=p_ddl; PREPARE crafting_stmt FROM @crafting_ddl; EXECUTE crafting_stmt; DEALLOCATE PREPARE crafting_stmt;
 END IF;
END$$
DELIMITER ;
CALL `phoenix_crafting_add_index`('phoenix_crafting_recipes','idx_crafting_category','ALTER TABLE `phoenix_crafting_recipes` ADD INDEX `idx_crafting_category` (`category`,`requiredLevel`)');
CALL `phoenix_crafting_add_index`('phoenix_crafting_ingredients','uq_crafting_ingredient','ALTER TABLE `phoenix_crafting_ingredients` ADD UNIQUE INDEX `uq_crafting_ingredient` (`recipeId`,`role`,`itemInstance`)');
CALL `phoenix_crafting_add_index`('phoenix_crafting_outputs','uq_crafting_output','ALTER TABLE `phoenix_crafting_outputs` ADD UNIQUE INDEX `uq_crafting_output` (`recipeId`,`itemInstance`)');
CALL `phoenix_crafting_add_index`('phoenix_crafting_stations','uq_crafting_station','ALTER TABLE `phoenix_crafting_stations` ADD UNIQUE INDEX `uq_crafting_station` (`recipeId`,`visual`)');
CALL `phoenix_crafting_add_index`('phoenix_crafting_stations','idx_crafting_station_visual','ALTER TABLE `phoenix_crafting_stations` ADD INDEX `idx_crafting_station_visual` (`visual`)');
CALL `phoenix_crafting_add_fk`('fk_crafting_ingredient_recipe','ALTER TABLE `phoenix_crafting_ingredients` ADD CONSTRAINT `fk_crafting_ingredient_recipe` FOREIGN KEY (`recipeId`) REFERENCES `phoenix_crafting_recipes` (`id`) ON DELETE CASCADE');
CALL `phoenix_crafting_add_fk`('fk_crafting_output_recipe','ALTER TABLE `phoenix_crafting_outputs` ADD CONSTRAINT `fk_crafting_output_recipe` FOREIGN KEY (`recipeId`) REFERENCES `phoenix_crafting_recipes` (`id`) ON DELETE CASCADE');
CALL `phoenix_crafting_add_fk`('fk_crafting_station_recipe','ALTER TABLE `phoenix_crafting_stations` ADD CONSTRAINT `fk_crafting_station_recipe` FOREIGN KEY (`recipeId`) REFERENCES `phoenix_crafting_recipes` (`id`) ON DELETE CASCADE');
DROP PROCEDURE IF EXISTS `phoenix_crafting_add_index`;
DROP PROCEDURE IF EXISTS `phoenix_crafting_add_fk`;
