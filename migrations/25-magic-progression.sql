USE `phoenix`;

DROP PROCEDURE IF EXISTS phoenix_add_column_25;
DELIMITER //
CREATE PROCEDURE phoenix_add_column_25(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
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

CALL phoenix_add_column_25('phoenix_characters', 'magicLevel', '`magicLevel` INT(11) NOT NULL DEFAULT 0 AFTER `crossbow`');
CALL phoenix_add_column_25('phoenix_characters', 'magicXp', '`magicXp` INT(11) NOT NULL DEFAULT 0 AFTER `magicLevel`');

DROP PROCEDURE IF EXISTS phoenix_add_column_25;