USE `phoenix`;

CREATE TABLE IF NOT EXISTS `phoenix_progression_settings` (
  `id` TINYINT UNSIGNED NOT NULL,
  `configJson` LONGTEXT NOT NULL,
  `schemaVersion` INT UNSIGNED NOT NULL DEFAULT 1,
  `revision` INT UNSIGNED NOT NULL DEFAULT 1,
  `updatedBy` INT UNSIGNED NULL,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phoenix_character_daily_lp` (
  `characterId` INT NOT NULL,
  `lastGrantDay` DATE NULL,
  `lastGrantAt` TIMESTAMP NULL,
  `revision` INT UNSIGNED NOT NULL DEFAULT 0,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`characterId`),
  KEY `idx_character_daily_lp_day` (`lastGrantDay`),
  CONSTRAINT `fk_character_daily_lp_character` FOREIGN KEY (`characterId`) REFERENCES `phoenix_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phoenix_character_lp_ledger` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `characterId` INT NOT NULL,
  `dayKey` DATE NULL,
  `delta` INT NOT NULL,
  `balanceAfter` INT UNSIGNED NOT NULL,
  `reason` VARCHAR(48) NOT NULL,
  `channel` VARCHAR(24) NOT NULL,
  `skillKey` VARCHAR(32) NULL,
  `amount` INT UNSIGNED NOT NULL DEFAULT 0,
  `sourceKey` VARCHAR(160) NOT NULL,
  `actorAccountId` INT UNSIGNED NULL,
  `metadataJson` LONGTEXT NULL,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_character_lp_ledger_source` (`characterId`,`sourceKey`),
  KEY `idx_character_lp_ledger_created` (`characterId`,`createdAt`),
  KEY `idx_character_lp_ledger_day` (`dayKey`),
  CONSTRAINT `fk_character_lp_ledger_character` FOREIGN KEY (`characterId`) REFERENCES `phoenix_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phoenix_progression_settings_audit` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `revision` INT UNSIGNED NOT NULL,
  `actorAccountId` INT UNSIGNED NULL,
  `beforeJson` LONGTEXT NULL,
  `afterJson` LONGTEXT NOT NULL,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_progression_settings_audit_revision` (`revision`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;