USE `phoenix`;

ALTER TABLE `phoenix_characters`
    MODIFY `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

UPDATE `phoenix_characters` SET `createdAt` = CURRENT_TIMESTAMP WHERE `createdAt` IS NULL OR `createdAt` = '0000-00-00 00:00:00';
