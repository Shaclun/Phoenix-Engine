(function (global) {
    "use strict";
    if (!global.PhoenixI18n || global.PhoenixI18n._questUiDictionary) return;
    global.PhoenixI18n._questUiDictionary = true;
    var langs = ["pl", "en", "de", "ru"];
    var rows = [
        ["quest.status.active", "Aktywne", "Active", "Aktiv", "Активно"],
        ["quest.status.completed", "Ukończone", "Completed", "Abgeschlossen", "Завершено"],
        ["quest.status.ready_to_turn_in", "Gotowe do oddania", "Ready to turn in", "Abgabebereit", "Готово к сдаче"],
        ["quest.status.reward_pending", "Oczekuje na nagrodę", "Reward pending", "Belohnung ausstehend", "Ожидает награды"],
        ["quest.status.failed", "Nieudane", "Failed", "Fehlgeschlagen", "Провалено"],
        ["quest.status.cancelled", "Anulowane", "Cancelled", "Abgebrochen", "Отменено"],
        ["quest.dialog.you", "Ty", "You", "Du", "Вы"],
        ["quest.dialog.choose", "Wybierz temat rozmowy.", "Choose a topic.", "Wähle ein Gesprächsthema.", "Выберите тему разговора."],
        ["quest.dialog.start", "Rozpocznij zadanie", "Start quest", "Quest beginnen", "Начать задание"],
        ["quest.dialog.learn", "Nauka", "Training", "Ausbildung", "Обучение"],
        ["quest.dialog.trade", "Handel", "Trade", "Handel", "Торговля"],
        ["quest.dialog.continue", "Kontynuuj zadanie", "Continue quest", "Quest fortsetzen", "Продолжить задание"],
        ["quest.dialog.empty", "Brak dostępnych odpowiedzi.", "No responses available.", "Keine Antworten verfügbar.", "Нет доступных ответов."],
        ["quest.log.choose", "Wybierz zadanie z listy.", "Choose a quest from the list.", "Wähle eine Quest aus der Liste.", "Выберите задание из списка."],
        ["quest.log.descriptionEmpty", "Brak dodatkowego opisu zadania.", "No additional quest description.", "Keine zusätzliche Questbeschreibung.", "Дополнительного описания нет."],
        ["quest.log.currentStage", "Aktualny etap", "Current stage", "Aktuelle Etappe", "Текущий этап"],
        ["quest.log.objectives", "Cele zadania", "Quest objectives", "Questziele", "Цели задания"],
        ["quest.log.objectivesEmpty", "Brak widocznych celów na tym etapie.", "No visible objectives at this stage.", "Keine sichtbaren Ziele in dieser Etappe.", "На этом этапе нет видимых целей."],
        ["quest.log.track", "Śledź zadanie", "Track quest", "Quest verfolgen", "Отслеживать"],
        ["quest.log.tracked", "Śledzone zadanie", "Tracked quest", "Verfolgte Quest", "Отслеживается"],
        ["quest.log.kicker", "DZIENNIK BOHATERA", "HERO'S JOURNAL", "HELDENTAGEBUCH", "ДНЕВНИК ГЕРОЯ"],
        ["quest.log.title", "Zadania", "Quests", "Quests", "Задания"],
        ["quest.log.journal", "Kronika wypraw", "Journey chronicle", "Reisechronik", "Хроника странствий"],
        ["quest.log.progress", "Postęp zadania", "Quest progress", "Questfortschritt", "Прогресс задания"],
        ["quest.log.activeStage", "Bieżący rozdział", "Current chapter", "Aktuelles Kapitel", "Текущая глава"],
        ["quest.log.emptyCategory", "Brak zadań w tej kategorii.", "No quests in this category.", "Keine Quests in dieser Kategorie.", "В этой категории нет заданий."],
        ["quest.error.operation", "Nie udało się wykonać operacji.", "The operation failed.", "Die Aktion ist fehlgeschlagen.", "Не удалось выполнить операцию."],
        ["quest.tracker.objective", "AKTUALNY CEL", "CURRENT OBJECTIVE", "AKTUELLES ZIEL", "ТЕКУЩАЯ ЦЕЛЬ"],
        ["quest.tracker.chapter", "BIEŻĄCY ROZDZIAŁ", "CURRENT CHAPTER", "AKTUELLES KAPITEL", "ТЕКУЩАЯ ГЛАВА"],
        ["quest.tracker.updated", "ZAKTUALIZOWANO", "UPDATED", "AKTUALISIERT", "ОБНОВЛЕНО"],
        ["quest.tracker.loadingWorld", "ŁADOWANIE ŚWIATA", "LOADING WORLD", "WELT WIRD GELADEN", "ЗАГРУЗКА МИРА"],
        ["quest.tracker.turnIn", "Wróć i oddaj zadanie", "Return and turn in the quest", "Kehre zurück und gib die Quest ab", "Вернитесь и сдайте задание"],
        ["quest.tracker.rewardPending", "Odbierz oczekującą nagrodę", "Claim the pending reward", "Hole die ausstehende Belohnung ab", "Получите ожидающую награду"],
        ["quest.tracker.noObjective", "Kontynuuj aktualny etap", "Continue the current stage", "Setze die aktuelle Etappe fort", "Продолжайте текущий этап"],
        ["quest.tracker.complete", "Ukończono", "Completed", "Abgeschlossen", "Завершено"]
    ];
    var dictionaries = {};
    langs.forEach(function (lang) { dictionaries[lang] = {}; });
    rows.forEach(function (row) { langs.forEach(function (lang, index) { dictionaries[lang][row[0]] = row[index + 1]; }); });
    var original = global.PhoenixI18n.t;
    global.PhoenixI18n.t = function (key) {
        var lang = global.PhoenixI18n.getLang ? global.PhoenixI18n.getLang() : "pl";
        if (dictionaries[lang] && key in dictionaries[lang]) return dictionaries[lang][key];
        if (key in dictionaries.pl) return dictionaries.pl[key];
        return original(key);
    };
})(window);