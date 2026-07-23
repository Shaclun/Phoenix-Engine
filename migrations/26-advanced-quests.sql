CREATE TABLE IF NOT EXISTS `phoenix_quest_definitions` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(64) NOT NULL,
    `status` VARCHAR(16) NOT NULL DEFAULT 'draft',
    `currentDraftRevisionId` INT NULL,
    `publishedRevisionId` INT NULL,
    `lockVersion` INT NOT NULL DEFAULT 1,
    `createdBy` INT NULL,
    `updatedBy` INT NULL,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_quest_definition_code` (`code`),
    KEY `idx_quest_definition_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_quest_revisions` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `definitionId` INT NOT NULL,
    `revisionNumber` INT NOT NULL,
    `revisionStatus` VARCHAR(16) NOT NULL DEFAULT 'draft',
    `schemaVersion` INT NOT NULL DEFAULT 1,
    `contentJson` LONGTEXT NOT NULL,
    `checksum` CHAR(64) NOT NULL DEFAULT '',
    `createdBy` INT NULL,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `publishedAt` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uniq_quest_revision_number` (`definitionId`, `revisionNumber`),
    KEY `idx_quest_revision_status` (`revisionStatus`),
    CONSTRAINT `fk_quest_revision_definition` FOREIGN KEY (`definitionId`) REFERENCES `phoenix_quest_definitions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_quest_npc_bindings` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `revisionId` INT NOT NULL,
    `bindingKey` VARCHAR(64) NOT NULL,
    `role` VARCHAR(24) NOT NULL,
    `refType` VARCHAR(24) NOT NULL,
    `refValue` VARCHAR(96) NOT NULL,
    `spawnId` INT NULL,
    `markerOffset` FLOAT NOT NULL DEFAULT 145,
    UNIQUE KEY `uniq_quest_npc_binding` (`revisionId`, `bindingKey`),
    KEY `idx_quest_npc_binding_lookup` (`refType`, `refValue`),
    CONSTRAINT `fk_quest_binding_revision` FOREIGN KEY (`revisionId`) REFERENCES `phoenix_quest_revisions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `phoenix_quest_stage_index` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `revisionId` INT NOT NULL,
    `stageKey` VARCHAR(64) NOT NULL,
    `stageType` VARCHAR(24) NOT NULL DEFAULT 'objectives',
    UNIQUE KEY `uniq_quest_stage_key` (`revisionId`, `stageKey`),
    CONSTRAINT `fk_quest_stage_revision` FOREIGN KEY (`revisionId`) REFERENCES `phoenix_quest_revisions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_character_quests` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterId` INT NOT NULL,
    `revisionId` INT NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `currentStageKey` VARCHAR(64) NOT NULL,
    `stateVersion` INT NOT NULL DEFAULT 1,
    `tracked` TINYINT NOT NULL DEFAULT 0,
    `rewardChoiceKey` VARCHAR(64) NULL,
    `startedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `completedAt` TIMESTAMP NULL DEFAULT NULL,
    `failedAt` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uniq_character_quest_revision` (`characterId`, `revisionId`),
    KEY `idx_character_quest_status` (`characterId`, `status`),
    CONSTRAINT `fk_character_quest_character` FOREIGN KEY (`characterId`) REFERENCES `phoenix_characters` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_character_quest_revision` FOREIGN KEY (`revisionId`) REFERENCES `phoenix_quest_revisions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_character_quest_objectives` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterQuestId` BIGINT NOT NULL,
    `objectiveKey` VARCHAR(64) NOT NULL,
    `progress` INT NOT NULL DEFAULT 0,
    `required` INT NOT NULL DEFAULT 1,
    `completedAt` TIMESTAMP NULL DEFAULT NULL,
    `dataJson` TEXT NULL,
    UNIQUE KEY `uniq_character_quest_objective` (`characterQuestId`, `objectiveKey`),
    CONSTRAINT `fk_quest_objective_state` FOREIGN KEY (`characterQuestId`) REFERENCES `phoenix_character_quests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_character_quest_history` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterQuestId` BIGINT NOT NULL,
    `sequenceNo` INT NOT NULL,
    `fromStageKey` VARCHAR(64) NULL,
    `toStageKey` VARCHAR(64) NULL,
    `eventType` VARCHAR(48) NOT NULL,
    `correlationId` VARCHAR(64) NOT NULL DEFAULT '',
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_character_quest_history_sequence` (`characterQuestId`, `sequenceNo`),
    CONSTRAINT `fk_quest_history_state` FOREIGN KEY (`characterQuestId`) REFERENCES `phoenix_character_quests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE IF NOT EXISTS `phoenix_quest_event_dedup` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterId` INT NOT NULL,
    `eventId` VARCHAR(64) NOT NULL,
    `eventType` VARCHAR(48) NOT NULL,
    `resultCode` VARCHAR(32) NOT NULL DEFAULT '',
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_quest_event_character` (`characterId`, `eventId`),
    KEY `idx_quest_event_created` (`createdAt`),
    CONSTRAINT `fk_quest_event_character` FOREIGN KEY (`characterId`) REFERENCES `phoenix_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_quest_reward_ledger` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterQuestId` BIGINT NOT NULL,
    `effectKey` VARCHAR(160) NOT NULL,
    `rewardType` VARCHAR(32) NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
    `attempts` INT NOT NULL DEFAULT 0,
    `resultJson` TEXT NULL,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `completedAt` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uniq_quest_reward_effect` (`effectKey`),
    KEY `idx_quest_reward_status` (`status`, `updatedAt`),
    CONSTRAINT `fk_quest_reward_state` FOREIGN KEY (`characterQuestId`) REFERENCES `phoenix_character_quests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phoenix_quest_audit` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `actorAccountId` INT NULL,
    `actorCharacterId` INT NULL,
    `operation` VARCHAR(48) NOT NULL,
    `entityType` VARCHAR(32) NOT NULL,
    `entityId` VARCHAR(64) NOT NULL,
    `correlationId` VARCHAR(64) NOT NULL DEFAULT '',
    `beforeJson` LONGTEXT NULL,
    `afterJson` LONGTEXT NULL,
    `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_quest_audit_entity` (`entityType`, `entityId`),
    KEY `idx_quest_audit_actor` (`actorAccountId`, `createdAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @quest_has_draft_fk = (SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`TABLE_CONSTRAINTS` WHERE `CONSTRAINT_SCHEMA`=DATABASE() AND `TABLE_NAME`='phoenix_quest_definitions' AND `CONSTRAINT_NAME`='fk_quest_definition_draft');
