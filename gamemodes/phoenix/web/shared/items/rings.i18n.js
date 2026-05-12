(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITRI_DEX_01", "Pierścień zręczności", "Ring of dexterity", "Geschicklichkeitsring", "Кольцо ловкости"],
		["ITRI_DEX_02", "Pierścień zręczności II", "Ring of dexterity II", "Geschicklichkeitsring II", "Кольцо ловкости II"],
		["ITRI_DEX_STRG_01", "Pierścień mocy", "Ring of power", "Machtring", "Кольцо мощи"],
		["ITRI_HP_01", "Pierścień zdrowia", "Ring of health", "Gesundheitsring", "Кольцо здоровья"],
		["ITRI_HP_02", "Pierścień zdrowia II", "Ring of health II", "Gesundheitsring II", "Кольцо здоровья II"],
		["ITRI_HP_MANA_01", "Pierścień życia i many", "Ring of life and mana", "Ring des Lebens und der Mana", "Кольцо жизни и маны"],
		["ITRI_MANA_01", "Pierścień many", "Ring of mana", "Manaring", "Кольцо маны"],
		["ITRI_MANA_02", "Pierścień many II", "Ring of mana II", "Manaring II", "Кольцо маны II"],
		["ITRI_PROT_EDGE_01", "Pierścień pancerza", "Ring of armor", "Panzerungsring", "Кольцо брони"],
		["ITRI_PROT_EDGE_02", "Pierścień pancerza II", "Ring of armor II", "Panzerungsring II", "Кольцо брони II"],
		["ITRI_PROT_FIRE_01", "Pierścień ognia", "Ring of fire", "Feuerring", "Кольцо огня"],
		["ITRI_PROT_FIRE_02", "Pierścień ognia II", "Ring of fire II", "Feuerring II", "Кольцо огня II"],
		["ITRI_PROT_MAGE_01", "Pierścień magii", "Ring of magic", "Magiering", "Кольцо магии"],
		["ITRI_PROT_MAGE_02", "Pierścień magii II", "Ring of magic II", "Magiering II", "Кольцо магии II"],
		["ITRI_PROT_POINT_01", "Pierścień ochrony", "Ring of protection", "Schutzring", "Кольцо защиты"],
		["ITRI_PROT_POINT_02", "Pierścień ochrony II", "Ring of protection II", "Schutzring II", "Кольцо защиты II"],
		["ITRI_PROT_TOTAL_01", "Pierścień żywiołów", "Ring of elements", "Elementarring", "Кольцо стихий"],
		["ITRI_PROT_TOTAL_02", "Pierścień żywiołów II", "Ring of elements II", "Elementarring II", "Кольцо стихий II"],
		["ITRI_STRG_01", "Pierścień siły", "Ring of strength", "Kraftring", "Кольцо силы"],
		["ITRI_STRG_02", "Pierścień siły II", "Ring of strength II", "Kraftring II", "Кольцо силы II"]
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
