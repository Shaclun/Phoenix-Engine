USE `phoenix`;

-- Add visual + scenario columns to phoenix_characters if missing.
-- Use generated procedure so script is idempotent.

DROP PROCEDURE IF EXISTS phoenix_add_col;
DELIMITER //
CREATE PROCEDURE phoenix_add_col(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
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

CALL phoenix_add_col('phoenix_characters', 'race',         '`race` TINYINT(4) NOT NULL DEFAULT 1');
CALL phoenix_add_col('phoenix_characters', 'fatness',      '`fatness` TINYINT(4) NOT NULL DEFAULT 1');
CALL phoenix_add_col('phoenix_characters', 'walking',      '`walking` TINYINT(4) NOT NULL DEFAULT 0');
CALL phoenix_add_col('phoenix_characters', 'weapon',       '`weapon` TINYINT(4) NOT NULL DEFAULT 0');
CALL phoenix_add_col('phoenix_characters', 'outfit',       '`outfit` TINYINT(4) NOT NULL DEFAULT 0');
CALL phoenix_add_col('phoenix_characters', 'scenario',     '`scenario` TINYINT(4) NOT NULL DEFAULT 0');
CALL phoenix_add_col('phoenix_characters', 'bodyModel',    '`bodyModel` VARCHAR(48) NOT NULL DEFAULT ''Hum_Body_Naked0''');
CALL phoenix_add_col('phoenix_characters', 'headModel',    '`headModel` VARCHAR(48) NOT NULL DEFAULT ''Hum_Head_Pony''');
CALL phoenix_add_col('phoenix_characters', 'bodyTexIndex', '`bodyTexIndex` INT(11) NOT NULL DEFAULT 1');

-- Fix any old broken world value left by previous escape bug.
UPDATE `phoenix_characters` SET `world` = 'NEWWORLD.ZEN'
	WHERE `world` IN ('NEWWORLDNEWWORLD.ZEN', '', 'NEWWORLD\\NEWWORLD.ZEN');

DROP PROCEDURE IF EXISTS phoenix_add_col;
