phoenix.character.Preview <- {
	active = false

	cameraAngle = 0.0
	cameraDistance = 300.0
	cameraPitch = 50.0
	minDistance = 100.0
	maxDistance = 800.0
	minPitch = -50.0
	maxPitch = 200.0
	rotationSpeed = 0.3
	pitchSpeed = 0.2
	zoomSensitivity = 25.0
	rightDown = false
	modelAngle = 180.0

	anchorX = 870.118
	anchorY = -96.2501
	anchorZ = -1848.33

	state = {
		gender = 0
		race = 1
		head = 1
		face = 0
		fatness = 1
		walking = 0
		weapon = 0
		ranged = 0
		outfit = 0
		scenario = 0
	}

	bodyTextures = {
		"0": { "0": [4], "1": [5], "2": [6], "3": [7] }
		"1": { "0": [0], "1": [1], "2": [2], "3": [3] }
	}

	faceTextures = {
		"0": {
			"0": [151]
			"1": [137, 138, 139, 140, 143, 144, 145, 146, 147, 148, 149, 150, 152, 153, 154, 155, 156]
			"2": [141, 158]
			"3": [142, 157]
		}
		"1": {
			"0": [19, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 88]
			"1": [0, 1, 2, 3, 5, 6, 7, 9, 10, 13, 14, 16, 18, 20, 21, 22, 23, 24, 25, 26, 27, 31, 32, 33, 34, 35, 36, 37, 38, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 159, 160, 161]
			"2": [8, 15, 29, 30, 40, 120, 121, 122, 123, 124, 125, 126, 127, 128]
			"3": [4, 11, 12, 17, 28, 129, 130, 131, 132, 133, 134, 135, 136]
		}
	}

	headModelsMale = [
		"Hum_Head_Pony",
		"Hum_Head_Bald",
		"Hum_Head_Thief",
		"Hum_Head_Psionic",
		"Hum_Head_Fighter",
		"Hum_Head_FatBald",
		"HUM_HEAD_LONGHAIR",
		"HUM_HEAD_PONYBEARD",
		"HUM_HEAD_BrodaDuza",
		"HUM_HEAD_BrodaMala",
		"HUM_HEAD_BrodaSrednia",
		"HUM_HEAD_BrodaWas",
		"HUM_HEAD_PSIONIC_PONY",
		"HUM_HEAD_WITHOUTPONY",
		"HUM_HEAD_MARVIN"
	]
	headModelsFemale = [
		"HUM_HEAD_BABE",
		"HUM_HEAD_BABE1",
		"HUM_HEAD_BABE2",
		"HUM_HEAD_BABE3",
		"HUM_HEAD_BABE4",
		"HUM_HEAD_BABE6",
		"HUM_HEAD_BABE7",
		"HUM_HEAD_BABE8",
		"HUM_HEAD_BABE12",
		"HUM_HEAD_BABEHAIR",
		"HUM_HEAD_IVY"
	]

	weapons = [
		{ key = "melee_1h", instance = "ITMW_1H_BAU_AXE" },
		{ key = "melee_2h", instance = "ITMW_2H_AXE_L_01" }
	]

	rangedWeapons = [
		{ key = "ranged_bow",      instance = "ITRW_BOW_L_01" },
		{ key = "ranged_crossbow", instance = "ITRW_CROSSBOW_L_01" }
	]

	outfits = [
		{ key = "outfit_worker",  male = "ITAR_BAU_L",     female = "ITAR_BAUBABE_L" },
		{ key = "outfit_citizen", male = "ITAR_VLK_M",     female = "ITAR_BAUBABE_M" },
		{ key = "outfit_leather", male = "ITAR_LEATHER_L", female = "ITAR_DJG_BABE" }
	]

	fatnessValues = [-1.0, 0.0, 1.0, 2.0]
	walkingModes = ["", "S_1HRUNL", "S_2HRUNL", "S_WALKL"]

	scenarios = [
		{ key = "shipwreck",   x = -37591.7, y = -2033.3,  z = 15142.5,  angle = 91.6603 },
		{ key = "swamp",       x = 21282.2,  y = -5116.71, z = 4491.03,  angle = 57.3989 },
		{ key = "lostMemory",  x = -19429.0, y = -2791.03, z = -11997.8, angle = 0.181277 }
	]

	currentEquippedWeapon = ""
	currentEquippedRanged = ""
	currentEquippedOutfit = ""
		selectionPreviewActive = false
	currentSelectionItems = []

	defaultState = function() {
		return {
			gender = 0
			race = 1
			head = 1
			face = 0
			fatness = 1
			walking = 0
			weapon = 0
			ranged = 0
			outfit = 0
			scenario = 0
		}
	}

	bodyModelFor = function(gender) {
		return (gender == 0) ? "Hum_Body_Babe0" : "Hum_Body_Naked0"
	}

	headListFor = function(gender) {
		return (gender == 0) ? phoenix.character.Preview.headModelsFemale : phoenix.character.Preview.headModelsMale
	}

	racesAvailableFor = function(gender) {
		local key = "" + gender
		local out = []
		if (key in phoenix.character.Preview.faceTextures) {
			local sub = phoenix.character.Preview.faceTextures[key]
			foreach (raceKey, list in sub) if (list != null && list.len() > 0) out.push(raceKey.tointeger())
		}
		out.sort()
		if (out.len() == 0) out = [1]
		return out
	}

	faceListFor = function(gender, race) {
		local g = "" + gender
		local r = "" + race
		if (!(g in phoenix.character.Preview.faceTextures)) return [0]
		local sub = phoenix.character.Preview.faceTextures[g]
		if (!(r in sub)) return [0]
		local list = sub[r]
		return (list == null || list.len() == 0) ? [0] : list
	}

	bodyTexFor = function(gender, race) {
		local g = "" + gender
		local r = "" + race
		if (!(g in phoenix.character.Preview.bodyTextures)) return 0
		local sub = phoenix.character.Preview.bodyTextures[g]
		if (!(r in sub)) return 0
		local list = sub[r]
		return (list == null || list.len() == 0) ? 0 : list[0]
	}

	normalizeRecordVisual = function(record) {
		local body = ("bodyModel" in record && record.bodyModel != null && record.bodyModel != "") ? record.bodyModel : "Hum_Body_Naked0"
		local head = ("headModel" in record && record.headModel != null && record.headModel != "") ? record.headModel : "Hum_Head_Pony"
		local bodyTex = ("bodyTexIndex" in record && record.bodyTexIndex != null) ? record.bodyTexIndex : 1
		local face = ("face" in record && record.face != null) ? record.face : 0
		local isFemale = false
		if ("gender" in record) isFemale = record.gender == PhoenixCharacterGender.Female
		else isFemale = body.tostring().toupper().find("BABE") != null

		if (isFemale) {
			body = "Hum_Body_Babe0"
			local headUpper = head.tostring().toupper()
			if (headUpper.find("BABE") == null && headUpper.find("IVY") == null) head = "Hum_Head_Babe"
			if (bodyTex >= 0 && bodyTex <= 3) bodyTex += 4
			if (face < 137 || face > 158) face = 137
		} else {
			body = "Hum_Body_Naked0"
			local headUpper = head.tostring().toupper()
			if (headUpper.find("BABE") != null || headUpper.find("IVY") != null) head = "Hum_Head_Pony"
			if (bodyTex >= 4 && bodyTex <= 7) bodyTex -= 4
			if (face >= 137 && face <= 158) face = 0
		}

		return { body = body, head = head, bodyTex = bodyTex, face = face }
	}
}

