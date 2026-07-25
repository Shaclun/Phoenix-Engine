USE `phoenix`;

SET @phoenix_old_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = REPLACE(REPLACE(REPLACE(REPLACE(@@SESSION.sql_mode, 'NO_ZERO_DATE', ''), 'NO_ZERO_IN_DATE', ''), 'STRICT_TRANS_TABLES', ''), 'STRICT_ALL_TABLES', '');
UPDATE `phoenix_characters`
SET `createdAt` = CURRENT_TIMESTAMP
WHERE `createdAt` IS NULL OR CAST(`createdAt` AS CHAR) = '0000-00-00 00:00:00';
ALTER TABLE `phoenix_characters`
    MODIFY `createdAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
SET SESSION sql_mode = @phoenix_old_sql_mode;