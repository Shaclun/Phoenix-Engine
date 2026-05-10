(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [
		["ITAR_BARKEEPER", "Strój karczmarza", "Innkeeper's outfit", "Wirtskleidung", "Одежда трактирщика"],
		["ITAR_BAU_L", "Lekkie ubranie chłopskie", "Light peasant clothes", "Leichte Bauernkleidung", "Лёгкая крестьянская одежда"],
		["ITAR_BAU_M", "Ubranie chłopskie", "Peasant clothes", "Bauernkleidung", "Крестьянская одежда"],
		["ITAR_BAUBABE_L", "Lekka suknia chłopska", "Light peasant dress", "Leichtes Bauernkleid", "Лёгкое крестьянское платье"],
		["ITAR_BAUBABE_M", "Suknia chłopska", "Peasant dress", "Bauernkleid", "Крестьянское платье"],
		["ITAR_BDT_H", "Ciężka zbroja bandyty", "Heavy bandit armor", "Schwere Banditenrüstung", "Тяжёлый доспех бандита"],
		["ITAR_BDT_M", "Zbroja bandyty", "Bandit armor", "Banditenrüstung", "Доспех бандита"],
		["ITAR_BLOODWYN_ADDON", "Zbroja Bloodwyna", "Bloodwyn's armor", "Bloodwyns Rüstung", "Доспех Бладвина"],
		["ITAR_CORANGAR", "Szata Cor Angara", "Cor Angar's robe", "Cor Angars Robe", "Одеяние Кор Ангара"],
		["ITAR_DEMENTOR", "Szata Poszukiwacza", "Seeker's robe", "Suchendenrobe", "Одеяние Искателя"],
		["ITAR_DIEGO", "Strój Diego", "Diego's outfit", "Diegos Kleidung", "Одежда Диего"],
		["ITAR_DJG_BABE", "Strój łowczyni smoków", "Dragon huntress outfit", "Drachenjägerinnenkleidung", "Одежда охотницы на драконов"],
		["ITAR_DJG_CRAWLER", "Pancerz z płytek pełzaczy", "Crawler plate armor", "Crawlerplattenrüstung", "Доспех из пластин ползунов"],
		["ITAR_DJG_H", "Ciężka zbroja łowcy smoków", "Heavy dragon hunter armor", "Schwere Drachenjägerrüstung", "Тяжёлый доспех охотника на драконов"],
		["ITAR_DJG_L", "Lekka zbroja łowcy smoków", "Light dragon hunter armor", "Leichte Drachenjägerrüstung", "Лёгкий доспех охотника на драконов"],
		["ITAR_DJG_M", "Średnia zbroja łowcy smoków", "Medium dragon hunter armor", "Mittlere Drachenjägerrüstung", "Средний доспех охотника на драконов"],
		["ITAR_FAKE_RANGER", "Zniszczona zbroja", "Damaged armor", "Beschädigte Rüstung", "Повреждённый доспех"],
		["ITAR_FIREARMOR_ADDON", "Magiczna zbroja", "Magic armor", "Magische Rüstung", "Магический доспех"],
		["ITAR_GOVERNOR", "Szata gubernatora", "Governor's robe", "Gouverneursrobe", "Одеяние губернатора"],
		["ITAR_JUDGE", "Szata sędziego", "Judge's robe", "Richterrobe", "Одеяние судьи"],
		["ITAR_KDF_H", "Ciężka szata maga ognia", "Heavy fire mage robe", "Schwere Feuermagierrobe", "Тяжёлое одеяние мага огня"],
		["ITAR_KDF_L", "Lekka szata maga ognia", "Light fire mage robe", "Leichte Feuermagierrobe", "Лёгкое одеяние мага огня"],
		["ITAR_KDW_H", "Szata maga wody", "Water mage robe", "Wassermagierrobe", "Одеяние мага воды"],
		["ITAR_KDW_L_ADDON", "Lekka toga maga wody", "Light water mage toga", "Leichte Wassermagiertoga", "Лёгкая тога мага воды"],
		["ITAR_LEATHER_L", "Skórzana zbroja", "Leather armor", "Lederrüstung", "Кожаный доспех"],
		["ITAR_LESTER", "Szata Lestera", "Lester's robe", "Lesters Robe", "Одеяние Лестера"],
		["ITAR_MAYAZOMBIE_ADDON", "Stara zbroja", "Old armor", "Alte Rüstung", "Старый доспех"],
		["ITAR_MIL_L", "Lekka zbroja straży miejskiej", "Light militia armor", "Leichte Milizrüstung", "Лёгкий доспех городской стражи"],
		["ITAR_MIL_M", "Zbroja straży miejskiej", "Militia armor", "Milizrüstung", "Доспех городской стражи"],
		["ITAR_NOV_L", "Szata nowicjusza", "Novice robe", "Novizenrobe", "Одеяние послушника"],
		["ITAR_OREBARON_ADDON", "Zbroja magnata", "Ore baron armor", "Erzbaronenrüstung", "Доспех рудного барона"],
		["ITAR_PAL_H", "Ciężka zbroja paladyna", "Heavy paladin armor", "Schwere Paladinrüstung", "Тяжёлый доспех паладина"],
		["ITAR_PAL_M", "Zbroja paladyna", "Paladin armor", "Paladinrüstung", "Доспех паладина"],
		["ITAR_PAL_SKEL", "Zbroja szkieletu paladyna", "Skeleton paladin armor", "Skelett-Paladinrüstung", "Доспех паладина-скелета"],
		["ITAR_PIR_H_ADDON", "Ubranie kapitana", "Captain's clothes", "Kapitänskleidung", "Одежда капитана"],
		["ITAR_PIR_L_ADDON", "Pirackie ubranie", "Pirate clothes", "Piratenkleidung", "Пиратская одежда"],
		["ITAR_PIR_M_ADDON", "Piracka zbroja", "Pirate armor", "Piratenrüstung", "Пиратский доспех"],
		["ITAR_PRISONER", "Łachmany więźnia", "Prisoner's rags", "Gefangenenfetzen", "Лохмотья заключённого"],
		["ITAR_RANGER_ADDON", "Zbroja Wodnego Kręgu", "Water Ring armor", "Rüstung des Wasserrings", "Доспех Круга Воды"],
		["ITAR_RAVEN_ADDON", "Zbroja Kruka", "Raven's armor", "Ravens Rüstung", "Доспех Ворона"],
		["ITAR_SLD_H", "Ciężka zbroja najemnika", "Heavy mercenary armor", "Schwere Söldnerrüstung", "Тяжёлый доспех наёмника"],
		["ITAR_SLD_L", "Lekka zbroja najemnika", "Light mercenary armor", "Leichte Söldnerrüstung", "Лёгкий доспех наёмника"],
		["ITAR_SLD_M", "Średnia zbroja najemnika", "Medium mercenary armor", "Mittlere Söldnerrüstung", "Средний доспех наёмника"],
		["ITAR_SMITH", "Fartuch kowala", "Smith's apron", "Schmiedeschürze", "Фартук кузнеца"],
		["ITAR_THORUS_ADDON", "Zbroja strażnika Kruka", "Raven guard armor", "Rüstung der Ravenwache", "Доспех стражника Ворона"],
		["ITAR_VLK_H", "Bogata szata mieszczańska", "Rich citizen robe", "Reiche Bürgerrobe", "Богатое одеяние горожанина"],
		["ITAR_VLK_L", "Lekkie ubranie mieszczańskie", "Light citizen clothes", "Leichte Bürgerkleidung", "Лёгкая одежда горожанина"],
		["ITAR_VLK_M", "Ubranie mieszczańskie", "Citizen clothes", "Bürgerkleidung", "Одежда горожанина"],
		["ITAR_XARDAS", "Szata Xardasa", "Xardas's robe", "Xardas' Robe", "Одеяние Ксардаса"]
	];

	const names = {};
	LANGS.forEach(function (lang) { names[lang] = {}; });
	ROWS.forEach(function (row) {
		const instance = row[0];
		LANGS.forEach(function (lang, index) {
			names[lang][instance] = row[index + 1];
		});
	});

	const previous = window.PhoenixI18n.tItem;
	window.PhoenixArmorNameI18n = names;
	window.PhoenixI18n.tItem = function (instance, suffix, fallback) {
		if (suffix !== "name" || !instance) {
			return typeof previous === "function" ? previous(instance, suffix, fallback) : (fallback || "");
		}
		const lang = window.PhoenixI18n.getLang ? window.PhoenixI18n.getLang() : "pl";
		const key = String(instance).toUpperCase();
		const dict = names[lang] || names.pl;
		if (dict && key in dict) return dict[key];
		if (lang !== "pl" && names.pl && key in names.pl) return names.pl[key];
		return typeof previous === "function" ? previous(instance, suffix, fallback) : (fallback || "");
	};
})();