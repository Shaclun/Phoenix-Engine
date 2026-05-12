(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITSH_METAL_01", "Żelazna tarcza", "Iron shield", "Eisenschild", "Железный щит"],
		["ITSH_METAL_02", "Stalowa tarcza", "Steel shield", "Stahlschild", "Стальной щит"],
		["ITSH_PAL_SHIELD", "Tarcza paladyna", "Paladin shield", "Paladinschild", "Щит паладина"],
		["ITSH_WOOD_01", "Drewniany puklerz", "Wooden buckler", "Holzbuckler", "Деревянный щит"],
		["ITSH_WOOD_02", "Drewniana tarcza", "Wooden shield", "Holzschild", "Деревянный щит"]
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
