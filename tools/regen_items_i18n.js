const fs = require("fs");
const path = require("path");

const json = fs.readFileSync("tools/dedalus_items.json", "utf8").replace(/^\uFEFF/, "");
const dedalus = JSON.parse(json);
const dedMap = new Map();
for (const e of dedalus) dedMap.set(e.Instance.toUpperCase(), e);

// Get instances registered in schemes
const schemesDir = "gamemodes/phoenix/modules/item/shared/schemes";
const schemeInstances = new Set();
const schemeNames = new Map();
for (const file of fs.readdirSync(schemesDir)) {
	if (!file.endsWith(".nut")) continue;
	const text = fs.readFileSync(path.join(schemesDir, file), "utf8");
	const re = /phoenix\.item\.register\("([A-Z0-9_]+)"/g;
	let m;
	while ((m = re.exec(text)) !== null) schemeInstances.add(m[1].toUpperCase());
	// also try to extract last "name" string argument
	const re2 = /phoenix\.item\.register\("([A-Z0-9_]+)"[^)]*"([^"]+)"\s*\)\)/g;
	let m2;
	while ((m2 = re2.exec(text)) !== null) schemeNames.set(m2[1].toUpperCase(), m2[2]);
}

// PL -> EN/DE/RU dictionary. Lowercase keys, match full names.
const DICT = {
	// 1H weapons
	"sztylet": { en: "Dagger", de: "Dolch", ru: "Кинжал" },
	"pogrzebacz": { en: "Poker", de: "Schürhaken", ru: "Кочерга" },
	"sierp": { en: "Sickle", de: "Sichel", ru: "Серп" },
	"laska": { en: "Staff", de: "Stock", ru: "Посох" },
	"pałka": { en: "Cudgel", de: "Keule", ru: "Палица" },
	"laga": { en: "Club", de: "Knüppel", ru: "Дубина" },
	"topór": { en: "Axe", de: "Axt", ru: "Топор" },
	"nóż na wilki": { en: "Wolf knife", de: "Wolfsmesser", ru: "Волчий нож" },
	"młot kowalski": { en: "Smith's hammer", de: "Schmiedehammer", ru: "Кузнечный молот" },
	"krótki miecz straży": { en: "Guard's short sword", de: "Kurzschwert der Wache", ru: "Короткий меч стражи" },
	"kiepski krótki miecz": { en: "Poor short sword", de: "Schlechtes Kurzschwert", ru: "Плохой короткий меч" },
	"maczuga z kolcami": { en: "Spiked cudgel", de: "Nagelknüppel", ru: "Палица с шипами" },
	"mała kosa": { en: "Small scythe", de: "Kleine Sense", ru: "Маленькая коса" },
	"miecz alrika": { en: "Alrik's sword", de: "Alriks Schwert", ru: "Меч Альрика" },
	"zardzewiały krótki miecz": { en: "Rusty short sword", de: "Rostiges Kurzschwert", ru: "Ржавый короткий меч" },
	"sługa wiatru": { en: "Servant of the wind", de: "Diener des Windes", ru: "Слуга ветра" },
	"zardzewiały topór": { en: "Rusty axe", de: "Rostige Axt", ru: "Ржавый топор" },
	"kiepski szeroki miecz": { en: "Poor broad sword", de: "Schlechtes Breitschwert", ru: "Плохой широкий меч" },
	"kiepski tasak": { en: "Poor cleaver", de: "Schlechter Hackmesser", ru: "Плохой тесак" },
	"kiepski miecz": { en: "Poor sword", de: "Schlechtes Schwert", ru: "Плохой меч" },
	"krótki miecz": { en: "Short sword", de: "Kurzschwert", ru: "Короткий меч" },
	"pałka z kolcami": { en: "Spiked club", de: "Nagelkeule", ru: "Дубина с шипами" },
	"pałasz bandytów": { en: "Bandit cutlass", de: "Banditen-Pallasch", ru: "Палаш бандитов" },
	"miecz": { en: "Sword", de: "Schwert", ru: "Меч" },
	"wilczy kieł": { en: "Wolf's tooth", de: "Wolfszahn", ru: "Волчий клык" },
	"pika bojowa": { en: "Battle pike", de: "Kampfpike", ru: "Боевая пика" },
	"pałka bojowa": { en: "Battle club", de: "Kampfkeule", ru: "Боевая палица" },
	"dobry krótki miecz": { en: "Good short sword", de: "Gutes Kurzschwert", ru: "Хороший короткий меч" },
	"młot wojenny": { en: "War hammer", de: "Kriegshammer", ru: "Боевой молот" },
	"topór marynarski": { en: "Sailor's axe", de: "Seemannsaxt", ru: "Моряцкий топор" },
	"piracki kordelas": { en: "Pirate cutlass", de: "Piraten-Entermesser", ru: "Пиратская абордажная сабля" },
	"topór pokładowy": { en: "Boarding axe", de: "Enteraxt", ru: "Абордажный топор" },
	"kordelas": { en: "Cutlass", de: "Entermesser", ru: "Абордажная сабля" },
	"miecz paladyna": { en: "Paladin's sword", de: "Paladinschwert", ru: "Меч паладина" },
	"ciężka pałka z kolcami": { en: "Heavy spiked club", de: "Schwere Nagelkeule", ru: "Тяжёлая дубина с шипами" },
	"tasak": { en: "Cleaver", de: "Hackmesser", ru: "Тесак" },
	"kiepski długi miecz": { en: "Poor long sword", de: "Schlechtes Langschwert", ru: "Плохой длинный меч" },
	"długi miecz magiczny": { en: "Magic long sword", de: "Magisches Langschwert", ru: "Магический длинный меч" },
	"dobry miecz": { en: "Good sword", de: "Gutes Schwert", ru: "Хороший меч" },
	"rębiczerep": { en: "Skullsplitter", de: "Schädelspalter", ru: "Черепокол" },
	"oskard": { en: "Pickaxe", de: "Spitzhacke", ru: "Кирка" },
	"długi miecz": { en: "Long sword", de: "Langschwert", ru: "Длинный меч" },
	"kiepski miecz półtoraręczny": { en: "Poor bastard sword", de: "Schlechter Bastardschwert", ru: "Плохой полуторный меч" },
	"topór bojowy": { en: "Battle axe", de: "Streitaxt", ru: "Боевой топор" },
	"podwójny topór": { en: "Double axe", de: "Doppelaxt", ru: "Двойной топор" },
	"morgenstern": { en: "Morning star", de: "Morgenstern", ru: "Моргенштерн" },
	"dobry długi miecz": { en: "Good long sword", de: "Gutes Langschwert", ru: "Хороший длинный меч" },
	"ciężki tasak": { en: "Heavy cleaver", de: "Schwerer Hackmesser", ru: "Тяжёлый тесак" },
	"maczeta": { en: "Machete", de: "Machete", ru: "Мачете" },
	"stara maczeta": { en: "Old machete", de: "Alte Machete", ru: "Старое мачете" },
	"buława": { en: "Mace", de: "Streitkolben", ru: "Булава" },
	"rubinowe ostrze": { en: "Ruby blade", de: "Rubinklinge", ru: "Рубиновый клинок" },
	"miecz ferrosa": { en: "Feros's sword", de: "Feros' Schwert", ru: "Меч Фероса" },
	"magiczny miecz półtoraręczny": { en: "Magic bastard sword", de: "Magischer Bastardschwert", ru: "Магический полуторный меч" },
	"kiepskie ostrze magiczne": { en: "Poor magic blade", de: "Schlechte magische Klinge", ru: "Плохой магический клинок" },
	"rapier": { en: "Rapier", de: "Rapier", ru: "Рапира" },
	"inkwizytor": { en: "Inquisitor", de: "Inquisitor", ru: "Инквизитор" },
	"kruczy dziób": { en: "Raven beak", de: "Rabenschnabel", ru: "Вороний клюв" },
	"dobry miecz półtoraręczny": { en: "Good bastard sword", de: "Guter Bastardschwert", ru: "Хороший полуторный меч" },
	"miecz runiczny": { en: "Rune sword", de: "Runenschwert", ru: "Рунный меч" },
	"wielki młot bojowy": { en: "Great war hammer", de: "Grosser Kriegshammer", ru: "Великий боевой молот" },
	"topór kata": { en: "Torturer's axe", de: "Folteraxt", ru: "Топор палача" },
	"miecz mistrzowski": { en: "Master sword", de: "Meisterschwert", ru: "Мастерский меч" },
	"el bastardo": { en: "El Bastardo", de: "El Bastardo", ru: "Эль Бастардо" },
	"betty": { en: "Betty", de: "Betty", ru: "Бетти" },
	"orkowa zguba": { en: "Orc slayer", de: "Orkschlächter", ru: "Орочья погибель" },
	"krzywy miecz": { en: "Curved sword", de: "Krummschwert", ru: "Кривой меч" },
	"mistrzowski miecz": { en: "Master sword", de: "Meisterschwert", ru: "Мастерский меч" },
	"klinga mistrza": { en: "Master blade", de: "Meisterklinge", ru: "Клинок мастера" },
	"błogosławione ostrze magiczne": { en: "Blessed magic blade", de: "Gesegnete magische Klinge", ru: "Благословенный магический клинок" },
	"święty miecz": { en: "Holy sword", de: "Heiliges Schwert", ru: "Святой меч" },
	"poświęcony miecz": { en: "Consecrated sword", de: "Geweihtes Schwert", ru: "Освящённый меч" },
	"gniew innosa": { en: "Wrath of Innos", de: "Innos' Zorn", ru: "Гнев Инноса" },
	"sztylet francisa": { en: "Francis's dagger", de: "Francis' Dolch", ru: "Кинжал Фрэнсиса" },
	"laska maletha": { en: "Maleth's staff", de: "Maleths Stock", ru: "Посох Малета" },
	"magiczne ostrze bojowe": { en: "Magic battle blade", de: "Magische Kampfklinge", ru: "Магический боевой клинок" },
	"magiczne ostrze na smoki": { en: "Magic dragon blade", de: "Magische Drachenklinge", ru: "Магический драконий клинок" },

	// 2H
	"lekki topór": { en: "Light axe", de: "Leichte Axt", ru: "Лёгкий топор" },
	"topór drwala": { en: "Woodcutter's axe", de: "Holzfälleraxt", ru: "Топор дровосека" },
	"dwuręczny miecz": { en: "Two-handed sword", de: "Zweihandschwert", ru: "Двуручный меч" },
	"kiepski miecz dwuręczny": { en: "Poor two-handed sword", de: "Schlechtes Zweihandschwert", ru: "Плохой двуручный меч" },
	"kiepski topór bojowy": { en: "Poor battle axe", de: "Schlechte Streitaxt", ru: "Плохой боевой топор" },
	"kij": { en: "Rod", de: "Stab", ru: "Жезл" },
	"piracki dwuręczny topór": { en: "Pirate two-handed axe", de: "Piraten-Zweihandaxt", ru: "Пиратский двуручный топор" },
	"piracki dwuręczny miecz": { en: "Pirate two-handed sword", de: "Piraten-Zweihandschwert", ru: "Пиратский двуручный меч" },
	"stalowa dwuręczna maczuga": { en: "Steel two-handed mace", de: "Stahlerne Zweihandkeule", ru: "Стальная двуручная палица" },
	"dwuręczny rąbacz": { en: "Two-handed hacker", de: "Zweihand-Hacker", ru: "Двуручный рубящий меч" },
	"prosty rąbacz": { en: "Simple hacker", de: "Einfacher Hacker", ru: "Простой рубящий меч" },
	"kostur maga ognia": { en: "Fire Mage staff", de: "Stab des Feuermagiers", ru: "Посох мага огня" },
	"magiczna różdżka": { en: "Magic wand", de: "Magischer Stab", ru: "Магический жезл" },
	"kostur maga wody": { en: "Water Mage staff", de: "Stab des Wassermagiers", ru: "Посох мага воды" },
	"zaklęty kostur ulthara": { en: "Ulthar's enchanted staff", de: "Ulthars verzauberter Stab", ru: "Зачарованный посох Ультара" },
	"tajfun": { en: "Typhoon", de: "Taifun", ru: "Тайфун" },
	"kij strażnika": { en: "Ranger's staff", de: "Stab des Waldläufers", ru: "Посох лесника" },
	"halabarda": { en: "Halberd", de: "Hellebarde", ru: "Алебарда" },
	"dwuręczny miecz paladyna": { en: "Paladin two-handed sword", de: "Zweihandschwert des Paladins", ru: "Двуручный меч паладина" },
	"rzadki dwuręczny miecz": { en: "Rare two-handed sword", de: "Seltenes Zweihandschwert", ru: "Редкий двуручный меч" },
	"specjalny dwuręczny miecz": { en: "Special two-handed sword", de: "Besonderes Zweihandschwert", ru: "Особый двуручный меч" },
	"mistrzowski dwuręczny miecz": { en: "Master two-handed sword", de: "Meister-Zweihandschwert", ru: "Мастерский двуручный меч" },
	"legendarny dwuręczny miecz": { en: "Legendary two-handed sword", de: "Legendäres Zweihandschwert", ru: "Легендарный двуручный меч" },
	"barbarzyński topór": { en: "Barbarian battle axe", de: "Barbarenstreitaxt", ru: "Варварский топор" },
	"topór berserkera": { en: "Berserker axe", de: "Berserkeraxt", ru: "Топор берсерка" },
	"smokobójca": { en: "Dragon slayer", de: "Drachenschneide", ru: "Драконорез" },
	"święty dwuręczny miecz": { en: "Holy two-handed sword", de: "Heiliges Zweihandschwert", ru: "Святой двуручный меч" },
	"poświęcony dwuręczny miecz": { en: "Consecrated two-handed sword", de: "Geweihtes Zweihandschwert", ru: "Освящённый двуручный меч" },
	"gniew innosa dwuręczny": { en: "Wrath of Innos (two-handed)", de: "Innos' Zorn (Zweihand)", ru: "Гнев Инноса (двуручный)" },
	"orkowy topór": { en: "Orc axe", de: "Orkaxt", ru: "Орочий топор" },
	"ciężki orkowy topór": { en: "Heavy orc axe", de: "Schwere Orkaxt", ru: "Тяжёлый орочий топор" },
	"dwusieczny orkowy topór": { en: "Double-edged orc axe", de: "Zweischneidige Orkaxt", ru: "Двухлезвийный орочий топор" },
	"wojenny orkowy topór": { en: "Orc war axe", de: "Orkkriegsaxt", ru: "Боевой орочий топор" },
	"orkowy miecz": { en: "Orc sword", de: "Orkschwert", ru: "Орочий меч" },
	"ciężki orkowy miecz": { en: "Heavy orc sword", de: "Schweres Orkschwert", ru: "Тяжёлый орочий меч" },

	// Ranged
	"strzała": { en: "Arrow", de: "Pfeil", ru: "Стрела" },
	"bełt": { en: "Bolt", de: "Bolzen", ru: "Болт" },
	"ognista strzała": { en: "Fire arrow", de: "Feuerpfeil", ru: "Пылающая стрела" },
	"magiczna strzała": { en: "Magic arrow", de: "Magischer Pfeil", ru: "Магическая стрела" },
	"magiczny bełt": { en: "Magic bolt", de: "Magischer Bolzen", ru: "Магический болт" },
	"drewniany łuk": { en: "Wooden bow", de: "Holzbogen", ru: "Деревянный лук" },
	"krótki łuk": { en: "Short bow", de: "Kurzbogen", ru: "Короткий лук" },
	"myśliwski łuk": { en: "Hunting bow", de: "Jagdbogen", ru: "Охотничий лук" },
	"wzmocniony łuk": { en: "Reinforced bow", de: "Verstärkter Bogen", ru: "Усиленный лук" },
	"kompozytowy łuk": { en: "Composite bow", de: "Kompositbogen", ru: "Композитный лук" },
	"myśliwski łuk bojowy": { en: "Hunting battle bow", de: "Jagd-Kampfbogen", ru: "Охотничий боевой лук" },
	"wojenny łuk": { en: "War bow", de: "Kriegsbogen", ru: "Боевой лук" },
	"łuk bojowy": { en: "Battle bow", de: "Kampfbogen", ru: "Боевой лук" },
	"długi łuk": { en: "Long bow", de: "Langbogen", ru: "Длинный лук" },
	"elitarny łuk": { en: "Elite bow", de: "Elitebogen", ru: "Элитный лук" },
	"mistrzowski łuk": { en: "Master bow", de: "Meisterbogen", ru: "Мастерский лук" },
	"legendarny łuk": { en: "Legendary bow", de: "Legendärer Bogen", ru: "Легендарный лук" },
	"łuk najemnika": { en: "Mercenary bow", de: "Söldnerbogen", ru: "Лук наёмника" },
	"ognisty łuk": { en: "Fire bow", de: "Feuerbogen", ru: "Огненный лук" },
	"magiczny łuk": { en: "Magic bow", de: "Magischer Bogen", ru: "Магический лук" },
	"kusza milicji": { en: "Militia crossbow", de: "Milizarmbrust", ru: "Арбалет милиции" },
	"prosta kusza": { en: "Simple crossbow", de: "Einfache Armbrust", ru: "Простой арбалет" },
	"kusza": { en: "Crossbow", de: "Armbrust", ru: "Арбалет" },
	"myśliwska kusza": { en: "Hunting crossbow", de: "Jagdarmbrust", ru: "Охотничий арбалет" },
	"kusza bojowa": { en: "Battle crossbow", de: "Kampfarmbrust", ru: "Боевой арбалет" },
	"wojenna kusza": { en: "War crossbow", de: "Kriegsarmbrust", ru: "Боевой арбалет" },
	"mistrzowska kusza": { en: "Master crossbow", de: "Meisterarmbrust", ru: "Мастерский арбалет" },
	"kusza dragomira": { en: "Dragomir's crossbow", de: "Dragomirs Armbrust", ru: "Арбалет Драгомира" },
	"kusza sengratha": { en: "Sengrath's crossbow", de: "Sengraths Armbrust", ru: "Арбалет Сенграта" },
	"magiczna kusza": { en: "Magic crossbow", de: "Magische Armbrust", ru: "Магический арбалет" },

	// Armor
	"lniana koszula": { en: "Linen shirt", de: "Leinenhemd", ru: "Льняная рубаха" },
	"lniana koszula z fartuchem": { en: "Linen shirt with apron", de: "Leinenhemd mit Schürze", ru: "Льняная рубаха с фартуком" },
	"kobieca lniana koszula": { en: "Woman's linen shirt", de: "Damen-Leinenhemd", ru: "Женская льняная рубаха" },
	"kobieca suknia wieśniaczki": { en: "Peasant dress", de: "Bauernkleid", ru: "Крестьянское платье" },
	"ubranie karczmarza": { en: "Barkeeper outfit", de: "Wirtsgewand", ru: "Наряд трактирщика" },
	"strój więźnia": { en: "Prisoner outfit", de: "Gefangenenkleidung", ru: "Одежда узника" },
	"ubranie mieszczanina": { en: "Citizen clothing", de: "Bürgerkleidung", ru: "Одежда горожанина" },
	"porządne ubranie mieszczanina": { en: "Decent citizen clothing", de: "Anständige Bürgerkleidung", ru: "Приличная одежда горожанина" },
	"bogate ubranie mieszczanina": { en: "Rich citizen clothing", de: "Reiche Bürgerkleidung", ru: "Богатая одежда горожанина" },
	"skórzany fartuch kowala": { en: "Smith's leather apron", de: "Schmiedeschürze", ru: "Кузнечный фартук" },
	"szata lestera": { en: "Lester's robe", de: "Lesters Robe", ru: "Одеяние Лестера" },
	"skórzana zbroja": { en: "Leather armor", de: "Lederrüstung", ru: "Кожаная броня" },
	"zbroja diega": { en: "Diego's armor", de: "Diegos Rüstung", ru: "Броня Диего" },
	"szata nowicjusza": { en: "Novice robe", de: "Novizenrobe", ru: "Одеяние послушника" },
	"szata maga ognia": { en: "Fire Mage robe", de: "Feuermagier-Robe", ru: "Одеяние мага огня" },
	"szata wysokiego maga ognia": { en: "High Fire Mage robe", de: "Hohe Feuermagier-Robe", ru: "Одеяние Верховного мага огня" },
	"szata maga wody": { en: "Water Mage robe", de: "Wassermagier-Robe", ru: "Одеяние мага воды" },
	"szata wysokiego maga wody": { en: "High Water Mage robe", de: "Hohe Wassermagier-Robe", ru: "Одеяние Верховного мага воды" },
	"szata gubernatora": { en: "Governor's robe", de: "Gewand des Gouverneurs", ru: "Одеяние губернатора" },
	"szata sędziego": { en: "Judge's robe", de: "Richterrobe", ru: "Одеяние судьи" },
	"zbroja milicji": { en: "Militia armor", de: "Milizrüstung", ru: "Броня милиции" },
	"pancerz milicji": { en: "Militia plate", de: "Milizpanzer", ru: "Панцирь милиции" },
	"średni pancerz paladyna": { en: "Paladin medium armor", de: "Paladin-Mittelrüstung", ru: "Средний доспех паладина" },
	"ciężki pancerz paladyna": { en: "Heavy paladin armor", de: "Schwere Paladinrüstung", ru: "Тяжёлый доспех паладина" },
	"lekka zbroja najemnika": { en: "Light mercenary armor", de: "Leichte Söldnerrüstung", ru: "Лёгкая броня наёмника" },
	"średnia zbroja najemnika": { en: "Medium mercenary armor", de: "Mittlere Söldnerrüstung", ru: "Средняя броня наёмника" },
	"ciężka zbroja najemnika": { en: "Heavy mercenary armor", de: "Schwere Söldnerrüstung", ru: "Тяжёлая броня наёмника" },
	"lekka zbroja smoczego łowcy": { en: "Light Dragon Hunter armor", de: "Leichte Drachenjägerrüstung", ru: "Лёгкая броня охотника на драконов" },
	"średnia zbroja smoczego łowcy": { en: "Medium Dragon Hunter armor", de: "Mittlere Drachenjägerrüstung", ru: "Средняя броня охотника на драконов" },
	"ciężka zbroja smoczego łowcy": { en: "Heavy Dragon Hunter armor", de: "Schwere Drachenjägerrüstung", ru: "Тяжёлая броня охотника на драконов" },
	"pancerz z pełzacza": { en: "Crawler armor", de: "Minecrawlerrüstung", ru: "Броня из ползунов" },
	"kobieca zbroja smoczego łowcy": { en: "Female Dragon Hunter armor", de: "Weibliche Drachenjägerrüstung", ru: "Женская броня охотника на драконов" },
	"lekka zbroja bandyty": { en: "Light bandit armor", de: "Leichte Banditenrüstung", ru: "Лёгкая броня бандита" },
	"ciężka zbroja bandyty": { en: "Heavy bandit armor", de: "Schwere Banditenrüstung", ru: "Тяжёлая броня бандита" },
	"lekka zbroja pirata": { en: "Light pirate armor", de: "Leichte Piratenrüstung", ru: "Лёгкая броня пирата" },
	"średnia zbroja pirata": { en: "Medium pirate armor", de: "Mittlere Piratenrüstung", ru: "Средняя броня пирата" },
	"ciężka zbroja pirata": { en: "Heavy pirate armor", de: "Schwere Piratenrüstung", ru: "Тяжёлая броня пирата" },
	"zbroja leśnika": { en: "Ranger armor", de: "Waldläuferrüstung", ru: "Броня лесника" },
	"podrabiana zbroja leśnika": { en: "Fake ranger armor", de: "Gefälschte Waldläuferrüstung", ru: "Поддельная броня лесника" },
	"zbroja barona rudy": { en: "Ore Baron armor", de: "Rüstung des Erzbarons", ru: "Броня барона руды" },
	"zbroja thorusa": { en: "Thorus's armor", de: "Thorus' Rüstung", ru: "Броня Торуса" },
	"zbroja bloodwyna": { en: "Bloodwyn's armor", de: "Bloodwyns Rüstung", ru: "Броня Бладвина" },
	"zbroja kruka": { en: "Raven's armor", de: "Rabens Rüstung", ru: "Броня Ворона" },
	"pancerz ognia": { en: "Fire armor", de: "Feuerrüstung", ru: "Огненная броня" },
	"szata strażnika mayi": { en: "Maya guardian robe", de: "Maya-Wächtergewand", ru: "Одеяние стража Майи" },
	"przeklęty pancerz paladyna": { en: "Cursed paladin armor", de: "Verfluchte Paladinrüstung", ru: "Проклятый доспех паладина" },
	"szata dementora": { en: "Dementor robe", de: "Dementorrobe", ru: "Одеяние дементора" },
	"szata corangara": { en: "Cor Angar's robe", de: "Cor Angars Robe", ru: "Одеяние Кор Ангара" },
	"szata xardasa": { en: "Xardas's robe", de: "Xardas' Robe", ru: "Одеяние Ксардаса" },

	// Helmets
	"słomiany kapelusz": { en: "Straw hat", de: "Strohhut", ru: "Соломенная шляпа" },
	"hełm milicji": { en: "Militia helmet", de: "Milizhelm", ru: "Шлем милиции" },
	"hełm paladyna": { en: "Paladin helmet", de: "Paladinhelm", ru: "Шлем паладина" },
	"hełm najemnika": { en: "Mercenary helmet", de: "Söldnerhelm", ru: "Шлем наёмника" },
	"hełm bandyty": { en: "Bandit helmet", de: "Banditenhelm", ru: "Шлем бандита" },
	"bandana pirata": { en: "Pirate bandana", de: "Piratenbandana", ru: "Бандана пирата" },
	"kaptur nowicjusza": { en: "Novice hood", de: "Novizenkapuze", ru: "Капюшон послушника" },
	"kaptur maga ognia": { en: "Fire Mage hood", de: "Feuermagierkapuze", ru: "Капюшон мага огня" },
	"kaptur maga wody": { en: "Water Mage hood", de: "Wassermagierkapuze", ru: "Капюшон мага воды" },

	// Shields
	"drewniany puklerz": { en: "Wooden buckler", de: "Holzbuckler", ru: "Деревянный щит" },
	"drewniana tarcza": { en: "Wooden shield", de: "Holzschild", ru: "Деревянный щит" },
	"żelazna tarcza": { en: "Iron shield", de: "Eisenschild", ru: "Железный щит" },
	"stalowa tarcza": { en: "Steel shield", de: "Stahlschild", ru: "Стальной щит" },
	"tarcza paladyna": { en: "Paladin shield", de: "Paladinschild", ru: "Щит паладина" },

	// Amulets
	"amulet pancerza": { en: "Armor amulet", de: "Panzerungsamulett", ru: "Амулет брони" },
	"amulet dębowej skóry": { en: "Oak skin amulet", de: "Eichenhautamulett", ru: "Амулет дубовой кожи" },
	"amulet ognia": { en: "Fire amulet", de: "Feueramulett", ru: "Амулет огня" },
	"amulet duchowej siły": { en: "Spirit strength amulet", de: "Geisteskraftamulett", ru: "Амулет духовной силы" },
	"amulet żywiołów": { en: "Elemental amulet", de: "Elementaramulett", ru: "Амулет стихий" },
	"amulet zręczności": { en: "Amulet of dexterity", de: "Amulett der Geschicklichkeit", ru: "Амулет ловкости" },
	"amulet siły": { en: "Amulet of strength", de: "Amulett der Kraft", ru: "Амулет силы" },
	"amulet koncentracji": { en: "Amulet of concentration", de: "Amulett der Konzentration", ru: "Амулет концентрации" },
	"amulet zdrowia": { en: "Amulet of health", de: "Amulett der Gesundheit", ru: "Амулет здоровья" },
	"amulet życia i many": { en: "Amulet of life and mana", de: "Amulett des Lebens und der Mana", ru: "Амулет жизни и маны" },
	"amulet mocy": { en: "Amulet of power", de: "Amulett der Macht", ru: "Амулет мощи" },
	"modlitewnik kruka": { en: "Raven's prayer book", de: "Rabens Gebetbuch", ru: "Молитвенник Ворона" },

	// Rings
	"pierścień pancerza": { en: "Ring of armor", de: "Panzerungsring", ru: "Кольцо брони" },
	"pierścień pancerza ii": { en: "Ring of armor II", de: "Panzerungsring II", ru: "Кольцо брони II" },
	"pierścień ochrony": { en: "Ring of protection", de: "Schutzring", ru: "Кольцо защиты" },
	"pierścień ochrony ii": { en: "Ring of protection II", de: "Schutzring II", ru: "Кольцо защиты II" },
	"pierścień ognia": { en: "Ring of fire", de: "Feuerring", ru: "Кольцо огня" },
	"pierścień ognia ii": { en: "Ring of fire II", de: "Feuerring II", ru: "Кольцо огня II" },
	"pierścień magii": { en: "Ring of magic", de: "Magiering", ru: "Кольцо магии" },
	"pierścień magii ii": { en: "Ring of magic II", de: "Magiering II", ru: "Кольцо магии II" },
	"pierścień żywiołów": { en: "Ring of elements", de: "Elementarring", ru: "Кольцо стихий" },
	"pierścień żywiołów ii": { en: "Ring of elements II", de: "Elementarring II", ru: "Кольцо стихий II" },
	"pierścień zręczności": { en: "Ring of dexterity", de: "Geschicklichkeitsring", ru: "Кольцо ловкости" },
	"pierścień zręczności ii": { en: "Ring of dexterity II", de: "Geschicklichkeitsring II", ru: "Кольцо ловкости II" },
	"pierścień siły": { en: "Ring of strength", de: "Kraftring", ru: "Кольцо силы" },
	"pierścień siły ii": { en: "Ring of strength II", de: "Kraftring II", ru: "Кольцо силы II" },
	"pierścień many": { en: "Ring of mana", de: "Manaring", ru: "Кольцо маны" },
	"pierścień many ii": { en: "Ring of mana II", de: "Manaring II", ru: "Кольцо маны II" },
	"pierścień zdrowia": { en: "Ring of health", de: "Gesundheitsring", ru: "Кольцо здоровья" },
	"pierścień zdrowia ii": { en: "Ring of health II", de: "Gesundheitsring II", ru: "Кольцо здоровья II" },
	"pierścień życia i many": { en: "Ring of life and mana", de: "Ring des Lebens und der Mana", ru: "Кольцо жизни и маны" },
	"pierścień mocy": { en: "Ring of power", de: "Machtring", ru: "Кольцо мощи" },

	// Belts
	"skórzany pas": { en: "Leather belt", de: "Ledergürtel", ru: "Кожаный пояс" },
	"wzmocniony pas": { en: "Reinforced belt", de: "Verstärkter Gürtel", ru: "Усиленный пояс" },
	"pas strażnika": { en: "Guard belt", de: "Wächtergürtel", ru: "Пояс стража" },
	"pas paladyna": { en: "Paladin belt", de: "Paladingürtel", ru: "Пояс паладина" },
	"pas milicji": { en: "Militia belt", de: "Milizgürtel", ru: "Пояс милиции" },
	"pas najemnika": { en: "Mercenary belt", de: "Söldnergürtel", ru: "Пояс наёмника" },
	"pas bandyty": { en: "Bandit belt", de: "Banditengürtel", ru: "Пояс бандита" },
	"pas pirata": { en: "Pirate belt", de: "Piratengürtel", ru: "Пояс пирата" },
	"pas zręczności": { en: "Belt of dexterity", de: "Gürtel der Geschicklichkeit", ru: "Пояс ловкости" },
	"pas siły": { en: "Belt of strength", de: "Gürtel der Kraft", ru: "Пояс силы" },
	"pas many": { en: "Belt of mana", de: "Gürtel der Mana", ru: "Пояс маны" },
	"pas zdrowia": { en: "Belt of health", de: "Gürtel der Gesundheit", ru: "Пояс здоровья" },

	// Potions
	"esencja lecznicza": { en: "Healing essence", de: "Heilessenz", ru: "Лечебная эссенция" },
	"ekstrakt leczniczy": { en: "Healing extract", de: "Heilextrakt", ru: "Лечебный экстракт" },
	"eliksir leczniczy": { en: "Healing elixir", de: "Heilelixier", ru: "Лечебный эликсир" },
	"eliksir życia": { en: "Elixir of life", de: "Lebenselixier", ru: "Эликсир жизни" },
	"esencja many": { en: "Mana essence", de: "Manaessenz", ru: "Эссенция маны" },
	"esencja many+": { en: "Permanent mana essence", de: "Dauerhafte Manaessenz", ru: "Постоянная эссенция маны" },
	"ekstrakt many": { en: "Mana extract", de: "Manaextrakt", ru: "Экстракт маны" },
	"eliksir many": { en: "Mana elixir", de: "Manaelixier", ru: "Эликсир маны" },
	"eliksir esencji": { en: "Essence elixir", de: "Essenzelixier", ru: "Эликсир эссенции" },
	"esencja życia": { en: "Essence of life", de: "Lebensessenz", ru: "Эссенция жизни" },
	"mała esencja many": { en: "Small mana essence", de: "Kleine Manaessenz", ru: "Малая эссенция маны" },
	"esencja siły": { en: "Essence of strength", de: "Kraftessenz", ru: "Эссенция силы" },
	"esencja zręczności": { en: "Essence of dexterity", de: "Geschicklichkeitsessenz", ru: "Эссенция ловкости" },
	"mikstura szybkości": { en: "Speed potion", de: "Geschwindigkeitstrank", ru: "Зелье скорости" },
	"megadrink": { en: "Mega drink", de: "Mega-Drink", ru: "Мегадринк" },
	"leczniczy napój": { en: "Healing draught", de: "Heiltrunk", ru: "Лечебный напиток" },
	"napój many": { en: "Mana draught", de: "Manatrunk", ru: "Напиток маны" },
	"mikstura": { en: "Potion", de: "Trank", ru: "Зелье" },

	// Food
	"jabłko": { en: "Apple", de: "Apfel", ru: "Яблоко" },
	"bekon": { en: "Bacon", de: "Speck", ru: "Бекон" },
	"piwo": { en: "Beer", de: "Bier", ru: "Пиво" },
	"gorzała": { en: "Booze", de: "Schnaps", ru: "Самогон" },
	"chleb": { en: "Bread", de: "Brot", ru: "Хлеб" },
	"ser": { en: "Cheese", de: "Käse", ru: "Сыр" },
	"ryba": { en: "Fish", de: "Fisch", ru: "Рыба" },
	"zupa rybna": { en: "Fish soup", de: "Fischsuppe", ru: "Рыбный суп" },
	"miód": { en: "Honey", de: "Honig", ru: "Мёд" },
	"mleko": { en: "Milk", de: "Milch", ru: "Молоко" },
	"baranina pieczona": { en: "Roasted mutton", de: "Gebratenes Hammelfleisch", ru: "Жареная баранина" },
	"baranina surowa": { en: "Raw mutton", de: "Rohes Hammelfleisch", ru: "Сырая баранина" },
	"kiełbasa": { en: "Sausage", de: "Wurst", ru: "Колбаса" },
	"gulasz": { en: "Stew", de: "Eintopf", ru: "Рагу" },
	"woda": { en: "Water", de: "Wasser", ru: "Вода" },
	"wino": { en: "Wine", de: "Wein", ru: "Вино" },
	"jajko": { en: "Egg", de: "Ei", ru: "Яйцо" },
	"rum": { en: "Rum", de: "Rum", ru: "Ром" },
	"grog": { en: "Grog", de: "Grog", ru: "Грог" },
	"ognisty gulasz": { en: "Fiery stew", de: "Feuriger Eintopf", ru: "Огненное рагу" },
	"zupa mięsna": { en: "Meat soup", de: "Fleischsuppe", ru: "Мясной суп" },
	"mięso muszli": { en: "Shell flesh", de: "Muschelfleisch", ru: "Мясо раковины" },

	// Herbs
	"chwast": { en: "Weed", de: "Unkraut", ru: "Сорняк" },
	"burak": { en: "Beet", de: "Rübe", ru: "Свёкла" },
	"bagienne ziele": { en: "Swamp herb", de: "Sumpfkraut", ru: "Болотная трава" },
	"magiczne ziele": { en: "Magic herb", de: "Magisches Kraut", ru: "Магическая трава" },
	"eteryczne ziele": { en: "Ethereal herb", de: "Ätherkraut", ru: "Эфирная трава" },
	"boskie ziele many": { en: "Divine mana herb", de: "Göttliches Manakraut", ru: "Божественная трава маны" },
	"krwawnik": { en: "Yarrow", de: "Schafgarbe", ru: "Тысячелистник" },
	"pole leczące": { en: "Healing field", de: "Heilfeld", ru: "Лечебное поле" },
	"królewski korzeń": { en: "King's root", de: "Königswurz", ru: "Королевский корень" },
	"zręczność leśna": { en: "Forest dexterity herb", de: "Waldgeschick", ru: "Лесная ловкость" },
	"siłak": { en: "Strength herb", de: "Kraftkraut", ru: "Силач" },
	"wiatrówka": { en: "Wind grass", de: "Windgras", ru: "Ветродуй" },
	"czerwony grzyb": { en: "Red mushroom", de: "Roter Pilz", ru: "Красный гриб" },
	"ciemny grzyb": { en: "Dark mushroom", de: "Dunkler Pilz", ru: "Тёмный гриб" },
	"niebieskie ziele": { en: "Blue plant", de: "Blaue Pflanze", ru: "Синее растение" },
	"leśne jagody": { en: "Forest berries", de: "Waldbeeren", ru: "Лесные ягоды" },
	"polne jagody": { en: "Plain berries", de: "Feldbeeren", ru: "Полевые ягоды" },
	"ziele temperancji": { en: "Tempering herb", de: "Mäßigungskraut", ru: "Трава умеренности" },
	"boskie ziele": { en: "Divine herb", de: "Göttliches Kraut", ru: "Божественная трава" },
	"zioło sagitty": { en: "Sagitta's herb", de: "Sagittas Kraut", ru: "Трава Сагитты" },

	// Keys
	"wytrych": { en: "Lockpick", de: "Dietrich", ru: "Отмычка" },
	"mosiężny klucz": { en: "Brass key", de: "Messingschlüssel", ru: "Латунный ключ" },
	"żelazny klucz": { en: "Iron key", de: "Eisenschlüssel", ru: "Железный ключ" },
	"stary klucz": { en: "Old key", de: "Alter Schlüssel", ru: "Старый ключ" },
	"klucz miejski": { en: "City key", de: "Stadtschlüssel", ru: "Городской ключ" },
	"klucz klasztorny": { en: "Monastery key", de: "Klosterschlüssel", ru: "Ключ от монастыря" },
	"klucz zamkowy": { en: "Castle key", de: "Burgschlüssel", ru: "Замковый ключ" },

	// Documents (maps/books/recipes)
	"mapa: khorinis": { en: "Map: Khorinis", de: "Karte: Khorinis", ru: "Карта: Хоринис" },
	"mapa: miasto khorinis": { en: "Map: Khorinis city", de: "Karte: Khorinis-Stadt", ru: "Карта: город Хоринис" },
	"mapa: górnicza dolina": { en: "Map: Mining Valley", de: "Karte: Minental", ru: "Карта: Горная долина" },
	"mapa: jharkendar": { en: "Map: Jharkendar", de: "Karte: Jharkendar", ru: "Карта: Джаркендар" },
	"księga walki jednoręcznej": { en: "One-handed combat book", de: "Buch der Einhandwaffen", ru: "Книга одноручного боя" },
	"księga walki dwuręcznej": { en: "Two-handed combat book", de: "Buch der Zweihandwaffen", ru: "Книга двуручного боя" },
	"księga łucznictwa": { en: "Archery book", de: "Buch der Bogenkunst", ru: "Книга лучного боя" },
	"księga kuszy": { en: "Crossbow book", de: "Buch der Armbrust", ru: "Книга арбалета" },
	"lista ziół": { en: "Herb list", de: "Kräuterliste", ru: "Список трав" },
	"receptura: mikstura many": { en: "Recipe: mana potion", de: "Rezept: Manatrank", ru: "Рецепт: зелье маны" },
	"receptura: mikstura leczenia": { en: "Recipe: healing potion", de: "Rezept: Heiltrank", ru: "Рецепт: лечебное зелье" },
	"receptura: eliksir siły": { en: "Recipe: strength elixir", de: "Rezept: Kraftelixier", ru: "Рецепт: эликсир силы" },
	"receptura: eliksir zręczności": { en: "Recipe: dexterity elixir", de: "Rezept: Geschicklichkeitselixier", ru: "Рецепт: эликсир ловкости" },
	"receptura: esencja życia": { en: "Recipe: essence of life", de: "Rezept: Lebensessenz", ru: "Рецепт: эссенция жизни" },
	"receptura: esencja many": { en: "Recipe: essence of mana", de: "Rezept: Manaessenz", ru: "Рецепт: эссенция маны" },

	// Materials
	"złoto": { en: "Gold", de: "Gold", ru: "Золото" },
	"bryłka rudy": { en: "Ore nugget", de: "Erzklumpen", ru: "Слиток руды" },
	"bryłka złota": { en: "Gold nugget", de: "Goldklumpen", ru: "Золотой самородок" },
	"węgiel": { en: "Coal", de: "Kohle", ru: "Уголь" },
	"siarka": { en: "Sulfur", de: "Schwefel", ru: "Сера" },
	"kwarc": { en: "Quartz", de: "Quarz", ru: "Кварц" },
	"akwamaryn": { en: "Aquamarine", de: "Aquamarin", ru: "Аквамарин" },
	"kryształ górski": { en: "Rock crystal", de: "Bergkristall", ru: "Горный хрусталь" },
	"czarna perła": { en: "Dark pearl", de: "Dunkle Perle", ru: "Чёрная жемчужина" },
	"pusta runa": { en: "Blank rune", de: "Leere Rune", ru: "Пустая руна" },
	"skóra": { en: "Leather", de: "Leder", ru: "Кожа" },
	"futro": { en: "Fur", de: "Fell", ru: "Мех" },
	"kość": { en: "Bone", de: "Knochen", ru: "Кость" },
	"zęby": { en: "Teeth", de: "Zähne", ru: "Зубы" },
	"pazur": { en: "Claw", de: "Klaue", ru: "Коготь" },
	"żołądek": { en: "Stomach", de: "Magen", ru: "Желудок" },
	"język": { en: "Tongue", de: "Zunge", ru: "Язык" },
	"oko": { en: "Eye", de: "Auge", ru: "Глаз" },
	"serce": { en: "Heart", de: "Herz", ru: "Сердце" },
	"łuska smoka": { en: "Dragon scale", de: "Drachenschuppe", ru: "Чешуя дракона" },
	"krew smoka": { en: "Dragon blood", de: "Drachenblut", ru: "Кровь дракона" },
	"młotek": { en: "Hammer", de: "Hammer", ru: "Молоток" },
	"piła": { en: "Saw", de: "Säge", ru: "Пила" },
	"kleszcze": { en: "Pliers", de: "Zange", ru: "Клещи" },
	"patelnia": { en: "Pan", de: "Pfanne", ru: "Сковорода" },
	"patelnia z jedzeniem": { en: "Pan with food", de: "Pfanne mit Essen", ru: "Сковорода с едой" },
	"miotła": { en: "Broom", de: "Besen", ru: "Метла" },
	"grabie": { en: "Rake", de: "Harke", ru: "Грабли" },
	"łopata": { en: "Scoop", de: "Schaufel", ru: "Лопата" },
	"sekstans": { en: "Sextant", de: "Sextant", ru: "Секстант" },
	"magiczny fokus": { en: "Magic focus", de: "Magischer Fokus", ru: "Магический фокус" },
	"pochodnia": { en: "Torch", de: "Fackel", ru: "Факел" },

	// Runes/Scrolls — generic pattern handled below
};

