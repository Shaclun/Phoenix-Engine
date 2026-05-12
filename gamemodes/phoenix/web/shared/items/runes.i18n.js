(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITRU_ARMYOFDARKNESS", "Runa: Armia Ciemności", "Rune: Army of darkness", "Rune: Armee der Dunkelheit", "Руна: Армия тьмы"],
		["ITRU_BREATHOFDEATH", "Runa: Oddech Śmierci", "Rune: Breath of death", "Rune: Atem des Todes", "Руна: Дыхание смерти"],
		["ITRU_CHARGEFIREBALL", "Runa: Naładowana Kula Ognia", "Rune: Charged fireball", "Rune: Geladener Feuerball", "Руна: Заряженный огненный шар"],
		["ITRU_FEAR", "Runa: Strach", "Rune: Fear", "Rune: Furcht", "Руна: Страх"],
		["ITRU_FIREBOLT", "Runa: Pocisk Ognia", "Rune: Firebolt", "Rune: Feuerblitz", "Руна: Огненный снаряд"],
		["ITRU_FIRERAIN", "Runa: Deszcz Ognia", "Rune: Fire rain", "Rune: Feuerregen", "Руна: Огненный дождь"],
		["ITRU_FIRESTORM", "Runa: Burza Ognia", "Rune: Firestorm", "Rune: Feuersturm", "Руна: Огненная буря"],
		["ITRU_FULLHEAL", "Runa: Pełne Leczenie", "Rune: Full heal", "Rune: Volle Heilung", "Руна: Полное лечение"],
		["ITRU_HARMUNDEAD", "Runa: Rażenie Nieumarłych", "Rune: Harm undead", "Rune: Untote schaden", "Руна: Поражение нежити"],
		["ITRU_ICEBOLT", "Runa: Pocisk Lodu", "Rune: Icebolt", "Rune: Eisblitz", "Руна: Ледяной снаряд"],
		["ITRU_ICECUBE", "Runa: Sześcian Lodu", "Rune: Ice cube", "Rune: Eiswürfel", "Руна: Ледяной куб"],
		["ITRU_ICEWAVE", "Runa: Fala Lodu", "Rune: Ice wave", "Rune: Eiswelle", "Руна: Ледяная волна"],
		["ITRU_INSTANTFIREBALL", "Runa: Kula Ognia", "Rune: Fireball", "Rune: Feuerball", "Руна: Огненный шар"],
		["ITRU_LIGHT", "Runa: Światło", "Rune: Light", "Rune: Licht", "Руна: Свет"],
		["ITRU_LIGHTHEAL", "Runa: Małe Leczenie", "Rune: Minor heal", "Rune: Kleine Heilung", "Руна: Малое лечение"],
		["ITRU_LIGHTNINGFLASH", "Runa: Błyskawica", "Rune: Lightning", "Rune: Blitz", "Руна: Молния"],
		["ITRU_MASSDEATH", "Runa: Masowa Śmierć", "Rune: Mass death", "Rune: Massentod", "Руна: Массовая смерть"],
		["ITRU_MASTEROFDISASTER", "Runa: Mistrz Zniszczenia", "Rune: Master of disaster", "Rune: Meister des Unheils", "Руна: Мастер разрушения"],
		["ITRU_MEDIUMHEAL", "Runa: Leczenie", "Rune: Heal", "Rune: Heilung", "Руна: Лечение"],
		["ITRU_PALDESTROYEVIL", "Runa: Niszcz Zło", "Rune: Destroy evil", "Rune: Böses vernichten", "Руна: Уничтожение зла"],
		["ITRU_PALFULLHEAL", "Runa: Pełne Leczenie Paladyna", "Rune: Paladin full heal", "Rune: Volle Paladinheilung", "Руна: Полное лечение паладина"],
		["ITRU_PALHOLYBOLT", "Runa: Święty Pocisk", "Rune: Holy bolt", "Rune: Heiliger Blitz", "Руна: Святой снаряд"],
		["ITRU_PALLIGHT", "Runa: Światło Paladyna", "Rune: Paladin light", "Rune: Paladinlicht", "Руна: Свет паладина"],
		["ITRU_PALLIGHTHEAL", "Runa: Małe Leczenie Paladyna", "Rune: Paladin minor heal", "Rune: Kleine Paladinheilung", "Руна: Малое лечение паладина"],
		["ITRU_PALMEDIUMHEAL", "Runa: Średnie Leczenie Paladyna", "Rune: Paladin medium heal", "Rune: Mittlere Paladinheilung", "Руна: Среднее лечение паладина"],
		["ITRU_PALREPELEVIL", "Runa: Odpędzenie Zła", "Rune: Repel evil", "Rune: Böses abwehren", "Руна: Изгнание зла"],
		["ITRU_PALTELEPORTSECRET", "Runa: Teleport Paladyna", "Rune: Paladin teleport", "Rune: Paladinteleport", "Руна: Телепорт паладина"],
		["ITRU_PYROKINESIS", "Runa: Pirokineza", "Rune: Pyrokinesis", "Rune: Pyrokinese", "Руна: Пирокинез"],
		["ITRU_SHRINK", "Runa: Pomniejszenie", "Rune: Shrink", "Rune: Schrumpfen", "Руна: Уменьшение"],
		["ITRU_SLEEP", "Runa: Sen", "Rune: Sleep", "Rune: Schlaf", "Руна: Сон"],
		["ITRU_SUMDEMON", "Runa: Przywołaj Demona", "Rune: Summon demon", "Rune: Dämon beschwören", "Руна: Призвать демона"],
		["ITRU_SUMGOBSKEL", "Runa: Szkielet Goblina", "Rune: Goblin skeleton", "Rune: Goblinskelett", "Руна: Скелет гоблина"],
		["ITRU_SUMGOL", "Runa: Przywołaj Golema", "Rune: Summon golem", "Rune: Golem beschwören", "Руна: Призвать голема"],
		["ITRU_SUMSKEL", "Runa: Przywołaj Szkielet", "Rune: Summon skeleton", "Rune: Skelett beschwören", "Руна: Призвать скелета"],
		["ITRU_SUMWOLF", "Runa: Przywołaj Wilka", "Rune: Summon wolf", "Rune: Wolf beschwören", "Руна: Призвать волка"],
		["ITRU_TELEPORT_3", "Runa: Teleport dodatkowy", "Rune: Extra teleport", "Rune: Zusätzlicher Teleport", "Руна: Дополнительный телепорт"],
		["ITRU_TELEPORTFARM", "Runa: Teleport Farma", "Rune: Teleport Farm", "Rune: Teleport Farm", "Руна: Телепорт ферма"],
		["ITRU_TELEPORTMONASTERY", "Runa: Teleport Klasztor", "Rune: Teleport Monastery", "Rune: Teleport Kloster", "Руна: Телепорт монастырь"],
		["ITRU_TELEPORTOC", "Runa: Teleport Zamek", "Rune: Teleport Castle", "Rune: Teleport Burg", "Руна: Телепорт замок"],
		["ITRU_TELEPORTOWDEMONTOWER", "Runa: Teleport Wieża Demona", "Rune: Teleport Demon tower", "Rune: Teleport Dämonenturm", "Руна: Телепорт башня демона"],
		["ITRU_TELEPORTPASSNW", "Runa: Teleport Przełęcz NW", "Rune: Teleport NW Pass", "Rune: Teleport NW-Pass", "Руна: Телепорт северный перевал"],
		["ITRU_TELEPORTPASSOW", "Runa: Teleport Przełęcz OW", "Rune: Teleport OW Pass", "Rune: Teleport OW-Pass", "Руна: Телепорт южный перевал"],
		["ITRU_TELEPORTSEAPORT", "Runa: Teleport Port", "Rune: Teleport Seaport", "Rune: Teleport Hafen", "Руна: Телепорт порт"],
		["ITRU_TELEPORTTAVERNE", "Runa: Teleport Karczma", "Rune: Teleport Tavern", "Rune: Teleport Taverne", "Руна: Телепорт таверна"],
		["ITRU_TELEPORTXARDAS", "Runa: Teleport Xardas", "Rune: Teleport Xardas", "Rune: Teleport Xardas", "Руна: Телепорт Ксардас"],
		["ITRU_THUNDERBALL", "Runa: Kula Błyskawic", "Rune: Thunderball", "Rune: Donnerball", "Руна: Шаровая молния"],
		["ITRU_WINDFIST", "Runa: Pięść Wiatru", "Rune: Windfist", "Rune: Windfaust", "Руна: Кулак ветра"],
		["ITRU_ZAP", "Runa: Iskra", "Rune: Zap", "Rune: Funke", "Руна: Искра"]
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
