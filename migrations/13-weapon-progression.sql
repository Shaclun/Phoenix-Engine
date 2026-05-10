USE `phoenix`;

CREATE TABLE IF NOT EXISTS `phoenix_character_weapon_progress` (
	`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`characterId` INT NOT NULL,
	`skillKey` VARCHAR(16) NOT NULL,
	`level` INT NOT NULL DEFAULT 0,
	`xp` INT NOT NULL DEFAULT 0,
	`cap` INT NOT NULL DEFAULT 30,
	`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `uq_weapon_progress_character_skill` (`characterId`, `skillKey`),
	KEY `idx_weapon_progress_character` (`characterId`),
	CONSTRAINT `fk_weapon_progress_character` FOREIGN KEY (`characterId`) REFERENCES `phoenix_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `phoenix_character_weapon_progress` (`characterId`, `skillKey`, `level`, `xp`, `cap`)
SELECT `id`, 'oneHand', `oneHand`, 0, CASE WHEN `oneHand` >= 60 THEN 100 WHEN `oneHand` >= 30 THEN 60 ELSE 30 END FROM `phoenix_characters`
ON DUPLICATE KEY UPDATE `level` = GREATEST(`level`, VALUES(`level`)), `cap` = GREATEST(`cap`, VALUES(`cap`));

INSERT INTO `phoenix_character_weapon_progress` (`characterId`, `skillKey`, `level`, `xp`, `cap`)
SELECT `id`, 'twoHand', `twoHand`, 0, CASE WHEN `twoHand` >= 60 THEN 100 WHEN `twoHand` >= 30 THEN 60 ELSE 30 END FROM `phoenix_characters`
ON DUPLICATE KEY UPDATE `level` = GREATEST(`level`, VALUES(`level`)), `cap` = GREATEST(`cap`, VALUES(`cap`));

INSERT INTO `phoenix_character_weapon_progress` (`characterId`, `skillKey`, `level`, `xp`, `cap`)
SELECT `id`, 'bow', `bow`, 0, CASE WHEN `bow` >= 60 THEN 100 WHEN `bow` >= 30 THEN 60 ELSE 30 END FROM `phoenix_characters`
ON DUPLICATE KEY UPDATE `level` = GREATEST(`level`, VALUES(`level`)), `cap` = GREATEST(`cap`, VALUES(`cap`));

INSERT INTO `phoenix_character_weapon_progress` (`characterId`, `skillKey`, `level`, `xp`, `cap`)
SELECT `id`, 'crossbow', `crossbow`, 0, CASE WHEN `crossbow` >= 60 THEN 100 WHEN `crossbow` >= 30 THEN 60 ELSE 30 END FROM `phoenix_characters`
ON DUPLICATE KEY UPDATE `level` = GREATEST(`level`, VALUES(`level`)), `cap` = GREATEST(`cap`, VALUES(`cap`));