SET @quest_draft_fk_sql = IF(@quest_has_draft_fk=0,'ALTER TABLE `phoenix_quest_definitions` ADD CONSTRAINT `fk_quest_definition_draft` FOREIGN KEY (`currentDraftRevisionId`) REFERENCES `phoenix_quest_revisions` (`id`) ON DELETE SET NULL','SELECT 1');
PREPARE quest_draft_fk_stmt FROM @quest_draft_fk_sql;
EXECUTE quest_draft_fk_stmt;
DEALLOCATE PREPARE quest_draft_fk_stmt;

SET @quest_has_published_fk = (SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`TABLE_CONSTRAINTS` WHERE `CONSTRAINT_SCHEMA`=DATABASE() AND `TABLE_NAME`='phoenix_quest_definitions' AND `CONSTRAINT_NAME`='fk_quest_definition_published');
SET @quest_published_fk_sql = IF(@quest_has_published_fk=0,'ALTER TABLE `phoenix_quest_definitions` ADD CONSTRAINT `fk_quest_definition_published` FOREIGN KEY (`publishedRevisionId`) REFERENCES `phoenix_quest_revisions` (`id`) ON DELETE SET NULL','SELECT 1');
PREPARE quest_published_fk_stmt FROM @quest_published_fk_sql;
EXECUTE quest_published_fk_stmt;
DEALLOCATE PREPARE quest_published_fk_stmt;

