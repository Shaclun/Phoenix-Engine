USE `phoenix`;

DROP PROCEDURE IF EXISTS phoenix_add_column_08;
DELIMITER //
CREATE PROCEDURE phoenix_add_column_08(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
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

CALL phoenix_add_column_08('phoenix_npc_spawns', 'presetId', '`presetId` INT UNSIGNED NULL AFTER `script`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'scaleX', '`scaleX` FLOAT NOT NULL DEFAULT 1.0 AFTER `angle`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'scaleY', '`scaleY` FLOAT NOT NULL DEFAULT 1.0 AFTER `scaleX`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'scaleZ', '`scaleZ` FLOAT NOT NULL DEFAULT 1.0 AFTER `scaleY`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'fatness', '`fatness` FLOAT NOT NULL DEFAULT 0.0 AFTER `scaleZ`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'hp', '`hp` INT NOT NULL DEFAULT 0 AFTER `fatness`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'level', '`level` INT NOT NULL DEFAULT 0 AFTER `hp`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'strength', '`strength` INT NOT NULL DEFAULT 0 AFTER `level`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'dexterity', '`dexterity` INT NOT NULL DEFAULT 0 AFTER `strength`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'bodyModel', '`bodyModel` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `dexterity`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'bodyTex', '`bodyTex` INT NOT NULL DEFAULT -1 AFTER `bodyModel`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'headModel', '`headModel` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `bodyTex`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'headTex', '`headTex` INT NOT NULL DEFAULT -1 AFTER `headModel`');
CALL phoenix_add_column_08('phoenix_npc_spawns', 'voice', '`voice` INT NOT NULL DEFAULT 0 AFTER `headTex`');
DROP PROCEDURE IF EXISTS phoenix_add_column_08;

SET @has_preset_index = (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='phoenix_npc_spawns' AND INDEX_NAME='idx_npc_spawns_preset');
SET @preset_index_sql = IF(@has_preset_index=0, 'ALTER TABLE `phoenix_npc_spawns` ADD INDEX `idx_npc_spawns_preset` (`presetId`)', 'SELECT 1');
PREPARE preset_index_stmt FROM @preset_index_sql;
EXECUTE preset_index_stmt;
DEALLOCATE PREPARE preset_index_stmt;

CREATE TABLE IF NOT EXISTS `phoenix_npc_presets` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) NOT NULL DEFAULT '',
    `instance` VARCHAR(64) NOT NULL,
    `category` VARCHAR(32) NOT NULL DEFAULT 'monster',
    `hostile` TINYINT NOT NULL DEFAULT 1,
    `respawnSec` INT NOT NULL DEFAULT 60,
    `scaleX` FLOAT NOT NULL DEFAULT 1.0,
    `scaleY` FLOAT NOT NULL DEFAULT 1.0,
    `scaleZ` FLOAT NOT NULL DEFAULT 1.0,
    `fatness` FLOAT NOT NULL DEFAULT 0.0,
    `hp` INT NOT NULL DEFAULT 0,
    `level` INT NOT NULL DEFAULT 0,
    `strength` INT NOT NULL DEFAULT 0,
    `dexterity` INT NOT NULL DEFAULT 0,
    `bodyModel` VARCHAR(64) NOT NULL DEFAULT '',
    `bodyTex` INT NOT NULL DEFAULT -1,
    `headModel` VARCHAR(64) NOT NULL DEFAULT '',
    `headTex` INT NOT NULL DEFAULT -1,
    `voice` INT NOT NULL DEFAULT 0,
    `metadata` JSON NULL,
    `createdBy` INT UNSIGNED NULL,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_npc_presets_code` (`code`),
    KEY `idx_npc_presets_instance` (`instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;