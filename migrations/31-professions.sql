USE `phoenix`;

CREATE TABLE IF NOT EXISTS `phoenix_professions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(48) NOT NULL,
  `namePl` VARCHAR(96) NOT NULL,
  `nameEn` VARCHAR(96) NOT NULL DEFAULT '',
  `nameDe` VARCHAR(96) NOT NULL DEFAULT '',
  `nameRu` VARCHAR(96) NOT NULL DEFAULT '',
  `descriptionPl` VARCHAR(512) NOT NULL DEFAULT '',
  `descriptionEn` VARCHAR(512) NOT NULL DEFAULT '',
  `descriptionDe` VARCHAR(512) NOT NULL DEFAULT '',
  `descriptionRu` VARCHAR(512) NOT NULL DEFAULT '',
  `maxLevel` INT(11) NOT NULL DEFAULT 100,
  `xpBase` INT(11) NOT NULL DEFAULT 100,
  `xpGrowth` DECIMAL(6,3) NOT NULL DEFAULT 1.350,
  `gatherTimeReductionPerTier` DECIMAL(6,3) NOT NULL DEFAULT 0.120,
  `gatherChancePerTier` INT(11) NOT NULL DEFAULT 3,
  `gatherYieldPerTier` INT(11) NOT NULL DEFAULT 1,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), UNIQUE KEY `uq_profession_code` (`code`), KEY `idx_profession_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phoenix_character_professions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `characterId` INT(11) NOT NULL,
  `professionId` INT(11) NOT NULL,
  `level` INT(11) NOT NULL DEFAULT 0,
  `xp` BIGINT(20) NOT NULL DEFAULT 0,
  `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), UNIQUE KEY `uq_character_profession` (`characterId`,`professionId`),
  KEY `idx_character_profession_character` (`characterId`), KEY `idx_character_profession_profession` (`professionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP PROCEDURE IF EXISTS `phoenix_profession_add_column`;
DELIMITER $$
CREATE PROCEDURE `phoenix_profession_add_column`(IN p_table VARCHAR(64), IN p_column VARCHAR(64), IN p_ddl TEXT)
BEGIN
 IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND COLUMN_NAME=p_column) THEN
  SET @profession_ddl=p_ddl; PREPARE profession_stmt FROM @profession_ddl; EXECUTE profession_stmt; DEALLOCATE PREPARE profession_stmt;
 END IF;
END$$
DELIMITER ;
CALL `phoenix_profession_add_column`('phoenix_crafting_recipes','professionId','ALTER TABLE `phoenix_crafting_recipes` ADD COLUMN `professionId` INT(11) NULL AFTER `requiredLevel`');
CALL `phoenix_profession_add_column`('phoenix_crafting_recipes','requiredProfessionTier','ALTER TABLE `phoenix_crafting_recipes` ADD COLUMN `requiredProfessionTier` INT(11) NOT NULL DEFAULT 0 AFTER `professionId`');
CALL `phoenix_profession_add_column`('phoenix_crafting_recipes','baseStamina','ALTER TABLE `phoenix_crafting_recipes` ADD COLUMN `baseStamina` INT(11) NOT NULL DEFAULT 0 AFTER `requiredProfessionTier`');
CALL `phoenix_profession_add_column`('phoenix_crafting_recipes','professionXp','ALTER TABLE `phoenix_crafting_recipes` ADD COLUMN `professionXp` INT(11) NOT NULL DEFAULT 0 AFTER `baseStamina`');
CALL `phoenix_profession_add_column`('phoenix_herb_spots','professionId','ALTER TABLE `phoenix_herb_spots` ADD COLUMN `professionId` INT(11) NULL AFTER `successChance`');
CALL `phoenix_profession_add_column`('phoenix_herb_spots','requiredProfessionTier','ALTER TABLE `phoenix_herb_spots` ADD COLUMN `requiredProfessionTier` INT(11) NOT NULL DEFAULT 0 AFTER `professionId`');
CALL `phoenix_profession_add_column`('phoenix_herb_spots','baseStamina','ALTER TABLE `phoenix_herb_spots` ADD COLUMN `baseStamina` INT(11) NOT NULL DEFAULT 4 AFTER `requiredProfessionTier`');
CALL `phoenix_profession_add_column`('phoenix_herb_spots','baseProfessionXp','ALTER TABLE `phoenix_herb_spots` ADD COLUMN `baseProfessionXp` INT(11) NOT NULL DEFAULT 8 AFTER `baseStamina`');
CALL `phoenix_profession_add_column`('phoenix_herb_spots','baseYield','ALTER TABLE `phoenix_herb_spots` ADD COLUMN `baseYield` INT(11) NOT NULL DEFAULT 1 AFTER `baseProfessionXp`');
DROP PROCEDURE IF EXISTS `phoenix_profession_add_column`;

