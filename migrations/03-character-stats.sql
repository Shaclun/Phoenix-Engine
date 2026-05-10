USE `phoenix`;

-- Add Gothic-style stats + equipment/inventory persistence to phoenix_characters.
-- Idempotent — reuses helper procedure pattern.

DROP PROCEDURE IF EXISTS phoenix_add_col2;
DELIMITER //
CREATE PROCEDURE phoenix_add_col2(IN tbl VARCHAR(64), IN col VARCHAR(64), IN ddl TEXT)
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.COLUMNS
		WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = tbl AND COLUMN_NAME = col
	) THEN
		SET @s = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN ', ddl);
		PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
	END IF;
END //
DELIMITER ;

CALL phoenix_add_col2('phoenix_characters', 'experienceNext', '`experienceNext` BIGINT(20) NOT NULL DEFAULT 500');
CALL phoenix_add_col2('phoenix_characters', 'learnPoints',    '`learnPoints` INT(11) NOT NULL DEFAULT 10');
CALL phoenix_add_col2('phoenix_characters', 'hp',             '`hp` INT(11) NOT NULL DEFAULT 40');
CALL phoenix_add_col2('phoenix_characters', 'hpMax',          '`hpMax` INT(11) NOT NULL DEFAULT 40');
CALL phoenix_add_col2('phoenix_characters', 'mana',           '`mana` INT(11) NOT NULL DEFAULT 0');
CALL phoenix_add_col2('phoenix_characters', 'manaMax',        '`manaMax` INT(11) NOT NULL DEFAULT 0');
CALL phoenix_add_col2('phoenix_characters', 'strength',       '`strength` INT(11) NOT NULL DEFAULT 10');
CALL phoenix_add_col2('phoenix_characters', 'dexterity',      '`dexterity` INT(11) NOT NULL DEFAULT 10');
CALL phoenix_add_col2('phoenix_characters', 'oneHand',        '`oneHand` INT(11) NOT NULL DEFAULT 0');
CALL phoenix_add_col2('phoenix_characters', 'twoHand',        '`twoHand` INT(11) NOT NULL DEFAULT 0');
CALL phoenix_add_col2('phoenix_characters', 'bow',            '`bow` INT(11) NOT NULL DEFAULT 0');
CALL phoenix_add_col2('phoenix_characters', 'crossbow',       '`crossbow` INT(11) NOT NULL DEFAULT 0');
CALL phoenix_add_col2('phoenix_characters', 'gold',           '`gold` BIGINT(20) NOT NULL DEFAULT 0');
CALL phoenix_add_col2('phoenix_characters', 'equipment',      '`equipment` TEXT NULL');
CALL phoenix_add_col2('phoenix_characters', 'inventory',      '`inventory` TEXT NULL');

DROP PROCEDURE IF EXISTS phoenix_add_col2;
