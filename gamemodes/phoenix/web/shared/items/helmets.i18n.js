(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITAR_BAU_HELM", "Słomiany kapelusz", "Straw hat", "Strohhut", "Соломенная шляпа"],
		["ITAR_BDT_HELM", "Hełm bandyty", "Bandit helmet", "Banditenhelm", "Шлем бандита"],
		["ITAR_KDF_HOOD", "Kaptur Maga Ognia", "Fire Mage hood", "Feuermagierkapuze", "Капюшон мага огня"],
		["ITAR_KDW_HOOD", "Kaptur Maga Wody", "Water Mage hood", "Wassermagierkapuze", "Капюшон мага воды"],
		["ITAR_MIL_HELM", "Hełm milicji", "Militia helmet", "Milizhelm", "Шлем милиции"],
		["ITAR_NOV_HOOD", "Kaptur nowicjusza", "Novice hood", "Novizenkapuze", "Капюшон послушника"],
		["ITAR_PAL_HELM", "Hełm paladyna", "Paladin helmet", "Paladinhelm", "Шлем паладина"],
		["ITAR_PIR_HELM", "Bandana pirata", "Pirate bandana", "Piratenbandana", "Бандана пирата"],
		["ITAR_SLD_HELM", "Hełm najemnika", "Mercenary helmet", "Söldnerhelm", "Шлем наёмника"]
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
