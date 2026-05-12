(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITRW_ADDON_FIREARROW", "Ognista strzała", "Fire arrow", "Feuerpfeil", "Пылающая стрела"],
		["ITRW_ADDON_FIREBOW", "Ognisty łuk", "Fire bow", "Feuerbogen", "Огненный лук"],
		["ITRW_ADDON_MAGICARROW", "Magiczna strzała", "Magic arrow", "Magischer Pfeil", "Магическая стрела"],
		["ITRW_ADDON_MAGICBOLT", "Magiczny bełt", "Magic bolt", "Magischer Bolzen", "Магический болт"],
		["ITRW_ADDON_MAGICBOW", "Magiczny łuk", "Magic bow", "Magischer Bogen", "Магический лук"],
		["ITRW_ADDON_MAGICCROSSBOW", "Magiczna kusza", "Magic crossbow", "Magische Armbrust", "Магический арбалет"],
		["ITRW_ARROW", "Strzała", "Arrow", "Pfeil", "Стрела"],
		["ITRW_BOLT", "Bełt", "Bolt", "Bolzen", "Болт"],
		["ITRW_BOW_H_01", "Kościany łuk", "Bone bow", "Knochenbogen", "Костяной лук"],
		["ITRW_BOW_H_02", "Łuk dębowy", "Oak bow", "Eichenbogen", "Дубовый лук"],
		["ITRW_BOW_H_03", "Łuk wojenny", "War bow", "Kriegsbogen", "Боевой лук"],
		["ITRW_BOW_H_04", "Smoczy łuk", "Dragon bow", "Drachenbogen", "Драконий лук"],
		["ITRW_BOW_L_01", "Krótki łuk", "Short bow", "Kurzbogen", "Короткий лук"],
		["ITRW_BOW_L_02", "Łuk wierzbowy", "Willow bow", "Weidenbogen", "Ивовый лук"],
		["ITRW_BOW_L_03", "Łuk myśliwski", "Hunting bow", "Jagdbogen", "Охотничий лук"],
		["ITRW_BOW_L_03_MIS", "Łuk myśliwski", "Hunting bow", "Jagdbogen", "Охотничий лук"],
		["ITRW_BOW_L_04", "Łuk z wiązu", "Elm bow", "Ulmenbogen", "Вязовый лук"],
		["ITRW_BOW_M_01", "Łuk kompozytowy", "Composite bow", "Kompositbogen", "Композитный лук"],
		["ITRW_BOW_M_02", "Łuk jesionowy", "Ash bow", "Eschenbogen", "Ясеневый лук"],
		["ITRW_BOW_M_03", "Długi łuk", "Long bow", "Langbogen", "Длинный лук"],
		["ITRW_BOW_M_04", "Łuk bukowy", "Beech bow", "Buchenbogen", "Буковый лук"],
		["ITRW_CROSSBOW_H_01", "Ciężka kusza", "Heavy crossbow", "Schwere Armbrust", "Тяжёлый арбалет"],
		["ITRW_CROSSBOW_H_02", "Kusza łowcy smoków", "Dragon Hunter crossbow", "Drachenjägerarmbrust", "Арбалет охотника на драконов"],
		["ITRW_CROSSBOW_L_01", "Kusza myśliwska", "Hunting crossbow", "Jagdarmbrust", "Охотничий арбалет"],
		["ITRW_CROSSBOW_L_02", "Lekka kusza", "Light crossbow", "Leichte Armbrust", "Лёгкий арбалет"],
		["ITRW_CROSSBOW_M_01", "Kusza", "Crossbow", "Armbrust", "Арбалет"],
		["ITRW_CROSSBOW_M_02", "Kusza bojowa", "Battle crossbow", "Kampfarmbrust", "Боевой арбалет"],
		["ITRW_DRAGOMIRSARMBRUST_MIS", "Kusza Dragomira", "Dragomir's crossbow", "Dragomirs Armbrust", "Арбалет Драгомира"],
		["ITRW_MIL_CROSSBOW", "Kusza", "Crossbow", "Armbrust", "Арбалет"],
		["ITRW_SENGRATHSARMBRUST_MIS", "Kusza Sengratha", "Sengrath's crossbow", "Sengraths Armbrust", "Арбалет Сенграта"],
		["ITRW_SLD_BOW", "Łuk", "Bow", "Bogen", "Лук"]
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
