(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITMW_1H_BAU_AXE", "Sierp", "Sickle", "Sichel", "Серп"],
		["ITMW_1H_BAU_MACE", "Laga", "Club", "Knüppel", "Дубина"],
		["ITMW_1H_BLESSED_01", "Kiepskie ostrze magiczne", "Poor magic blade", "Schlechte magische Klinge", "Плохой магический клинок"],
		["ITMW_1H_BLESSED_02", "Błogosławione ostrze magiczne", "Blessed magic blade", "Gesegnete magische Klinge", "Благословенный магический клинок"],
		["ITMW_1H_BLESSED_03", "Gniew Innosa", "Wrath of Innos", "Innos' Zorn", "Гнев Инноса"],
		["ITMW_1H_COMMON_01", "Miecz", "Sword", "Schwert", "Меч"],
		["ITMW_1H_FERROSSWORD_MIS", "Miecz Ferosa", "Feros's sword", "Feros' Schwert", "Меч Фероса"],
		["ITMW_1H_MACE_L_01", "Pogrzebacz", "Poker", "Schürhaken", "Кочерга"],
		["ITMW_1H_MACE_L_03", "Pałka", "Cudgel", "Keule", "Палица"],
		["ITMW_1H_MACE_L_04", "Młot kowalski", "Smith's hammer", "Schmiedehammer", "Кузнечный молот"],
		["ITMW_1H_MIL_SWORD", "Kiepski szeroki miecz", "Poor broad sword", "Schlechtes Breitschwert", "Плохой широкий меч"],
		["ITMW_1H_MISC_AXE", "Zardzewiały topór", "Rusty axe", "Rostige Axt", "Ржавый топор"],
		["ITMW_1H_MISC_SWORD", "Zardzewiały krótki miecz", "Rusty short sword", "Rostiges Kurzschwert", "Ржавый короткий меч"],
		["ITMW_1H_NOV_MACE", "Pika bojowa", "Battle pike", "Kampfpike", "Боевая пика"],
		["ITMW_1H_PAL_SWORD", "Miecz paladyna", "Paladin's sword", "Paladinschwert", "Меч паладина"],
		["ITMW_1H_SLD_AXE", "Kiepski tasak", "Poor cleaver", "Schlechter Hackmesser", "Плохой тесак"],
		["ITMW_1H_SLD_SWORD", "Kiepski miecz", "Poor sword", "Schlechtes Schwert", "Плохой меч"],
		["ITMW_1H_SPECIAL_01", "Długi miecz magiczny", "Magic long sword", "Magisches Langschwert", "Магический длинный меч"],
		["ITMW_1H_SPECIAL_02", "Magiczny miecz półtoraręczny", "Magic bastard sword", "Magischer Bastardschwert", "Магический полуторный меч"],
		["ITMW_1H_SPECIAL_03", "Magiczne ostrze bojowe", "Magic battle blade", "Magische Kampfklinge", "Магический боевой клинок"],
		["ITMW_1H_SPECIAL_04", "Magiczne ostrze na smoki", "Magic dragon blade", "Magische Drachenklinge", "Магический драконий клинок"],
		["ITMW_1H_SWORD_L_03", "Nóż na wilki", "Wolf knife", "Wolfsmesser", "Волчий нож"],
		["ITMW_1H_VLK_AXE", "Topór", "Axe", "Axt", "Топор"],
		["ITMW_1H_VLK_DAGGER", "Sztylet", "Dagger", "Dolch", "Кинжал"],
		["ITMW_1H_VLK_MACE", "Laska", "Staff", "Stock", "Посох"],
		["ITMW_1H_VLK_SWORD", "Miecz", "Sword", "Schwert", "Меч"],
		["ITMW_ADDON_BANDITTRADER", "Pałasz bandytów", "Bandit cutlass", "Banditen-Pallasch", "Палаш бандитов"],
		["ITMW_ADDON_BETTY", "Betty", "Betty", "Betty", "Бетти"],
		["ITMW_ADDON_HACKER_1H_01", "Maczeta", "Machete", "Machete", "Мачете"],
		["ITMW_ADDON_HACKER_1H_02", "Stara maczeta", "Old machete", "Alte Machete", "Старое мачете"],
		["ITMW_ADDON_KEULE_1H_01", "Sługa Wiatru", "Servant of the wind", "Diener des Windes", "Слуга ветра"],
		["ITMW_ADDON_KNIFE01", "Nóż na wilki", "Wolf knife", "Wolfsmesser", "Волчий нож"],
		["ITMW_ADDON_PIR1HAXE", "Topór pokładowy", "Boarding axe", "Enteraxt", "Абордажный топор"],
		["ITMW_ADDON_PIR1HSWORD", "Kordelas", "Cutlass", "Entermesser", "Абордажная сабля"],
		["ITMW_ALRIKSSWORD_MIS", "Miecz Alrika", "Alrik's sword", "Alriks Schwert", "Меч Альрика"],
		["ITMW_BARTAXT", "Wielki topór", "Great axe", "Große Axt", "Большой топор"],
		["ITMW_DOPPELAXT", "Topór obosieczny", "Double-edged axe", "Doppelschneidige Axt", "Двухлезвийный топор"],
		["ITMW_ELBASTARDO", "El Bastardo", "El Bastardo", "El Bastardo", "Эль Бастардо"],
		["ITMW_FOLTERAXT", "Katowski topór", "Executioner's axe", "Henkersaxt", "Топор палача"],
		["ITMW_FRANCISDAGGER_MIS", "Złoty sztylet", "Golden dagger", "Goldener Dolch", "Золотой кинжал"],
		["ITMW_INQUISITOR", "Inkwizytor", "Inquisitor", "Inquisitor", "Инквизитор"],
		["ITMW_KRIEGSHAMMER1", "Młot wojenny", "War hammer", "Kriegshammer", "Боевой молот"],
		["ITMW_KRIEGSHAMMER2", "Ciężki młot wojenny", "Heavy war hammer", "Schwerer Kriegshammer", "Тяжёлый боевой молот"],
		["ITMW_KRIEGSKEULE", "Pałka bojowa", "Battle club", "Kampfkeule", "Боевая палица"],
		["ITMW_KRUMMSCHWERT", "Kordelas", "Cutlass", "Entermesser", "Абордажная сабля"],
		["ITMW_MALETHSGEHSTOCK_MIS", "Laska Maletha", "Maleth's staff", "Maleths Stock", "Посох Малета"],
		["ITMW_MEISTERDEGEN", "Miecz mistrzowski", "Master sword", "Meisterschwert", "Мастерский меч"],
		["ITMW_MORGENSTERN", "Buława i łańcuch", "Mace and chain", "Streitkolben und Kette", "Булава с цепью"],
		["ITMW_NAGELKEULE", "Pałka z kolcami", "Spiked club", "Nagelkeule", "Дубина с шипами"],
		["ITMW_NAGELKEULE2", "Ciężka pałka z kolcami", "Heavy spiked club", "Schwere Nagelkeule", "Тяжёлая дубина с шипами"],
		["ITMW_NAGELKNUEPPEL", "Maczuga z kolcami", "Spiked cudgel", "Nagelknüppel", "Палица с шипами"],
		["ITMW_ORKSCHLAECHTER", "Orkowa Zguba", "Orc slayer", "Orkschlächter", "Орочья погибель"],
		["ITMW_PIRATENSAEBEL", "Piracki kordelas", "Pirate cutlass", "Piraten-Entermesser", "Пиратская абордажная сабля"],
		["ITMW_RABENSCHNABEL", "Kruczy Dziób", "Raven beak", "Rabenschnabel", "Вороний клюв"],
		["ITMW_RAPIER", "Rapier", "Rapier", "Rapier", "Рапира"],
		["ITMW_RUBINKLINGE", "Rubinowe ostrze", "Ruby blade", "Rubinklinge", "Рубиновый клинок"],
		["ITMW_RUNENSCHWERT", "Miecz runiczny", "Rune sword", "Runenschwert", "Рунный меч"],
		["ITMW_SCHIFFSAXT", "Topór marynarski", "Sailor's axe", "Seemannsaxt", "Моряцкий топор"],
		["ITMW_SCHWERT", "Kiepski długi miecz", "Poor long sword", "Schlechtes Langschwert", "Плохой длинный меч"],
		["ITMW_SCHWERT1", "Dobry miecz", "Good sword", "Gutes Schwert", "Хороший меч"],
		["ITMW_SCHWERT2", "Długi miecz", "Long sword", "Langschwert", "Длинный меч"],
		["ITMW_SCHWERT3", "Kiepski miecz półtoraręczny", "Poor bastard sword", "Schlechter Bastardschwert", "Плохой полуторный меч"],
		["ITMW_SCHWERT4", "Dobry długi miecz", "Good long sword", "Gutes Langschwert", "Хороший длинный меч"],
		["ITMW_SCHWERT5", "Dobry miecz półtoraręczny", "Good bastard sword", "Guter Bastardschwert", "Хороший полуторный меч"],
		["ITMW_SENSE", "Mała kosa", "Small scythe", "Kleine Sense", "Маленькая коса"],
		["ITMW_SHORTSWORD1", "Krótki miecz straży", "Guard's short sword", "Kurzschwert der Wache", "Короткий меч стражи"],
		["ITMW_SHORTSWORD2", "Kiepski krótki miecz", "Poor short sword", "Schlechtes Kurzschwert", "Плохой короткий меч"],
		["ITMW_SHORTSWORD3", "Krótki miecz", "Short sword", "Kurzschwert", "Короткий меч"],
		["ITMW_SHORTSWORD4", "Wilczy kieł", "Wolf's tooth", "Wolfszahn", "Волчий клык"],
		["ITMW_SHORTSWORD5", "Dobry krótki miecz", "Good short sword", "Gutes Kurzschwert", "Хороший короткий меч"],
		["ITMW_SPICKER", "Rębiczerep", "Skullsplitter", "Schädelspalter", "Черепокол"],
		["ITMW_STEINBRECHER", "Oskard", "Pickaxe", "Spitzhacke", "Кирка"],
		["ITMW_STREITKOLBEN", "Buława", "Mace", "Streitkolben", "Булава"]
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