// Direct per-instance overrides (used when Dedalus lacks the name or we want a custom label).
// Keys are UPPERCASE instance IDs. Each entry provides all four languages.
const OVERRIDE = {
	// 1H specials
	"ITMW_1H_SPECIAL_01":        { pl: "Długi miecz magiczny",       en: "Magic long sword",         de: "Magisches Langschwert",        ru: "Магический длинный меч" },
	"ITMW_1H_SPECIAL_02":        { pl: "Magiczny miecz półtoraręczny", en: "Magic bastard sword",   de: "Magischer Bastardschwert",     ru: "Магический полуторный меч" },
	"ITMW_1H_SPECIAL_03":        { pl: "Magiczne ostrze bojowe",     en: "Magic battle blade",      de: "Magische Kampfklinge",         ru: "Магический боевой клинок" },
	"ITMW_1H_SPECIAL_04":        { pl: "Magiczne ostrze na smoki",   en: "Magic dragon blade",      de: "Magische Drachenklinge",       ru: "Магический драконий клинок" },
	"ITMW_1H_BLESSED_01":        { pl: "Kiepskie ostrze magiczne",   en: "Poor magic blade",        de: "Schlechte magische Klinge",    ru: "Плохой магический клинок" },
	"ITMW_1H_BLESSED_02":        { pl: "Błogosławione ostrze magiczne", en: "Blessed magic blade",  de: "Gesegnete magische Klinge",    ru: "Благословенный магический клинок" },
	"ITMW_1H_BLESSED_03":        { pl: "Gniew Innosa",               en: "Wrath of Innos",          de: "Innos' Zorn",                  ru: "Гнев Инноса" },
	"ITMW_1H_COMMON_01":         { pl: "Miecz",                      en: "Sword",                   de: "Schwert",                      ru: "Меч" },
	"ITMW_1H_FERROSSWORD_MIS":   { pl: "Miecz Ferosa",               en: "Feros's sword",           de: "Feros' Schwert",               ru: "Меч Фероса" },
	"ITMW_ALRIKSSWORD_MIS":      { pl: "Miecz Alrika",               en: "Alrik's sword",           de: "Alriks Schwert",               ru: "Меч Альрика" },
	"ITMW_MALETHSGEHSTOCK_MIS":  { pl: "Laska Maletha",              en: "Maleth's staff",          de: "Maleths Stock",                ru: "Посох Малета" },

	// 2H specials
	"ITMW_2H_ROD":               { pl: "Kij",                        en: "Rod",                     de: "Stab",                         ru: "Жезл" },
	"ITMW_2H_SPECIAL_01":        { pl: "Długi miecz magiczny",       en: "Magic long sword",        de: "Magisches Langschwert",        ru: "Магический длинный меч" },
	"ITMW_2H_SPECIAL_02":        { pl: "Magiczny miecz półtoraręczny", en: "Magic bastard sword",   de: "Magischer Bastardschwert",     ru: "Магический полуторный меч" },
	"ITMW_2H_SPECIAL_03":        { pl: "Magiczne ostrze bojowe",     en: "Magic battle blade",      de: "Magische Kampfklinge",         ru: "Магический боевой клинок" },
	"ITMW_2H_SPECIAL_04":        { pl: "Magiczne ostrze na smoki",   en: "Magic dragon blade",      de: "Magische Drachenklinge",       ru: "Магический драконий клинок" },
	"ITMW_2H_BLESSED_01":        { pl: "Kiepskie ostrze magiczne (2H)", en: "Poor magic blade (2H)",de: "Schlechte magische Klinge (2H)",ru: "Плохой магический клинок (2H)" },
	"ITMW_2H_BLESSED_02":        { pl: "Błogosławione ostrze magiczne (2H)", en: "Blessed magic blade (2H)", de: "Gesegnete magische Klinge (2H)", ru: "Благословенный магический клинок (2H)" },
	"ITMW_2H_BLESSED_03":        { pl: "Gniew Innosa (2H)",          en: "Wrath of Innos (2H)",     de: "Innos' Zorn (2H)",             ru: "Гнев Инноса (2H)" },

	// Amulets
	"ITAM_PROT_EDGE_01":         { pl: "Amulet pancerza",            en: "Armor amulet",            de: "Panzerungsamulett",            ru: "Амулет брони" },
	"ITAM_PROT_POINT_01":        { pl: "Amulet dębowej skóry",       en: "Oak skin amulet",         de: "Eichenhautamulett",            ru: "Амулет дубовой кожи" },
	"ITAM_PROT_FIRE_01":         { pl: "Amulet ognia",               en: "Fire amulet",             de: "Feueramulett",                 ru: "Амулет огня" },
	"ITAM_PROT_MAGE_01":         { pl: "Amulet duchowej siły",       en: "Spirit strength amulet",  de: "Geisteskraftamulett",          ru: "Амулет духовной силы" },
	"ITAM_PROT_TOTAL_01":        { pl: "Amulet żywiołów",            en: "Elemental amulet",        de: "Elementaramulett",             ru: "Амулет стихий" },
	"ITAM_DEX_01":               { pl: "Amulet zręczności",          en: "Amulet of dexterity",     de: "Amulett der Geschicklichkeit", ru: "Амулет ловкости" },
	"ITAM_STRG_01":              { pl: "Amulet siły",                en: "Amulet of strength",      de: "Amulett der Kraft",            ru: "Амулет силы" },
	"ITAM_MANA_01":              { pl: "Amulet koncentracji",        en: "Amulet of concentration", de: "Amulett der Konzentration",    ru: "Амулет концентрации" },
	"ITAM_HP_01":                { pl: "Amulet zdrowia",             en: "Amulet of health",        de: "Amulett der Gesundheit",       ru: "Амулет здоровья" },
	"ITAM_HP_MANA_01":           { pl: "Amulet życia i many",        en: "Amulet of life and mana", de: "Amulett des Lebens und der Mana", ru: "Амулет жизни и маны" },
	"ITAM_DEX_STRG_01":          { pl: "Amulet mocy",                en: "Amulet of power",         de: "Amulett der Macht",            ru: "Амулет мощи" },
	"ITAM_ADDON_RAVENSGEBETBUCH":{ pl: "Modlitewnik Kruka",          en: "Raven's prayer book",     de: "Rabens Gebetbuch",             ru: "Молитвенник Ворона" },

	// Rings
	"ITRI_PROT_EDGE_01":         { pl: "Pierścień pancerza",         en: "Ring of armor",           de: "Panzerungsring",               ru: "Кольцо брони" },
	"ITRI_PROT_EDGE_02":         { pl: "Pierścień pancerza II",      en: "Ring of armor II",        de: "Panzerungsring II",            ru: "Кольцо брони II" },
	"ITRI_PROT_POINT_01":        { pl: "Pierścień ochrony",          en: "Ring of protection",      de: "Schutzring",                   ru: "Кольцо защиты" },
	"ITRI_PROT_POINT_02":        { pl: "Pierścień ochrony II",       en: "Ring of protection II",   de: "Schutzring II",                ru: "Кольцо защиты II" },
	"ITRI_PROT_FIRE_01":         { pl: "Pierścień ognia",            en: "Ring of fire",            de: "Feuerring",                    ru: "Кольцо огня" },
	"ITRI_PROT_FIRE_02":         { pl: "Pierścień ognia II",         en: "Ring of fire II",         de: "Feuerring II",                 ru: "Кольцо огня II" },
	"ITRI_PROT_MAGE_01":         { pl: "Pierścień magii",            en: "Ring of magic",           de: "Magiering",                    ru: "Кольцо магии" },
	"ITRI_PROT_MAGE_02":         { pl: "Pierścień magii II",         en: "Ring of magic II",        de: "Magiering II",                 ru: "Кольцо магии II" },
	"ITRI_PROT_TOTAL_01":        { pl: "Pierścień żywiołów",         en: "Ring of elements",        de: "Elementarring",                ru: "Кольцо стихий" },
	"ITRI_PROT_TOTAL_02":        { pl: "Pierścień żywiołów II",      en: "Ring of elements II",     de: "Elementarring II",             ru: "Кольцо стихий II" },
	"ITRI_DEX_01":               { pl: "Pierścień zręczności",       en: "Ring of dexterity",       de: "Geschicklichkeitsring",        ru: "Кольцо ловкости" },
	"ITRI_DEX_02":               { pl: "Pierścień zręczności II",    en: "Ring of dexterity II",    de: "Geschicklichkeitsring II",     ru: "Кольцо ловкости II" },
	"ITRI_STRG_01":              { pl: "Pierścień siły",             en: "Ring of strength",        de: "Kraftring",                    ru: "Кольцо силы" },
	"ITRI_STRG_02":              { pl: "Pierścień siły II",          en: "Ring of strength II",     de: "Kraftring II",                 ru: "Кольцо силы II" },
	"ITRI_MANA_01":              { pl: "Pierścień many",             en: "Ring of mana",            de: "Manaring",                     ru: "Кольцо маны" },
	"ITRI_MANA_02":              { pl: "Pierścień many II",          en: "Ring of mana II",         de: "Manaring II",                  ru: "Кольцо маны II" },
	"ITRI_HP_01":                { pl: "Pierścień zdrowia",          en: "Ring of health",          de: "Gesundheitsring",              ru: "Кольцо здоровья" },
	"ITRI_HP_02":                { pl: "Pierścień zdrowia II",       en: "Ring of health II",       de: "Gesundheitsring II",           ru: "Кольцо здоровья II" },
	"ITRI_HP_MANA_01":           { pl: "Pierścień życia i many",     en: "Ring of life and mana",   de: "Ring des Lebens und der Mana", ru: "Кольцо жизни и маны" },
	"ITRI_DEX_STRG_01":          { pl: "Pierścień mocy",             en: "Ring of power",           de: "Machtring",                    ru: "Кольцо мощи" },

	// Belts
	"ITBE_ADDON_LEATHER_01":     { pl: "Skórzany pas",               en: "Leather belt",            de: "Ledergürtel",                  ru: "Кожаный пояс" },
	"ITBE_ADDON_LEATHER_02":     { pl: "Wzmocniony pas",             en: "Reinforced belt",         de: "Verstärkter Gürtel",           ru: "Усиленный пояс" },
	"ITBE_ADDON_STT_01":         { pl: "Pas strażnika",              en: "Guard belt",              de: "Wächtergürtel",                ru: "Пояс стража" },
	"ITBE_ADDON_PAL_01":         { pl: "Pas paladyna",               en: "Paladin belt",            de: "Paladingürtel",                ru: "Пояс паладина" },
	"ITBE_ADDON_MIL_01":         { pl: "Pas milicji",                en: "Militia belt",            de: "Milizgürtel",                  ru: "Пояс милиции" },
	"ITBE_ADDON_SLD_01":         { pl: "Pas najemnika",              en: "Mercenary belt",          de: "Söldnergürtel",                ru: "Пояс наёмника" },
	"ITBE_ADDON_BDT_01":         { pl: "Pas bandyty",                en: "Bandit belt",             de: "Banditengürtel",               ru: "Пояс бандита" },
	"ITBE_ADDON_PIR_01":         { pl: "Pas pirata",                 en: "Pirate belt",             de: "Piratengürtel",                ru: "Пояс пирата" },
	"ITBE_ADDON_DEX":            { pl: "Pas zręczności",             en: "Belt of dexterity",       de: "Gürtel der Geschicklichkeit",  ru: "Пояс ловкости" },
	"ITBE_ADDON_STRG":           { pl: "Pas siły",                   en: "Belt of strength",        de: "Gürtel der Kraft",             ru: "Пояс силы" },
	"ITBE_ADDON_MANA":           { pl: "Pas many",                   en: "Belt of mana",            de: "Gürtel der Mana",              ru: "Пояс маны" },
	"ITBE_ADDON_HP":             { pl: "Pas zdrowia",                en: "Belt of health",          de: "Gürtel der Gesundheit",        ru: "Пояс здоровья" },

	// Helmets
	"ITAR_BAU_HELM":             { pl: "Słomiany kapelusz",          en: "Straw hat",               de: "Strohhut",                     ru: "Соломенная шляпа" },
	"ITAR_MIL_HELM":             { pl: "Hełm milicji",               en: "Militia helmet",          de: "Milizhelm",                    ru: "Шлем милиции" },
	"ITAR_PAL_HELM":             { pl: "Hełm paladyna",              en: "Paladin helmet",          de: "Paladinhelm",                  ru: "Шлем паладина" },
	"ITAR_SLD_HELM":             { pl: "Hełm najemnika",             en: "Mercenary helmet",        de: "Söldnerhelm",                  ru: "Шлем наёмника" },
	"ITAR_BDT_HELM":             { pl: "Hełm bandyty",               en: "Bandit helmet",           de: "Banditenhelm",                 ru: "Шлем бандита" },
	"ITAR_PIR_HELM":             { pl: "Bandana pirata",             en: "Pirate bandana",          de: "Piratenbandana",               ru: "Бандана пирата" },
	"ITAR_NOV_HOOD":             { pl: "Kaptur nowicjusza",          en: "Novice hood",             de: "Novizenkapuze",                ru: "Капюшон послушника" },
	"ITAR_KDF_HOOD":             { pl: "Kaptur Maga Ognia",          en: "Fire Mage hood",          de: "Feuermagierkapuze",            ru: "Капюшон мага огня" },
	"ITAR_KDW_HOOD":             { pl: "Kaptur Maga Wody",           en: "Water Mage hood",         de: "Wassermagierkapuze",           ru: "Капюшон мага воды" },

	// Shields
	"ITSH_WOOD_01":              { pl: "Drewniany puklerz",          en: "Wooden buckler",          de: "Holzbuckler",                  ru: "Деревянный щит" },
	"ITSH_WOOD_02":              { pl: "Drewniana tarcza",           en: "Wooden shield",           de: "Holzschild",                   ru: "Деревянный щит" },
	"ITSH_METAL_01":             { pl: "Żelazna tarcza",             en: "Iron shield",             de: "Eisenschild",                  ru: "Железный щит" },
	"ITSH_METAL_02":             { pl: "Stalowa tarcza",             en: "Steel shield",            de: "Stahlschild",                  ru: "Стальной щит" },
	"ITSH_PAL_SHIELD":           { pl: "Tarcza paladyna",            en: "Paladin shield",          de: "Paladinschild",                ru: "Щит паладина" },

	// Potions
	"ITPO_HEALTH_01":            { pl: "Esencja lecznicza",          en: "Healing essence",         de: "Heilessenz",                   ru: "Лечебная эссенция" },
	"ITPO_HEALTH_02":            { pl: "Ekstrakt leczniczy",         en: "Healing extract",         de: "Heilextrakt",                  ru: "Лечебный экстракт" },
	"ITPO_HEALTH_03":            { pl: "Eliksir leczniczy",          en: "Healing elixir",          de: "Heilelixier",                  ru: "Лечебный эликсир" },
	"ITPO_HEALTH_ADDON_04":      { pl: "Eliksir życia",              en: "Elixir of life",          de: "Lebenselixier",                ru: "Эликсир жизни" },
	"ITPO_MANA_01":              { pl: "Esencja many",               en: "Mana essence",            de: "Manaessenz",                   ru: "Эссенция маны" },
	"ITPO_MANA_02":              { pl: "Ekstrakt many",              en: "Mana extract",            de: "Manaextrakt",                  ru: "Экстракт маны" },
	"ITPO_MANA_03":              { pl: "Eliksir many",               en: "Mana elixir",             de: "Manaelixier",                  ru: "Эликсир маны" },
	"ITPO_MANA_ADDON_04":        { pl: "Eliksir esencji",            en: "Essence elixir",          de: "Essenzelixier",                ru: "Эликсир эссенции" },
	"ITPO_PERM_HEALTH":          { pl: "Esencja życia",              en: "Essence of life",         de: "Lebensessenz",                 ru: "Эссенция жизни" },
	"ITPO_PERM_MANA":            { pl: "Esencja many+",              en: "Permanent mana essence",  de: "Dauerhafte Manaessenz",        ru: "Постоянная эссенция маны" },
	"ITPO_PERM_LITTLEMANA":      { pl: "Mała esencja many",          en: "Small mana essence",      de: "Kleine Manaessenz",            ru: "Малая эссенция маны" },
	"ITPO_PERM_STR":             { pl: "Esencja siły",               en: "Essence of strength",     de: "Kraftessenz",                  ru: "Эссенция силы" },
	"ITPO_PERM_DEX":             { pl: "Esencja zręczności",         en: "Essence of dexterity",    de: "Geschicklichkeitsessenz",      ru: "Эссенция ловкости" },
	"ITPO_SPEED":                { pl: "Mikstura szybkości",         en: "Speed potion",            de: "Geschwindigkeitstrank",        ru: "Зелье скорости" },
	"ITPO_MEGADRINK":            { pl: "Megadrink",                  en: "Mega drink",              de: "Mega-Drink",                   ru: "Мегадринк" },
	"ITPO_HEALTH_TRUNK":         { pl: "Leczniczy napój",            en: "Healing draught",         de: "Heiltrunk",                    ru: "Лечебный напиток" },
	"ITPO_MANA_TRUNK":           { pl: "Napój many",                 en: "Mana draught",            de: "Manatrunk",                    ru: "Напиток маны" },

	// Food extra
	"ITFO_EGG":                  { pl: "Jajko",                      en: "Egg",                     de: "Ei",                           ru: "Яйцо" },

	// Keys
	"ITKE_KEY_CITY_01":          { pl: "Klucz miejski",              en: "City key",                de: "Stadtschlüssel",               ru: "Городской ключ" },
	"ITKE_KEY_CASTLE_01":        { pl: "Klucz zamkowy",              en: "Castle key",              de: "Burgschlüssel",                ru: "Замковый ключ" },
	"ITKE_KEY_MONASTERY_01":     { pl: "Klucz klasztorny",           en: "Monastery key",           de: "Klosterschlüssel",             ru: "Ключ от монастыря" },

	// Documents (extras)
	"ITWR_MAP_NEWWORLD":         { pl: "Mapa: Khorinis",             en: "Map: Khorinis",           de: "Karte: Khorinis",              ru: "Карта: Хоринис" },
	"ITWR_MAP_NEWWORLD_CITY":    { pl: "Mapa: Miasto Khorinis",      en: "Map: Khorinis city",      de: "Karte: Khorinis-Stadt",        ru: "Карта: город Хоринис" },
	"ITWR_MAP_OLDWORLD":         { pl: "Mapa: Górnicza Dolina",      en: "Map: Mining Valley",      de: "Karte: Minental",              ru: "Карта: Горная долина" },
	"ITWR_MAP_ADDONWORLD":       { pl: "Mapa: Jharkendar",           en: "Map: Jharkendar",         de: "Karte: Jharkendar",            ru: "Карта: Джаркендар" },
	"ITWR_EINHANDBUCH":          { pl: "Księga walki jednoręcznej",  en: "One-handed combat book",  de: "Buch der Einhandwaffen",       ru: "Книга одноручного боя" },
	"ITWR_ZWEIHANDBUCH":         { pl: "Księga walki dwuręcznej",    en: "Two-handed combat book",  de: "Buch der Zweihandwaffen",      ru: "Книга двуручного боя" },
	"ITWR_BOGENBUCH":            { pl: "Księga łucznictwa",          en: "Archery book",            de: "Buch der Bogenkunst",          ru: "Книга лучного боя" },
	"ITWR_ARMBRUSTBUCH":         { pl: "Księga kuszy",               en: "Crossbow book",           de: "Buch der Armbrust",            ru: "Книга арбалета" },
	"ITWR_KRAEUTERLISTE":        { pl: "Lista ziół",                 en: "Herb list",               de: "Kräuterliste",                 ru: "Список трав" },
	"ITWR_MANAREZEPT":           { pl: "Receptura: mikstura many",   en: "Recipe: mana potion",     de: "Rezept: Manatrank",            ru: "Рецепт: зелье маны" },
	"ITWR_HEALINGREZEPT":        { pl: "Receptura: mikstura leczenia", en: "Recipe: healing potion",de: "Rezept: Heiltrank",           ru: "Рецепт: лечебное зелье" },
	"ITWR_STRREZEPT":            { pl: "Receptura: eliksir siły",    en: "Recipe: strength elixir", de: "Rezept: Kraftelixier",         ru: "Рецепт: эликсир силы" },
	"ITWR_DEXREZEPT":            { pl: "Receptura: eliksir zręczności", en: "Recipe: dexterity elixir", de: "Rezept: Geschicklichkeitselixier", ru: "Рецепт: эликсир ловкости" },
	"ITWR_PERM_HPREZEPT":        { pl: "Receptura: esencja życia",   en: "Recipe: essence of life", de: "Rezept: Lebensessenz",         ru: "Рецепт: эссенция жизни" },
	"ITWR_PERM_MANAREZEPT":      { pl: "Receptura: esencja many",    en: "Recipe: essence of mana", de: "Rezept: Manaessenz",           ru: "Рецепт: эссенция маны" },

	// Materials
	"ITMI_GOLD":                 { pl: "Złoto",                      en: "Gold",                    de: "Gold",                         ru: "Золото" },
	"ITMI_NUGGET":               { pl: "Bryłka rudy",                en: "Ore nugget",              de: "Erzklumpen",                   ru: "Кусок руды" },
	"ITMI_GOLDNUGGET_ADDON":     { pl: "Bryłka złota",               en: "Gold nugget",             de: "Goldklumpen",                  ru: "Золотой самородок" },
	"ITMI_COAL":                 { pl: "Węgiel",                     en: "Coal",                    de: "Kohle",                        ru: "Уголь" },
	"ITMI_SULFUR":               { pl: "Siarka",                     en: "Sulfur",                  de: "Schwefel",                     ru: "Сера" },
	"ITMI_QUARTZ":               { pl: "Kwarc",                      en: "Quartz",                  de: "Quarz",                        ru: "Кварц" },
	"ITMI_AQUAMARINE":           { pl: "Akwamaryn",                  en: "Aquamarine",              de: "Aquamarin",                    ru: "Аквамарин" },
	"ITMI_ROCKCRYSTAL":          { pl: "Kryształ górski",            en: "Rock crystal",            de: "Bergkristall",                 ru: "Горный хрусталь" },
	"ITMI_DARKPEARL":            { pl: "Czarna perła",               en: "Dark pearl",              de: "Dunkle Perle",                 ru: "Чёрная жемчужина" },
	"ITMI_RUNEBLANK":            { pl: "Pusta runa",                 en: "Blank rune",              de: "Leere Rune",                   ru: "Пустая руна" },
	"ITMI_LEATHER":              { pl: "Skóra",                      en: "Leather",                 de: "Leder",                        ru: "Кожа" },
	"ITMI_FUR":                  { pl: "Futro",                      en: "Fur",                     de: "Fell",                         ru: "Мех" },
	"ITMI_BONE":                 { pl: "Kość",                       en: "Bone",                    de: "Knochen",                      ru: "Кость" },
	"ITMI_TEETH":                { pl: "Zęby",                       en: "Teeth",                   de: "Zähne",                        ru: "Зубы" },
	"ITMI_CLAW":                 { pl: "Pazur",                      en: "Claw",                    de: "Klaue",                        ru: "Коготь" },
	"ITMI_STOMACH":              { pl: "Żołądek",                    en: "Stomach",                 de: "Magen",                        ru: "Желудок" },
	"ITMI_TONGUE":               { pl: "Język",                      en: "Tongue",                  de: "Zunge",                        ru: "Язык" },
	"ITMI_EYE":                  { pl: "Oko",                        en: "Eye",                     de: "Auge",                         ru: "Глаз" },
	"ITMI_HEART":                { pl: "Serce",                      en: "Heart",                   de: "Herz",                         ru: "Сердце" },
	"ITMI_DRAGONSCALE":          { pl: "Łuska smoka",                en: "Dragon scale",            de: "Drachenschuppe",               ru: "Чешуя дракона" },
	"ITMI_DRAGONBLOOD":          { pl: "Krew smoka",                 en: "Dragon blood",            de: "Drachenblut",                  ru: "Кровь дракона" },
	"ITMI_HAMMER":               { pl: "Młotek",                     en: "Hammer",                  de: "Hammer",                       ru: "Молоток" },
	"ITMI_SAW":                  { pl: "Piła",                       en: "Saw",                     de: "Säge",                         ru: "Пила" },
	"ITMI_PLIERS":               { pl: "Kleszcze",                   en: "Pliers",                  de: "Zange",                        ru: "Клещи" },
	"ITMI_PAN":                  { pl: "Patelnia",                   en: "Pan",                     de: "Pfanne",                       ru: "Сковорода" },
	"ITMI_PANFULL":              { pl: "Patelnia z jedzeniem",       en: "Pan with food",           de: "Pfanne mit Essen",             ru: "Сковорода с едой" },
	"ITMI_BROOM":                { pl: "Miotła",                     en: "Broom",                   de: "Besen",                        ru: "Метла" },
	"ITMI_RAKE":                 { pl: "Grabie",                     en: "Rake",                    de: "Harke",                        ru: "Грабли" },
	"ITMI_SCOOP":                { pl: "Łopata",                     en: "Scoop",                   de: "Schaufel",                     ru: "Лопата" },
	"ITMI_SEXTANT":              { pl: "Sekstans",                   en: "Sextant",                 de: "Sextant",                      ru: "Секстант" },
	"ITMI_FOCUS":                { pl: "Magiczny fokus",             en: "Magic focus",             de: "Magischer Fokus",              ru: "Магический фокус" },
	"ITMI_TORCH":                { pl: "Pochodnia",                  en: "Torch",                   de: "Fackel",                       ru: "Факел" },

	// Herb miss
	"ITPL_SAGITTA_HERB_MIS":     { pl: "Zioło Sagitty",              en: "Sagitta's herb",          de: "Sagittas Kraut",               ru: "Трава Сагитты" },

	// Armor (proper Dedalus names)
	"ITAR_BAU_L":                { pl: "Strój farmera 1",            en: "Farmer's outfit 1",       de: "Bauernkleidung 1",             ru: "Одежда крестьянина 1" },
	"ITAR_BAU_M":                { pl: "Strój farmera 2",            en: "Farmer's outfit 2",       de: "Bauernkleidung 2",             ru: "Одежда крестьянина 2" },
	"ITAR_BAUBABE_L":            { pl: "Suknia farmerki 1",          en: "Farm woman's dress 1",    de: "Bäuerinnenkleid 1",            ru: "Платье крестьянки 1" },
	"ITAR_BAUBABE_M":            { pl: "Suknia farmerki 2",          en: "Farm woman's dress 2",    de: "Bäuerinnenkleid 2",            ru: "Платье крестьянки 2" },
	"ITAR_BARKEEPER":            { pl: "Strój ziemianina",           en: "Landowner outfit",        de: "Grundbesitzergewand",          ru: "Одежда землевладельца" },
	"ITAR_VLK_L":                { pl: "Strój obywatela",            en: "Citizen outfit",          de: "Bürgergewand",                 ru: "Одежда горожанина" },
	"ITAR_VLK_M":                { pl: "Strój obywatela",            en: "Citizen outfit",          de: "Bürgergewand",                 ru: "Одежда горожанина" },
	"ITAR_VLK_H":                { pl: "Strój obywatela",            en: "Citizen outfit",          de: "Bürgergewand",                 ru: "Одежда горожанина" },
	"ITAR_SMITH":                { pl: "Strój kowala",               en: "Smith outfit",            de: "Schmiedekleidung",             ru: "Одежда кузнеца" },
	"ITAR_PRISONER":             { pl: "Łachy skazańca",             en: "Prisoner rags",           de: "Gefangenenlumpen",             ru: "Лохмотья заключённого" },
	"ITAR_LEATHER_L":            { pl: "Skórzany pancerz",           en: "Leather armor",           de: "Lederrüstung",                 ru: "Кожаный доспех" },
	"ITAR_DIEGO":                { pl: "Pancerz Diega",              en: "Diego's armor",           de: "Diegos Rüstung",               ru: "Доспех Диего" },
	"ITAR_LESTER":               { pl: "Szata Lestera",              en: "Lester's robe",           de: "Lesters Robe",                 ru: "Одеяние Лестера" },
	"ITAR_NOV_L":                { pl: "Habit nowicjusza",           en: "Novice robe",             de: "Novizenrobe",                  ru: "Одеяние послушника" },
	"ITAR_KDF_L":                { pl: "Szata Maga Ognia",           en: "Fire Mage robe",          de: "Feuermagier-Robe",             ru: "Одеяние мага огня" },
	"ITAR_KDF_H":                { pl: "Ciężka szata ognia",         en: "Heavy fire robe",         de: "Schwere Feuerrobe",            ru: "Тяжёлое одеяние огня" },
	"ITAR_KDW_L_ADDON":          { pl: "Lekka toga Maga Wody",       en: "Light Water Mage robe",   de: "Leichte Wassermagier-Robe",    ru: "Лёгкое одеяние мага воды" },
	"ITAR_KDW_H":                { pl: "Szata Maga Wody",            en: "Water Mage robe",         de: "Wassermagier-Robe",            ru: "Одеяние мага воды" },
	"ITAR_GOVERNOR":             { pl: "Kaftan gubernatora",         en: "Governor's coat",         de: "Gouverneursmantel",            ru: "Кафтан губернатора" },
	"ITAR_JUDGE":                { pl: "Szata sędziego",             en: "Judge robe",              de: "Richterrobe",                  ru: "Одеяние судьи" },
	"ITAR_MIL_L":                { pl: "Lekki pancerz straży",       en: "Light guard armor",       de: "Leichter Wächterpanzer",       ru: "Лёгкая броня стражи" },
	"ITAR_MIL_M":                { pl: "Ciężki pancerz straży",      en: "Heavy guard armor",       de: "Schwerer Wächterpanzer",       ru: "Тяжёлая броня стражи" },
	"ITAR_PAL_M":                { pl: "Pancerz rycerza",            en: "Knight armor",            de: "Ritterrüstung",                ru: "Рыцарская броня" },
	"ITAR_PAL_H":                { pl: "Pancerz paladyna",           en: "Paladin armor",           de: "Paladinrüstung",               ru: "Броня паладина" },
	"ITAR_SLD_L":                { pl: "Lekki pancerz najemnika",    en: "Light mercenary armor",   de: "Leichter Söldnerpanzer",       ru: "Лёгкая броня наёмника" },
	"ITAR_SLD_M":                { pl: "Średni pancerz najemnika",   en: "Medium mercenary armor",  de: "Mittlerer Söldnerpanzer",      ru: "Средняя броня наёмника" },
	"ITAR_SLD_H":                { pl: "Ciężki pancerz najemnika",   en: "Heavy mercenary armor",   de: "Schwerer Söldnerpanzer",       ru: "Тяжёлая броня наёмника" },
	"ITAR_DJG_L":                { pl: "Lekki pancerz łowcy smoków", en: "Light Dragon Hunter armor", de: "Leichte Drachenjägerrüstung",ru: "Лёгкая броня охотника на драконов" },
	"ITAR_DJG_M":                { pl: "Średni pancerz łowcy smoków",en: "Medium Dragon Hunter armor",de: "Mittlere Drachenjägerrüstung",ru: "Средняя броня охотника на драконов" },
	"ITAR_DJG_H":                { pl: "Ciężki pancerz łowcy smoków",en: "Heavy Dragon Hunter armor", de: "Schwere Drachenjägerrüstung",ru: "Тяжёлая броня охотника на драконов" },
	"ITAR_DJG_CRAWLER":          { pl: "Zbroja z pancerzy pełzaczy", en: "Crawler plate armor",     de: "Minecrawlerpanzerung",         ru: "Броня из ползунов" },
	"ITAR_DJG_BABE":             { pl: "Kobiecy pancerz łowcy smoków", en: "Female Dragon Hunter armor", de: "Weibliche Drachenjägerrüstung", ru: "Женская броня охотника на драконов" },
	"ITAR_BDT_M":                { pl: "Średni pancerz bandyty",     en: "Medium bandit armor",     de: "Mittlerer Banditenpanzer",     ru: "Средняя броня бандита" },
	"ITAR_BDT_H":                { pl: "Ciężki pancerz bandyty",     en: "Heavy bandit armor",      de: "Schwerer Banditenpanzer",      ru: "Тяжёлая броня бандита" },
	"ITAR_PIR_L_ADDON":          { pl: "Pirackie ubranie",           en: "Pirate clothing",         de: "Piratenkleidung",              ru: "Пиратская одежда" },
	"ITAR_PIR_M_ADDON":          { pl: "Piracka zbroja",             en: "Pirate armor",            de: "Piratenrüstung",               ru: "Пиратская броня" },
	"ITAR_PIR_H_ADDON":          { pl: "Ubranie kapitana",           en: "Captain clothing",        de: "Kapitänskleidung",             ru: "Одежда капитана" },
	"ITAR_RANGER_ADDON":         { pl: "Zbroja Wodnego Kręgu",       en: "Water Circle armor",      de: "Wasserkreis-Rüstung",          ru: "Броня Круга Воды" },
	"ITAR_FAKE_RANGER":          { pl: "Zniszczona zbroja",          en: "Worn armor",              de: "Abgenutzte Rüstung",           ru: "Изношенная броня" },
	"ITAR_OREBARON_ADDON":       { pl: "Zbroja magnata",             en: "Ore Baron armor",         de: "Erzbaronrüstung",              ru: "Броня магната руды" },
	"ITAR_THORUS_ADDON":         { pl: "Ciężka zbroja gwardzisty",   en: "Heavy guard armor",       de: "Schwere Wachpanzerung",        ru: "Тяжёлая броня гвардейца" },
	"ITAR_BLOODWYN_ADDON":       { pl: "Zbroja Bloodwyna",           en: "Bloodwyn's armor",        de: "Bloodwyns Rüstung",            ru: "Броня Бладвина" },
	"ITAR_RAVEN_ADDON":          { pl: "Zbroja Kruka",               en: "Raven's armor",           de: "Rabens Rüstung",               ru: "Броня Ворона" },
	"ITAR_FIREARMOR_ADDON":      { pl: "Magiczna zbroja",            en: "Magic armor",             de: "Magische Rüstung",             ru: "Магическая броня" },
	"ITAR_MAYAZOMBIE_ADDON":     { pl: "Stara zbroja",               en: "Old armor",               de: "Alte Rüstung",                 ru: "Старая броня" },
	"ITAR_PAL_SKEL":             { pl: "Stara rycerska zbroja",      en: "Old knight armor",        de: "Alte Ritterrüstung",           ru: "Старая рыцарская броня" },
	"ITAR_DEMENTOR":             { pl: "Mroczny płaszcz",            en: "Dark cloak",              de: "Dunkler Mantel",               ru: "Тёмный плащ" },
	"ITAR_CORANGAR":             { pl: "Pancerz Cor Angara",         en: "Cor Angar's armor",       de: "Cor Angars Rüstung",           ru: "Броня Кор Ангара" },
	"ITAR_XARDAS":               { pl: "Szata Mrocznej Magii",       en: "Dark Magic robe",         de: "Robe der dunklen Magie",       ru: "Одеяние Тёмной магии" },

	// Food
	"ITFO_BACON":                { pl: "Szynka",                     en: "Ham",                     de: "Schinken",                     ru: "Окорок" },
	"ITFO_BOOZE":                { pl: "Gin",                        en: "Gin",                     de: "Gin",                          ru: "Джин" },
	"ITFO_MUTTON":               { pl: "Smażone mięso",              en: "Fried meat",              de: "Gebratenes Fleisch",           ru: "Жареное мясо" },
	"ITFO_MUTTONRAW":            { pl: "Surowe mięso",               en: "Raw meat",                de: "Rohes Fleisch",                ru: "Сырое мясо" },
	"ITFO_ADDON_SHELLFLESH":     { pl: "Ostryga",                    en: "Oyster",                  de: "Auster",                       ru: "Устрица" },

	// Keys (generic)
	"ITKE_KEY_01":               { pl: "Klucz",                      en: "Key",                     de: "Schlüssel",                    ru: "Ключ" },
	"ITKE_KEY_02":               { pl: "Klucz",                      en: "Key",                     de: "Schlüssel",                    ru: "Ключ" },
	"ITKE_KEY_03":               { pl: "Klucz",                      en: "Key",                     de: "Schlüssel",                    ru: "Ключ" },

	// 2H weapons extras
	"ITMW_2H_AXE_L_01":          { pl: "Kilof",                      en: "Pickaxe",                 de: "Spitzhacke",                   ru: "Кирка" },
	"ITMW_2H_ORCAXE_01":         { pl: "Lekki orkowy topór",         en: "Light orc axe",           de: "Leichte Orkaxt",               ru: "Лёгкий орочий топор" },
	"ITMW_2H_ORCAXE_02":         { pl: "Średni orkowy topór",        en: "Medium orc axe",          de: "Mittlere Orkaxt",              ru: "Средний орочий топор" },
	"ITMW_2H_ORCAXE_04":         { pl: "Ogromny orkowy topór",       en: "Huge orc axe",            de: "Riesige Orkaxt",               ru: "Огромный орочий топор" },
	"ITMW_2H_ORCSWORD_01":       { pl: "Jaszczurzy miecz",           en: "Lizard sword",            de: "Echsenschwert",                ru: "Ящерий меч" },
	"ITMW_2H_ORCSWORD_02":       { pl: "Orkowy miecz wojenny",       en: "Orc war sword",           de: "Orkkriegsschwert",             ru: "Боевой орочий меч" },
	"ITMW_2H_PAL_SWORD":         { pl: "Miecz dwuręczny paladyna",   en: "Paladin two-handed sword",de: "Zweihandschwert des Paladins", ru: "Двуручный меч паладина" },
	"ITMW_ADDON_HACKER_2H_01":   { pl: "Wielka maczeta",             en: "Great machete",           de: "Grosse Machete",               ru: "Большое мачете" },
	"ITMW_ADDON_HACKER_2H_02":   { pl: "Wielka, stara maczeta",      en: "Great old machete",       de: "Grosse alte Machete",          ru: "Большое старое мачете" },
	"ITMW_ADDON_KEULE_2H_01":    { pl: "Sługa Burzy",                en: "Servant of the Storm",    de: "Diener des Sturms",            ru: "Слуга бури" },
	"ITMW_ADDON_PIR2HAXE":       { pl: "Miażdżydeska",               en: "Plank crusher",           de: "Plankenbrecher",               ru: "Доскодавитель" },
	"ITMW_ADDON_PIR2HSWORD":     { pl: "Miecz pokładowy",            en: "Deck sword",              de: "Decksschwert",                 ru: "Палубный меч" },
	"ITMW_ADDON_STAB01":         { pl: "Kostur maga",                en: "Mage staff",              de: "Magierstab",                   ru: "Посох мага" },
	"ITMW_ADDON_STAB03":         { pl: "Wodny kostur",               en: "Water staff",             de: "Wasserstab",                   ru: "Посох воды" },
	"ITMW_ADDON_STAB04":         { pl: "Kostur Ulthara",             en: "Ulthar's staff",          de: "Ulthars Stab",                 ru: "Посох Ультара" },
	"ITMW_BARBARENSTREITAXT":    { pl: "Barbarzyński topór bojowy",  en: "Barbarian battle axe",    de: "Barbarenstreitaxt",            ru: "Варварский боевой топор" },
	"ITMW_BARTAXT":              { pl: "Wielki topór",               en: "Great axe",               de: "Große Axt",                    ru: "Большой топор" },
	"ITMW_DOPPELAXT":            { pl: "Topór obosieczny",           en: "Double-edged axe",        de: "Doppelschneidige Axt",         ru: "Двухлезвийный топор" },
	"ITMW_DRACHENSCHNEIDE":      { pl: "Smocza Zguba",               en: "Dragon's Bane",           de: "Drachenschneide",              ru: "Драконоубийца" },
	"ITMW_FOLTERAXT":            { pl: "Katowski topór",             en: "Executioner's axe",       de: "Henkersaxt",                   ru: "Топор палача" },
	"ITMW_FRANCISDAGGER_MIS":    { pl: "Złoty sztylet",              en: "Golden dagger",           de: "Goldener Dolch",               ru: "Золотой кинжал" },
	"ITMW_KRIEGSHAMMER2":        { pl: "Ciężki młot wojenny",        en: "Heavy war hammer",        de: "Schwerer Kriegshammer",        ru: "Тяжёлый боевой молот" },
	"ITMW_MORGENSTERN":          { pl: "Buława i łańcuch",           en: "Mace and chain",          de: "Streitkolben und Kette",       ru: "Булава с цепью" },
	"ITMW_RANGERSTAFF_ADDON":    { pl: "Pika bojowa Wodnego Kręgu",  en: "Water Circle battle pike",de: "Wasserkreis-Kampfpike",        ru: "Боевая пика Круга Воды" },

	// Herbs (Dedalus originals)
	"ITPL_BEET":                 { pl: "Rzepa",                      en: "Turnip",                  de: "Rübe",                         ru: "Репа" },
	"ITPL_BLUEPLANT":            { pl: "Niebieski bez",              en: "Blue elder",              de: "Blauer Holunder",              ru: "Синяя бузина" },
	"ITPL_DEX_HERB_01":          { pl: "Goblinie jagody",            en: "Goblin berries",          de: "Goblinbeeren",                 ru: "Гоблинские ягоды" },
	"ITPL_FORESTBERRY":          { pl: "Leśna jagoda",               en: "Forest berry",            de: "Waldbeere",                    ru: "Лесная ягода" },
	"ITPL_HEALTH_HERB_01":       { pl: "Roślina lecznicza",          en: "Healing plant",           de: "Heilpflanze",                  ru: "Лечебное растение" },
	"ITPL_HEALTH_HERB_02":       { pl: "Ziele lecznicze",            en: "Healing herb",            de: "Heilkraut",                    ru: "Лечебная трава" },
	"ITPL_HEALTH_HERB_03":       { pl: "Korzeń leczniczy",           en: "Healing root",            de: "Heilwurzel",                   ru: "Лечебный корень" },
	"ITPL_MANA_HERB_01":         { pl: "Ognista pokrzywa",           en: "Fire nettle",             de: "Feuernessel",                  ru: "Огненная крапива" },
	"ITPL_MANA_HERB_02":         { pl: "Ogniste ziele",              en: "Fire herb",               de: "Feuerkraut",                   ru: "Огненная трава" },
	"ITPL_MANA_HERB_03":         { pl: "Ognisty korzeń",             en: "Fire root",               de: "Feuerwurzel",                  ru: "Огненный корень" },
	"ITPL_MUSHROOM_02":          { pl: "Mięso kopacza",              en: "Crawler meat",            de: "Minecrawlerfleisch",           ru: "Мясо ползуна" },
	"ITPL_PERM_HERB":            { pl: "Szczaw królewski",           en: "Royal sorrel",            de: "Königssauerampfer",            ru: "Королевский щавель" },
	"ITPL_PLANEBERRY":           { pl: "Polna jagoda",               en: "Field berry",             de: "Feldbeere",                    ru: "Полевая ягода" },
	"ITPL_SPEED_HERB_01":        { pl: "Zębate ziele",               en: "Toothed herb",            de: "Zahnkraut",                    ru: "Зубчатая трава" },
	"ITPL_STRENGTH_HERB_01":     { pl: "Smoczy korzeń",              en: "Dragon root",             de: "Drachenwurzel",                ru: "Драконий корень" },
	"ITPL_TEMP_HERB":            { pl: "Rdest polny",                en: "Field knotweed",          de: "Ackerknöterich",               ru: "Спорыш полевой" },
	"ITPL_WEED":                 { pl: "Chwasty",                    en: "Weeds",                   de: "Unkraut",                      ru: "Сорняки" },

	// Bows (Dedalus)
	"ITRW_BOW_L_02":             { pl: "Łuk wierzbowy",              en: "Willow bow",              de: "Weidenbogen",                  ru: "Ивовый лук" },
	"ITRW_BOW_L_03":             { pl: "Łuk myśliwski",              en: "Hunting bow",             de: "Jagdbogen",                    ru: "Охотничий лук" },
	"ITRW_BOW_L_03_MIS":         { pl: "Łuk myśliwski",              en: "Hunting bow",             de: "Jagdbogen",                    ru: "Охотничий лук" },
	"ITRW_BOW_L_04":             { pl: "Łuk z wiązu",                en: "Elm bow",                 de: "Ulmenbogen",                   ru: "Вязовый лук" },
	"ITRW_BOW_M_01":             { pl: "Łuk kompozytowy",            en: "Composite bow",           de: "Kompositbogen",                ru: "Композитный лук" },
	"ITRW_BOW_M_02":             { pl: "Łuk jesionowy",              en: "Ash bow",                 de: "Eschenbogen",                  ru: "Ясеневый лук" },
	"ITRW_BOW_M_04":             { pl: "Łuk bukowy",                 en: "Beech bow",               de: "Buchenbogen",                  ru: "Буковый лук" },
	"ITRW_BOW_H_01":             { pl: "Kościany łuk",               en: "Bone bow",                de: "Knochenbogen",                 ru: "Костяной лук" },
	"ITRW_BOW_H_02":             { pl: "Łuk dębowy",                 en: "Oak bow",                 de: "Eichenbogen",                  ru: "Дубовый лук" },
	"ITRW_BOW_H_03":             { pl: "Łuk wojenny",                en: "War bow",                 de: "Kriegsbogen",                  ru: "Боевой лук" },
	"ITRW_BOW_H_04":             { pl: "Smoczy łuk",                 en: "Dragon bow",              de: "Drachenbogen",                 ru: "Драконий лук" },
	"ITRW_SLD_BOW":              { pl: "Łuk",                        en: "Bow",                     de: "Bogen",                        ru: "Лук" },
	"ITRW_CROSSBOW_L_01":        { pl: "Kusza myśliwska",            en: "Hunting crossbow",        de: "Jagdarmbrust",                 ru: "Охотничий арбалет" },
	"ITRW_CROSSBOW_L_02":        { pl: "Lekka kusza",                en: "Light crossbow",          de: "Leichte Armbrust",             ru: "Лёгкий арбалет" },
	"ITRW_CROSSBOW_H_01":        { pl: "Ciężka kusza",               en: "Heavy crossbow",          de: "Schwere Armbrust",             ru: "Тяжёлый арбалет" },
	"ITRW_CROSSBOW_H_02":        { pl: "Kusza łowcy smoków",         en: "Dragon Hunter crossbow",  de: "Drachenjägerarmbrust",         ru: "Арбалет охотника на драконов" },
	"ITRW_DRAGOMIRSARMBRUST_MIS":{ pl: "Kusza Dragomira",            en: "Dragomir's crossbow",     de: "Dragomirs Armbrust",           ru: "Арбалет Драгомира" },
	"ITRW_SENGRATHSARMBRUST_MIS":{ pl: "Kusza Sengratha",            en: "Sengrath's crossbow",     de: "Sengraths Armbrust",           ru: "Арбалет Сенграта" },

	// Runes
	"ITRU_LIGHT":                { pl: "Runa: Światło",              en: "Rune: Light",             de: "Rune: Licht",                  ru: "Руна: Свет" },
	"ITRU_LIGHTHEAL":            { pl: "Runa: Małe Leczenie",        en: "Rune: Minor heal",        de: "Rune: Kleine Heilung",         ru: "Руна: Малое лечение" },
	"ITRU_MEDIUMHEAL":           { pl: "Runa: Leczenie",             en: "Rune: Heal",              de: "Rune: Heilung",                ru: "Руна: Лечение" },
	"ITRU_FULLHEAL":             { pl: "Runa: Pełne Leczenie",       en: "Rune: Full heal",         de: "Rune: Volle Heilung",          ru: "Руна: Полное лечение" },
	"ITRU_INSTANTFIREBALL":      { pl: "Runa: Kula Ognia",           en: "Rune: Fireball",          de: "Rune: Feuerball",              ru: "Руна: Огненный шар" },
	"ITRU_CHARGEFIREBALL":       { pl: "Runa: Naładowana Kula Ognia",en: "Rune: Charged fireball",  de: "Rune: Geladener Feuerball",    ru: "Руна: Заряженный огненный шар" },
	"ITRU_FIRESTORM":            { pl: "Runa: Burza Ognia",          en: "Rune: Firestorm",         de: "Rune: Feuersturm",             ru: "Руна: Огненная буря" },
	"ITRU_FIRERAIN":             { pl: "Runa: Deszcz Ognia",         en: "Rune: Fire rain",         de: "Rune: Feuerregen",             ru: "Руна: Огненный дождь" },
	"ITRU_PYROKINESIS":          { pl: "Runa: Pirokineza",           en: "Rune: Pyrokinesis",       de: "Rune: Pyrokinese",             ru: "Руна: Пирокинез" },
	"ITRU_ICEBOLT":              { pl: "Runa: Pocisk Lodu",          en: "Rune: Icebolt",           de: "Rune: Eisblitz",               ru: "Руна: Ледяной снаряд" },
	"ITRU_ICECUBE":              { pl: "Runa: Sześcian Lodu",        en: "Rune: Ice cube",          de: "Rune: Eiswürfel",              ru: "Руна: Ледяной куб" },
	"ITRU_ICEWAVE":              { pl: "Runa: Fala Lodu",            en: "Rune: Ice wave",          de: "Rune: Eiswelle",               ru: "Руна: Ледяная волна" },
	"ITRU_LIGHTNINGFLASH":       { pl: "Runa: Błyskawica",           en: "Rune: Lightning",         de: "Rune: Blitz",                  ru: "Руна: Молния" },
	"ITRU_THUNDERBALL":          { pl: "Runa: Kula Błyskawic",       en: "Rune: Thunderball",       de: "Rune: Donnerball",             ru: "Руна: Шаровая молния" },
	"ITRU_WINDFIST":             { pl: "Runa: Pięść Wiatru",         en: "Rune: Windfist",          de: "Rune: Windfaust",              ru: "Руна: Кулак ветра" },
	"ITRU_FIREBOLT":             { pl: "Runa: Pocisk Ognia",         en: "Rune: Firebolt",          de: "Rune: Feuerblitz",             ru: "Руна: Огненный снаряд" },
	"ITRU_ZAP":                  { pl: "Runa: Iskra",                en: "Rune: Zap",               de: "Rune: Funke",                  ru: "Руна: Искра" },
	"ITRU_FEAR":                 { pl: "Runa: Strach",               en: "Rune: Fear",              de: "Rune: Furcht",                 ru: "Руна: Страх" },
	"ITRU_SLEEP":                { pl: "Runa: Sen",                  en: "Rune: Sleep",             de: "Rune: Schlaf",                 ru: "Руна: Сон" },
	"ITRU_SHRINK":               { pl: "Runa: Pomniejszenie",        en: "Rune: Shrink",            de: "Rune: Schrumpfen",             ru: "Руна: Уменьшение" },
	"ITRU_HARMUNDEAD":           { pl: "Runa: Rażenie Nieumarłych",  en: "Rune: Harm undead",       de: "Rune: Untote schaden",         ru: "Руна: Поражение нежити" },
	"ITRU_SUMGOBSKEL":           { pl: "Runa: Szkielet Goblina",     en: "Rune: Goblin skeleton",   de: "Rune: Goblinskelett",          ru: "Руна: Скелет гоблина" },
	"ITRU_SUMSKEL":              { pl: "Runa: Przywołaj Szkielet",   en: "Rune: Summon skeleton",   de: "Rune: Skelett beschwören",     ru: "Руна: Призвать скелета" },
	"ITRU_SUMWOLF":              { pl: "Runa: Przywołaj Wilka",      en: "Rune: Summon wolf",       de: "Rune: Wolf beschwören",        ru: "Руна: Призвать волка" },
	"ITRU_SUMGOL":               { pl: "Runa: Przywołaj Golema",     en: "Rune: Summon golem",      de: "Rune: Golem beschwören",       ru: "Руна: Призвать голема" },
	"ITRU_SUMDEMON":             { pl: "Runa: Przywołaj Demona",     en: "Rune: Summon demon",      de: "Rune: Dämon beschwören",       ru: "Руна: Призвать демона" },
	"ITRU_BREATHOFDEATH":        { pl: "Runa: Oddech Śmierci",       en: "Rune: Breath of death",   de: "Rune: Atem des Todes",         ru: "Руна: Дыхание смерти" },
	"ITRU_MASSDEATH":            { pl: "Runa: Masowa Śmierć",        en: "Rune: Mass death",        de: "Rune: Massentod",              ru: "Руна: Массовая смерть" },
	"ITRU_MASTEROFDISASTER":     { pl: "Runa: Mistrz Zniszczenia",   en: "Rune: Master of disaster",de: "Rune: Meister des Unheils",    ru: "Руна: Мастер разрушения" },
	"ITRU_ARMYOFDARKNESS":       { pl: "Runa: Armia Ciemności",      en: "Rune: Army of darkness",  de: "Rune: Armee der Dunkelheit",   ru: "Руна: Армия тьмы" },
	"ITRU_PALLIGHT":             { pl: "Runa: Światło Paladyna",     en: "Rune: Paladin light",     de: "Rune: Paladinlicht",           ru: "Руна: Свет паладина" },
	"ITRU_PALLIGHTHEAL":         { pl: "Runa: Małe Leczenie Paladyna",en: "Rune: Paladin minor heal",de: "Rune: Kleine Paladinheilung",  ru: "Руна: Малое лечение паладина" },
	"ITRU_PALMEDIUMHEAL":        { pl: "Runa: Średnie Leczenie Paladyna", en: "Rune: Paladin medium heal", de: "Rune: Mittlere Paladinheilung", ru: "Руна: Среднее лечение паладина" },
	"ITRU_PALFULLHEAL":          { pl: "Runa: Pełne Leczenie Paladyna", en: "Rune: Paladin full heal", de: "Rune: Volle Paladinheilung", ru: "Руна: Полное лечение паладина" },
	"ITRU_PALHOLYBOLT":          { pl: "Runa: Święty Pocisk",        en: "Rune: Holy bolt",         de: "Rune: Heiliger Blitz",         ru: "Руна: Святой снаряд" },
	"ITRU_PALREPELEVIL":         { pl: "Runa: Odpędzenie Zła",       en: "Rune: Repel evil",        de: "Rune: Böses abwehren",         ru: "Руна: Изгнание зла" },
	"ITRU_PALDESTROYEVIL":       { pl: "Runa: Niszcz Zło",           en: "Rune: Destroy evil",      de: "Rune: Böses vernichten",       ru: "Руна: Уничтожение зла" },
	"ITRU_PALTELEPORTSECRET":    { pl: "Runa: Teleport Paladyna",    en: "Rune: Paladin teleport",  de: "Rune: Paladinteleport",        ru: "Руна: Телепорт паладина" },
	"ITRU_TELEPORTSEAPORT":      { pl: "Runa: Teleport Port",        en: "Rune: Teleport Seaport", de: "Rune: Teleport Hafen",          ru: "Руна: Телепорт порт" },
	"ITRU_TELEPORTMONASTERY":    { pl: "Runa: Teleport Klasztor",    en: "Rune: Teleport Monastery",de: "Rune: Teleport Kloster",       ru: "Руна: Телепорт монастырь" },
	"ITRU_TELEPORTFARM":         { pl: "Runa: Teleport Farma",       en: "Rune: Teleport Farm",     de: "Rune: Teleport Farm",          ru: "Руна: Телепорт ферма" },
	"ITRU_TELEPORTXARDAS":       { pl: "Runa: Teleport Xardas",      en: "Rune: Teleport Xardas",   de: "Rune: Teleport Xardas",        ru: "Руна: Телепорт Ксардас" },
	"ITRU_TELEPORTPASSNW":       { pl: "Runa: Teleport Przełęcz NW", en: "Rune: Teleport NW Pass", de: "Rune: Teleport NW-Pass",        ru: "Руна: Телепорт северный перевал" },
	"ITRU_TELEPORTPASSOW":       { pl: "Runa: Teleport Przełęcz OW", en: "Rune: Teleport OW Pass", de: "Rune: Teleport OW-Pass",        ru: "Руна: Телепорт южный перевал" },
	"ITRU_TELEPORTOC":           { pl: "Runa: Teleport Zamek",       en: "Rune: Teleport Castle",   de: "Rune: Teleport Burg",          ru: "Руна: Телепорт замок" },
	"ITRU_TELEPORTOWDEMONTOWER": { pl: "Runa: Teleport Wieża Demona",en: "Rune: Teleport Demon tower", de: "Rune: Teleport Dämonenturm", ru: "Руна: Телепорт башня демона" },
	"ITRU_TELEPORTTAVERNE":      { pl: "Runa: Teleport Karczma",     en: "Rune: Teleport Tavern",   de: "Rune: Teleport Taverne",       ru: "Руна: Телепорт таверна" },
	"ITRU_TELEPORT_3":           { pl: "Runa: Teleport dodatkowy",   en: "Rune: Extra teleport",    de: "Rune: Zusätzlicher Teleport",  ru: "Руна: Дополнительный телепорт" },

	// Scrolls
	"ITSC_LIGHT":                { pl: "Zwój: Światło",              en: "Scroll: Light",           de: "Schriftrolle: Licht",          ru: "Свиток: Свет" },
	"ITSC_LIGHTHEAL":            { pl: "Zwój: Małe Leczenie",        en: "Scroll: Minor heal",      de: "Schriftrolle: Kleine Heilung", ru: "Свиток: Малое лечение" },
	"ITSC_MEDIUMHEAL":           { pl: "Zwój: Leczenie",             en: "Scroll: Heal",            de: "Schriftrolle: Heilung",        ru: "Свиток: Лечение" },
	"ITSC_FULLHEAL":             { pl: "Zwój: Pełne Leczenie",       en: "Scroll: Full heal",       de: "Schriftrolle: Volle Heilung",  ru: "Свиток: Полное лечение" },
	"ITSC_INSTANTFIREBALL":      { pl: "Zwój: Kula Ognia",           en: "Scroll: Fireball",        de: "Schriftrolle: Feuerball",      ru: "Свиток: Огненный шар" },
	"ITSC_CHARGEFIREBALL":       { pl: "Zwój: Naładowana Kula Ognia",en: "Scroll: Charged fireball",de: "Schriftrolle: Geladener Feuerball", ru: "Свиток: Заряженный огненный шар" },
	"ITSC_FIRESTORM":            { pl: "Zwój: Burza Ognia",          en: "Scroll: Firestorm",       de: "Schriftrolle: Feuersturm",     ru: "Свиток: Огненная буря" },
	"ITSC_FIRERAIN":             { pl: "Zwój: Deszcz Ognia",         en: "Scroll: Fire rain",       de: "Schriftrolle: Feuerregen",     ru: "Свиток: Огненный дождь" },
	"ITSC_PYROKINESIS":          { pl: "Zwój: Pirokineza",           en: "Scroll: Pyrokinesis",     de: "Schriftrolle: Pyrokinese",     ru: "Свиток: Пирокинез" },
	"ITSC_ICEBOLT":              { pl: "Zwój: Pocisk Lodu",          en: "Scroll: Icebolt",         de: "Schriftrolle: Eisblitz",       ru: "Свиток: Ледяной снаряд" },
	"ITSC_ICECUBE":              { pl: "Zwój: Sześcian Lodu",        en: "Scroll: Ice cube",        de: "Schriftrolle: Eiswürfel",      ru: "Свиток: Ледяной куб" },
	"ITSC_ICEWAVE":              { pl: "Zwój: Fala Lodu",            en: "Scroll: Ice wave",        de: "Schriftrolle: Eiswelle",       ru: "Свиток: Ледяная волна" },
	"ITSC_LIGHTNINGFLASH":       { pl: "Zwój: Błyskawica",           en: "Scroll: Lightning",       de: "Schriftrolle: Blitz",          ru: "Свиток: Молния" },
	"ITSC_THUNDERBALL":          { pl: "Zwój: Kula Błyskawic",       en: "Scroll: Thunderball",     de: "Schriftrolle: Donnerball",     ru: "Свиток: Шаровая молния" },
	"ITSC_WINDFIST":             { pl: "Zwój: Pięść Wiatru",         en: "Scroll: Windfist",        de: "Schriftrolle: Windfaust",      ru: "Свиток: Кулак ветра" },
	"ITSC_FIREBOLT":             { pl: "Zwój: Pocisk Ognia",         en: "Scroll: Firebolt",        de: "Schriftrolle: Feuerblitz",     ru: "Свиток: Огненный снаряд" },
	"ITSC_ZAP":                  { pl: "Zwój: Iskra",                en: "Scroll: Zap",             de: "Schriftrolle: Funke",          ru: "Свиток: Искра" },
	"ITSC_FEAR":                 { pl: "Zwój: Strach",               en: "Scroll: Fear",            de: "Schriftrolle: Furcht",         ru: "Свиток: Страх" },
	"ITSC_SLEEP":                { pl: "Zwój: Sen",                  en: "Scroll: Sleep",           de: "Schriftrolle: Schlaf",         ru: "Свиток: Сон" },
	"ITSC_SHRINK":               { pl: "Zwój: Pomniejszenie",        en: "Scroll: Shrink",          de: "Schriftrolle: Schrumpfen",     ru: "Свиток: Уменьшение" },
	"ITSC_HARMUNDEAD":           { pl: "Zwój: Rażenie Nieumarłych",  en: "Scroll: Harm undead",     de: "Schriftrolle: Untote schaden", ru: "Свиток: Поражение нежити" },
	"ITSC_SUMGOBSKEL":           { pl: "Zwój: Szkielet Goblina",     en: "Scroll: Goblin skeleton", de: "Schriftrolle: Goblinskelett",  ru: "Свиток: Скелет гоблина" },
	"ITSC_SUMSKEL":              { pl: "Zwój: Przywołaj Szkielet",   en: "Scroll: Summon skeleton", de: "Schriftrolle: Skelett beschwören", ru: "Свиток: Призвать скелета" },
	"ITSC_SUMWOLF":              { pl: "Zwój: Przywołaj Wilka",      en: "Scroll: Summon wolf",     de: "Schriftrolle: Wolf beschwören",ru: "Свиток: Призвать волка" },
	"ITSC_SUMGOL":               { pl: "Zwój: Przywołaj Golema",     en: "Scroll: Summon golem",    de: "Schriftrolle: Golem beschwören", ru: "Свиток: Призвать голема" },
	"ITSC_SUMDEMON":             { pl: "Zwój: Przywołaj Demona",     en: "Scroll: Summon demon",    de: "Schriftrolle: Dämon beschwören", ru: "Свиток: Призвать демона" },
	"ITSC_BREATHOFDEATH":        { pl: "Zwój: Oddech Śmierci",       en: "Scroll: Breath of death", de: "Schriftrolle: Atem des Todes", ru: "Свиток: Дыхание смерти" },
	"ITSC_MASSDEATH":            { pl: "Zwój: Masowa Śmierć",        en: "Scroll: Mass death",      de: "Schriftrolle: Massentod",      ru: "Свиток: Массовая смерть" },
	"ITSC_MASTEROFDISASTER":     { pl: "Zwój: Mistrz Zniszczenia",   en: "Scroll: Master of disaster", de: "Schriftrolle: Meister des Unheils", ru: "Свиток: Мастер разрушения" },
	"ITSC_ARMYOFDARKNESS":       { pl: "Zwój: Armia Ciemności",      en: "Scroll: Army of darkness",de: "Schriftrolle: Armee der Dunkelheit", ru: "Свиток: Армия тьмы" }
};


