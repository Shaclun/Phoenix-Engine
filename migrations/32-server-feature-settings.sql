USE `phoenix`;

CREATE TABLE IF NOT EXISTS `phoenix_server_feature_settings` (
  `id` TINYINT UNSIGNED NOT NULL,
  `profile` VARCHAR(16) NOT NULL DEFAULT 'mmorpg',
  `levelingEnabled` TINYINT(1) NOT NULL DEFAULT 1,
  `mobExperienceEnabled` TINYINT(1) NOT NULL DEFAULT 1,
  `rpChatEnabled` TINYINT(1) NOT NULL DEFAULT 0,
  `rpCommandsEnabled` TINYINT(1) NOT NULL DEFAULT 0,
  `revision` INT UNSIGNED NOT NULL DEFAULT 1,
  `updatedBy` INT UNSIGNED NULL,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `phoenix_server_feature_settings` (`id`,`profile`,`levelingEnabled`,`mobExperienceEnabled`,`rpChatEnabled`,`rpCommandsEnabled`,`revision`)
VALUES (1,'mmorpg',1,1,0,0,1)
ON DUPLICATE KEY UPDATE `id`=`id`;