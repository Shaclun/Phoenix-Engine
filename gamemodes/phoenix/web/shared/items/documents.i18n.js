(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITWR_ARMBRUSTBUCH", "Księga kuszy", "Crossbow book", "Buch der Armbrust", "Книга арбалета"],
		["ITWR_BOGENBUCH", "Księga łucznictwa", "Archery book", "Buch der Bogenkunst", "Книга лучного боя"],
		["ITWR_DEXREZEPT", "Receptura: eliksir zręczności", "Recipe: dexterity elixir", "Rezept: Geschicklichkeitselixier", "Рецепт: эликсир ловкости"],
		["ITWR_EINHANDBUCH", "Księga walki jednoręcznej", "One-handed combat book", "Buch der Einhandwaffen", "Книга одноручного боя"],
		["ITWR_HEALINGREZEPT", "Receptura: mikstura leczenia", "Recipe: healing potion", "Rezept: Heiltrank", "Рецепт: лечебное зелье"],
		["ITWR_KRAEUTERLISTE", "Lista ziół", "Herb list", "Kräuterliste", "Список трав"],
		["ITWR_MANAREZEPT", "Receptura: mikstura many", "Recipe: mana potion", "Rezept: Manatrank", "Рецепт: зелье маны"],
		["ITWR_MAP_ADDONWORLD", "Mapa: Jharkendar", "Map: Jharkendar", "Karte: Jharkendar", "Карта: Джаркендар"],
		["ITWR_MAP_NEWWORLD", "Mapa: Khorinis", "Map: Khorinis", "Karte: Khorinis", "Карта: Хоринис"],
		["ITWR_MAP_NEWWORLD_CITY", "Mapa: Miasto Khorinis", "Map: Khorinis city", "Karte: Khorinis-Stadt", "Карта: город Хоринис"],
		["ITWR_MAP_OLDWORLD", "Mapa: Górnicza Dolina", "Map: Mining Valley", "Karte: Minental", "Карта: Горная долина"],
		["ITWR_PERM_HPREZEPT", "Receptura: esencja życia", "Recipe: essence of life", "Rezept: Lebensessenz", "Рецепт: эссенция жизни"],
		["ITWR_PERM_MANAREZEPT", "Receptura: esencja many", "Recipe: essence of mana", "Rezept: Manaessenz", "Рецепт: эссенция маны"],
		["ITWR_STRREZEPT", "Receptura: eliksir siły", "Recipe: strength elixir", "Rezept: Kraftelixier", "Рецепт: эликсир силы"],
		["ITWR_ZWEIHANDBUCH", "Księga walki dwuręcznej", "Two-handed combat book", "Buch der Zweihandwaffen", "Книга двуручного боя"]
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
