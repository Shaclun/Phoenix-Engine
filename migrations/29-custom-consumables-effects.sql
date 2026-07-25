ALTER TABLE `phoenix_custom_items`
    ADD COLUMN `onUse` VARCHAR(24) NOT NULL DEFAULT '' AFTER `flags`,
    ADD COLUMN `effectJson` MEDIUMTEXT NULL AFTER `onUse`,
    ADD COLUMN `labelsJson` MEDIUMTEXT NULL AFTER `effectJson`,
    ADD COLUMN `descriptionsJson` MEDIUMTEXT NULL AFTER `labelsJson`,
    ADD COLUMN `contentJson` MEDIUMTEXT NULL AFTER `descriptionsJson`,
    ADD COLUMN `updatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `createdAt`;

UPDATE `phoenix_custom_items`
SET `labelsJson` = JSON_OBJECT('pl', `name`, 'en', '', 'de', '', 'ru', ''),
    `descriptionsJson` = JSON_OBJECT('pl', `description`, 'en', '', 'de', '', 'ru', ''),
    `effectJson` = JSON_ARRAY(),
    `contentJson` = JSON_OBJECT('pl', '', 'en', '', 'de', '', 'ru', '')
WHERE `labelsJson` IS NULL OR `descriptionsJson` IS NULL OR `effectJson` IS NULL OR `contentJson` IS NULL;