phoenix.character.Preview.applyVisual <- function() {
	local s = phoenix.character.Preview.state
	local body = phoenix.character.Preview.bodyModelFor(s.gender)
	local heads = phoenix.character.Preview.headListFor(s.gender)
	if (s.head < 0 || s.head >= heads.len()) s.head = 0
	local head = heads[s.head]
	local bodyTex = phoenix.character.Preview.bodyTexFor(s.gender, s.race)
	local faceList = phoenix.character.Preview.faceListFor(s.gender, s.race)
	if (s.face < 0 || s.face >= faceList.len()) s.face = 0
	local faceTex = faceList[s.face]

	try { setPlayerVisual(heroId, body, bodyTex, head, faceTex) } catch (e) {}

	local fatIdx = s.fatness
	if (fatIdx < 0 || fatIdx >= phoenix.character.Preview.fatnessValues.len()) fatIdx = 1
	try { setPlayerFatness(heroId, phoenix.character.Preview.fatnessValues[fatIdx]) } catch (e) {}
}

phoenix.character.Preview.applyAnimation <- function() {
	local idx = phoenix.character.Preview.state.walking
	local mode = phoenix.character.Preview.walkingModes[idx >= 0 && idx < phoenix.character.Preview.walkingModes.len() ? idx : 0]
	if (mode == "") return
	try { applyPlayerOverlay(heroId, mode + ".MDS") } catch (e) {}
}

