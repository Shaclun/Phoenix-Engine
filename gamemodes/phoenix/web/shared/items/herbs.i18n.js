(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITPL_BEET", "Rzepa", "Turnip", "Rübe", "Репа"],
		["ITPL_BLUEPLANT", "Niebieski bez", "Blue elder", "Blauer Holunder", "Синяя бузина"],
		["ITPL_DEX_HERB_01", "Goblinie jagody", "Goblin berries", "Goblinbeeren", "Гоблинские ягоды"],
		["ITPL_FORESTBERRY", "Leśna jagoda", "Forest berry", "Waldbeere", "Лесная ягода"],
		["ITPL_HEALTH_HERB_01", "Roślina lecznicza", "Healing plant", "Heilpflanze", "Лечебное растение"],
		["ITPL_HEALTH_HERB_02", "Ziele lecznicze", "Healing herb", "Heilkraut", "Лечебная трава"],
		["ITPL_HEALTH_HERB_03", "Korzeń leczniczy", "Healing root", "Heilwurzel", "Лечебный корень"],
		["ITPL_MANA_HERB_01", "Ognista pokrzywa", "Fire nettle", "Feuernessel", "Огненная крапива"],
		["ITPL_MANA_HERB_02", "Ogniste ziele", "Fire herb", "Feuerkraut", "Огненная трава"],
		["ITPL_MANA_HERB_03", "Ognisty korzeń", "Fire root", "Feuerwurzel", "Огненный корень"],
		["ITPL_MUSHROOM_01", "Ciemny grzyb", "Dark mushroom", "Dunkler Pilz", "Тёмный гриб"],
		["ITPL_MUSHROOM_02", "Mięso kopacza", "Crawler meat", "Minecrawlerfleisch", "Мясо ползуна"],
		["ITPL_PERM_HERB", "Szczaw królewski", "Royal sorrel", "Königssauerampfer", "Королевский щавель"],
		["ITPL_PLANEBERRY", "Polna jagoda", "Field berry", "Feldbeere", "Полевая ягода"],
		["ITPL_SAGITTA_HERB_MIS", "Zioło Sagitty", "Sagitta's herb", "Sagittas Kraut", "Трава Сагитты"],
		["ITPL_SPEED_HERB_01", "Zębate ziele", "Toothed herb", "Zahnkraut", "Зубчатая трава"],
		["ITPL_STRENGTH_HERB_01", "Smoczy korzeń", "Dragon root", "Drachenwurzel", "Драконий корень"],
		["ITPL_SWAMPHERB", "Bagienne ziele", "Swamp herb", "Sumpfkraut", "Болотная трава"],
		["ITPL_TEMP_HERB", "Rdest polny", "Field knotweed", "Ackerknöterich", "Спорыш полевой"],
		["ITPL_WEED", "Chwasty", "Weeds", "Unkraut", "Сорняки"]
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
