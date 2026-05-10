local Stackable = PhoenixItemFlag.Stackable
local Food = PhoenixItemCategory.Food
local Material = PhoenixItemCategory.Material

local function herb(value, stackMax, category = Food, effect = null) {
	local data = {
		category = category,
		value = value,
		weight = 0.1,
		stackMax = stackMax,
		flags = Stackable
	}
	if (effect != null) {
		data.onUse <- effect.kind
		data.effect <- effect.data
	}
	return data
}

phoenix.item.register("ITPL_WEED", herb(1, 100))
phoenix.item.register("ITPL_BEET", herb(2, 100))
phoenix.item.register("ITPL_SWAMPHERB", herb(10, 100, Material))
phoenix.item.register("ITPL_MANA_HERB_01", herb(10, 100, Food, { kind = "mana", data = { mana = 5 } }))
phoenix.item.register("ITPL_MANA_HERB_02", herb(25, 100, Food, { kind = "mana", data = { mana = 10 } }))
phoenix.item.register("ITPL_MANA_HERB_03", herb(60, 100, Food, { kind = "mana", data = { mana = 20 } }))
phoenix.item.register("ITPL_HEALTH_HERB_01", herb(10, 100, Food, { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITPL_HEALTH_HERB_02", herb(25, 100, Food, { kind = "heal", data = { hp = 10 } }))
phoenix.item.register("ITPL_HEALTH_HERB_03", herb(60, 100, Food, { kind = "heal", data = { hp = 20 } }))
phoenix.item.register("ITPL_DEX_HERB_01", herb(350, 50, Material))
phoenix.item.register("ITPL_STRENGTH_HERB_01", herb(350, 50, Material))
phoenix.item.register("ITPL_SPEED_HERB_01", herb(100, 50, Material))
phoenix.item.register("ITPL_MUSHROOM_01", herb(5, 100, Food, { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITPL_MUSHROOM_02", herb(5, 100, Food, { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITPL_BLUEPLANT", herb(20, 100, Material))
phoenix.item.register("ITPL_FORESTBERRY", herb(5, 100, Food, { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITPL_PLANEBERRY", herb(5, 100, Food, { kind = "heal", data = { hp = 5 } }))
phoenix.item.register("ITPL_TEMP_HERB", herb(250, 50, Material))
phoenix.item.register("ITPL_PERM_HERB", herb(500, 50, Material))
phoenix.item.register("ITPL_SAGITTA_HERB_MIS", herb(500, 50, Material))