phoenix.character.Preview.applyWeaponPreview <- function() {
	local s = phoenix.character.Preview.state
	if (s.weapon < 0 || s.weapon >= phoenix.character.Preview.weapons.len()) return
	local entry = phoenix.character.Preview.weapons[s.weapon]
	if (phoenix.character.Preview.currentEquippedWeapon != "") {
		try { unequipItem(heroId, phoenix.character.Preview.currentEquippedWeapon) } catch (e) {}
		try { removeItem(heroId, phoenix.character.Preview.currentEquippedWeapon, 1) } catch (e) {}
	}
	phoenix.character.Preview.currentEquippedWeapon = ""
	if (entry.instance == "") return
	try { giveItem(heroId, entry.instance, 1) } catch (e) {}
	try { equipItem(heroId, entry.instance) } catch (e) {}
	phoenix.character.Preview.currentEquippedWeapon = entry.instance
}

phoenix.character.Preview.applyRangedPreview <- function() {
	local s = phoenix.character.Preview.state
	if (s.ranged < 0 || s.ranged >= phoenix.character.Preview.rangedWeapons.len()) return
	local entry = phoenix.character.Preview.rangedWeapons[s.ranged]
	if (phoenix.character.Preview.currentEquippedRanged != "") {
		try { unequipItem(heroId, phoenix.character.Preview.currentEquippedRanged) } catch (e) {}
		try { removeItem(heroId, phoenix.character.Preview.currentEquippedRanged, 1) } catch (e) {}
	}
	phoenix.character.Preview.currentEquippedRanged = ""
	if (entry.instance == "") return
	try { giveItem(heroId, entry.instance, 1) } catch (e) {}
	try { equipItem(heroId, entry.instance) } catch (e) {}
	phoenix.character.Preview.currentEquippedRanged = entry.instance
}

phoenix.character.Preview.applyOutfitPreview <- function() {
	local s = phoenix.character.Preview.state
	if (s.outfit < 0 || s.outfit >= phoenix.character.Preview.outfits.len()) return
	local entry = phoenix.character.Preview.outfits[s.outfit]
	local instance = (s.gender == 0) ? entry.female : entry.male
	if (phoenix.character.Preview.currentEquippedOutfit != "") {
		try { unequipItem(heroId, phoenix.character.Preview.currentEquippedOutfit) } catch (e) {}
		try { removeItem(heroId, phoenix.character.Preview.currentEquippedOutfit, 1) } catch (e) {}
	}
	phoenix.character.Preview.currentEquippedOutfit = ""
	if (instance == null || instance == "") return
	try { giveItem(heroId, instance, 1) } catch (e) {}
	try { equipItem(heroId, instance) } catch (e) {}
	phoenix.character.Preview.currentEquippedOutfit = instance
}

