phoenix.character.Model <- {
	list = []
	activeId = 0

	function requestList() {
		phoenix.character.Message.RequestList().serialize().send(RELIABLE_ORDERED)
	}

	function select(characterId) {
		local message = phoenix.character.Message.Select()
		message.characterId = characterId
		message.serialize().send(RELIABLE_ORDERED)
	}

	function create(payload) {
		local message = phoenix.character.Message.Create()
		message.name = "name" in payload ? payload.name : ""
		message.gender = "gender" in payload ? payload.gender : 0
		message.klass = "klass" in payload ? payload.klass : 3
		message.race = "race" in payload ? payload.race : 0
		message.fatness = "fatness" in payload ? payload.fatness : 1
		message.walking = "walking" in payload ? payload.walking : 0
		message.weapon = "weapon" in payload ? payload.weapon : 0
		message.ranged = "ranged" in payload ? payload.ranged : 0
		message.outfit = "outfit" in payload ? payload.outfit : 0
		message.scenario = "scenario" in payload ? payload.scenario : 0
		message.bodyModel = "bodyModel" in payload ? payload.bodyModel : "Hum_Body_Naked0"
		message.headModel = "headModel" in payload ? payload.headModel : "Hum_Head_Pony"
		message.bodyTexIndex = "bodyTexIndex" in payload ? payload.bodyTexIndex : 1
		message.face = "face" in payload ? payload.face : 0
		message.voice = "voice" in payload ? payload.voice : 0
		message.serialize().send(RELIABLE_ORDERED)
	}

	function remove(characterId) {
		local message = phoenix.character.Message.Delete()
		message.characterId = characterId
		message.serialize().send(RELIABLE_ORDERED)
	}

	function onList(message) {
		phoenix.character.Model.list = message.characters
		phoenix.web.Manager.emit("phoenix:character:list", { characters = message.characters })
	}

	function onCreateResult(message) {
		phoenix.web.Manager.emit("phoenix:character:createResult", {
			success = message.success
			error = message.error
		})
	}

	function onAfterSelect(message) {
		phoenix.character.Model.activeId = message.characterId
		phoenix.web.Manager.hide()
		callEvent("phoenix.character.OnSelected", message.characterId, message.name)
	}
}

phoenix.character.Message.List.bind(phoenix.character.Model.onList)
phoenix.character.Message.CreateResult.bind(phoenix.character.Model.onCreateResult)
phoenix.character.Message.AfterSelect.bind(phoenix.character.Model.onAfterSelect)
