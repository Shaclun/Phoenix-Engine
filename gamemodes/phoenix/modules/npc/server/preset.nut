phoenix.npc.Preset <- {

	cache = {}

	function _esc(v) { try { return ORM.engine.escape(v.tostring()) } catch (e) { return v.tostring() } }

	function rowToObject(r) {
		local read = phoenix.npc.Spawn
		return {
			id = r.id,
			code = read._readStr(r, "code", ""),
			label = read._readStr(r, "label", ""),
			instance = read._readStr(r, "instance", ""),
			category = read._readStr(r, "category", "monster"),
			kind = read._readStr(r, "kind", "monster"),
			hostile = read._readInt(r, "hostile", 1),
			respawnSec = read._readInt(r, "respawnSec", 60),
			scaleX = read._readFloat(r, "scaleX", 1.0),
			scaleY = read._readFloat(r, "scaleY", 1.0),
			scaleZ = read._readFloat(r, "scaleZ", 1.0),
			fatness = read._readFloat(r, "fatness", 0.0),
			hp = read._readInt(r, "hp", 0),
			level = read._readInt(r, "level", 0),
			strength = read._readInt(r, "strength", 0),
			dexterity = read._readInt(r, "dexterity", 0),
			bodyModel = read._readStr(r, "bodyModel", ""),
			bodyTex = read._readInt(r, "bodyTex", -1),
			headModel = read._readStr(r, "headModel", ""),
			headTex = read._readInt(r, "headTex", -1),
			voice = read._readInt(r, "voice", 0),
			idleAnimation = read._readStr(r, "idleAnimation", ""),
			aggroRadius = read._readInt(r, "aggroRadius", 800),
			attackRange = read._readInt(r, "attackRange", 180),
			attackDamage = read._readInt(r, "attackDamage", 10),
			walkSpeed = read._readInt(r, "walkSpeed", 250),
			baseExperience = read._readInt(r, "baseExperience", 0),
			metadata = read._readStr(r, "metadata", ""),
			createdBy = read._readInt(r, "createdBy", 0)
		}
	}

	function loadAll(callback) {
		ORM.engine.executeAsync("SELECT * FROM `phoenix_npc_presets` ORDER BY `kind`, `label` ASC", function (rows) {
			phoenix.npc.Preset.cache = {}
			local out = []
			if (rows != null) {
				foreach (r in rows) {
					try {
						local p = phoenix.npc.Preset.rowToObject(r)
						phoenix.npc.Preset.cache[p.id] <- p
						out.append(p)
					} catch (e) {}
				}
			}
			if (callback != null) callback(out)
		})
	}

	function get(id) {
		if (id in phoenix.npc.Preset.cache) return phoenix.npc.Preset.cache[id]
		return null
	}

	function save(input, callback) {
		local esc = phoenix.npc.Preset._esc
		local p = {
			code = ("code" in input && input.code != "") ? input.code.tostring() : ("preset_" + getTickCount()),
			label = ("label" in input) ? input.label.tostring() : "",
			instance = ("instance" in input) ? input.instance.tostring().toupper() : "",
			category = ("category" in input) ? input.category.tostring() : "monster",
			kind = ("kind" in input) ? input.kind.tostring() : "monster",
			hostile = ("hostile" in input) ? input.hostile : 1,
			respawnSec = ("respawnSec" in input) ? input.respawnSec : 60,
			scaleX = ("scaleX" in input) ? input.scaleX.tofloat() : 1.0,
			scaleY = ("scaleY" in input) ? input.scaleY.tofloat() : 1.0,
			scaleZ = ("scaleZ" in input) ? input.scaleZ.tofloat() : 1.0,
			fatness = ("fatness" in input) ? input.fatness.tofloat() : 0.0,
			hp = ("hp" in input) ? input.hp : 0,
			level = ("level" in input) ? input.level : 0,
			strength = ("strength" in input) ? input.strength : 0,
			dexterity = ("dexterity" in input) ? input.dexterity : 0,
			bodyModel = ("bodyModel" in input) ? input.bodyModel.tostring() : "",
			bodyTex = ("bodyTex" in input) ? input.bodyTex : -1,
			headModel = ("headModel" in input) ? input.headModel.tostring() : "",
			headTex = ("headTex" in input) ? input.headTex : -1,
			voice = ("voice" in input) ? input.voice : 0,
			idleAnimation = ("idleAnimation" in input) ? input.idleAnimation.tostring() : "",
			aggroRadius = ("aggroRadius" in input) ? input.aggroRadius : 800,
			attackRange = ("attackRange" in input) ? input.attackRange : 180,
			attackDamage = ("attackDamage" in input) ? input.attackDamage : 10,
			walkSpeed = ("walkSpeed" in input) ? input.walkSpeed : 250,
			baseExperience = ("baseExperience" in input) ? input.baseExperience : (("expReward" in input) ? input.expReward : 0),
			createdBy = ("createdBy" in input) ? input.createdBy : null
		}
		if (p.instance == "") { if (callback != null) callback(-1); return }

		local valSql = "'" + esc(p.code) + "','" + esc(p.label) + "','" + esc(p.instance) + "','" + esc(p.category) + "','" + esc(p.kind) + "'," +
			p.hostile + "," + p.respawnSec + "," + p.scaleX + "," + p.scaleY + "," + p.scaleZ + "," + p.fatness + "," +
			p.hp + "," + p.level + "," + p.strength + "," + p.dexterity + ",'" +
			esc(p.bodyModel) + "'," + p.bodyTex + ",'" + esc(p.headModel) + "'," + p.headTex + "," + p.voice + ",'" +
			esc(p.idleAnimation) + "'," + p.aggroRadius + "," + p.attackRange + "," + p.attackDamage + "," + p.walkSpeed + "," + p.baseExperience + "," +
			(p.createdBy != null ? p.createdBy.tostring() : "NULL")

		local sql = "INSERT INTO `phoenix_npc_presets` " +
			"(`code`,`label`,`instance`,`category`,`kind`,`hostile`,`respawnSec`," +
			"`scaleX`,`scaleY`,`scaleZ`,`fatness`,`hp`,`level`,`strength`,`dexterity`," +
			"`bodyModel`,`bodyTex`,`headModel`,`headTex`,`voice`," +
			"`idleAnimation`,`aggroRadius`,`attackRange`,`attackDamage`,`walkSpeed`,`baseExperience`,`createdBy`) VALUES (" + valSql + ") " +
			"ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`instance`=VALUES(`instance`),`category`=VALUES(`category`),`kind`=VALUES(`kind`)," +
			"`hostile`=VALUES(`hostile`),`respawnSec`=VALUES(`respawnSec`)," +
			"`scaleX`=VALUES(`scaleX`),`scaleY`=VALUES(`scaleY`),`scaleZ`=VALUES(`scaleZ`),`fatness`=VALUES(`fatness`)," +
			"`hp`=VALUES(`hp`),`level`=VALUES(`level`),`strength`=VALUES(`strength`),`dexterity`=VALUES(`dexterity`)," +
			"`bodyModel`=VALUES(`bodyModel`),`bodyTex`=VALUES(`bodyTex`)," +
			"`headModel`=VALUES(`headModel`),`headTex`=VALUES(`headTex`),`voice`=VALUES(`voice`)," +
			"`idleAnimation`=VALUES(`idleAnimation`),`aggroRadius`=VALUES(`aggroRadius`)," +
			"`attackRange`=VALUES(`attackRange`),`attackDamage`=VALUES(`attackDamage`),`walkSpeed`=VALUES(`walkSpeed`),`baseExperience`=VALUES(`baseExperience`)"

		ORM.engine.executeAsync(sql, function (_) {
			phoenix.npc.Preset.loadAll(function (_2) {
				local newId = -1
				foreach (id, pr in phoenix.npc.Preset.cache) {
					if (pr.code == p.code) { newId = id; break }
				}
				if (callback != null) callback(newId)
			})
		})
	}

	function remove(id, callback) {
		ORM.engine.executeAsync("DELETE FROM `phoenix_npc_presets` WHERE `id` = " + id, function (_) {
			if (id in phoenix.npc.Preset.cache) delete phoenix.npc.Preset.cache[id]
			if (callback != null) callback(true)
		})
	}

	function buildSpawnRowFromPreset(presetId, overrides) {
		local p = phoenix.npc.Preset.get(presetId)
		if (p == null) return null
		local function pick(key, fallback) {
			if (overrides != null && key in overrides && overrides[key] != null) return overrides[key]
			return fallback
		}
		return {
			instance = pick("instance", p.instance),
			name = pick("name", ""),
			world = pick("world", ""),
			posX = pick("posX", 0.0).tofloat(),
			posY = pick("posY", 0.0).tofloat(),
			posZ = pick("posZ", 0.0).tofloat(),
			angle = pick("angle", 0.0).tofloat(),
			hostile = pick("hostile", p.hostile),
			respawnSec = pick("respawnSec", p.respawnSec),
			tag = pick("tag", ""),
			script = pick("script", ""),
			metadata = pick("metadata", ""),
			presetId = p.id,
			kind = pick("kind", p.kind),
			scaleX = pick("scaleX", p.scaleX).tofloat(),
			scaleY = pick("scaleY", p.scaleY).tofloat(),
			scaleZ = pick("scaleZ", p.scaleZ).tofloat(),
			fatness = pick("fatness", p.fatness).tofloat(),
			hp = pick("hp", p.hp),
			level = pick("level", p.level),
			strength = pick("strength", p.strength),
			dexterity = pick("dexterity", p.dexterity),
			bodyModel = pick("bodyModel", p.bodyModel),
			bodyTex = pick("bodyTex", p.bodyTex),
			headModel = pick("headModel", p.headModel),
			headTex = pick("headTex", p.headTex),
			voice = pick("voice", p.voice),
			idleAnimation = pick("idleAnimation", p.idleAnimation),
			aggroRadius = pick("aggroRadius", p.aggroRadius),
			attackRange = pick("attackRange", p.attackRange),
			attackDamage = pick("attackDamage", p.attackDamage),
			walkSpeed = pick("walkSpeed", p.walkSpeed),
			baseExperience = pick("baseExperience", p.baseExperience),
			createdBy = pick("createdBy", null)
		}
	}
}

addEventHandler("onInit", function () {
	setTimer(function () {
		try {
			phoenix.npc.Preset.loadAll(function (list) {})
		} catch (e) {}
	}, 2000, 1)
})
