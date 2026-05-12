(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITAR_BARKEEPER", "Strój ziemianina", "Landowner outfit", "Grundbesitzergewand", "Одежда землевладельца"],
		["ITAR_BAU_L", "Strój farmera 1", "Farmer's outfit 1", "Bauernkleidung 1", "Одежда крестьянина 1"],
		["ITAR_BAU_M", "Strój farmera 2", "Farmer's outfit 2", "Bauernkleidung 2", "Одежда крестьянина 2"],
		["ITAR_BAUBABE_L", "Suknia farmerki 1", "Farm woman's dress 1", "Bäuerinnenkleid 1", "Платье крестьянки 1"],
		["ITAR_BAUBABE_M", "Suknia farmerki 2", "Farm woman's dress 2", "Bäuerinnenkleid 2", "Платье крестьянки 2"],
		["ITAR_BDT_H", "Ciężki pancerz bandyty", "Heavy bandit armor", "Schwerer Banditenpanzer", "Тяжёлая броня бандита"],
		["ITAR_BDT_M", "Średni pancerz bandyty", "Medium bandit armor", "Mittlerer Banditenpanzer", "Средняя броня бандита"],
		["ITAR_BLOODWYN_ADDON", "Zbroja Bloodwyna", "Bloodwyn's armor", "Bloodwyns Rüstung", "Броня Бладвина"],
		["ITAR_CORANGAR", "Pancerz Cor Angara", "Cor Angar's armor", "Cor Angars Rüstung", "Броня Кор Ангара"],
		["ITAR_DEMENTOR", "Mroczny płaszcz", "Dark cloak", "Dunkler Mantel", "Тёмный плащ"],
		["ITAR_DIEGO", "Pancerz Diega", "Diego's armor", "Diegos Rüstung", "Доспех Диего"],
		["ITAR_DJG_BABE", "Kobiecy pancerz łowcy smoków", "Female Dragon Hunter armor", "Weibliche Drachenjägerrüstung", "Женская броня охотника на драконов"],
		["ITAR_DJG_CRAWLER", "Zbroja z pancerzy pełzaczy", "Crawler plate armor", "Minecrawlerpanzerung", "Броня из ползунов"],
		["ITAR_DJG_H", "Ciężki pancerz łowcy smoków", "Heavy Dragon Hunter armor", "Schwere Drachenjägerrüstung", "Тяжёлая броня охотника на драконов"],
		["ITAR_DJG_L", "Lekki pancerz łowcy smoków", "Light Dragon Hunter armor", "Leichte Drachenjägerrüstung", "Лёгкая броня охотника на драконов"],
		["ITAR_DJG_M", "Średni pancerz łowcy smoków", "Medium Dragon Hunter armor", "Mittlere Drachenjägerrüstung", "Средняя броня охотника на драконов"],
		["ITAR_FAKE_RANGER", "Zniszczona zbroja", "Worn armor", "Abgenutzte Rüstung", "Изношенная броня"],
		["ITAR_FIREARMOR_ADDON", "Magiczna zbroja", "Magic armor", "Magische Rüstung", "Магическая броня"],
		["ITAR_GOVERNOR", "Kaftan gubernatora", "Governor's coat", "Gouverneursmantel", "Кафтан губернатора"],
		["ITAR_JUDGE", "Szata sędziego", "Judge robe", "Richterrobe", "Одеяние судьи"],
		["ITAR_KDF_H", "Ciężka szata ognia", "Heavy fire robe", "Schwere Feuerrobe", "Тяжёлое одеяние огня"],
		["ITAR_KDF_L", "Szata Maga Ognia", "Fire Mage robe", "Feuermagier-Robe", "Одеяние мага огня"],
		["ITAR_KDW_H", "Szata Maga Wody", "Water Mage robe", "Wassermagier-Robe", "Одеяние мага воды"],
		["ITAR_KDW_L_ADDON", "Lekka toga Maga Wody", "Light Water Mage robe", "Leichte Wassermagier-Robe", "Лёгкое одеяние мага воды"],
		["ITAR_LEATHER_L", "Skórzany pancerz", "Leather armor", "Lederrüstung", "Кожаный доспех"],
		["ITAR_LESTER", "Szata Lestera", "Lester's robe", "Lesters Robe", "Одеяние Лестера"],
		["ITAR_MAYAZOMBIE_ADDON", "Stara zbroja", "Old armor", "Alte Rüstung", "Старая броня"],
		["ITAR_MIL_L", "Lekki pancerz straży", "Light guard armor", "Leichter Wächterpanzer", "Лёгкая броня стражи"],
		["ITAR_MIL_M", "Ciężki pancerz straży", "Heavy guard armor", "Schwerer Wächterpanzer", "Тяжёлая броня стражи"],
		["ITAR_NOV_L", "Habit nowicjusza", "Novice robe", "Novizenrobe", "Одеяние послушника"],
		["ITAR_OREBARON_ADDON", "Zbroja magnata", "Ore Baron armor", "Erzbaronrüstung", "Броня магната руды"],
		["ITAR_PAL_H", "Pancerz paladyna", "Paladin armor", "Paladinrüstung", "Броня паладина"],
		["ITAR_PAL_M", "Pancerz rycerza", "Knight armor", "Ritterrüstung", "Рыцарская броня"],
		["ITAR_PAL_SKEL", "Stara rycerska zbroja", "Old knight armor", "Alte Ritterrüstung", "Старая рыцарская броня"],
		["ITAR_PIR_H_ADDON", "Ubranie kapitana", "Captain clothing", "Kapitänskleidung", "Одежда капитана"],
		["ITAR_PIR_L_ADDON", "Pirackie ubranie", "Pirate clothing", "Piratenkleidung", "Пиратская одежда"],
		["ITAR_PIR_M_ADDON", "Piracka zbroja", "Pirate armor", "Piratenrüstung", "Пиратская броня"],
		["ITAR_PRISONER", "Łachy skazańca", "Prisoner rags", "Gefangenenlumpen", "Лохмотья заключённого"],
		["ITAR_RANGER_ADDON", "Zbroja Wodnego Kręgu", "Water Circle armor", "Wasserkreis-Rüstung", "Броня Круга Воды"],
		["ITAR_RAVEN_ADDON", "Zbroja Kruka", "Raven's armor", "Rabens Rüstung", "Броня Ворона"],
		["ITAR_SLD_H", "Ciężki pancerz najemnika", "Heavy mercenary armor", "Schwerer Söldnerpanzer", "Тяжёлая броня наёмника"],
		["ITAR_SLD_L", "Lekki pancerz najemnika", "Light mercenary armor", "Leichter Söldnerpanzer", "Лёгкая броня наёмника"],
		["ITAR_SLD_M", "Średni pancerz najemnika", "Medium mercenary armor", "Mittlerer Söldnerpanzer", "Средняя броня наёмника"],
		["ITAR_SMITH", "Strój kowala", "Smith outfit", "Schmiedekleidung", "Одежда кузнеца"],
		["ITAR_THORUS_ADDON", "Ciężka zbroja gwardzisty", "Heavy guard armor", "Schwere Wachpanzerung", "Тяжёлая броня гвардейца"],
		["ITAR_VLK_H", "Strój obywatela", "Citizen outfit", "Bürgergewand", "Одежда горожанина"],
		["ITAR_VLK_L", "Strój obywatela", "Citizen outfit", "Bürgergewand", "Одежда горожанина"],
		["ITAR_VLK_M", "Strój obywatela", "Citizen outfit", "Bürgergewand", "Одежда горожанина"],
		["ITAR_XARDAS", "Szata Mrocznej Magii", "Dark Magic robe", "Robe der dunklen Magie", "Одеяние Тёмной магии"]
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
