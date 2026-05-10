(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITPL_WEED", "Chwast", "Weed", "Unkraut", "Сорняк"],
		["ITPL_BEET", "Burak", "Beet", "Rübe", "Свекла"],
		["ITPL_SWAMPHERB", "Bagienne ziele", "Swampweed", "Sumpfkraut", "Болотник"],
		["ITPL_MANA_HERB_01", "Ognisty korzeń", "Fire root", "Feuerwurzel", "Огненный корень"],
		["ITPL_MANA_HERB_02", "Szczaw królewski", "King's sorrel", "Kronstöckel", "Царский щавель"],
		["ITPL_MANA_HERB_03", "Korzeń many", "Mana root", "Mana-Wurzel", "Корень маны"],
		["ITPL_HEALTH_HERB_01", "Roślina lecznicza", "Healing plant", "Heilpflanze", "Лечебное растение"],
		["ITPL_HEALTH_HERB_02", "Ziele lecznicze", "Healing herb", "Heilkraut", "Лечебная трава"],
		["ITPL_HEALTH_HERB_03", "Korzeń leczniczy", "Healing root", "Heilwurzel", "Лечебный корень"],
		["ITPL_DEX_HERB_01", "Jagody goblina", "Goblin berries", "Goblinbeeren", "Гоблинские ягоды"],
		["ITPL_STRENGTH_HERB_01", "Smoczy korzeń", "Dragon root", "Drachenwurzel", "Драконий корень"],
		["ITPL_SPEED_HERB_01", "Rdest polny", "Field knotweed", "Feldknöterich", "Полевой спорыш"],
		["ITPL_MUSHROOM_01", "Grzyb", "Mushroom", "Pilz", "Гриб"],
		["ITPL_MUSHROOM_02", "Ciemny grzyb", "Dark mushroom", "Dunkelpilz", "Тёмный гриб"],
		["ITPL_BLUEPLANT", "Niebieski bez", "Blue elder", "Blauer Holunder", "Синяя бузина"],
		["ITPL_FORESTBERRY", "Leśna jagoda", "Forest berry", "Waldbeere", "Лесная ягода"],
		["ITPL_PLANEBERRY", "Polna jagoda", "Field berry", "Feldbeere", "Полевая ягода"],
		["ITPL_TEMP_HERB", "Ziele specjalne", "Special herb", "Spezialkraut", "Особая трава"],
		["ITPL_PERM_HERB", "Królewski szczaw", "King's sorrel", "Kronstöckel", "Царский щавель"],
		["ITPL_SAGITTA_HERB_MIS", "Ziele Sagitty", "Sagitta's herb", "Sagittas Kraut", "Трава Сагитты"]
	];

	const names = {};
	LANGS.forEach(function (lang) { names[lang] = {}; });
	ROWS.forEach(function (row) {
		const instance = row[0];
		LANGS.forEach(function (lang, index) { names[lang][instance] = row[index + 1]; });
	});

	const previous = window.PhoenixI18n.tItem;
	window.PhoenixHerbNameI18n = names;
	window.PhoenixI18n.tItem = function (instance, suffix, fallback) {
		if (suffix !== "name" || !instance) {
			return typeof previous === "function" ? previous(instance, suffix, fallback) : (fallback || "");
		}
		const lang = window.PhoenixI18n.getLang ? window.PhoenixI18n.getLang() : "pl";
		const key = String(instance).toUpperCase();
		const dict = names[lang] || names.pl;
		if (dict && key in dict) return dict[key];
		if (lang !== "pl" && names.pl && key in names.pl) return names.pl[key];
		return typeof previous === "function" ? previous(instance, suffix, fallback) : (fallback || "");
	};
})();