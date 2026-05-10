CREATE TABLE IF NOT EXISTS `phoenix_social_friends` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `characterId` INT(11) NOT NULL,
  `friendCharacterId` INT(11) NOT NULL,
  `friendName` VARCHAR(64) NOT NULL DEFAULT '',
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `social_friend_unique` (`characterId`, `friendCharacterId`),
  KEY `social_friend_character_idx` (`characterId`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
