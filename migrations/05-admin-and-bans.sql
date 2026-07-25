USE `phoenix`;

DROP PROCEDURE IF EXISTS phoenix_add_column_05;
DELIMITER //
CREATE PROCEDURE phoenix_add_column_05(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
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
CALL phoenix_add_column_05('phoenix_accounts', 'role', '`role` TINYINT(4) NOT NULL DEFAULT 0 AFTER `status`');
DROP PROCEDURE IF EXISTS phoenix_add_column_05;

CREATE TABLE IF NOT EXISTS `phoenix_bans` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `scope` TINYINT(4) NOT NULL,
    `accountId` INT(11) NULL DEFAULT NULL,
    `characterId` INT(11) NULL DEFAULT NULL,
    `ipAddress` VARCHAR(45) NOT NULL DEFAULT '',
    `serial` VARCHAR(64) NOT NULL DEFAULT '',
    `reason` VARCHAR(255) NOT NULL DEFAULT '',
    `issuedBy` INT(11) NULL DEFAULT NULL,
    `issuedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expiresAt` TIMESTAMP NULL DEFAULT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_bans_scope_active` (`scope`, `active`),
    KEY `idx_bans_account` (`accountId`),
    KEY `idx_bans_character` (`characterId`),
    KEY `idx_bans_ip` (`ipAddress`),
    KEY `idx_bans_serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

UPDATE `phoenix_accounts` SET `role` = 1 WHERE LOWER(`normalizedUsername`) = 'shaclow';