USE `phoenix`;

ALTER TABLE `phoenix_bestiary`
    ADD COLUMN IF NOT EXISTS `name`     VARCHAR(96) NOT NULL DEFAULT '' AFTER `instance`,
    ADD COLUMN IF NOT EXISTS `visual`   VARCHAR(96) NOT NULL DEFAULT '' AFTER `name`,
    ADD COLUMN IF NOT EXISTS `kind`     VARCHAR(24) NOT NULL DEFAULT 'monster' AFTER `visual`;

ALTER TABLE `phoenix_bestiary` DROP INDEX IF EXISTS `uniq_char_inst`;
ALTER TABLE `phoenix_bestiary` ADD UNIQUE KEY IF NOT EXISTS `uniq_char_inst_name` (`characterId`, `instance`, `name`);
