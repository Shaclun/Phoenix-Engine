USE `phoenix`;

ALTER TABLE `phoenix_accounts`
	ADD COLUMN `role` TINYINT(4) NOT NULL DEFAULT 0 AFTER `status`;

CREATE TABLE IF NOT EXISTS `phoenix_bans` (
	`id`         INT(11) NOT NULL AUTO_INCREMENT,
	`scope`      TINYINT(4) NOT NULL,
	`accountId`  INT(11) NULL DEFAULT NULL,
	`characterId` INT(11) NULL DEFAULT NULL,
	`ipAddress`  VARCHAR(45) NOT NULL DEFAULT '',
	`serial`     VARCHAR(64) NOT NULL DEFAULT '',
	`reason`     VARCHAR(255) NOT NULL DEFAULT '',
	`issuedBy`   INT(11) NULL DEFAULT NULL,
	`issuedAt`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`expiresAt`  TIMESTAMP NULL DEFAULT NULL,
	`active`     TINYINT(1) NOT NULL DEFAULT 1,
	PRIMARY KEY (`id`),
	KEY `idx_bans_scope_active` (`scope`, `active`),
	KEY `idx_bans_account` (`accountId`),
	KEY `idx_bans_character` (`characterId`),
	KEY `idx_bans_ip` (`ipAddress`),
	KEY `idx_bans_serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

UPDATE `phoenix_accounts` SET `role` = 1 WHERE LOWER(`normalizedUsername`) = 'shaclow';
