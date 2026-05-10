function ClassTank(pid) {
    setPlayerVisual(pid, "Hum_Body_Naked0", 3, "Hum_Head_Psionic", 59)
    setPlayerMaxHealth(pid, 3800)
    setPlayerHealth(pid, 3800)
    setPlayerStrength(pid, 100)
    setPlayerSkillWeapon(pid, 0, 50)

    giveItem(pid, "ITPO_HEALTH_ADDON_04", 10)
    giveItem(pid, "ITPO_SPEED", 10)

    giveItem(pid, "ITAR_DJG_H", 1)
    giveItem(pid, "ITMW_SCHWERT2", 1)

    equipItem(pid, "ITAR_DJG_H")
    equipItem(pid, "ITMW_SCHWERT2")

    applyPlayerOverlay(pid, "HUMANS_ARROGANCE.MDS")
}

function ClassFighter(pid) {
    setPlayerVisual(pid, "Hum_Body_Naked0", 2, "Hum_Head_Fighter", 120)
    setPlayerMaxHealth(pid, 2800)
    setPlayerHealth(pid, 2800)
    setPlayerStrength(pid, 120)
    setPlayerDexterity(pid, 70)
    setPlayerSkillWeapon(pid, 0, 50)

    giveItem(pid, "ITPO_HEALTH_ADDON_04", 10)
    giveItem(pid, "ITPO_SPEED", 10)

    giveItem(pid, "ITAR_SLD_H", 1)
    giveItem(pid, "ITMW_SCHWERT5", 1)

    equipItem(pid, "ITAR_SLD_H")
    equipItem(pid, "ITMW_SCHWERT5")
}

function ClassArcher(pid) {
    setPlayerVisual(pid, "Hum_Body_Naked0", 1, "Hum_Head_FatBald", 32)
    setPlayerMaxHealth(pid, 2200)
    setPlayerHealth(pid, 2200)
    setPlayerStrength(pid, 100)
    setPlayerDexterity(pid, 120)
    setPlayerSkillWeapon(pid, 0, 70)
    setPlayerSkillWeapon(pid, 2, 60)

    giveItem(pid, "ITAR_BDT_H", 1)
    giveItem(pid, "ITMW_SCHWERT1", 1)
    giveItem(pid, "ITRW_BOW_H_01", 1)

    equipItem(pid, "ITAR_BDT_H")
    equipItem(pid, "ITMW_SCHWERT1")
    equipItem(pid, "ITRW_BOW_H_01")

    giveItem(pid, "ITRW_ARROW", 100)

    giveItem(pid, "ITPO_HEALTH_ADDON_04", 10)
    giveItem(pid, "ITPO_SPEED", 10)
}