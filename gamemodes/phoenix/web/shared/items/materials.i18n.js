(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITMI_AQUAMARINE", "Akwamaryn", "Aquamarine", "Aquamarin", "Аквамарин"],
		["ITMI_BONE", "Kość", "Bone", "Knochen", "Кость"],
		["ITMI_BROOM", "Miotła", "Broom", "Besen", "Метла"],
		["ITMI_CLAW", "Pazur", "Claw", "Klaue", "Коготь"],
		["ITMI_COAL", "Węgiel", "Coal", "Kohle", "Уголь"],
		["ITMI_DARKPEARL", "Czarna perła", "Dark pearl", "Dunkle Perle", "Чёрная жемчужина"],
		["ITMI_DRAGONBLOOD", "Krew smoka", "Dragon blood", "Drachenblut", "Кровь дракона"],
		["ITMI_DRAGONSCALE", "Łuska smoka", "Dragon scale", "Drachenschuppe", "Чешуя дракона"],
		["ITMI_EYE", "Oko", "Eye", "Auge", "Глаз"],
		["ITMI_FOCUS", "Magiczny fokus", "Magic focus", "Magischer Fokus", "Магический фокус"],
		["ITMI_FUR", "Futro", "Fur", "Fell", "Мех"],
		["ITMI_GOLD", "Złoto", "Gold", "Gold", "Золото"],
		["ITMI_GOLDNUGGET_ADDON", "Bryłka złota", "Gold nugget", "Goldklumpen", "Золотой самородок"],
		["ITMI_HAMMER", "Młotek", "Hammer", "Hammer", "Молоток"],
		["ITMI_HEART", "Serce", "Heart", "Herz", "Сердце"],
		["ITMI_LEATHER", "Skóra", "Leather", "Leder", "Кожа"],
		["ITMI_NUGGET", "Bryłka rudy", "Ore nugget", "Erzklumpen", "Кусок руды"],
		["ITMI_PAN", "Patelnia", "Pan", "Pfanne", "Сковорода"],
		["ITMI_PANFULL", "Patelnia z jedzeniem", "Pan with food", "Pfanne mit Essen", "Сковорода с едой"],
		["ITMI_PLIERS", "Kleszcze", "Pliers", "Zange", "Клещи"],
		["ITMI_QUARTZ", "Kwarc", "Quartz", "Quarz", "Кварц"],
		["ITMI_RAKE", "Grabie", "Rake", "Harke", "Грабли"],
		["ITMI_ROCKCRYSTAL", "Kryształ górski", "Rock crystal", "Bergkristall", "Горный хрусталь"],
		["ITMI_RUNEBLANK", "Pusta runa", "Blank rune", "Leere Rune", "Пустая руна"],
		["ITMI_SAW", "Piła", "Saw", "Säge", "Пила"],
		["ITMI_SCOOP", "Łopata", "Scoop", "Schaufel", "Лопата"],
		["ITMI_SEXTANT", "Sekstans", "Sextant", "Sextant", "Секстант"],
		["ITMI_STOMACH", "Żołądek", "Stomach", "Magen", "Желудок"],
		["ITMI_SULFUR", "Siarka", "Sulfur", "Schwefel", "Сера"],
		["ITMI_TEETH", "Zęby", "Teeth", "Zähne", "Зубы"],
		["ITMI_TONGUE", "Język", "Tongue", "Zunge", "Язык"],
		["ITMI_TORCH", "Pochodnia", "Torch", "Fackel", "Факел"]
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
