phoenix.npc.spawnAtAdmin <- function (adminPid, params, callback) {
	if (!isPlayerConnected(adminPid)) { if (callback != null) callback(-1); return }

	local x = 0.0; local y = 0.0; local z = 0.0; local angle = 0.0; local world = ""
	try { local p = getPlayerPosition(adminPid); if (p != null) { x = p.x; y = p.y; z = p.z } } catch (e) {}
	try { angle = getPlayerAngle(adminPid) } catch (e) {}
	try { world = getPlayerWorld(adminPid) } catch (e) {}

	if ("posX" in params) x = params.posX.tofloat()
	if ("posY" in params) y = params.posY.tofloat()
	if ("posZ" in params) z = params.posZ.tofloat()
	if ("angle" in params) angle = params.angle.tofloat()
	if ("world" in params && params.world != "") world = params.world.tostring()
	if (x == 0.0 && y == 0.0 && z == 0.0) {
		try { local p2 = getPlayerPosition(adminPid); if (p2 != null) { x = p2.x; y = p2.y; z = p2.z } } catch (e) {}
		try { angle = getPlayerAngle(adminPid) } catch (e) {}
		try { world = getPlayerWorld(adminPid) } catch (e) {}
	}

	local row = null
	if ("presetId" in params && params.presetId > 0) {
		local overrides = {
			posX = x, posY = y, posZ = z, angle = angle, world = world,
			name = ("name" in params) ? params.name.tostring() : "",
			tag = ("tag" in params) ? params.tag.tostring() : "",
			createdBy = adminPid
		}
		foreach (k in ["scaleX","scaleY","scaleZ","fatness","hp","level","strength","dexterity",
			"hostile","respawnSec","bodyModel","bodyTex","headModel","headTex","voice","instance","kind",
			"idleAnimation","aggroRadius","attackRange","attackDamage","walkSpeed","baseExperience","teacherSkills","teachCost"]) {
			if (k in params) overrides[k] <- params[k]
		}
		row = phoenix.npc.Preset.buildSpawnRowFromPreset(params.presetId, overrides)
		if (row == null) { if (callback != null) callback(-1); return }
	} else {
		local instance = ("instance" in params) ? params.instance.tostring().toupper() : ""
		if (instance == "") { if (callback != null) callback(-1); return }
		local hostile = ("hostile" in params) ? params.hostile : (phoenix.npc.isHostileByInstance(instance) ? 1 : 0)
		row = {
			instance = instance,
			name = ("name" in params) ? params.name.tostring() : "",
			world = world,
			posX = x, posY = y, posZ = z, angle = angle,
			hostile = hostile,
			respawnSec = ("respawnSec" in params) ? params.respawnSec : 60,
			tag = ("tag" in params) ? params.tag.tostring() : "",
			script = ("script" in params) ? params.script.tostring() : "",
			metadata = ("metadata" in params) ? params.metadata.tostring() : "",
			presetId = 0,
			kind = ("kind" in params) ? params.kind.tostring() : "monster",
			scaleX = ("scaleX" in params) ? params.scaleX.tofloat() : 1.0,
			scaleY = ("scaleY" in params) ? params.scaleY.tofloat() : 1.0,
			scaleZ = ("scaleZ" in params) ? params.scaleZ.tofloat() : 1.0,
			fatness = ("fatness" in params) ? params.fatness.tofloat() : 0.0,
			hp = ("hp" in params) ? params.hp : 0,
			level = ("level" in params) ? params.level : 0,
			strength = ("strength" in params) ? params.strength : 0,
			dexterity = ("dexterity" in params) ? params.dexterity : 0,
			bodyModel = ("bodyModel" in params) ? params.bodyModel.tostring() : "",
			bodyTex = ("bodyTex" in params) ? params.bodyTex : -1,
			headModel = ("headModel" in params) ? params.headModel.tostring() : "",
			headTex = ("headTex" in params) ? params.headTex : -1,
			voice = ("voice" in params) ? params.voice : 0,
			idleAnimation = ("idleAnimation" in params) ? params.idleAnimation.tostring() : "",
			aggroRadius = ("aggroRadius" in params) ? params.aggroRadius : 900,
			attackRange = ("attackRange" in params) ? params.attackRange : 180,
			attackDamage = ("attackDamage" in params) ? params.attackDamage : 10,
			walkSpeed = ("walkSpeed" in params) ? params.walkSpeed : 250,
			baseExperience = ("baseExperience" in params) ? params.baseExperience : (("expReward" in params) ? params.expReward : (phoenix.npc.findCatalog(instance) != null && "baseExperience" in phoenix.npc.findCatalog(instance) ? phoenix.npc.findCatalog(instance).baseExperience : 0)),
			teacherSkills = ("teacherSkills" in params) ? params.teacherSkills.tostring() : "",
			teachCost = ("teachCost" in params) ? params.teachCost : 100,
			createdBy = adminPid
		}
	}

	phoenix.npc.Spawn.insertAndSpawn(row, callback)
}
