USE `phoenix`;

DROP PROCEDURE IF EXISTS phoenix_add_col11;
DELIMITER //
CREATE PROCEDURE phoenix_add_col11(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
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

CALL phoenix_add_col11('phoenix_characters', 'playTimeSec',  '`playTimeSec` INT(11) NOT NULL DEFAULT 0');
CALL phoenix_add_col11('phoenix_characters', 'lastPlayedAt', '`lastPlayedAt` TIMESTAMP NULL DEFAULT NULL');
CALL phoenix_add_col11('phoenix_characters', 'status',       '`status` TINYINT(4) NOT NULL DEFAULT 1');

DROP PROCEDURE IF EXISTS phoenix_add_col11;
