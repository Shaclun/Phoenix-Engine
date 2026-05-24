USE `phoenix`;

CREATE TABLE IF NOT EXISTS `phoenix_bestiary_render` (
    `instance`       VARCHAR(64)   NOT NULL,
    `rotX`           FLOAT         NOT NULL DEFAULT 0.158,
    `rotY`           FLOAT         NOT NULL DEFAULT -0.853,
    `rotZ`           FLOAT         NOT NULL DEFAULT 0,
    `scaleValue`     FLOAT         NOT NULL DEFAULT 1.5,
    `lightIntensity` FLOAT         NOT NULL DEFAULT 2.3,
    `updatedAt`      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`instance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
