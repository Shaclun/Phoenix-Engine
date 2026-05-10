local function join_handler(pid) {
    sendMessageToAll(0, 255, 0, getPlayerName(pid) + " connected with the server.")

	ClassArcher(pid)
	spawnPlayer(pid)
	setPlayerPosition(pid, 0, 0, 0)
}

addEventHandler("onPlayerJoin", join_handler)

local function respawn_handler(pid) {
    if (isNpc(pid))
        return

    sendMessageToAll(255, 150, 0, getPlayerName(pid) + " has respawned.")

	ClassArcher(pid)
	spawnPlayer(pid)
}

addEventHandler("onPlayerRespawn", respawn_handler)

local function init_handler() {
	randomseed(getTickCount())

}

addEventHandler("onInit", init_handler)