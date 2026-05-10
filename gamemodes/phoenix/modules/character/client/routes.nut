phoenix.web.Router.on("phoenix:character:requestList", function(_payload) {
	phoenix.character.Preview.stop()
	phoenix.character.Model.requestList()
})

phoenix.web.Router.on("phoenix:character:select", function(payload) {
	if (payload == null || !("characterId" in payload)) return
	phoenix.character.Preview.stopSelect()
	phoenix.character.Preview.stop()
	phoenix.character.Model.select(payload.characterId)
})

phoenix.web.Router.on("phoenix:character:list:focus", function(payload) {
	if (payload == null || !("characterId" in payload)) return
	local id = payload.characterId
	local found = null
	foreach (entry in phoenix.character.Model.list) {
		if (entry.id == id) { found = entry; break }
	}
	if (found == null) return
	phoenix.character.Preview.startSelect()
	phoenix.character.Preview.applyForRecord(found)
})

phoenix.web.Router.on("phoenix:character:list:enter", function(_payload) {

})

phoenix.web.Router.on("phoenix:character:list:leave", function(_payload) {
	phoenix.character.Preview.stopSelect()
})

phoenix.web.Router.on("phoenix:character:create", function(payload) {
	phoenix.character.Model.create(payload)
})

phoenix.web.Router.on("phoenix:character:delete", function(payload) {
	if (payload == null || !("characterId" in payload)) return
	phoenix.character.Model.remove(payload.characterId)
})

phoenix.web.Router.on("phoenix:character:create:start", function(_payload) {
	phoenix.character.Preview.start()
})

phoenix.web.Router.on("phoenix:character:create:stop", function(_payload) {
	phoenix.character.Preview.stop()
})

phoenix.web.Router.on("phoenix:character:create:cycle", function(payload) {
	if (payload == null) return
	if (!("key" in payload) || !("dir" in payload)) return
	phoenix.character.Preview.cycle(payload.key, payload.dir)
})

phoenix.web.Router.on("phoenix:character:preview:rotate", function(payload) {
	if (payload == null || !("dir" in payload)) return
	phoenix.character.Preview.rotate(payload.dir)
})

phoenix.web.Router.on("phoenix:character:create:submit", function(payload) {
	if (payload == null || !("name" in payload)) return
	local data = phoenix.character.Preview.collectPayload()
	data.name <- payload.name
	phoenix.character.Model.create(data)
})
