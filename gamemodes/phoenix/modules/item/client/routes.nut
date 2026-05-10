

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
		if (payload == null || !("instance" in payload)) return
		local target = null
		foreach (it in phoenix.item.Model.items) {
			if (it.instance == payload.instance) {
				if (target == null) target = it
				else if (it.equipped) target = it
			}
		}
		if (target == null) return
		local category = ("category" in target) ? target.category : 0
		local isWeapon = category == PhoenixItemCategory.Weapon1H || category == PhoenixItemCategory.Weapon2H || category == PhoenixItemCategory.Bow || category == PhoenixItemCategory.Crossbow
		local isEquipment = category >= PhoenixItemCategory.Weapon1H && category <= PhoenixItemCategory.Belt
		if (isWeapon && target.equipped) {
			local mode = WEAPONMODE_1HS
			if (category == PhoenixItemCategory.Weapon2H) mode = WEAPONMODE_2HS
			else if (category == PhoenixItemCategory.Bow) mode = WEAPONMODE_BOW
			else if (category == PhoenixItemCategory.Crossbow) mode = WEAPONMODE_CBOW
			try { drawWeapon(heroId, mode) } catch (e) {}
		} else if (isEquipment) {
			phoenix.item.Model.requestEquip(target.id, !target.equipped)
		} else {
			phoenix.item.Model.requestUse(target.id)
		}
	})
}
