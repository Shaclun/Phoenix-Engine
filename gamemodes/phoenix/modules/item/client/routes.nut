

if ("Router" in phoenix.web && phoenix.web.Router != null) {

	phoenix.web.Router.on("phoenix:item:requestUse", function(payload) {
		if (payload == null || !("id" in payload)) return
		phoenix.item.Model.requestUse(payload.id)
	})

	phoenix.web.Router.on("phoenix:item:requestEquip", function(payload) {
		if (payload == null || !("id" in payload)) return
		local equip = ("equip" in payload) ? payload.equip : true
		phoenix.item.Model.requestEquip(payload.id, equip)
	})

	phoenix.web.Router.on("phoenix:item:requestUpgrade", function(payload) {
		if (payload == null || !("id" in payload)) return
		phoenix.item.Model.requestUpgrade(payload.id)
	})

	phoenix.web.Router.on("phoenix:item:requestDrop", function(payload) {
		if (payload == null || !("id" in payload)) return
		local amount = ("amount" in payload) ? payload.amount : 1
		local name = ("name" in payload && payload.name != null) ? payload.name.tostring() : ""
		local visual = ("visual" in payload && payload.visual != null) ? payload.visual.tostring() : ""
		phoenix.item.Model.requestDrop(payload.id, amount, name, visual)
	})

	phoenix.web.Router.on("phoenix:item:closeRequest", function(payload) {
		if ("Interface" in phoenix.item && phoenix.item.Interface != null) {
			phoenix.item.Interface.close()
		}
	})

	phoenix.web.Router.on("phoenix:hotbar:use", function(payload) {
		if (payload == null) return
		local slot = -1
		if ("slot" in payload) slot = payload.slot.tointeger()
		if (slot < 0 || slot > 7) return
		local m = phoenix.player.Message.HotbarActivate()
		m.slot = slot
		try { m.serialize().send(RELIABLE) } catch (e) {}
	})
}
