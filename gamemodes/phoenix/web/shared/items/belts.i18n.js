(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITBE_ADDON_BDT_01", "Pas bandyty", "Bandit belt", "Banditengürtel", "Пояс бандита"],
		["ITBE_ADDON_DEX", "Pas zręczności", "Belt of dexterity", "Gürtel der Geschicklichkeit", "Пояс ловкости"],
		["ITBE_ADDON_HP", "Pas zdrowia", "Belt of health", "Gürtel der Gesundheit", "Пояс здоровья"],
		["ITBE_ADDON_LEATHER_01", "Skórzany pas", "Leather belt", "Ledergürtel", "Кожаный пояс"],
		["ITBE_ADDON_LEATHER_02", "Wzmocniony pas", "Reinforced belt", "Verstärkter Gürtel", "Усиленный пояс"],
		["ITBE_ADDON_MANA", "Pas many", "Belt of mana", "Gürtel der Mana", "Пояс маны"],
		["ITBE_ADDON_MIL_01", "Pas milicji", "Militia belt", "Milizgürtel", "Пояс милиции"],
		["ITBE_ADDON_PAL_01", "Pas paladyna", "Paladin belt", "Paladingürtel", "Пояс паладина"],
		["ITBE_ADDON_PIR_01", "Pas pirata", "Pirate belt", "Piratengürtel", "Пояс пирата"],
		["ITBE_ADDON_SLD_01", "Pas najemnika", "Mercenary belt", "Söldnergürtel", "Пояс наёмника"],
		["ITBE_ADDON_STRG", "Pas siły", "Belt of strength", "Gürtel der Kraft", "Пояс силы"],
		["ITBE_ADDON_STT_01", "Pas strażnika", "Guard belt", "Wächtergürtel", "Пояс стража"]
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