phoenix.character.Preview.cycle <- function(key, direction) {
	if (!phoenix.character.Preview.active) return
	local s = phoenix.character.Preview.state

	if (key == "gender") {
		s.gender = (s.gender + direction + 2) % 2
		local races = phoenix.character.Preview.racesAvailableFor(s.gender)
		if (races.find(s.race) == null) s.race = races[0]
		s.face = 0
		s.head = 0
		phoenix.character.Preview.applyVisual()
		phoenix.character.Preview.applyOutfitPreview()
		phoenix.character.Preview.broadcastAll()
		return
	}

	if (key == "race") {
		local races = phoenix.character.Preview.racesAvailableFor(s.gender)
		local idx = races.find(s.race)
		if (idx == null) idx = 0
		idx = (idx + direction + races.len()) % races.len()
		s.race = races[idx]
		s.face = 0
		phoenix.character.Preview.applyVisual()
		phoenix.character.Preview.notifyOption("race")
		phoenix.character.Preview.notifyOption("face")
		return
	}

	if (key == "head") {
		local heads = phoenix.character.Preview.headListFor(s.gender)
		s.head = (s.head + direction + heads.len()) % heads.len()
		phoenix.character.Preview.applyVisual()
		phoenix.character.Preview.notifyOption("head")
		return
	}

	if (key == "face") {
		local faces = phoenix.character.Preview.faceListFor(s.gender, s.race)
		s.face = (s.face + direction + faces.len()) % faces.len()
		phoenix.character.Preview.applyVisual()
		phoenix.character.Preview.notifyOption("face")
		return
	}

	if (key == "fatness") {
		local n = phoenix.character.Preview.fatnessValues.len()
		s.fatness = (s.fatness + direction + n) % n
		phoenix.character.Preview.applyVisual()
		phoenix.character.Preview.notifyOption("fatness")
		return
	}

	if (key == "walking") {
		local n = phoenix.character.Preview.walkingModes.len()
		s.walking = (s.walking + direction + n) % n
		phoenix.character.Preview.applyAnimation()
		phoenix.character.Preview.notifyOption("walking")
		return
	}

	if (key == "weapon") {
		local n = phoenix.character.Preview.weapons.len()
		s.weapon = (s.weapon + direction + n) % n
		phoenix.character.Preview.applyWeaponPreview()
		phoenix.character.Preview.notifyOption("weapon")
		return
	}

	if (key == "ranged") {
		local n = phoenix.character.Preview.rangedWeapons.len()
		s.ranged = (s.ranged + direction + n) % n
		phoenix.character.Preview.applyRangedPreview()
		phoenix.character.Preview.notifyOption("ranged")
		return
	}

	if (key == "outfit") {
		local n = phoenix.character.Preview.outfits.len()
		s.outfit = (s.outfit + direction + n) % n
		phoenix.character.Preview.applyOutfitPreview()
		phoenix.character.Preview.notifyOption("outfit")
		return
	}

	if (key == "scenario") {
		local n = phoenix.character.Preview.scenarios.len()
		s.scenario = (s.scenario + direction + n) % n
		phoenix.character.Preview.notifyOption("scenario")
		return
	}
}

phoenix.character.Preview.labelOf <- function(key) {
	local s = phoenix.character.Preview.state
	if (key == "gender") return "character.create.gender." + s.gender
	if (key == "race")   return "character.create.race." + s.race
	if (key == "head")   return "" + (s.head + 1)
	if (key == "face")   return "" + (s.face + 1)
	if (key == "fatness") return "character.create.fatness." + s.fatness
	if (key == "walking") return "character.create.walking." + s.walking
	if (key == "weapon")  return "character.create.weapon." + s.weapon
	if (key == "ranged")  return "character.create.ranged." + s.ranged
	if (key == "outfit")  return "character.create.outfit." + s.outfit
	if (key == "scenario") return "character.create.scenario." + s.scenario
	return ""
}

phoenix.character.Preview.notifyOption <- function(key) {
	phoenix.web.Manager.emit("phoenix:character:option", {
		key = key
		value = phoenix.character.Preview.labelOf(key)
		i18n = true
	})
}

phoenix.character.Preview.broadcastAll <- function() {
	foreach (key in ["gender", "race", "head", "face", "fatness", "walking", "weapon", "ranged", "outfit", "scenario"]) {
		phoenix.character.Preview.notifyOption(key)
	}
}

