CREATE TABLE IF NOT EXISTS `phoenix_npc_spawns` (
    `id`           INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `instance`     VARCHAR(64) NOT NULL,
    `name`         VARCHAR(96) DEFAULT '',
    `world`        VARCHAR(96) NOT NULL DEFAULT 'NEWWORLD\\NEWWORLD.ZEN',
    `posX`         FLOAT NOT NULL DEFAULT 0,
    `posY`         FLOAT NOT NULL DEFAULT 0,
    `posZ`         FLOAT NOT NULL DEFAULT 0,
    `angle`        FLOAT NOT NULL DEFAULT 0,
    `hostile`      TINYINT NOT NULL DEFAULT 0,
    `respawnSec`   INT NOT NULL DEFAULT 60,
    `tag`          VARCHAR(48) DEFAULT '',
    `script`       VARCHAR(96) DEFAULT '',
    `metadata`     TEXT NULL,
    `createdBy`    INT NULL,
    `createdAt`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_npc_world` (`world`),
    KEY `idx_npc_tag` (`tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `phoenix_quests` (
    `id`            INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `code`          VARCHAR(64) NOT NULL UNIQUE,
    `title`         VARCHAR(128) DEFAULT '',
    `description`   TEXT NULL,
    `giverInstance` VARCHAR(64) DEFAULT '',
    `type`          VARCHAR(24) NOT NULL DEFAULT 'fetch',
    `payload`       TEXT NULL,
    `createdAt`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_quest_giver` (`giverInstance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `phoenix_quest_states` (
    `id`           INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterId`  INT NOT NULL,
    `questCode`    VARCHAR(64) NOT NULL,
    `status`       VARCHAR(16) NOT NULL DEFAULT 'active',
    `progress`     INT NOT NULL DEFAULT 0,
    `progressGoal` INT NOT NULL DEFAULT 1,
    `startedAt`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completedAt`  TIMESTAMP NULL DEFAULT NULL,
    `notes`        TEXT NULL,
    UNIQUE KEY `uniq_char_quest` (`characterId`, `questCode`),
    KEY `idx_qs_char` (`characterId`),
    KEY `idx_qs_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS `phoenix_bestiary` (
    `id`            INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterId`   INT NOT NULL,
    `instance`      VARCHAR(64) NOT NULL,
    `killed`        INT NOT NULL DEFAULT 0,
    `firstKilledAt` TIMESTAMP NULL DEFAULT NULL,
    `lastKilledAt`  TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uniq_char_inst` (`characterId`, `instance`),
    KEY `idx_best_char` (`characterId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
