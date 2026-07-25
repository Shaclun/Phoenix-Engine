USE `phoenix`;

DROP PROCEDURE IF EXISTS phoenix_add_column_09;
DELIMITER //
CREATE PROCEDURE phoenix_add_column_09(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = tbl AND COLUMN_NAME = col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN ', ddl);
        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

CALL phoenix_add_column_09('phoenix_npc_presets', 'kind', '`kind` VARCHAR(16) NOT NULL DEFAULT ''monster'' AFTER `category`');
CALL phoenix_add_column_09('phoenix_npc_presets', 'idleAnimation', '`idleAnimation` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `voice`');
CALL phoenix_add_column_09('phoenix_npc_presets', 'aggroRadius', '`aggroRadius` INT NOT NULL DEFAULT 1800 AFTER `idleAnimation`');
CALL phoenix_add_column_09('phoenix_npc_presets', 'attackRange', '`attackRange` INT NOT NULL DEFAULT 180 AFTER `aggroRadius`');
CALL phoenix_add_column_09('phoenix_npc_presets', 'attackDamage', '`attackDamage` INT NOT NULL DEFAULT 10 AFTER `attackRange`');
CALL phoenix_add_column_09('phoenix_npc_presets', 'walkSpeed', '`walkSpeed` INT NOT NULL DEFAULT 250 AFTER `attackDamage`');
CALL phoenix_add_column_09('phoenix_npc_spawns', 'kind', '`kind` VARCHAR(16) NOT NULL DEFAULT ''monster'' AFTER `presetId`');
CALL phoenix_add_column_09('phoenix_npc_spawns', 'idleAnimation', '`idleAnimation` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `voice`');
CALL phoenix_add_column_09('phoenix_npc_spawns', 'aggroRadius', '`aggroRadius` INT NOT NULL DEFAULT 1800 AFTER `idleAnimation`');
CALL phoenix_add_column_09('phoenix_npc_spawns', 'attackRange', '`attackRange` INT NOT NULL DEFAULT 180 AFTER `aggroRadius`');
CALL phoenix_add_column_09('phoenix_npc_spawns', 'attackDamage', '`attackDamage` INT NOT NULL DEFAULT 10 AFTER `attackRange`');
CALL phoenix_add_column_09('phoenix_npc_spawns', 'walkSpeed', '`walkSpeed` INT NOT NULL DEFAULT 250 AFTER `attackDamage`');

DROP PROCEDURE IF EXISTS phoenix_add_column_09;