phoenix.character.Preview.collectPayload <- function() {
	local s = phoenix.character.Preview.state
	local body = phoenix.character.Preview.bodyModelFor(s.gender)
	local heads = phoenix.character.Preview.headListFor(s.gender)
	local headModel = heads[s.head < heads.len() ? s.head : 0]
	local bodyTex = phoenix.character.Preview.bodyTexFor(s.gender, s.race)
	local faces = phoenix.character.Preview.faceListFor(s.gender, s.race)
	local faceTex = faces[s.face < faces.len() ? s.face : 0]
	return {

		gender = (s.gender == 0) ? 2 : 1
		klass = 3
		race = s.race
		fatness = s.fatness
		walking = s.walking
		weapon = s.weapon
		ranged = s.ranged
		outfit = s.outfit
		scenario = s.scenario
		bodyModel = body
		headModel = headModel
		bodyTexIndex = bodyTex
		face = faceTex
		voice = 0
	}
}

phoenix.character.Preview.applyAngle <- function() {
	try { setPlayerAngle(heroId, phoenix.character.Preview.modelAngle, true) } catch (e) { try { setPlayerAngle(heroId, phoenix.character.Preview.modelAngle) } catch (e2) {} }
}

phoenix.character.Preview.rotate <- function(direction) {
	if (!phoenix.character.Preview.active) return
	phoenix.character.Preview.modelAngle += direction.tofloat() * 15.0
	while (phoenix.character.Preview.modelAngle < 0.0) phoenix.character.Preview.modelAngle += 360.0
	while (phoenix.character.Preview.modelAngle >= 360.0) phoenix.character.Preview.modelAngle -= 360.0
	phoenix.character.Preview.applyAngle()
}

phoenix.character.Preview.start <- function() {
	phoenix.character.Preview.clearSelectionEquipment()
	phoenix.character.Preview.clearCreatorEquipment()
	phoenix.character.Preview.state = phoenix.character.Preview.defaultState()
	phoenix.character.Preview.active = true
	phoenix.character.Preview.cameraAngle = 0.0
	phoenix.character.Preview.cameraDistance = 300.0
	phoenix.character.Preview.cameraPitch = 50.0
	phoenix.character.Preview.modelAngle = 180.0

	try { Camera.movementEnabled = false } catch (e) {}
	try { Camera.modeChangeEnabled = false } catch (e) {}
	try { setHudMode(HUD_ALL, HUD_MODE_HIDDEN) } catch (e) {}
	try { setCursorVisible(true) } catch (e) {}

	phoenix.character.Preview.applyVisual()
	phoenix.character.Preview.applyAnimation()
	phoenix.character.Preview.applyWeaponPreview()
	phoenix.character.Preview.applyRangedPreview()
	phoenix.character.Preview.applyOutfitPreview()
	phoenix.character.Preview.applyAngle()
	phoenix.character.Preview.broadcastAll()
}

phoenix.character.Preview.stop <- function() {
	if (!phoenix.character.Preview.active) return
	phoenix.character.Preview.active = false
	if (phoenix.character.Preview.currentEquippedWeapon != "") {
		try { unequipItem(heroId, phoenix.character.Preview.currentEquippedWeapon) } catch (e) {}
		try { removeItem(heroId, phoenix.character.Preview.currentEquippedWeapon, 1) } catch (e) {}
		phoenix.character.Preview.currentEquippedWeapon = ""
	}
	if (phoenix.character.Preview.currentEquippedRanged != "") {
		try { unequipItem(heroId, phoenix.character.Preview.currentEquippedRanged) } catch (e) {}
		try { removeItem(heroId, phoenix.character.Preview.currentEquippedRanged, 1) } catch (e) {}
		phoenix.character.Preview.currentEquippedRanged = ""
	}
	if (phoenix.character.Preview.currentEquippedOutfit != "") {
		try { unequipItem(heroId, phoenix.character.Preview.currentEquippedOutfit) } catch (e) {}
		try { removeItem(heroId, phoenix.character.Preview.currentEquippedOutfit, 1) } catch (e) {}
		phoenix.character.Preview.currentEquippedOutfit = ""
	}
}

