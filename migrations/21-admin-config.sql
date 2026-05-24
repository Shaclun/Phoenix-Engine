USE `phoenix`;

-- Generic key/value store for admin-tunable configuration that needs to reach the client
-- (lobby camera spots, character default spawn, scenario spawns etc).
CREATE TABLE IF NOT EXISTS `phoenix_admin_config` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `configKey`  VARCHAR(64)  NOT NULL,
    `payload`    TEXT         NOT NULL,
    `updatedAt`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_config_key` (`configKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
