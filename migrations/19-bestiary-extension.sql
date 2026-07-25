USE `phoenix`;

DROP PROCEDURE IF EXISTS phoenix_add_column_19;
DELIMITER //
CREATE PROCEDURE phoenix_add_column_19(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
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
CALL phoenix_add_column_19('phoenix_bestiary', 'name', '`name` VARCHAR(96) NOT NULL DEFAULT '''' AFTER `instance`');
CALL phoenix_add_column_19('phoenix_bestiary', 'visual', '`visual` VARCHAR(96) NOT NULL DEFAULT '''' AFTER `name`');
CALL phoenix_add_column_19('phoenix_bestiary', 'kind', '`kind` VARCHAR(24) NOT NULL DEFAULT ''monster'' AFTER `visual`');
DROP PROCEDURE IF EXISTS phoenix_add_column_19;

SET @has_old_bestiary_index = (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='phoenix_bestiary' AND INDEX_NAME='uniq_char_inst');
SET @drop_old_bestiary_index = IF(@has_old_bestiary_index>0, 'ALTER TABLE `phoenix_bestiary` DROP INDEX `uniq_char_inst`', 'SELECT 1');
PREPARE bestiary_drop_stmt FROM @drop_old_bestiary_index;
EXECUTE bestiary_drop_stmt;
DEALLOCATE PREPARE bestiary_drop_stmt;

SET @has_new_bestiary_index = (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='phoenix_bestiary' AND INDEX_NAME='uniq_char_inst_name');
SET @add_new_bestiary_index = IF(@has_new_bestiary_index=0, 'ALTER TABLE `phoenix_bestiary` ADD UNIQUE KEY `uniq_char_inst_name` (`characterId`,`instance`,`name`)', 'SELECT 1');
PREPARE bestiary_add_stmt FROM @add_new_bestiary_index;
EXECUTE bestiary_add_stmt;
DEALLOCATE PREPARE bestiary_add_stmt;