(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITMW_2H_AXE_L_01", "Kilof", "Pickaxe", "Spitzhacke", "Кирка"],
		["ITMW_2H_BAU_AXE", "Topór drwala", "Woodcutter's axe", "Holzfälleraxt", "Топор дровосека"],
		["ITMW_2H_BLESSED_01", "Kiepskie ostrze magiczne (2H)", "Poor magic blade (2H)", "Schlechte magische Klinge (2H)", "Плохой магический клинок (2H)"],
		["ITMW_2H_BLESSED_02", "Błogosławione ostrze magiczne (2H)", "Blessed magic blade (2H)", "Gesegnete magische Klinge (2H)", "Благословенный магический клинок (2H)"],
		["ITMW_2H_BLESSED_03", "Gniew Innosa (2H)", "Wrath of Innos (2H)", "Innos' Zorn (2H)", "Гнев Инноса (2H)"],
		["ITMW_2H_ORCAXE_01", "Lekki orkowy topór", "Light orc axe", "Leichte Orkaxt", "Лёгкий орочий топор"],
		["ITMW_2H_ORCAXE_02", "Średni orkowy topór", "Medium orc axe", "Mittlere Orkaxt", "Средний орочий топор"],
		["ITMW_2H_ORCAXE_03", "Ciężki orkowy topór", "Heavy orc axe", "Schwere Orkaxt", "Тяжёлый орочий топор"],
		["ITMW_2H_ORCAXE_04", "Ogromny orkowy topór", "Huge orc axe", "Riesige Orkaxt", "Огромный орочий топор"],
		["ITMW_2H_ORCSWORD_01", "Jaszczurzy miecz", "Lizard sword", "Echsenschwert", "Ящерий меч"],
		["ITMW_2H_ORCSWORD_02", "Orkowy miecz wojenny", "Orc war sword", "Orkkriegsschwert", "Боевой орочий меч"],
		["ITMW_2H_PAL_SWORD", "Miecz dwuręczny paladyna", "Paladin two-handed sword", "Zweihandschwert des Paladins", "Двуручный меч паладина"],
		["ITMW_2H_ROD", "Kij", "Rod", "Stab", "Жезл"],
		["ITMW_2H_SLD_AXE", "Kiepski topór bojowy", "Poor battle axe", "Schlechte Streitaxt", "Плохой боевой топор"],
		["ITMW_2H_SLD_SWORD", "Kiepski miecz dwuręczny", "Poor two-handed sword", "Schlechtes Zweihandschwert", "Плохой двуручный меч"],
		["ITMW_2H_SPECIAL_01", "Długi miecz magiczny", "Magic long sword", "Magisches Langschwert", "Магический длинный меч"],
		["ITMW_2H_SPECIAL_02", "Magiczny miecz półtoraręczny", "Magic bastard sword", "Magischer Bastardschwert", "Магический полуторный меч"],
		["ITMW_2H_SPECIAL_03", "Magiczne ostrze bojowe", "Magic battle blade", "Magische Kampfklinge", "Магический боевой клинок"],
		["ITMW_2H_SPECIAL_04", "Magiczne ostrze na smoki", "Magic dragon blade", "Magische Drachenklinge", "Магический драконий клинок"],
		["ITMW_ADDON_HACKER_2H_01", "Wielka maczeta", "Great machete", "Grosse Machete", "Большое мачете"],
		["ITMW_ADDON_HACKER_2H_02", "Wielka, stara maczeta", "Great old machete", "Grosse alte Machete", "Большое старое мачете"],
		["ITMW_ADDON_KEULE_2H_01", "Sługa Burzy", "Servant of the Storm", "Diener des Sturms", "Слуга бури"],
		["ITMW_ADDON_PIR2HAXE", "Miażdżydeska", "Plank crusher", "Plankenbrecher", "Доскодавитель"],
		["ITMW_ADDON_PIR2HSWORD", "Miecz pokładowy", "Deck sword", "Decksschwert", "Палубный меч"],
		["ITMW_ADDON_STAB01", "Kostur maga", "Mage staff", "Magierstab", "Посох мага"],
		["ITMW_ADDON_STAB02", "Magiczna różdżka", "Magic wand", "Magischer Stab", "Магический жезл"],
		["ITMW_ADDON_STAB03", "Wodny kostur", "Water staff", "Wasserstab", "Посох воды"],
		["ITMW_ADDON_STAB04", "Kostur Ulthara", "Ulthar's staff", "Ulthars Stab", "Посох Ультара"],
		["ITMW_ADDON_STAB05", "Tajfun", "Typhoon", "Taifun", "Тайфун"],
		["ITMW_BARBARENSTREITAXT", "Barbarzyński topór bojowy", "Barbarian battle axe", "Barbarenstreitaxt", "Варварский боевой топор"],
		["ITMW_BERSERKERAXT", "Topór berserkera", "Berserker axe", "Berserkeraxt", "Топор берсерка"],
		["ITMW_DRACHENSCHNEIDE", "Smocza Zguba", "Dragon's Bane", "Drachenschneide", "Драконоубийца"],
		["ITMW_HELLEBARDE", "Halabarda", "Halberd", "Hellebarde", "Алебарда"],
		["ITMW_RANGERSTAFF_ADDON", "Pika bojowa Wodnego Kręgu", "Water Circle battle pike", "Wasserkreis-Kampfpike", "Боевая пика Круга Воды"]
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