function classify(inst) {
	if (inst.startsWith("ITMW_")) return "weapons";
	if (inst.startsWith("ITRW_")) return "ranged";
	if (inst.startsWith("ITAR_")) return "armor";
	if (inst.startsWith("ITSH_")) return "shields";
	if (inst.startsWith("ITBE_")) return "belts";
	if (inst.startsWith("ITAM_")) return "amulets";
	if (inst.startsWith("ITRI_")) return "rings";
	if (inst.startsWith("ITPO_")) return "potions";
	if (inst.startsWith("ITFO_")) return "food";
	if (inst.startsWith("ITPL_")) return "herbs";
	if (inst.startsWith("ITRU_")) return "runes";
	if (inst.startsWith("ITSC_")) return "scrolls";
	if (inst.startsWith("ITKE_")) return "keys";
	if (inst.startsWith("ITWR_")) return "documents";
	if (inst.startsWith("ITMI_")) return "materials";
	return "other";
}

// Translations for runes/scrolls by stripping prefix "Runa: "/"Zwój: "
const RUNE_MAP = {
	"światło": { en: "Light", de: "Licht", ru: "Свет" },
	"pocisk ognia": { en: "Firebolt", de: "Feuerblitz", ru: "Огненный снаряд" },
	"iskra": { en: "Zap", de: "Funke", ru: "Искра" },
	"małe leczenie": { en: "Minor heal", de: "Kleine Heilung", ru: "Малое лечение" },
	"szkielet goblina": { en: "Summon goblin skeleton", de: "Goblinskelett beschwören", ru: "Вызов гоблин-скелета" },
	"kula ognia": { en: "Fireball", de: "Feuerball", ru: "Огненный шар" },
	"pocisk lodu": { en: "Icebolt", de: "Eisblitz", ru: "Ледяной снаряд" },
	"przywołaj wilka": { en: "Summon wolf", de: "Wolf beschwören", ru: "Призвать волка" },
	"pięść wiatru": { en: "Windfist", de: "Windfaust", ru: "Кулак ветра" },
	"sen": { en: "Sleep", de: "Schlaf", ru: "Сон" },
	"leczenie": { en: "Heal", de: "Heilung", ru: "Лечение" },
	"przywołaj szkielet": { en: "Summon skeleton", de: "Skelett beschwören", ru: "Вызов скелета" },
	"strach": { en: "Fear", de: "Furcht", ru: "Страх" },
	"sześcian lodu": { en: "Ice cube", de: "Eiswürfel", ru: "Ледяной куб" },
	"kula błyskawic": { en: "Thunderball", de: "Donnerball", ru: "Шаровая молния" },
	"burza ognia": { en: "Firestorm", de: "Feuersturm", ru: "Огненная буря" },
	"przywołaj golema": { en: "Summon golem", de: "Golem beschwören", ru: "Вызов голема" },
	"rażenie nieumarłych": { en: "Harm undead", de: "Untote schaden", ru: "Поражение нежити" },
	"błyskawica": { en: "Lightning flash", de: "Blitzschlag", ru: "Молния" },
	"naładowana kula ognia": { en: "Charge fireball", de: "Geladener Feuerball", ru: "Заряженный огненный шар" },
	"fala lodu": { en: "Ice wave", de: "Eiswelle", ru: "Ледяная волна" },
	"przywołaj demona": { en: "Summon demon", de: "Dämon beschwören", ru: "Вызов демона" },
	"pełne leczenie": { en: "Full heal", de: "Volle Heilung", ru: "Полное лечение" },
	"pirokineza": { en: "Pyrokinesis", de: "Pyrokinese", ru: "Пирокинез" },
	"deszcz ognia": { en: "Fire rain", de: "Feuerregen", ru: "Огненный дождь" },
	"oddech śmierci": { en: "Breath of death", de: "Atem des Todes", ru: "Дыхание смерти" },
	"masowa śmierć": { en: "Mass death", de: "Massentod", ru: "Массовая смерть" },
	"mistrz zniszczenia": { en: "Master of disaster", de: "Meister des Unheils", ru: "Мастер разрушения" },
	"armia ciemności": { en: "Army of darkness", de: "Armee der Dunkelheit", ru: "Армия тьмы" },
	"pomniejszenie": { en: "Shrink", de: "Schrumpfen", ru: "Уменьшение" },
	"światło paladyna": { en: "Paladin light", de: "Paladinlicht", ru: "Свет паладина" },
	"małe leczenie paladyna": { en: "Paladin minor heal", de: "Kleine Paladinheilung", ru: "Малое лечение паладина" },
	"święty pocisk": { en: "Holy bolt", de: "Heiliger Blitz", ru: "Святой снаряд" },
	"średnie leczenie paladyna": { en: "Paladin medium heal", de: "Mittlere Paladinheilung", ru: "Среднее лечение паладина" },
	"odpędzenie zła": { en: "Repel evil", de: "Böses abwehren", ru: "Изгнание зла" },
	"pełne leczenie paladyna": { en: "Paladin full heal", de: "Volle Paladinheilung", ru: "Полное лечение паладина" },
	"niszcz zło": { en: "Destroy evil", de: "Böses vernichten", ru: "Уничтожение зла" },
	"teleport paladyna": { en: "Paladin teleport", de: "Paladinteleport", ru: "Телепорт паладина" },
	"teleport port": { en: "Teleport: Seaport", de: "Teleport: Hafen", ru: "Телепорт: порт" },
	"teleport klasztor": { en: "Teleport: Monastery", de: "Teleport: Kloster", ru: "Телепорт: монастырь" },
	"teleport farma": { en: "Teleport: Farm", de: "Teleport: Farm", ru: "Телепорт: ферма" },
	"teleport xardas": { en: "Teleport: Xardas", de: "Teleport: Xardas", ru: "Телепорт: Ксардас" },
	"teleport przełęcz nw": { en: "Teleport: NW Pass", de: "Teleport: NW-Pass", ru: "Телепорт: северный перевал" },
	"teleport przełęcz ow": { en: "Teleport: OW Pass", de: "Teleport: OW-Pass", ru: "Телепорт: южный перевал" },
	"teleport zamek": { en: "Teleport: Castle", de: "Teleport: Burg", ru: "Телепорт: замок" },
	"teleport wieża demona": { en: "Teleport: Demon tower", de: "Teleport: Dämonenturm", ru: "Телепорт: башня демона" },
	"teleport karczma": { en: "Teleport: Tavern", de: "Teleport: Taverne", ru: "Телепорт: таверна" },
	"teleport dodatkowy": { en: "Teleport (spare)", de: "Zusätzlicher Teleport", ru: "Дополнительный телепорт" }
};

