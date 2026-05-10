
CREATE TABLE IF NOT EXISTS `phoenix_admin_log` (
    `id`         INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `adminId`    INT NULL,
    `adminName`  VARCHAR(64) DEFAULT '',
    `action`     VARCHAR(48) NOT NULL,
    `targetType` VARCHAR(24) DEFAULT '',
    `targetId`   INT NULL,
    `targetName` VARCHAR(64) DEFAULT '',
    `details`    TEXT NULL,
    `createdAt`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_log_admin` (`adminId`),
    KEY `idx_log_action` (`action`),
    KEY `idx_log_created` (`createdAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_custom_items` (
    `id`          INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `instance`    VARCHAR(64) NOT NULL UNIQUE,
    `category`    TINYINT NOT NULL DEFAULT 0,
    `slot`        TINYINT NOT NULL DEFAULT 0,
    `name`        VARCHAR(96) DEFAULT '',
    `description` VARCHAR(512) DEFAULT '',
    `visual`      VARCHAR(96) DEFAULT '',
    `value`       INT DEFAULT 0,
    `weight`      FLOAT DEFAULT 0.0,
    `stackMax`    INT DEFAULT 1,
    `damage`      INT DEFAULT 0,
    `damageType`  TINYINT DEFAULT 0,
    `protEdge`    INT DEFAULT 0,
    `protBlunt`   INT DEFAULT 0,
    `protPoint`   INT DEFAULT 0,
    `protFire`    INT DEFAULT 0,
    `protMagic`   INT DEFAULT 0,
    `flags`       INT DEFAULT 0,
    `createdBy`   INT NULL,
    `createdAt`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_custom_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
