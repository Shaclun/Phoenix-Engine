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

CALL phoenix_add_col2('phoenix_characters', 'stamina',    '`stamina` INT(11) NOT NULL DEFAULT 100');
CALL phoenix_add_col2('phoenix_characters', 'staminaMax', '`staminaMax` INT(11) NOT NULL DEFAULT 100');

DROP PROCEDURE IF EXISTS phoenix_add_col2;
