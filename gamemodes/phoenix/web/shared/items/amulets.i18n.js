(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITAM_ADDON_RAVENSGEBETBUCH", "Modlitewnik Kruka", "Raven's prayer book", "Rabens Gebetbuch", "Молитвенник Ворона"],
		["ITAM_DEX_01", "Amulet zręczności", "Amulet of dexterity", "Amulett der Geschicklichkeit", "Амулет ловкости"],
		["ITAM_DEX_STRG_01", "Amulet mocy", "Amulet of power", "Amulett der Macht", "Амулет мощи"],
		["ITAM_HP_01", "Amulet zdrowia", "Amulet of health", "Amulett der Gesundheit", "Амулет здоровья"],
		["ITAM_HP_MANA_01", "Amulet życia i many", "Amulet of life and mana", "Amulett des Lebens und der Mana", "Амулет жизни и маны"],
		["ITAM_MANA_01", "Amulet koncentracji", "Amulet of concentration", "Amulett der Konzentration", "Амулет концентрации"],
		["ITAM_PROT_EDGE_01", "Amulet pancerza", "Armor amulet", "Panzerungsamulett", "Амулет брони"],
		["ITAM_PROT_FIRE_01", "Amulet ognia", "Fire amulet", "Feueramulett", "Амулет огня"],
		["ITAM_PROT_MAGE_01", "Amulet duchowej siły", "Spirit strength amulet", "Geisteskraftamulett", "Амулет духовной силы"],
		["ITAM_PROT_POINT_01", "Amulet dębowej skóry", "Oak skin amulet", "Eichenhautamulett", "Амулет дубовой кожи"],
		["ITAM_PROT_TOTAL_01", "Amulet żywiołów", "Elemental amulet", "Elementaramulett", "Амулет стихий"],
		["ITAM_STRG_01", "Amulet siły", "Amulet of strength", "Amulett der Kraft", "Амулет силы"]
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
