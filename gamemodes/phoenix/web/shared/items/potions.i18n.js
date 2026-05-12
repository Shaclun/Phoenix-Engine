(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITPO_HEALTH_01", "Esencja lecznicza", "Healing essence", "Heilessenz", "Лечебная эссенция"],
		["ITPO_HEALTH_02", "Ekstrakt leczniczy", "Healing extract", "Heilextrakt", "Лечебный экстракт"],
		["ITPO_HEALTH_03", "Eliksir leczniczy", "Healing elixir", "Heilelixier", "Лечебный эликсир"],
		["ITPO_HEALTH_ADDON_04", "Eliksir życia", "Elixir of life", "Lebenselixier", "Эликсир жизни"],
		["ITPO_HEALTH_TRUNK", "Leczniczy napój", "Healing draught", "Heiltrunk", "Лечебный напиток"],
		["ITPO_MANA_01", "Esencja many", "Mana essence", "Manaessenz", "Эссенция маны"],
		["ITPO_MANA_02", "Ekstrakt many", "Mana extract", "Manaextrakt", "Экстракт маны"],
		["ITPO_MANA_03", "Eliksir many", "Mana elixir", "Manaelixier", "Эликсир маны"],
		["ITPO_MANA_ADDON_04", "Eliksir esencji", "Essence elixir", "Essenzelixier", "Эликсир эссенции"],
		["ITPO_MANA_TRUNK", "Napój many", "Mana draught", "Manatrunk", "Напиток маны"],
		["ITPO_MEGADRINK", "Megadrink", "Mega drink", "Mega-Drink", "Мегадринк"],
		["ITPO_PERM_DEX", "Esencja zręczności", "Essence of dexterity", "Geschicklichkeitsessenz", "Эссенция ловкости"],
		["ITPO_PERM_HEALTH", "Esencja życia", "Essence of life", "Lebensessenz", "Эссенция жизни"],
		["ITPO_PERM_LITTLEMANA", "Mała esencja many", "Small mana essence", "Kleine Manaessenz", "Малая эссенция маны"],
		["ITPO_PERM_MANA", "Esencja many+", "Permanent mana essence", "Dauerhafte Manaessenz", "Постоянная эссенция маны"],
		["ITPO_PERM_STR", "Esencja siły", "Essence of strength", "Kraftessenz", "Эссенция силы"],
		["ITPO_SPEED", "Mikstura szybkości", "Speed potion", "Geschwindigkeitstrank", "Зелье скорости"]
	];

	const map = window.PhoenixItemI18n || {};
	LANGS.forEach(function (lang) {
		if (!map[lang]) map[lang] = {};
	});
	ROWS.forEach(function (row) {
		const inst = row[0];
		LANGS.forEach(function (lang, idx) {
			map[lang]["item." + inst + ".name"] = row[idx + 1];
		});
	});
	window.PhoenixItemI18n = map;

	if (!window.PhoenixI18n._itemTHook) {
		window.PhoenixI18n._itemTHook = true;
		const orig = window.PhoenixI18n.tItem;
		window.PhoenixI18n.tItem = function (instance, suffix, fallback) {
			if (!instance) return fallback || "";
			const key = "item." + String(instance).toUpperCase() + "." + (suffix || "name");
			const lang = window.PhoenixI18n.getLang();
			const cur = window.PhoenixItemI18n && window.PhoenixItemI18n[lang];
			if (cur && key in cur) return cur[key];
			if (typeof orig === "function") return orig(instance, suffix, fallback);
			return fallback || "";
		};
	}
})();