phoenix.character.Preview.clearCreatorEquipment <- function() {
	local instances = []
	foreach (entry in phoenix.character.Preview.weapons) instances.push(entry.instance)
	foreach (entry in phoenix.character.Preview.rangedWeapons) instances.push(entry.instance)
	foreach (entry in phoenix.character.Preview.outfits) {
		instances.push(entry.male)
		instances.push(entry.female)
	}
	foreach (instance in instances) {
		if (instance == null || instance == "") continue
		try { unequipItem(heroId, instance) } catch (e) {}
		try { removeItem(heroId, instance, 1) } catch (e) {}
	}
	phoenix.character.Preview.currentEquippedWeapon = ""
	phoenix.character.Preview.currentEquippedRanged = ""
	phoenix.character.Preview.currentEquippedOutfit = ""
}

phoenix.character.Preview.clearSelectionEquipment <- function() {
	foreach (instance in phoenix.character.Preview.currentSelectionItems) {
		try { unequipItem(heroId, instance) } catch (e) {}
		try { removeItem(heroId, instance, 1) } catch (e) {}
	}
	phoenix.character.Preview.currentSelectionItems = []
}

phoenix.character.Preview.applyEquipmentString <- function(raw) {
	phoenix.character.Preview.clearSelectionEquipment()
	if (raw == null || raw == "") return
	phoenix.character.Preview.selectionPreviewActive = true
	local parts = split(raw, ",")
	foreach (part in parts) {
		local fields = split(part, "|")
		if (fields.len() == 0) continue
		local instance = fields[0]
		if (instance == "") continue
		if (instance == "ITRW_ARROW" || instance == "ITRW_BOLT") continue
		try { giveItem(heroId, instance, 1) } catch (e) {}
		try { equipItem(heroId, instance) } catch (e) {}
		phoenix.character.Preview.currentSelectionItems.push(instance)
	}
}

phoenix.character.Preview.requestWorldRestore <- function() {
	local msg = phoenix.character.Message.PreviewRestore()
	try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
}

phoenix.character.Preview.onMouseDown <- function(button) {
	if (!phoenix.character.Preview.active) return
	if (button == MOUSE_BUTTONRIGHT) phoenix.character.Preview.rightDown = true
}

phoenix.character.Preview.onMouseUp <- function(button) {
	if (button == MOUSE_BUTTONRIGHT) phoenix.character.Preview.rightDown = false
}

phoenix.character.Preview.onMouseMove <- function(dx, dy) {
	if (!phoenix.character.Preview.active) return
	if (!phoenix.character.Preview.rightDown) return

	phoenix.character.Preview.cameraAngle += dx * phoenix.character.Preview.rotationSpeed
	while (phoenix.character.Preview.cameraAngle < 0) phoenix.character.Preview.cameraAngle += 360
	while (phoenix.character.Preview.cameraAngle >= 360) phoenix.character.Preview.cameraAngle -= 360

	phoenix.character.Preview.cameraPitch -= dy * phoenix.character.Preview.pitchSpeed
	if (phoenix.character.Preview.cameraPitch < phoenix.character.Preview.minPitch) phoenix.character.Preview.cameraPitch = phoenix.character.Preview.minPitch
	if (phoenix.character.Preview.cameraPitch > phoenix.character.Preview.maxPitch) phoenix.character.Preview.cameraPitch = phoenix.character.Preview.maxPitch
}

phoenix.character.Preview.onMouseWheel <- function(direction) {
	if (!phoenix.character.Preview.active) return
	phoenix.character.Preview.cameraDistance -= direction * phoenix.character.Preview.zoomSensitivity
	if (phoenix.character.Preview.cameraDistance < phoenix.character.Preview.minDistance) phoenix.character.Preview.cameraDistance = phoenix.character.Preview.minDistance
	if (phoenix.character.Preview.cameraDistance > phoenix.character.Preview.maxDistance) phoenix.character.Preview.cameraDistance = phoenix.character.Preview.maxDistance
}

