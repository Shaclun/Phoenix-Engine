USE `phoenix`;

SET @phoenix_add_flags_json = IF(
  EXISTS(
    SELECT 1 FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'phoenix_server_feature_settings'
      AND `COLUMN_NAME` = 'flagsJson'
  ),
  'SELECT 1',
  'ALTER TABLE `phoenix_server_feature_settings` ADD COLUMN `flagsJson` LONGTEXT NULL AFTER `rpCommandsEnabled`'
);
PREPARE phoenix_stmt FROM @phoenix_add_flags_json;
EXECUTE phoenix_stmt;
DEALLOCATE PREPARE phoenix_stmt;

SET @phoenix_add_schema_version = IF(
  EXISTS(
    SELECT 1 FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'phoenix_server_feature_settings'
      AND `COLUMN_NAME` = 'schemaVersion'
  ),
  'SELECT 1',
  'ALTER TABLE `phoenix_server_feature_settings` ADD COLUMN `schemaVersion` INT UNSIGNED NOT NULL DEFAULT 2 AFTER `flagsJson`'
);
PREPARE phoenix_stmt FROM @phoenix_add_schema_version;
EXECUTE phoenix_stmt;
DEALLOCATE PREPARE phoenix_stmt;

UPDATE `phoenix_server_feature_settings`
SET `flagsJson` = JSON_OBJECT(
  'progression.leveling', `levelingEnabled`,
  'progression.mobExperience', `mobExperienceEnabled`,
  'chat.ooc', `rpChatEnabled`,
  'chat.rpActions', `rpCommandsEnabled`
), `schemaVersion` = 2
WHERE `id` = 1 AND (`flagsJson` IS NULL OR `flagsJson` = '');