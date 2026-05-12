(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITKE_KEY_01", "Klucz", "Key", "Schlüssel", "Ключ"],
		["ITKE_KEY_02", "Klucz", "Key", "Schlüssel", "Ключ"],
		["ITKE_KEY_03", "Klucz", "Key", "Schlüssel", "Ключ"],
		["ITKE_KEY_CASTLE_01", "Klucz zamkowy", "Castle key", "Burgschlüssel", "Замковый ключ"],
		["ITKE_KEY_CITY_01", "Klucz miejski", "City key", "Stadtschlüssel", "Городской ключ"],
		["ITKE_KEY_MONASTERY_01", "Klucz klasztorny", "Monastery key", "Klosterschlüssel", "Ключ от монастыря"],
		["ITKE_LOCKPICK", "Wytrych", "Lockpick", "Dietrich", "Отмычка"]
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