CREATE TABLE IF NOT EXISTS `phoenix_character_flags` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `characterId` INT NOT NULL,
    `flagKey` VARCHAR(64) NOT NULL,
    `flagValue` VARCHAR(255) NOT NULL DEFAULT '',
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_character_flag` (`characterId`, `flagKey`),
    CONSTRAINT `fk_character_flag_character` FOREIGN KEY (`characterId`) REFERENCES `phoenix_characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @quest_has_item_effect_key = (SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE `TABLE_SCHEMA`=DATABASE() AND `TABLE_NAME`='phoenix_items' AND `COLUMN_NAME`='effectKey');
SET @quest_item_effect_key_sql = IF(@quest_has_item_effect_key=0,'ALTER TABLE `phoenix_items` ADD COLUMN `effectKey` VARCHAR(160) NULL AFTER `source`','SELECT 1');
PREPARE quest_item_effect_key_stmt FROM @quest_item_effect_key_sql;
EXECUTE quest_item_effect_key_stmt;
DEALLOCATE PREPARE quest_item_effect_key_stmt;

SET @quest_has_item_effect_index = (SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`STATISTICS` WHERE `TABLE_SCHEMA`=DATABASE() AND `TABLE_NAME`='phoenix_items' AND `COLUMN_NAME`='effectKey' AND `NON_UNIQUE`=0);
SET @quest_item_effect_index_sql = IF(@quest_has_item_effect_index=0,'ALTER TABLE `phoenix_items` ADD UNIQUE KEY `effectKey` (`effectKey`)','SELECT 1');
PREPARE quest_item_effect_index_stmt FROM @quest_item_effect_index_sql;
EXECUTE quest_item_effect_index_stmt;
DEALLOCATE PREPARE quest_item_effect_index_stmt;


CREATE TABLE IF NOT EXISTS `phoenix_account_permissions` (
    `accountId` INT NOT NULL,
    `permissionKey` VARCHAR(64) NOT NULL,
    `granted` TINYINT NOT NULL DEFAULT 1,
    `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`accountId`, `permissionKey`),
    KEY `idx_account_permission_key` (`permissionKey`, `granted`),
    CONSTRAINT `fk_account_permission_account` FOREIGN KEY (`accountId`) REFERENCES `phoenix_accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


SET @quest_has_reward_choice = (SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`COLUMNS` WHERE `TABLE_SCHEMA`=DATABASE() AND `TABLE_NAME`='phoenix_character_quests' AND `COLUMN_NAME`='rewardChoiceKey');
SET @quest_reward_choice_sql = IF(@quest_has_reward_choice=0,'ALTER TABLE `phoenix_character_quests` ADD COLUMN `rewardChoiceKey` VARCHAR(64) NULL AFTER `tracked`','SELECT 1');
PREPARE quest_reward_choice_stmt FROM @quest_reward_choice_sql;
EXECUTE quest_reward_choice_stmt;
DEALLOCATE PREPARE quest_reward_choice_stmt;


CREATE TABLE IF NOT EXISTS `phoenix_quest_legacy_map` (
    `legacyQuestId` INT NOT NULL,
    `legacyQuestCode` VARCHAR(64) NOT NULL,
    `definitionId` INT NOT NULL,
    `draftRevisionId` INT NOT NULL,
    `conversionStatus` VARCHAR(24) NOT NULL DEFAULT 'draft_created',
    `reportJson` TEXT NULL,
    `convertedBy` INT NULL,
    `convertedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`legacyQuestId`),
    UNIQUE KEY `uniq_legacy_quest_code` (`legacyQuestCode`),
    KEY `idx_legacy_definition` (`definitionId`),
    CONSTRAINT `fk_legacy_map_definition` FOREIGN KEY (`definitionId`) REFERENCES `phoenix_quest_definitions` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_legacy_map_revision` FOREIGN KEY (`draftRevisionId`) REFERENCES `phoenix_quest_revisions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;