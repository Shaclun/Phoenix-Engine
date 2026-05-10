ALTER TABLE `phoenix_npc_presets`
    ADD COLUMN `kind` VARCHAR(16) NOT NULL DEFAULT 'monster' AFTER `category`,
    ADD COLUMN `idleAnimation` VARCHAR(64) NOT NULL DEFAULT '' AFTER `voice`,
    ADD COLUMN `aggroRadius` INT NOT NULL DEFAULT 1800 AFTER `idleAnimation`,
    ADD COLUMN `attackRange` INT NOT NULL DEFAULT 180 AFTER `aggroRadius`,
    ADD COLUMN `attackDamage` INT NOT NULL DEFAULT 10 AFTER `attackRange`,
    ADD COLUMN `walkSpeed` INT NOT NULL DEFAULT 250 AFTER `attackDamage`;

ALTER TABLE `phoenix_npc_spawns`
    ADD COLUMN `kind` VARCHAR(16) NOT NULL DEFAULT 'monster' AFTER `presetId`,
    ADD COLUMN `idleAnimation` VARCHAR(64) NOT NULL DEFAULT '' AFTER `voice`,
    ADD COLUMN `aggroRadius` INT NOT NULL DEFAULT 1800 AFTER `idleAnimation`,
    ADD COLUMN `attackRange` INT NOT NULL DEFAULT 180 AFTER `aggroRadius`,
    ADD COLUMN `attackDamage` INT NOT NULL DEFAULT 10 AFTER `attackRange`,
    ADD COLUMN `walkSpeed` INT NOT NULL DEFAULT 250 AFTER `attackDamage`;
