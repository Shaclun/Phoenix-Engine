-- =====================================================================
-- Phoenix item module — schema reference.
-- ORM auto-creates this from gamemodes/phoenix/modules/database/server/
-- models/item.nut, but this file documents the layout for manual ops
-- (backups, ad-hoc admin queries, recovery from a fresh DB).
-- =====================================================================

CREATE TABLE IF NOT EXISTS `phoenix_items` (
	`id`         INT(11)      NOT NULL AUTO_INCREMENT,
	`ownerType`  TINYINT(4)   NOT NULL,
	`ownerId`    INT(11)      NOT NULL,
	`instanceId` VARCHAR(64)  NOT NULL,
	`amount`     INT(11)      NOT NULL DEFAULT 1,
	`quality`    TINYINT(4)   NOT NULL DEFAULT 2,
	`upgrade`    TINYINT(4)   NOT NULL DEFAULT 0,
	`durability` INT(11)      NOT NULL DEFAULT 100,
	`equipped`   TINYINT(4)   NOT NULL DEFAULT 0,
	`slot`       TINYINT(4)   NOT NULL DEFAULT 0,
	`source`     VARCHAR(32)  NOT NULL DEFAULT 'system',
	`createdAt`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatedAt`  TIMESTAMP    NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `owner_idx` (`ownerType`, `ownerId`),
	KEY `instance_idx` (`instanceId`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Owner type enum reference (PhoenixInventoryOwner):
--   0 = Player    (ownerId -> phoenix_characters.id)
--   1 = Chest     (ownerId -> chest container PK)
--   2 = Vendor    (ownerId -> vendor PK)
--   3 = Ground    (ownerId -> world drop PK)
--   4 = Trade     (ownerId -> trade session PK)

-- Quality enum reference (PhoenixItemQuality):
--   0 = Terrible (0.65x)
--   1 = Poor     (0.85x)
--   2 = Common   (1.00x)
--   3 = Fine     (1.10x)
--   4 = Exquisite(1.25x)
--   5 = Magnificent (1.45x)

-- Upgrade levels: 0..9 (only weapons/armor/shields/helmets).
-- Final stat multiplier = quality.mult * (1 + upgrade.bonus).
