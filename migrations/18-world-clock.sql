USE `phoenix`;

CREATE TABLE IF NOT EXISTS `phoenix_world_state` (
    `id`         TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `timeHour`   TINYINT UNSIGNED NOT NULL DEFAULT 8,
    `timeMin`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `dayLength`  INT UNSIGNED     NOT NULL DEFAULT 60,
    `weather`    VARCHAR(16)      NOT NULL DEFAULT 'clear',
    `wind`       FLOAT            NOT NULL DEFAULT 0.0,
    `updatedAt`  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `phoenix_world_state` (`id`, `timeHour`, `timeMin`, `dayLength`, `weather`, `wind`)
VALUES (1, 8, 0, 60, 'clear', 0.0);