phoenix.character.Preview.onRender <- function() {
	if (!phoenix.character.Preview.active) return

	local pos = null
	try { pos = getPlayerPosition(heroId) } catch (e) { return }
	if (pos == null) return

	try { setPlayerPosition(heroId, phoenix.character.Preview.anchorX, phoenix.character.Preview.anchorY, phoenix.character.Preview.anchorZ) } catch (e) {}
	phoenix.character.Preview.applyAngle()

	local px = phoenix.character.Preview.anchorX
	local py = phoenix.character.Preview.anchorY
	local pz = phoenix.character.Preview.anchorZ

	local heroAngle = 0.0
	try { heroAngle = getPlayerAngle(heroId) } catch (e) {}

	local finalAngle = heroAngle + phoenix.character.Preview.cameraAngle
	local angleRad = finalAngle * 3.14159 / 180.0

	local camX = px + sin(angleRad) * phoenix.character.Preview.cameraDistance
	local camY = py + 100.0 + phoenix.character.Preview.cameraPitch
	local camZ = pz + cos(angleRad) * phoenix.character.Preview.cameraDistance

	try { Camera.setPosition(camX, camY, camZ) } catch (e) {}

	local dX = px - camX
	local dZ = pz - camZ
	local dY = (py + 90.0) - camY
	local yaw = atan2(dX, dZ) * 180.0 / 3.14159
	local distance2D = sqrt(dX * dX + dZ * dZ)
	local pitch = -atan2(dY, distance2D) * 180.0 / 3.14159

	try { Camera.setRotation(pitch, yaw, 0) } catch (e) {}
}

addEventHandler("onMouseDown", function(button) {
	phoenix.character.Preview.onMouseDown(button)
})
addEventHandler("onMouseUp", function(button) {
	phoenix.character.Preview.onMouseUp(button)
})
addEventHandler("onMouseMove", function(dx, dy) {
	phoenix.character.Preview.onMouseMove(dx, dy)
})
addEventHandler("onMouseWheel", function(dir) {
	phoenix.character.Preview.onMouseWheel(dir)
})
addEventHandler("onRender", function() {
	phoenix.character.Preview.onRender()
})

phoenix.character.Preview.applyForRecord <- function(record) {
	if (record == null) return
	local visual = phoenix.character.Preview.normalizeRecordVisual(record)
	local body = visual.body
	local head = visual.head
	local bodyTex = visual.bodyTex
	local face = visual.face
	try { setPlayerVisual(heroId, body, bodyTex, head, face) } catch (e) {}
	if ("fatness" in record && record.fatness != null) {
		local fatIdx = record.fatness
		if (fatIdx < 0 || fatIdx >= phoenix.character.Preview.fatnessValues.len()) fatIdx = 1
		try { setPlayerFatness(heroId, phoenix.character.Preview.fatnessValues[fatIdx]) } catch (e) {}
	}
	if ("equipment" in record) phoenix.character.Preview.applyEquipmentString(record.equipment)
	phoenix.character.Preview.applyAngle()
}

phoenix.character.Preview.startSelect <- function() {
	if (phoenix.character.Preview.active) return
	phoenix.character.Preview.active = true
	phoenix.character.Preview.cameraAngle = 0.0
	phoenix.character.Preview.cameraDistance = 300.0
	phoenix.character.Preview.cameraPitch = 50.0
	phoenix.character.Preview.modelAngle = 180.0
	try { Camera.movementEnabled = false } catch (e) {}
	try { Camera.modeChangeEnabled = false } catch (e) {}
	try { setHudMode(HUD_ALL, HUD_MODE_HIDDEN) } catch (e) {}
	try { setCursorVisible(true) } catch (e) {}
}

phoenix.character.Preview.stopSelect <- function() {
	if (!phoenix.character.Preview.active) return
	phoenix.character.Preview.active = false
	phoenix.character.Preview.clearSelectionEquipment()
	phoenix.character.Preview.selectionPreviewActive = false
	phoenix.character.Preview.requestWorldRestore()
}
