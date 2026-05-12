(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITSC_ARMYOFDARKNESS", "Zwój: Armia Ciemności", "Scroll: Army of darkness", "Schriftrolle: Armee der Dunkelheit", "Свиток: Армия тьмы"],
		["ITSC_BREATHOFDEATH", "Zwój: Oddech Śmierci", "Scroll: Breath of death", "Schriftrolle: Atem des Todes", "Свиток: Дыхание смерти"],
		["ITSC_CHARGEFIREBALL", "Zwój: Naładowana Kula Ognia", "Scroll: Charged fireball", "Schriftrolle: Geladener Feuerball", "Свиток: Заряженный огненный шар"],
		["ITSC_FEAR", "Zwój: Strach", "Scroll: Fear", "Schriftrolle: Furcht", "Свиток: Страх"],
		["ITSC_FIREBOLT", "Zwój: Pocisk Ognia", "Scroll: Firebolt", "Schriftrolle: Feuerblitz", "Свиток: Огненный снаряд"],
		["ITSC_FIRERAIN", "Zwój: Deszcz Ognia", "Scroll: Fire rain", "Schriftrolle: Feuerregen", "Свиток: Огненный дождь"],
		["ITSC_FIRESTORM", "Zwój: Burza Ognia", "Scroll: Firestorm", "Schriftrolle: Feuersturm", "Свиток: Огненная буря"],
		["ITSC_FULLHEAL", "Zwój: Pełne Leczenie", "Scroll: Full heal", "Schriftrolle: Volle Heilung", "Свиток: Полное лечение"],
		["ITSC_HARMUNDEAD", "Zwój: Rażenie Nieumarłych", "Scroll: Harm undead", "Schriftrolle: Untote schaden", "Свиток: Поражение нежити"],
		["ITSC_ICEBOLT", "Zwój: Pocisk Lodu", "Scroll: Icebolt", "Schriftrolle: Eisblitz", "Свиток: Ледяной снаряд"],
		["ITSC_ICECUBE", "Zwój: Sześcian Lodu", "Scroll: Ice cube", "Schriftrolle: Eiswürfel", "Свиток: Ледяной куб"],
		["ITSC_ICEWAVE", "Zwój: Fala Lodu", "Scroll: Ice wave", "Schriftrolle: Eiswelle", "Свиток: Ледяная волна"],
		["ITSC_INSTANTFIREBALL", "Zwój: Kula Ognia", "Scroll: Fireball", "Schriftrolle: Feuerball", "Свиток: Огненный шар"],
		["ITSC_LIGHT", "Zwój: Światło", "Scroll: Light", "Schriftrolle: Licht", "Свиток: Свет"],
		["ITSC_LIGHTHEAL", "Zwój: Małe Leczenie", "Scroll: Minor heal", "Schriftrolle: Kleine Heilung", "Свиток: Малое лечение"],
		["ITSC_LIGHTNINGFLASH", "Zwój: Błyskawica", "Scroll: Lightning", "Schriftrolle: Blitz", "Свиток: Молния"],
		["ITSC_MASSDEATH", "Zwój: Masowa Śmierć", "Scroll: Mass death", "Schriftrolle: Massentod", "Свиток: Массовая смерть"],
		["ITSC_MASTEROFDISASTER", "Zwój: Mistrz Zniszczenia", "Scroll: Master of disaster", "Schriftrolle: Meister des Unheils", "Свиток: Мастер разрушения"],
		["ITSC_MEDIUMHEAL", "Zwój: Leczenie", "Scroll: Heal", "Schriftrolle: Heilung", "Свиток: Лечение"],
		["ITSC_PYROKINESIS", "Zwój: Pirokineza", "Scroll: Pyrokinesis", "Schriftrolle: Pyrokinese", "Свиток: Пирокинез"],
		["ITSC_SHRINK", "Zwój: Pomniejszenie", "Scroll: Shrink", "Schriftrolle: Schrumpfen", "Свиток: Уменьшение"],
		["ITSC_SLEEP", "Zwój: Sen", "Scroll: Sleep", "Schriftrolle: Schlaf", "Свиток: Сон"],
		["ITSC_SUMDEMON", "Zwój: Przywołaj Demona", "Scroll: Summon demon", "Schriftrolle: Dämon beschwören", "Свиток: Призвать демона"],
		["ITSC_SUMGOBSKEL", "Zwój: Szkielet Goblina", "Scroll: Goblin skeleton", "Schriftrolle: Goblinskelett", "Свиток: Скелет гоблина"],
		["ITSC_SUMGOL", "Zwój: Przywołaj Golema", "Scroll: Summon golem", "Schriftrolle: Golem beschwören", "Свиток: Призвать голема"],
		["ITSC_SUMSKEL", "Zwój: Przywołaj Szkielet", "Scroll: Summon skeleton", "Schriftrolle: Skelett beschwören", "Свиток: Призвать скелета"],
		["ITSC_SUMWOLF", "Zwój: Przywołaj Wilka", "Scroll: Summon wolf", "Schriftrolle: Wolf beschwören", "Свиток: Призвать волка"],
		["ITSC_THUNDERBALL", "Zwój: Kula Błyskawic", "Scroll: Thunderball", "Schriftrolle: Donnerball", "Свиток: Шаровая молния"],
		["ITSC_WINDFIST", "Zwój: Pięść Wiatru", "Scroll: Windfist", "Schriftrolle: Windfaust", "Свиток: Кулак ветра"],
		["ITSC_ZAP", "Zwój: Iskra", "Scroll: Zap", "Schriftrolle: Funke", "Свиток: Искра"]
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