function translateRuneOrScroll(plName, prefix) {
	const clean = plName.toLowerCase().replace(new RegExp("^" + prefix + ":?\\s*", "i"), "");
	const data = RUNE_MAP[clean];
	if (!data) return null;
	return {
		en: prefix + ": " + data.en,
		de: (prefix === "Runa" ? "Rune" : "Schriftrolle") + ": " + data.de,
		ru: (prefix === "Runa" ? "Руна" : "Свиток") + ": " + data.ru
	};
}

function translate(pl, inst) {
	if (!pl) return null;
	const lower = pl.toLowerCase();
	if (DICT[lower]) return DICT[lower];
	if (inst.startsWith("ITRU_")) {
		const t = translateRuneOrScroll(pl, "Runa");
		if (t) return t;
	}
	if (inst.startsWith("ITSC_")) {
		const t = translateRuneOrScroll(pl, "Zwój");
		if (t) return t;
	}
	return null;
}

const buckets = {};
let missing = [];
for (const inst of schemeInstances) {
	const kind = classify(inst);
	if (!buckets[kind]) buckets[kind] = [];
	let pl, en, de, ru;
	if (OVERRIDE[inst]) {
		pl = OVERRIDE[inst].pl; en = OVERRIDE[inst].en; de = OVERRIDE[inst].de; ru = OVERRIDE[inst].ru;
	} else {
		const dd = dedMap.get(inst);
		pl = dd && dd.Name ? dd.Name : (schemeNames.get(inst) || inst);
		const t = translate(pl, inst);
		if (t) {
			en = t.en; de = t.de; ru = t.ru;
		} else {
			en = pl; de = pl; ru = pl;
			missing.push({ inst, pl });
		}
	}
	buckets[kind].push([inst, pl, en, de, ru]);
}