CREATE TABLE IF NOT EXISTS `phoenix_hunting_carcasses` (
  `npcInstance` VARCHAR(64) NOT NULL, `corpseVisual` VARCHAR(128) NOT NULL DEFAULT '',
  `professionId` INT(11) NULL, `requiredProfessionTier` INT(11) NOT NULL DEFAULT 0,
  `baseStamina` INT(11) NOT NULL DEFAULT 8, `professionXp` INT(11) NOT NULL DEFAULT 15,
  `skinTimeMs` INT(11) NOT NULL DEFAULT 5000, `lifetimeSec` INT(11) NOT NULL DEFAULT 120,
  `active` TINYINT(1) NOT NULL DEFAULT 1, PRIMARY KEY (`npcInstance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `phoenix_hunting_loot` (
  `id` INT(11) NOT NULL AUTO_INCREMENT, `npcInstance` VARCHAR(64) NOT NULL,
  `itemInstance` VARCHAR(64) NOT NULL, `baseChance` INT(11) NOT NULL DEFAULT 0,
  `baseMin` INT(11) NOT NULL DEFAULT 1, `baseMax` INT(11) NOT NULL DEFAULT 1,
  `chancePerTier` INT(11) NOT NULL DEFAULT 3, `amountPerTier` DECIMAL(6,3) NOT NULL DEFAULT 0.500,
  `active` TINYINT(1) NOT NULL DEFAULT 1, PRIMARY KEY (`id`),
  UNIQUE KEY `uq_hunting_loot` (`npcInstance`,`itemInstance`), KEY `idx_hunting_instance` (`npcInstance`,`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `phoenix_professions` (`code`,`namePl`,`nameEn`,`nameDe`,`nameRu`,`descriptionPl`) VALUES
('GATHERING','Zbieractwo','Gathering','Sammeln','Собирательство','Zbieranie roślin i surowców.'),
('SMITHING','Kowalstwo','Smithing','Schmiedekunst','Кузнечное дело','Wytwarzanie broni metalowej.'),
('ARMORSMITHING','Płatnerstwo','Armorsmithing','Rüstungsschmiedekunst','Бронное дело','Wytwarzanie pancerzy.'),
('BOWMAKING','Łuczarstwo','Bowmaking','Bogenbau','Изготовление луков','Wytwarzanie łuków i amunicji.'),
('HUNTING','Myślistwo','Hunting','Jagd','Охота','Skórowanie zwierząt i pozyskiwanie trofeów.'),
('ALCHEMY','Alchemia','Alchemy','Alchemie','Алхимия','Warzenie mikstur.'),
('RUNECRAFTING','Tworzenie run','Runecrafting','Runenherstellung','Создание рун','Tworzenie run magicznych.'),
('SCROLLCRAFTING','Tworzenie zwojów','Scrollcrafting','Schriftrollenherstellung','Создание свитков','Tworzenie magicznych zwojów.'),
('COOKING','Gotowanie','Cooking','Kochen','Кулинария','Przygotowywanie potraw.'),
('JEWELCRAFTING','Jubilerstwo','Jewelcrafting','Juwelierkunst','Ювелирное дело','Wytwarzanie biżuterii.')
ON DUPLICATE KEY UPDATE `namePl`=VALUES(`namePl`),`nameEn`=VALUES(`nameEn`),`nameDe`=VALUES(`nameDe`),`nameRu`=VALUES(`nameRu`),`descriptionPl`=VALUES(`descriptionPl`),`active`=1;

UPDATE `phoenix_herb_spots` SET `professionId`=(SELECT `id` FROM `phoenix_professions` WHERE `code`='GATHERING' LIMIT 1) WHERE `professionId` IS NULL;

INSERT INTO `phoenix_hunting_carcasses` (`npcInstance`,`corpseVisual`,`professionId`) SELECT 'WOLF','WOLF.MDS',`id` FROM `phoenix_professions` WHERE `code`='HUNTING' ON DUPLICATE KEY UPDATE `professionId`=VALUES(`professionId`),`active`=1;
INSERT INTO `phoenix_hunting_carcasses` (`npcInstance`,`corpseVisual`,`professionId`) SELECT 'YWOLF','WOLF.MDS',`id` FROM `phoenix_professions` WHERE `code`='HUNTING' ON DUPLICATE KEY UPDATE `professionId`=VALUES(`professionId`),`active`=1;
INSERT INTO `phoenix_hunting_loot` (`npcInstance`,`itemInstance`,`baseChance`,`baseMin`,`baseMax`,`chancePerTier`,`amountPerTier`) VALUES
('WOLF','ITMI_FUR',50,1,1,5,0.50),('WOLF','ITMI_CLAW',20,1,1,4,0.35),('WOLF','ITMI_TEETH',10,1,1,3,0.25),('WOLF','ITFO_MUTTONRAW',80,1,2,4,1.00),
('YWOLF','ITMI_FUR',50,1,1,5,0.50),('YWOLF','ITMI_CLAW',20,1,1,4,0.35),('YWOLF','ITMI_TEETH',10,1,1,3,0.25),('YWOLF','ITFO_MUTTONRAW',80,1,2,4,1.00)
ON DUPLICATE KEY UPDATE `baseChance`=VALUES(`baseChance`),`baseMin`=VALUES(`baseMin`),`baseMax`=VALUES(`baseMax`),`chancePerTier`=VALUES(`chancePerTier`),`amountPerTier`=VALUES(`amountPerTier`),`active`=1;