USE `phoenix`;

DROP PROCEDURE IF EXISTS phoenix_add_col2;
DELIMITER //
CREATE PROCEDURE phoenix_add_col2(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.COLUMNS
		WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = tbl AND COLUMN_NAME = col
	) THEN
		SET @s = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN ', ddl);
		PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
	END IF;
END //
DELIMITER ;

CALL phoenix_add_col2('phoenix_npc_spawns', 'baseExperience', '`baseExperience` INT NOT NULL DEFAULT 0 AFTER `walkSpeed`');
CALL phoenix_add_col2('phoenix_npc_presets', 'baseExperience', '`baseExperience` INT NOT NULL DEFAULT 0 AFTER `walkSpeed`');

CREATE TABLE IF NOT EXISTS `phoenix_npc_catalog_overrides` (
	`instance` VARCHAR(64) NOT NULL,
	`label` VARCHAR(128) NOT NULL DEFAULT '',
	`category` VARCHAR(32) NOT NULL DEFAULT 'monster',
	`tier` INT NOT NULL DEFAULT 1,
	`defaultHostile` TINYINT NOT NULL DEFAULT 1,
	`baseExperience` INT NOT NULL DEFAULT 0,
	`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP PROCEDURE IF EXISTS phoenix_add_col2;