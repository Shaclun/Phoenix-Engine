USE `phoenix`;

ALTER TABLE `phoenix_characters`
    ADD COLUMN `magicLevel` INT(11) NOT NULL DEFAULT 0 AFTER `crossbow`,
    ADD COLUMN `magicXp`    INT(11) NOT NULL DEFAULT 0 AFTER `magicLevel`;