for (const rows of Object.values(buckets)) rows.sort((a, b) => a[0].localeCompare(b[0]));

function emit(rows) {
	const header = `(function () {
	if (!window.PhoenixI18n) return;

	const LANGS = ["pl", "en", "de", "ru"];
	const ROWS = [\n`;
	const body = rows.map(r => "\t\t[\"" + r[0] + "\", " + r.slice(1).map(JSON.stringify).join(", ") + "]").join(",\n");
	const footer = `\n\t];

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
`;
	return header + body + footer;
}

const filesPlan = {
	"weapons-1h": (buckets.weapons || []).filter(r => !/^(ITMW_2H_|ITMW_BARBARENSTREITAXT|ITMW_BERSERKERAXT|ITMW_DRACHENSCHNEIDE|ITMW_2H_BLESSED|ITMW_2H_OR|ITMW_HELLEBARDE|ITMW_ADDON_PIR2H|ITMW_ADDON_HACKER_2H|ITMW_ADDON_KEULE_2H|ITMW_ADDON_STAB|ITMW_RANGERSTAFF|ITMW_ROD)/.test(r[0])),
	"weapons-2h": (buckets.weapons || []).filter(r => /^(ITMW_2H_|ITMW_BARBARENSTREITAXT|ITMW_BERSERKERAXT|ITMW_DRACHENSCHNEIDE|ITMW_2H_BLESSED|ITMW_2H_OR|ITMW_HELLEBARDE|ITMW_ADDON_PIR2H|ITMW_ADDON_HACKER_2H|ITMW_ADDON_KEULE_2H|ITMW_ADDON_STAB|ITMW_RANGERSTAFF|ITMW_ROD)/.test(r[0])),
	"weapons-ranged": buckets.ranged || [],
	"armor": (buckets.armor || []).filter(r => !/HELM|HOOD/.test(r[0])),
	"helmets": (buckets.armor || []).filter(r => /HELM|HOOD/.test(r[0])),
	"shields": buckets.shields || [],
	"amulets": buckets.amulets || [],
	"rings": buckets.rings || [],
	"belts": buckets.belts || [],
	"potions": buckets.potions || [],
	"food": buckets.food || [],
	"herbs": buckets.herbs || [],
	"runes": buckets.runes || [],
	"scrolls": buckets.scrolls || [],
	"keys": buckets.keys || [],
	"documents": buckets.documents || [],
	"materials": buckets.materials || []
};

const outDir = "gamemodes/phoenix/web/shared/items";
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);
for (const f of fs.readdirSync(outDir)) fs.unlinkSync(path.join(outDir, f));

let total = 0;
for (const [name, rows] of Object.entries(filesPlan)) {
	if (rows.length === 0) continue;
	total += rows.length;
	fs.writeFileSync(path.join(outDir, name + ".i18n.js"), emit(rows), "utf8");
}

if (missing.length) {
	fs.writeFileSync("tools/i18n_missing.json", JSON.stringify(missing, null, 2));
	console.log("Missing translations:", missing.length, "(see tools/i18n_missing.json)");
}
console.log("Generated", Object.keys(filesPlan).filter(k => filesPlan[k].length).length, "files, total", total, "items");
