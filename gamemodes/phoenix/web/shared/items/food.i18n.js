(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITFO_ADDON_FIRESTEW", "Ognisty gulasz", "Fiery stew", "Feuriger Eintopf", "Огненное рагу"],
		["ITFO_ADDON_GROG", "Grog", "Grog", "Grog", "Грог"],
		["ITFO_ADDON_MEATSOUP", "Gulasz", "Stew", "Eintopf", "Рагу"],
		["ITFO_ADDON_RUM", "Rum", "Rum", "Rum", "Ром"],
		["ITFO_ADDON_SHELLFLESH", "Ostryga", "Oyster", "Auster", "Устрица"],
		["ITFO_APPLE", "Jabłko", "Apple", "Apfel", "Яблоко"],
		["ITFO_BACON", "Szynka", "Ham", "Schinken", "Окорок"],
		["ITFO_BEER", "Piwo", "Beer", "Bier", "Пиво"],
		["ITFO_BOOZE", "Gin", "Gin", "Gin", "Джин"],
		["ITFO_BREAD", "Chleb", "Bread", "Brot", "Хлеб"],
		["ITFO_CHEESE", "Ser", "Cheese", "Käse", "Сыр"],
		["ITFO_EGG", "Jajko", "Egg", "Ei", "Яйцо"],
		["ITFO_FISH", "Ryba", "Fish", "Fisch", "Рыба"],
		["ITFO_FISHSOUP", "Zupa rybna", "Fish soup", "Fischsuppe", "Рыбный суп"],
		["ITFO_HONEY", "Miód", "Honey", "Honig", "Мёд"],
		["ITFO_MILK", "Mleko", "Milk", "Milch", "Молоко"],
		["ITFO_MUTTON", "Smażone mięso", "Fried meat", "Gebratenes Fleisch", "Жареное мясо"],
		["ITFO_MUTTONRAW", "Surowe mięso", "Raw meat", "Rohes Fleisch", "Сырое мясо"],
		["ITFO_SAUSAGE", "Kiełbasa", "Sausage", "Wurst", "Колбаса"],
		["ITFO_STEW", "Gulasz", "Stew", "Eintopf", "Рагу"],
		["ITFO_WATER", "Woda", "Water", "Wasser", "Вода"],
		["ITFO_WINE", "Wino", "Wine", "Wein", "Вино"]
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
