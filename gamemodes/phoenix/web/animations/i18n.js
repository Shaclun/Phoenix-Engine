(function (global) {
	"use strict";
	if (!global.PhoenixI18n || global.PhoenixI18n._animationsDictionary) return;
	global.PhoenixI18n._animationsDictionary = true;
	const languages = ["pl", "en", "de", "ru"];
	const rows = [
		["animations.kicker", "GESTY BOHATERA", "HERO GESTURES", "HELDENGESTEN", "ЖЕСТЫ ГЕРОЯ"],
		["animations.title", "Animacje", "Animations", "Animationen", "Анимации"],
		["animations.slots", "Przypisania klawiszy", "Key bindings", "Tastenbelegung", "Назначение клавиш"],
		["animations.slotsHint", "Przeciągnij animację na slot lub wybierz slot i użyj przycisku", "Drag an animation onto a slot or select a slot and use the button", "Ziehe eine Animation auf einen Platz oder wähle einen Platz", "Перетащите анимацию в слот или выберите слот"],
		["animations.slot.empty", "Pusty slot", "Empty slot", "Leerer Platz", "Пустой слот"],
		["animations.search", "Szukaj animacji...", "Search animations...", "Animationen suchen...", "Поиск анимаций..."],
		["animations.empty", "Brak animacji spełniających kryteria.", "No animations match the filters.", "Keine passenden Animationen.", "Нет подходящих анимаций."],
		["animations.footer", "N otwiera panel · F1–F12 odtwarza przypisane gesty · ruch przerywa animację", "N opens the panel · F1–F12 plays bound gestures · movement stops the animation", "N öffnet das Menü · F1–F12 spielt Gesten · Bewegung beendet die Animation", "N открывает меню · F1–F12 запускает жесты · движение останавливает анимацию"],
		["animations.category.all", "Wszystkie", "All", "Alle", "Все"],
		["animations.category.active", "Czynności", "Actions", "Aktionen", "Действия"],
		["animations.category.reaction", "Reakcje", "Reactions", "Reaktionen", "Реакции"],
		["animations.category.idle", "Pozycje", "Poses", "Posen", "Позы"],
		["animations.status.available", "Dostępna", "Available", "Verfügbar", "Доступно"],
		["animations.status.locked", "Zablokowana", "Locked", "Gesperrt", "Заблокировано"],
		["animations.detail.ready", "Animacja jest bezpieczna poza walką. Zostanie przerwana przez ruch, broń lub zmianę stanu.", "Safe outside combat. Movement, weapons or a state change will stop it.", "Außerhalb des Kampfes sicher. Bewegung, Waffen oder Zustandswechsel beenden sie.", "Безопасно вне боя. Движение, оружие или смена состояния остановят её."],
		["animations.detail.targetSlot", "Wybrany slot", "Selected slot", "Gewählter Platz", "Выбранный слот"],
		["animations.action.play", "Odtwórz", "Play", "Abspielen", "Запустить"],
		["animations.action.assign", "Przypisz", "Assign", "Zuweisen", "Назначить"],
		["animations.action.stop", "Zatrzymaj", "Stop", "Stoppen", "Остановить"],
		["animations.action.close", "Zamknij", "Close", "Schließen", "Закрыть"],
		["animations.action.clear", "Wyczyść slot", "Clear slot", "Platz leeren", "Очистить слот"],
		["animations.result.assigned", "Animacja została przypisana.", "Animation assigned.", "Animation zugewiesen.", "Анимация назначена."],
		["animations.result.playing", "Odtwarzanie animacji.", "Animation playing.", "Animation wird abgespielt.", "Анимация запущена."],
		["animations.result.stopped", "Animacja zatrzymana.", "Animation stopped.", "Animation gestoppt.", "Анимация остановлена."],
		["animations.reason.mobsi", "Ta animacja wymaga konkretnego obiektu świata i nie może być bezpiecznie uruchomiona ręcznie.", "This animation requires a world object and cannot be played safely by hand.", "Diese Animation benötigt ein Weltobjekt und kann nicht sicher manuell gestartet werden.", "Эта анимация требует объект мира и не может быть безопасно запущена вручную."],
		["animations.reason.weaponState", "Ta animacja wymaga kontrolowanego stanu broni.", "This animation requires a controlled weapon state.", "Diese Animation benötigt einen kontrollierten Waffenzustand.", "Эта анимация требует контролируемое состояние оружия."],
		["animations.reason.combatState", "Ta animacja należy do systemu walki.", "This animation belongs to the combat system.", "Diese Animation gehört zum Kampfsystem.", "Эта анимация относится к боевой системе."],
		["animations.reason.victimState", "Ta animacja zmienia postać w ofiarę obrażeń.", "This animation puts the character into a damage victim state.", "Diese Animation versetzt die Figur in einen Schadenszustand.", "Эта анимация переводит персонажа в состояние жертвы урона."],
		["animations.reason.bodyState", "Ta pozycja zmienia trwały stan ciała i jest zablokowana dla bezpieczeństwa.", "This pose changes a persistent body state and is locked for safety.", "Diese Pose ändert einen dauerhaften Körperzustand und ist gesperrt.", "Эта поза меняет постоянное состояние тела и заблокирована."],
		["animations.reason.deathState", "Ta animacja jest zarezerwowana dla systemu śmierci i odrodzenia.", "This animation is reserved for the death and revival system.", "Diese Animation ist für Tod und Wiederbelebung reserviert.", "Эта анимация зарезервирована для системы смерти и возрождения."]
		,["animations.error.disabled", "System animacji jest wyłączony.", "The animation system is disabled.", "Das Animationssystem ist deaktiviert.", "Система анимаций отключена."]
		,["animations.error.noCharacter", "Najpierw wybierz postać.", "Select a character first.", "Wähle zuerst eine Figur.", "Сначала выберите персонажа."]
		,["animations.error.disconnected", "Brak połączenia z postacią.", "Character connection unavailable.", "Charakterverbindung nicht verfügbar.", "Соединение с персонажем недоступно."]
		,["animations.error.dead", "Nie możesz użyć animacji w tym stanie.", "You cannot use animations in this state.", "In diesem Zustand sind Animationen nicht möglich.", "В этом состоянии нельзя использовать анимации."]
		,["animations.error.weapon", "Schowaj broń przed użyciem animacji.", "Sheathe your weapon before using an animation.", "Stecke die Waffe weg, bevor du eine Animation nutzt.", "Уберите оружие перед использованием анимации."]
		,["animations.error.combat", "Animacje są zablokowane podczas walki i chwilę po niej.", "Animations are locked during combat and briefly afterward.", "Animationen sind während und kurz nach dem Kampf gesperrt.", "Анимации заблокированы во время боя и вскоре после него."]
		,["animations.error.dialog", "Najpierw zakończ rozmowę.", "Finish the conversation first.", "Beende zuerst das Gespräch.", "Сначала завершите разговор."]
		,["animations.error.operation", "Najpierw zakończ bieżącą czynność.", "Finish the current action first.", "Beende zuerst die aktuelle Tätigkeit.", "Сначала завершите текущее действие."]
		,["animations.error.invalidAnimation", "Nieprawidłowa animacja.", "Invalid animation.", "Ungültige Animation.", "Недопустимая анимация."]
		,["animations.error.cooldown", "Odczekaj chwilę przed kolejną animacją.", "Wait a moment before playing another animation.", "Warte kurz vor der nächsten Animation.", "Подождите перед следующей анимацией."]
		,["animations.error.playFailed", "Nie udało się uruchomić animacji.", "The animation could not be played.", "Die Animation konnte nicht abgespielt werden.", "Не удалось запустить анимацию."]
		,["animations.error.unsafe", "Ta animacja jest zablokowana.", "This animation is locked.", "Diese Animation ist gesperrt.", "Эта анимация заблокирована."]
		,["animations.entry.pee", "Oddawanie moczu", "Pee", "Urinieren", "Справить нужду"]
		,["animations.entry.search", "Rozglądanie się", "Look around", "Umschauen", "Осмотреться"]
		,["animations.entry.wash", "Mycie się", "Wash", "Waschen", "Умыться"]
		,["animations.entry.plunder", "Przeszukiwanie", "Search ground", "Durchsuchen", "Обыскать"]
		,["animations.entry.pray", "Modlitwa", "Pray", "Beten", "Молиться"]
		,["animations.entry.prayIdol", "Modlitwa przy posągu", "Pray at idol", "Am Schrein beten", "Молитва у идола"]
		,["animations.entry.prayStand", "Modlitwa na stojąco", "Standing prayer", "Stehendes Gebet", "Молитва стоя"]
		,["animations.entry.inspectSword", "Oglądanie miecza", "Inspect sword", "Schwert ansehen", "Осмотреть меч"]
		,["animations.entry.checkSword", "Sprawdzanie miecza", "Check sword", "Schwert prüfen", "Проверить меч"]
		,["animations.entry.finish", "Dobijanie przeciwnika", "Finish enemy", "Gegner erledigen", "Добить врага"]
		,["animations.entry.train", "Trening mieczem", "Sword training", "Schwerttraining", "Тренировка с мечом"]
		,["animations.entry.cheer", "Dopingowanie", "Cheer", "Anfeuern", "Подбадривать"]
		,["animations.entry.cheerExcited", "Entuzjastyczny doping", "Excited cheer", "Begeistert anfeuern", "Радостно болеть"]
		,["animations.entry.cheerDisappointed", "Rozczarowanie walką", "Disappointed cheer", "Enttäuscht reagieren", "Разочарованно болеть"]
		,["animations.entry.magic1", "Ćwiczenie magii I", "Practice magic I", "Magie üben I", "Практика магии I"]
		,["animations.entry.magic2", "Ćwiczenie magii II", "Practice magic II", "Magie üben II", "Практика магии II"]
		,["animations.entry.magic3", "Ćwiczenie magii III", "Practice magic III", "Magie üben III", "Практика магии III"]
		,["animations.entry.magic4", "Ćwiczenie magii IV", "Practice magic IV", "Magie üben IV", "Практика магии IV"]
		,["animations.entry.dance1", "Taniec I", "Dance I", "Tanz I", "Танец I"]
		,["animations.entry.dance2", "Taniec II", "Dance II", "Tanz II", "Танец II"]
		,["animations.entry.dance3", "Taniec III", "Dance III", "Tanz III", "Танец III"]
		,["animations.entry.dance4", "Taniec IV", "Dance IV", "Tanz IV", "Танец IV"]
		,["animations.entry.dance5", "Taniec V", "Dance V", "Tanz V", "Танец V"]
		,["animations.entry.dance6", "Taniec VI", "Dance VI", "Tanz VI", "Танец VI"]
		,["animations.entry.dance7", "Taniec VII", "Dance VII", "Tanz VII", "Танец VII"]
		,["animations.entry.dance8", "Taniec VIII", "Dance VIII", "Tanz VIII", "Танец VIII"]
		,["animations.entry.dance9", "Taniec IX", "Dance IX", "Tanz IX", "Танец IX"]
		,["animations.entry.panic", "Panika w ogniu", "Fire panic", "Feuerpanik", "Паника в огне"]
		,["animations.entry.call", "Przywołanie", "Come here", "Herbeirufen", "Позвать"]
		,["animations.entry.greetCool", "Swobodne powitanie", "Casual greeting", "Lässiger Gruß", "Свободное приветствие"]
		,["animations.entry.greetNovice", "Powitanie nowicjusza", "Novice greeting", "Novizengruß", "Приветствие послушника"]
		,["animations.entry.greetGuard", "Powitanie strażnika", "Guard greeting", "Wächtergruß", "Приветствие стражника"]
		,["animations.entry.greetLeft", "Powitanie ze wskazaniem", "Pointing greeting", "Gruß mit Zeigen", "Приветствие с указанием"]
		,["animations.entry.greetRight", "Powitanie dłonią", "Waving greeting", "Gruß mit Winken", "Приветствие взмахом"]
		,["animations.entry.getLost1", "Przegonienie I", "Get lost I", "Verschwinde I", "Прогнать I"]
		,["animations.entry.getLost2", "Przegonienie II", "Get lost II", "Verschwinde II", "Прогнать II"]
		,["animations.entry.threaten", "Groźba", "Threaten", "Drohen", "Угрожать"]
		,["animations.entry.forgetIt", "Machnięcie ręką", "Forget it", "Abwinken", "Махнуть рукой"]
		,["animations.entry.dontKnow", "Wzruszenie ramion", "Shrug", "Achselzucken", "Пожать плечами"]
		,["animations.entry.no", "Zaprzeczenie", "No", "Nein", "Нет"]
		,["animations.entry.yes", "Potwierdzenie", "Yes", "Ja", "Да"]
		,["animations.entry.cannot", "Nie dam rady", "Cannot do it", "Geht nicht", "Не получится"]
		,["animations.entry.point", "Wskazywanie", "Point", "Zeigen", "Указать"]
		,["animations.entry.chestKick", "Kopnięcie skrzyni", "Kick chest", "Truhe treten", "Пнуть сундук"]
		,["animations.entry.noEntry", "Zakaz wstępu", "No entry", "Kein Zutritt", "Вход запрещён"]
		,["animations.entry.scratchHead", "Drapanie po głowie", "Scratch head", "Kopf kratzen", "Почесать голову"]
		,["animations.entry.scratchEggs", "Drapanie w kroczu", "Scratch groin", "Im Schritt kratzen", "Почесать пах"]
		,["animations.entry.scratchLeft", "Drapanie lewego ramienia", "Scratch left shoulder", "Linke Schulter kratzen", "Почесать левое плечо"]
		,["animations.entry.scratchRight", "Drapanie prawego ramienia", "Scratch right shoulder", "Rechte Schulter kratzen", "Почесать правое плечо"]
		,["animations.entry.legShake", "Otrzepanie nogi", "Shake leg", "Bein ausschütteln", "Стряхнуть ногу"]
		,["animations.entry.boringKick", "Nudne kopnięcie", "Bored kick", "Gelangweilter Tritt", "Ленивый пинок"]
		,["animations.entry.lookout", "Czujne rozglądanie", "Lookout", "Ausschau halten", "Осматриваться"]
		,["animations.entry.sit", "Siadanie", "Sit", "Hinsetzen", "Сесть"]
		,["animations.entry.lowGuard", "Strażnik — ręce na biodrach", "Guard — hands on hips", "Wache — Hände an der Hüfte", "Стражник — руки на поясе"]
		,["animations.entry.highGuard", "Strażnik — skrzyżowane ręce", "Guard — arms crossed", "Wache — Arme verschränkt", "Стражник — скрещённые руки"]
		,["animations.entry.sleepGround", "Sen na ziemi", "Sleep on ground", "Am Boden schlafen", "Спать на земле"]
		,["animations.entry.sleepBed", "Sen w łóżku", "Sleep in bed", "Im Bett schlafen", "Спать в кровати"]
		,["animations.entry.kneelChest", "Klękanie przy skrzyni", "Kneel at chest", "An Truhe knien", "Встать на колени у сундука"]
		,["animations.entry.woundedA", "Ranny I", "Wounded I", "Verwundet I", "Ранен I"]
		,["animations.entry.woundedB", "Ranny II", "Wounded II", "Verwundet II", "Ранен II"]
		,["animations.entry.deadB", "Martwy I", "Dead I", "Tot I", "Мёртв I"]
		,["animations.entry.dead", "Martwy II", "Dead II", "Tot II", "Мёртв II"]
	];
	const dictionaries = {};
	languages.forEach(function (language) { dictionaries[language] = {}; });
	rows.forEach(function (row) { languages.forEach(function (language, index) { dictionaries[language][row[0]] = row[index + 1]; }); });
	const original = global.PhoenixI18n.t;
	global.PhoenixI18n.t = function (key) {
		const language = global.PhoenixI18n.getLang ? global.PhoenixI18n.getLang() : "pl";
		if (dictionaries[language] && key in dictionaries[language]) return dictionaries[language][key];
		if (key in dictionaries.pl) return dictionaries.pl[key];
		return original(key);
	};
})(window);