CREATE TABLE IF NOT EXISTS `phoenix_herb_gathers` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`characterId` INT(11) NOT NULL,
	`plantId` VARCHAR(96) NOT NULL,
	`instanceId` VARCHAR(64) NOT NULL,
	`lastGatheredAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`lastSuccess` TINYINT(1) NOT NULL DEFAULT 0,
	`attempts` INT(11) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	UNIQUE KEY `character_plant_unique` (`characterId`, `plantId`),
	KEY `plant_idx` (`plantId`),
	KEY `character_idx` (`characterId`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phoenix_herb_spots` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`plantId` VARCHAR(96) NOT NULL,
	`instanceId` VARCHAR(64) NOT NULL,
	`world` VARCHAR(96) NOT NULL DEFAULT 'NEWWORLD.ZEN',
	`posX` FLOAT NOT NULL DEFAULT 0,
	`posY` FLOAT NOT NULL DEFAULT 0,
	`posZ` FLOAT NOT NULL DEFAULT 0,
	`gatherMs` INT(11) NOT NULL DEFAULT 0,
	`cooldownSec` INT(11) NOT NULL DEFAULT 0,
	`successChance` INT(11) NOT NULL DEFAULT 100,
	`active` TINYINT(1) NOT NULL DEFAULT 1,
	`createdBy` INT(11) NULL,
	`createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `plant_unique` (`plantId`),
	KEY `world_idx` (`world`),
	KEY `instance_idx` (`instanceId`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;