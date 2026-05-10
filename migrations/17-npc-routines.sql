USE `phoenix`;

CREATE TABLE IF NOT EXISTS `phoenix_npc_routines` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `spawnId`     INT UNSIGNED NOT NULL,
    `enabled`     TINYINT      NOT NULL DEFAULT 1,
    `loop`        TINYINT      NOT NULL DEFAULT 1,
    `nodes`       MEDIUMTEXT   NOT NULL,
    `createdBy`   INT UNSIGNED NULL,
    `createdAt`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_npc_routines_spawn` (`spawnId`),
    KEY `idx_npc_routines_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
