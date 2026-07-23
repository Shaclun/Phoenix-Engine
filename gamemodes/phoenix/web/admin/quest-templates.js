(function (global) {
    "use strict";

    var LANGS = ["pl", "en", "de", "ru"];
    var ROWS = [
        ["admin.quest.templates.title", "Gotowe schematy questów", "Ready-made quest templates", "Fertige Questvorlagen", "Готовые шаблоны заданий"],
        ["admin.quest.templates.subtitle", "Wybierz archetyp z kompletną strukturą i immersyjnymi dialogami. Brakujące zasoby uzupełnisz w formularzu.", "Choose an archetype with a complete structure and immersive dialogue. Fill in missing resources in the form.", "Wähle einen Archetyp mit vollständiger Struktur und immersiven Dialogen. Fehlende Ressourcen ergänzt du im Formular.", "Выберите архетип с полной структурой и атмосферными диалогами. Недостающие ресурсы заполните в форме."],
        ["admin.quest.templates.apply", "Użyj schematu", "Use template", "Vorlage verwenden", "Использовать шаблон"],
        ["admin.quest.templates.blank.name", "Pusty quest", "Blank quest", "Leere Quest", "Пустое задание"],
        ["admin.quest.templates.blank.description", "Minimalny draft do zbudowania od podstaw.", "A minimal draft to build from scratch.", "Ein minimaler Entwurf zum Aufbau von Grund auf.", "Минимальный черновик для создания с нуля."],
        ["admin.quest.templates.blank.requirements", "Wymaga NPC i co najmniej jednego celu", "Requires an NPC and at least one objective", "Benötigt einen NPC und mindestens ein Ziel", "Требуется NPC и как минимум одна цель"],
        ["admin.quest.templates.hunt.name", "Kontrakt łowiecki", "Hunting contract", "Jagdauftrag", "Охотничий контракт"],
        ["admin.quest.templates.hunt.description", "Zleceniodawca prosi o zgładzenie zagrożenia i oczekuje raportu po wykonaniu pracy.", "A patron asks you to eliminate a threat and report back when the work is done.", "Ein Auftraggeber bittet dich, eine Bedrohung zu beseitigen und anschließend Bericht zu erstatten.", "Заказчик просит устранить угрозу и вернуться с докладом."],
        ["admin.quest.templates.hunt.requirements", "Wymaga zleceniodawcy i wyboru przeciwnika", "Requires a quest giver and enemy selection", "Benötigt einen Auftraggeber und die Auswahl eines Gegners", "Требуется заказчик и выбор противника"],
        ["admin.quest.templates.delivery.name", "Zaginiona przesyłka", "The missing shipment", "Die verlorene Lieferung", "Пропавший груз"],
        ["admin.quest.templates.delivery.description", "Odzyskaj rozproszony ładunek, a następnie dostarcz go wskazanej osobie.", "Recover the scattered cargo, then deliver it to the designated person.", "Berge die verstreute Ladung und bringe sie anschließend zur vorgesehenen Person.", "Соберите потерянный груз и доставьте его указанному человеку."],
        ["admin.quest.templates.delivery.requirements", "Wymaga zleceniodawcy, odbiorcy i przedmiotu", "Requires a quest giver, recipient and item", "Benötigt Auftraggeber, Empfänger und Gegenstand", "Требуется заказчик, получатель и предмет"],
        ["admin.quest.templates.expedition.name", "Ślady zapomnianej drogi", "Traces of the forgotten road", "Spuren des vergessenen Weges", "Следы забытой дороги"],
        ["admin.quest.templates.expedition.description", "Wyrusz na zwiad, odwiedź niebezpieczne miejsca i złóż szczegółowy raport.", "Scout the region, visit dangerous locations and deliver a detailed report.", "Erkunde die Region, besuche gefährliche Orte und erstatte ausführlich Bericht.", "Исследуйте местность, посетите опасные места и представьте подробный отчёт."],
        ["admin.quest.templates.expedition.requirements", "Wymaga zleceniodawcy i konfiguracji trzech stref", "Requires a quest giver and three configured zones", "Benötigt einen Auftraggeber und drei konfigurierte Zonen", "Требуется заказчик и настройка трёх зон"],
        ["admin.quest.templates.intrigue.name", "Cena milczenia", "The price of silence", "Der Preis des Schweigens", "Цена молчания"],
        ["admin.quest.templates.intrigue.description", "Rozbudowana rozmowa z decyzją, flagą fabularną i wyborem nagrody.", "An extended conversation with a decision, a story flag and a reward choice.", "Ein ausführliches Gespräch mit Entscheidung, Handlungsflag und Belohnungswahl.", "Развёрнутый диалог с решением, сюжетным флагом и выбором награды."],
        ["admin.quest.templates.intrigue.requirements", "Wymaga jednego zleceniodawcy", "Requires one quest giver", "Benötigt einen Auftraggeber", "Требуется один заказчик"],
        ["admin.quest.template.applied", "Utworzono nowy draft na podstawie schematu: {0}", "Created a new draft from template: {0}", "Neuer Entwurf aus Vorlage erstellt: {0}", "Создан новый черновик по шаблону: {0}"],
        ["admin.quest.template.blank.title", "Nowe zadanie", "New quest", "Neue Quest", "Новое задание"],
        ["admin.quest.template.blank.stage", "Pierwszy etap", "First stage", "Erste Etappe", "Первый этап"],
        ["admin.quest.template.hunt.title", "Bestia na trakcie", "The beast on the road", "Die Bestie am Weg", "Чудовище на тракте"],
        ["admin.quest.template.hunt.description", "Na uczęszczanym trakcie pojawiło się niebezpieczne stworzenie. Odszukaj je, zgładź i wróć po zapłatę.", "A dangerous creature has appeared on a busy road. Find it, kill it and return for payment.", "Auf einer belebten Straße ist eine gefährliche Kreatur aufgetaucht. Finde sie, töte sie und kehre für deine Belohnung zurück.", "На оживлённом тракте появилось опасное существо. Найдите его, убейте и вернитесь за наградой."],
        ["admin.quest.template.hunt.stage", "Tropienie zagrożenia", "Hunting the threat", "Jagd auf die Bedrohung", "Охота на угрозу"],
        ["admin.quest.template.hunt.objective", "Zgładź bestię terroryzującą trakt", "Slay the beast terrorising the road", "Erschlage die Bestie, die den Weg terrorisiert", "Убейте чудовище, терроризирующее тракт"],
        ["admin.quest.template.hunt.start.1", "Od kilku nocy żaden kupiec nie odważył się przejechać traktem. Coś poluje tam po zmroku.", "For several nights no merchant has dared use the road. Something hunts there after dark.", "Seit mehreren Nächten wagt sich kein Händler mehr auf den Weg. Nach Einbruch der Dunkelheit jagt dort etwas.", "Уже несколько ночей ни один торговец не решается выйти на тракт. После заката там кто-то охотится."],
        ["admin.quest.template.hunt.start.choice.1", "Mów dalej. Co widzieli świadkowie?", "Go on. What did the witnesses see?", "Sprich weiter. Was haben die Zeugen gesehen?", "Продолжай. Что видели свидетели?"],
        ["admin.quest.template.hunt.start.2", "Tylko ślady pazurów i porzucone wozy. Jeśli masz odwagę, zakończ to, zanim zginą kolejni ludzie.", "Only claw marks and abandoned wagons. If you have the courage, end this before more people die.", "Nur Krallenspuren und verlassene Wagen. Wenn du Mut hast, beende es, bevor weitere Menschen sterben.", "Лишь следы когтей и брошенные повозки. Если хватит смелости, покончи с этим, пока не погибли другие."],
        ["admin.quest.template.hunt.start.choice.2", "Znajdę tę bestię i uwolnię trakt.", "I will find the beast and clear the road.", "Ich werde die Bestie finden und den Weg sichern.", "Я найду чудовище и освобожу тракт."],
        ["admin.quest.template.hunt.turnin.1", "Widzę po twoim spojrzeniu, że trakt znów jest bezpieczny. Czy bestia nie żyje?", "I can tell by your eyes that the road is safe again. Is the beast dead?", "Ich sehe es an deinem Blick: Der Weg ist wieder sicher. Ist die Bestie tot?", "По твоему взгляду вижу: тракт снова безопасен. Чудовище мертво?"],
        ["admin.quest.template.hunt.turnin.choice", "Nie będzie już polować na podróżnych.", "It will hunt travellers no more.", "Sie wird keine Reisenden mehr jagen.", "Оно больше не будет охотиться на путников."],
        ["admin.quest.template.hunt.turnin.2", "Dobra robota. Kupcy zapamiętają, komu zawdzięczają spokojną drogę.", "Good work. The merchants will remember who restored peace to their road.", "Gute Arbeit. Die Händler werden sich merken, wem sie den sicheren Weg verdanken.", "Хорошая работа. Торговцы запомнят, кому обязаны безопасной дорогой."],
        ["admin.quest.template.hunt.turnin.finish", "Przyjmuję zapłatę.", "I accept the payment.", "Ich nehme die Bezahlung an.", "Я принимаю плату."]
    ];

    ROWS.push(
        ["admin.quest.template.delivery.title", "Zaginiona przesyłka", "The missing shipment", "Die verlorene Lieferung", "Пропавший груз"],
        ["admin.quest.template.delivery.description", "Odzyskaj zagubiony ładunek i przekaż go odbiorcy, zanim wieść o stracie dotrze do konkurencji.", "Recover the lost cargo and deliver it before word of the loss reaches the competition.", "Berge die verlorene Ladung und liefere sie ab, bevor die Konkurrenz davon erfährt.", "Верните потерянный груз и доставьте его, прежде чем о пропаже узнают конкуренты."],
        ["admin.quest.template.delivery.stage.collect", "Odzyskanie ładunku", "Recovering the cargo", "Bergung der Ladung", "Возвращение груза"],
        ["admin.quest.template.delivery.stage.deliver", "Dostarczenie przesyłki", "Delivering the shipment", "Auslieferung der Sendung", "Доставка груза"],
        ["admin.quest.template.delivery.objective.collect", "Odzyskaj rozproszony ładunek", "Recover the scattered cargo", "Berge die verstreute Ladung", "Соберите потерянный груз"],
        ["admin.quest.template.delivery.objective.deliver", "Przekaż odzyskany ładunek odbiorcy", "Give the recovered cargo to the recipient", "Übergib die geborgene Ladung dem Empfänger", "Передайте найденный груз получателю"],
        ["admin.quest.template.delivery.start.1", "Miał dziś dotrzeć ważny ładunek, lecz wóz znaleziono pusty przy rozstaju. Strażnicy przysięgają, że niczego nie widzieli.", "An important shipment was due today, but the wagon was found empty at the crossroads. The guards swear they saw nothing.", "Heute sollte eine wichtige Lieferung eintreffen, doch der Wagen wurde leer an der Kreuzung gefunden. Die Wachen schwören, nichts gesehen zu haben.", "Сегодня должен был прибыть важный груз, но повозку нашли пустой у развилки. Стражники клянутся, что ничего не видели."],
        ["admin.quest.template.delivery.start.choice.1", "Kto miał odebrać przesyłkę?", "Who was meant to receive it?", "Wer sollte die Lieferung erhalten?", "Кто должен был получить груз?"],
        ["admin.quest.template.delivery.start.2", "Zaufany człowiek po drugiej stronie miasta. Odzyskaj towar i oddaj go bez rozgłosu. Nie możemy pozwolić sobie na kolejny skandal.", "A trusted contact across town. Recover the goods and deliver them quietly. We cannot afford another scandal.", "Ein vertrauenswürdiger Kontakt am anderen Ende der Stadt. Berge die Ware und liefere sie unauffällig. Einen weiteren Skandal können wir uns nicht leisten.", "Надёжный человек на другом конце города. Верните товар и доставьте его без шума. Ещё один скандал нам ни к чему."],
        ["admin.quest.template.delivery.start.choice.2", "Odzyskam ładunek i dopilnuję dostawy.", "I will recover the cargo and see it delivered.", "Ich berge die Ladung und sorge für ihre Auslieferung.", "Я верну груз и прослежу за доставкой."],
        ["admin.quest.template.delivery.continue", "Hasło? Nie przyjmuję przesyłek od nieznajomych.", "The password? I do not accept packages from strangers.", "Das Kennwort? Ich nehme keine Lieferungen von Fremden an.", "Пароль? Я не принимаю посылки от незнакомцев."],
        ["admin.quest.template.delivery.continue.choice", "Przynoszę to, co zaginęło na rozstaju.", "I bring what went missing at the crossroads.", "Ich bringe, was an der Kreuzung verloren ging.", "Я принёс то, что пропало у развилки."],
        ["admin.quest.template.delivery.turnin", "Ładunek jest kompletny. Dobra robota — a teraz zapomnij, dla kogo ją wykonałeś.", "The shipment is complete. Good work — now forget who you did it for.", "Die Lieferung ist vollständig. Gute Arbeit — und nun vergiss, für wen du sie erledigt hast.", "Груз в полном составе. Хорошая работа — а теперь забудь, для кого ты её выполнил."],
        ["admin.quest.template.delivery.turnin.choice", "Nasza umowa jest zakończona.", "Our agreement is concluded.", "Unsere Abmachung ist erfüllt.", "Наш договор исполнен."],
        ["admin.quest.template.expedition.title", "Ślady zapomnianej drogi", "Traces of the forgotten road", "Spuren des vergessenen Weges", "Следы забытой дороги"],
        ["admin.quest.template.expedition.description", "Sprawdź trzy punkty dawnego szlaku i wróć z wiadomością, czy droga może znów służyć podróżnym.", "Inspect three points along the old route and report whether travellers can use it again.", "Untersuche drei Punkte entlang der alten Route und berichte, ob Reisende sie wieder nutzen können.", "Осмотрите три точки старого пути и доложите, можно ли снова открыть его для путников."],
        ["admin.quest.template.expedition.stage", "Zwiad na dawnym szlaku", "Scouting the old route", "Erkundung der alten Route", "Разведка старого пути"],
        ["admin.quest.template.expedition.objective.1", "Odszukaj początek zapomnianego szlaku", "Find the beginning of the forgotten route", "Finde den Anfang des vergessenen Weges", "Найдите начало забытого пути"],
        ["admin.quest.template.expedition.objective.2", "Zbadaj opuszczony posterunek", "Inspect the abandoned outpost", "Untersuche den verlassenen Außenposten", "Исследуйте заброшенный пост"],
        ["admin.quest.template.expedition.objective.3", "Dotrzyj do końca dawnej drogi", "Reach the end of the old road", "Erreiche das Ende des alten Weges", "Доберитесь до конца старой дороги"],
        ["admin.quest.template.expedition.start.1", "Stare mapy wspominają drogę krótszą o dwa dni marszu. Nikt jednak nie wrócił stamtąd od wielu lat.", "Old maps show a road that saves two days of travel. Yet no one has returned from it in years.", "Alte Karten zeigen einen Weg, der zwei Reisetage spart. Doch seit Jahren ist niemand von dort zurückgekehrt.", "На старых картах есть дорога, сокращающая путь на два дня. Но уже много лет никто оттуда не возвращался."],
        ["admin.quest.template.expedition.start.choice.1", "Czego mam tam szukać?", "What should I look for there?", "Wonach soll ich dort suchen?", "Что мне там искать?"],
        ["admin.quest.template.expedition.start.2", "Śladów osuwisk, bandytów i wszystkiego, co zamknęło szlak. Nie szukam bohatera — potrzebuję kogoś, kto wróci i opowie prawdę.", "Signs of landslides, bandits and whatever closed the route. I do not need a hero — I need someone who returns and tells the truth.", "Spuren von Erdrutschen, Banditen und allem, was den Weg versperrt hat. Ich brauche keinen Helden — ich brauche jemanden, der zurückkehrt und die Wahrheit berichtet.", "Следы обвалов, разбойников и всего, что закрыло путь. Мне не нужен герой — нужен тот, кто вернётся и расскажет правду."],
        ["admin.quest.template.expedition.start.choice.2", "Przejdę szlak i wrócę z raportem.", "I will walk the route and return with a report.", "Ich werde den Weg begehen und mit einem Bericht zurückkehren.", "Я пройду этот путь и вернусь с докладом."],
        ["admin.quest.template.expedition.turnin.1", "Wróciłeś. To już więcej, niż udało się poprzednim zwiadowcom. Co znalazłeś?", "You returned. That is already more than the previous scouts managed. What did you find?", "Du bist zurück. Das ist bereits mehr, als die früheren Späher geschafft haben. Was hast du gefunden?", "Ты вернулся. Это уже больше, чем удалось прежним разведчикам. Что ты обнаружил?"],
        ["admin.quest.template.expedition.turnin.choice", "Szlak zbadałem od początku do końca. Oto mój raport.", "I inspected the route from beginning to end. Here is my report.", "Ich habe den Weg von Anfang bis Ende untersucht. Hier ist mein Bericht.", "Я обследовал путь от начала до конца. Вот мой отчёт."],
        ["admin.quest.template.expedition.turnin.2", "Dzięki tym informacjom nikt nie wyruszy tam na ślepo. Dobra robota.", "With this information no one will venture there blindly. Good work.", "Dank dieser Informationen wird sich niemand mehr blindlings dorthin wagen. Gute Arbeit.", "Теперь никто не отправится туда вслепую. Хорошая работа."],
        ["admin.quest.template.expedition.turnin.finish", "Oby droga znów służyła ludziom.", "May the road serve the people again.", "Möge der Weg den Menschen wieder dienen.", "Пусть дорога снова служит людям."]
    );

    ROWS.push(
        ["admin.quest.template.intrigue.title", "Cena milczenia", "The price of silence", "Der Preis des Schweigens", "Цена молчания"],
        ["admin.quest.template.intrigue.description", "Poznaj tajemnicę zleceniodawcy i zdecyduj, czy przyjąć zapłatę za milczenie, czy odrzucić układ.", "Learn the patron's secret and decide whether to accept payment for silence or reject the bargain.", "Erfahre das Geheimnis des Auftraggebers und entscheide, ob du Schweigegeld annimmst oder den Handel ablehnst.", "Узнайте тайну заказчика и решите, принять ли плату за молчание или отказаться от сделки."],
        ["admin.quest.template.intrigue.stage", "Niewygodna prawda", "An inconvenient truth", "Eine unbequeme Wahrheit", "Неудобная правда"],
        ["admin.quest.template.intrigue.objective", "Wysłuchaj całej historii", "Hear the whole story", "Höre die ganze Geschichte", "Выслушайте всю историю"],
        ["admin.quest.template.intrigue.start.1", "Zanim odpowiesz, wiedz jedno: ta rozmowa może zaszkodzić ludziom potężniejszym od nas obojga.", "Before you answer, know this: this conversation could harm people more powerful than either of us.", "Bevor du antwortest, wisse eines: Dieses Gespräch könnte Menschen schaden, die mächtiger sind als wir beide.", "Прежде чем ответишь, знай: этот разговор может навредить людям, куда более могущественным, чем мы оба."],
        ["admin.quest.template.intrigue.start.choice.ask", "Skoro ryzyko jest tak wielkie, dlaczego mówisz właśnie mnie?", "If the risk is so great, why tell me?", "Wenn das Risiko so groß ist, warum erzählst du es gerade mir?", "Если риск так велик, почему ты рассказываешь это мне?"],
        ["admin.quest.template.intrigue.start.choice.leave", "Nie chcę mieć z tym nic wspólnego.", "I want nothing to do with this.", "Ich will damit nichts zu tun haben.", "Я не хочу иметь с этим ничего общего."],
        ["admin.quest.template.intrigue.start.2", "Bo nie należysz jeszcze do żadnej ze stron. Widziałem, jak słuchasz, zanim wyciągniesz broń — dziś to rzadsze niż odwaga.", "Because you do not yet belong to either side. I have seen you listen before drawing steel — these days that is rarer than courage.", "Weil du noch keiner Seite angehörst. Ich habe gesehen, dass du zuhörst, bevor du die Waffe ziehst — heutzutage ist das seltener als Mut.", "Потому что ты пока не принадлежишь ни одной стороне. Я видел, как ты слушаешь, прежде чем хвататься за оружие — нынче это реже храбрости."],
        ["admin.quest.template.intrigue.start.choice.accept", "Opowiedz mi wszystko. Zachowam tę wiedzę dla siebie.", "Tell me everything. I will keep this knowledge to myself.", "Erzähl mir alles. Ich werde dieses Wissen für mich behalten.", "Расскажи всё. Я сохраню эту тайну."],
        ["admin.quest.template.intrigue.start.choice.refuse", "Prawda nie należy do tego, kto płaci najwięcej.", "Truth does not belong to the highest bidder.", "Die Wahrheit gehört nicht dem Meistbietenden.", "Правда не принадлежит тому, кто больше заплатит."],
        ["admin.quest.template.intrigue.turnin.1", "A więc znasz już prawdę. Pozostaje tylko pytanie: ile warte jest twoje milczenie?", "So now you know the truth. Only one question remains: what is your silence worth?", "Nun kennst du also die Wahrheit. Es bleibt nur eine Frage: Was ist dein Schweigen wert?", "Теперь ты знаешь правду. Остался один вопрос: сколько стоит твоё молчание?"],
        ["admin.quest.template.intrigue.turnin.choice.gold", "Milczenie ma swoją cenę. Przyjmuję złoto.", "Silence has its price. I accept the gold.", "Schweigen hat seinen Preis. Ich nehme das Gold.", "У молчания есть цена. Я принимаю золото."],
        ["admin.quest.template.intrigue.turnin.choice.favor", "Zachowaj złoto. Będziesz mi winien przysługę.", "Keep the gold. You will owe me a favour.", "Behalt das Gold. Du wirst mir einen Gefallen schulden.", "Оставь золото себе. Ты будешь должен мне услугу."],
        ["admin.quest.template.intrigue.reward.gold", "Sakwa za milczenie", "A purse for silence", "Ein Beutel für Schweigen", "Кошель за молчание"],
        ["admin.quest.template.intrigue.reward.exp", "Wdzięczność informatora", "The informant's gratitude", "Dankbarkeit des Informanten", "Благодарность осведомителя"],
        ["admin.quest.ui.new", "Nowy quest", "New quest", "Neue Quest", "Новое задание"],
        ["admin.quest.ui.refresh", "Odśwież", "Refresh", "Aktualisieren", "Обновить"],
        ["admin.quest.ui.legacyReport", "Raport legacy", "Legacy report", "Legacy-Bericht", "Отчёт legacy"],
        ["admin.quest.ui.workflow", "Draft → walidacja → publikacja niezmiennej rewizji", "Draft → validation → immutable revision publication", "Entwurf → Validierung → Veröffentlichung einer unveränderlichen Revision", "Черновик → проверка → публикация неизменяемой ревизии"],
        ["admin.quest.ui.search", "Szukaj kodu lub tytułu", "Search code or title", "Code oder Titel suchen", "Искать по коду или названию"],
        ["admin.quest.ui.allStatuses", "Wszystkie statusy", "All statuses", "Alle Status", "Все статусы"],
        ["admin.quest.ui.emptyList", "Brak definicji questów.", "No quest definitions.", "Keine Questdefinitionen.", "Нет определений заданий."],
        ["admin.quest.ui.choose", "Wybierz quest albo utwórz nowy draft.", "Select a quest or create a new draft.", "Wähle eine Quest oder erstelle einen neuen Entwurf.", "Выберите задание или создайте новый черновик."],
        ["admin.quest.ui.code", "Kod", "Code", "Code", "Код"],
        ["admin.quest.ui.status", "Status", "Status", "Status", "Статус"],
        ["admin.quest.ui.form", "Formularz", "Form", "Formular", "Форма"],
        ["admin.quest.ui.json", "JSON", "JSON", "JSON", "JSON"],
        ["admin.quest.ui.unsaved", "Niezapisane zmiany", "Unsaved changes", "Ungespeicherte Änderungen", "Несохранённые изменения"],
        ["admin.quest.ui.saved", "Zapisano", "Saved", "Gespeichert", "Сохранено"],
        ["admin.quest.ui.validation", "Waliduj przed publikacją", "Validate before publication", "Vor Veröffentlichung validieren", "Проверить перед публикацией"],
        ["admin.quest.ui.saveDraft", "Zapisz draft", "Save draft", "Entwurf speichern", "Сохранить черновик"],
        ["admin.quest.ui.publish", "Publikuj", "Publish", "Veröffentlichen", "Опубликовать"],
        ["admin.quest.ui.archive", "Archiwizuj", "Archive", "Archivieren", "Архивировать"],
        ["admin.quest.ui.clone", "Klonuj", "Clone", "Klonen", "Клонировать"],
        ["admin.quest.ui.remove", "Usuń", "Remove", "Entfernen", "Удалить"],
        ["admin.quest.ui.close", "Zamknij", "Close", "Schließen", "Закрыть"],
        ["admin.quest.ui.applyTemplateConfirmTitle", "Zastąpić bieżący draft?", "Replace the current draft?", "Aktuellen Entwurf ersetzen?", "Заменить текущий черновик?"],
        ["admin.quest.ui.applyTemplateConfirmMessage", "Bieżąca, niezapisana zawartość zostanie zastąpiona wybranym schematem.", "The current unsaved content will be replaced with the selected template.", "Der aktuelle ungespeicherte Inhalt wird durch die ausgewählte Vorlage ersetzt.", "Текущее несохранённое содержимое будет заменено выбранным шаблоном."],
        ["admin.quest.ui.applyTemplateConfirm", "Zastosuj schemat", "Apply template", "Vorlage anwenden", "Применить шаблон"]
    );


    var DICTIONARIES = {};
    LANGS.forEach(function (lang) { DICTIONARIES[lang] = {}; });
    ROWS.forEach(function (row) {
        LANGS.forEach(function (lang, index) { DICTIONARIES[lang][row[0]] = row[index + 1]; });
    });

    function translate(key) {
        var lang = global.PhoenixI18n && global.PhoenixI18n.getLang ? global.PhoenixI18n.getLang() : "pl";
        var current = DICTIONARIES[lang] || DICTIONARIES.pl;
        return current[key] || DICTIONARIES.pl[key] || key;
    }

    if (global.PhoenixI18n && !global.PhoenixI18n._questTemplateHook) {
        global.PhoenixI18n._questTemplateHook = true;
        var originalTranslate = global.PhoenixI18n.t;
        global.PhoenixI18n.t = function (key) {
            var value = translate(key);
            if (value !== key) return value;
            return typeof originalTranslate === "function" ? originalTranslate(key) : key;
        };
    }

    function text(suffix) { return translate("admin.quest.template." + suffix); }
    function timestampCode(prefix) { return prefix + "_" + String(Date.now()).slice(-6); }
    function binding(key, role) { return { key: key, role: role, refType: "spawn", refValue: "", markerOffset: 165 }; }
    function choice(key, value, target, actions) { return { key: key, text: value, target: target || "", actions: actions || [] }; }
    function node(key, speaker, value, choices) { return { key: key, speaker: speaker, text: value, choices: choices }; }
    function graph(key, bindingKey, mode, startNodeKey, nodes) { return { key: key, bindingKey: bindingKey, mode: mode, startNodeKey: startNodeKey, nodes: nodes }; }
    function reward(key, type, amount, label, choiceGroup) {
        var value = { key: key, type: type, amount: amount };
        if (label) value.label = label;
        if (choiceGroup) value.choiceGroup = choiceGroup;
        return value;
    }
    function editor(code, content) { return { id: 0, code: timestampCode(code), status: "draft", lockVersion: 0, content: content }; }

    function blank() {
        return editor("NEW_QUEST", {
            metadata: { title: text("blank.title"), description: "" },
            availability: null,
            startStageKey: "start",
            npcBindings: [],
            stages: [{ key: "start", title: text("blank.stage"), type: "objectives", objectiveMode: "all", objectives: [], transitions: [], markerBindings: [], terminal: "success" }],
            dialogGraphs: [],
            rewards: []
        });
    }

    function hunt() {
        return editor("HUNT_CONTRACT", {
            metadata: { title: text("hunt.title"), description: text("hunt.description") },
            availability: null,
            startStageKey: "hunt",
            npcBindings: [binding("giver", "giver")],
            stages: [{
                key: "hunt",
                title: text("hunt.stage"),
                type: "objectives",
                objectiveMode: "all",
                objectives: [{ key: "kill_threat", type: "kill", required: 1, visible: true, label: text("hunt.objective"), config: { refType: "instance", refValue: "" } }],
                transitions: [],
                markerBindings: [],
                terminal: "success",
                turnInBindingKey: "giver"
            }],
            dialogGraphs: [
                graph("hunt_start", "giver", "start", "hunt_start_1", [
                    node("hunt_start_1", "npc", text("hunt.start.1"), [choice("ask_witnesses", text("hunt.start.choice.1"), "hunt_start_2")]),
                    node("hunt_start_2", "npc", text("hunt.start.2"), [choice("accept_hunt", text("hunt.start.choice.2"))])
                ]),
                graph("hunt_turn_in", "giver", "turn_in", "hunt_turn_1", [
                    node("hunt_turn_1", "npc", text("hunt.turnin.1"), [choice("confirm_kill", text("hunt.turnin.choice"), "hunt_turn_2")]),
                    node("hunt_turn_2", "npc", text("hunt.turnin.2"), [choice("finish_hunt", text("hunt.turnin.finish"))])
                ])
            ],
            rewards: [reward("hunt_experience", "experience", 250), reward("hunt_payment", "currency", 150)]
        });
    }

    function delivery() {
        return editor("MISSING_SHIPMENT", {
            metadata: { title: text("delivery.title"), description: text("delivery.description") },
            availability: null,
            startStageKey: "recover_cargo",
            npcBindings: [binding("giver", "giver"), binding("recipient", "turn_in")],
            stages: [
                {
                    key: "recover_cargo",
                    title: text("delivery.stage.collect"),
                    type: "objectives",
                    objectiveMode: "all",
                    objectives: [{ key: "collect_cargo", type: "collect", required: 3, visible: true, label: text("delivery.objective.collect"), config: { instance: "" } }],
                    transitions: [{ key: "cargo_recovered", target: "deliver_cargo", condition: null }],
                    markerBindings: []
                },
                {
                    key: "deliver_cargo",
                    title: text("delivery.stage.deliver"),
                    type: "objectives",
                    objectiveMode: "all",
                    objectives: [{ key: "deliver_cargo_items", type: "deliver", required: 3, visible: true, label: text("delivery.objective.deliver"), config: { instance: "" } }],
                    transitions: [],
                    markerBindings: [{ bindingKey: "recipient", markerType: "continue" }],
                    terminal: "success",
                    turnInBindingKey: "recipient"
                }
            ],
            dialogGraphs: [
                graph("delivery_start", "giver", "start", "delivery_start_1", [
                    node("delivery_start_1", "npc", text("delivery.start.1"), [choice("ask_recipient", text("delivery.start.choice.1"), "delivery_start_2")]),
                    node("delivery_start_2", "npc", text("delivery.start.2"), [choice("accept_delivery", text("delivery.start.choice.2"))])
                ]),
                graph("delivery_handover", "recipient", "continue", "delivery_handover_1", [
                    node("delivery_handover_1", "npc", text("delivery.continue"), [choice("hand_over_cargo", text("delivery.continue.choice"), "", [{ type: "deliver", instance: "", amount: 3 }])])
                ]),
                graph("delivery_turn_in", "recipient", "turn_in", "delivery_turn_1", [
                    node("delivery_turn_1", "npc", text("delivery.turnin"), [choice("finish_delivery", text("delivery.turnin.choice"))])
                ])
            ],
            rewards: [reward("delivery_experience", "experience", 300), reward("delivery_payment", "currency", 200)]
        });
    }


    function expedition() {
        return editor("FORGOTTEN_ROAD", {
            metadata: { title: text("expedition.title"), description: text("expedition.description") },
            availability: null,
            startStageKey: "scout_route",
            npcBindings: [binding("giver", "giver")],
            stages: [{
                key: "scout_route",
                title: text("expedition.stage"),
                type: "objectives",
                objectiveMode: "all",
                objectives: [
                    { key: "reach_route_start", type: "reach", required: 1, visible: true, label: text("expedition.objective.1"), config: { zoneKey: "forgotten_road_start", world: "", x: 0, y: 0, z: 0, radius: 0 } },
                    { key: "reach_old_outpost", type: "reach", required: 1, visible: true, label: text("expedition.objective.2"), config: { zoneKey: "forgotten_road_outpost", world: "", x: 0, y: 0, z: 0, radius: 0 } },
                    { key: "reach_route_end", type: "reach", required: 1, visible: true, label: text("expedition.objective.3"), config: { zoneKey: "forgotten_road_end", world: "", x: 0, y: 0, z: 0, radius: 0 } }
                ],
                transitions: [],
                markerBindings: [],
                terminal: "success",
                turnInBindingKey: "giver"
            }],
            dialogGraphs: [
                graph("expedition_start", "giver", "start", "expedition_start_1", [
                    node("expedition_start_1", "npc", text("expedition.start.1"), [choice("ask_mission", text("expedition.start.choice.1"), "expedition_start_2")]),
                    node("expedition_start_2", "npc", text("expedition.start.2"), [choice("accept_expedition", text("expedition.start.choice.2"))])
                ]),
                graph("expedition_turn_in", "giver", "turn_in", "expedition_turn_1", [
                    node("expedition_turn_1", "npc", text("expedition.turnin.1"), [choice("give_report", text("expedition.turnin.choice"), "expedition_turn_2")]),
                    node("expedition_turn_2", "npc", text("expedition.turnin.2"), [choice("finish_expedition", text("expedition.turnin.finish"))])
                ])
            ],
            rewards: [reward("expedition_experience", "experience", 400), { key: "route_discovered", type: "flag", value: "1" }]
        });
    }

    function intrigue() {
        return editor("PRICE_OF_SILENCE", {
            metadata: { title: text("intrigue.title"), description: text("intrigue.description") },
            availability: null,
            startStageKey: "hear_secret",
            npcBindings: [binding("giver", "giver")],
            stages: [{
                key: "hear_secret",
                title: text("intrigue.stage"),
                type: "objectives",
                objectiveMode: "all",
                objectives: [{ key: "hear_story", type: "talk", required: 1, visible: true, label: text("intrigue.objective"), config: { refType: "spawn", refValue: "" } }],
                transitions: [],
                markerBindings: [],
                terminal: "success",
                turnInBindingKey: "giver"
            }],
            dialogGraphs: [
                graph("intrigue_start", "giver", "start", "intrigue_start_1", [
                    node("intrigue_start_1", "npc", text("intrigue.start.1"), [
                        choice("ask_why_me", text("intrigue.start.choice.ask"), "intrigue_start_2"),
                        choice("listen_carefully", text("intrigue.start.choice.leave"), "intrigue_start_2")
                    ]),
                    node("intrigue_start_2", "npc", text("intrigue.start.2"), [
                        choice("promise_silence", text("intrigue.start.choice.accept"), "", [{ type: "setFlag", key: "secret_kept", value: "1" }]),
                        choice("reject_bargain", text("intrigue.start.choice.refuse"), "", [{ type: "setFlag", key: "secret_kept", value: "0" }])
                    ])
                ]),
                graph("intrigue_turn_in", "giver", "turn_in", "intrigue_turn_1", [
                    node("intrigue_turn_1", "npc", text("intrigue.turnin.1"), [
                        choice("choose_gold", text("intrigue.turnin.choice.gold")),
                        choice("choose_favour", text("intrigue.turnin.choice.favor"))
                    ])
                ])
            ],
            rewards: [
                reward("silence_gold", "currency", 300, text("intrigue.reward.gold"), "silence_reward"),
                reward("informant_gratitude", "experience", 450, text("intrigue.reward.exp"), "silence_reward")
            ]
        });
    }

    var FACTORIES = { blank: blank, hunt: hunt, delivery: delivery, expedition: expedition, intrigue: intrigue };
    var DESCRIPTORS = [
        { id: "blank", icon: "◇", nameKey: "admin.quest.templates.blank.name", descriptionKey: "admin.quest.templates.blank.description", requirementsKey: "admin.quest.templates.blank.requirements" },
        { id: "hunt", icon: "⚔", nameKey: "admin.quest.templates.hunt.name", descriptionKey: "admin.quest.templates.hunt.description", requirementsKey: "admin.quest.templates.hunt.requirements" },
        { id: "delivery", icon: "▣", nameKey: "admin.quest.templates.delivery.name", descriptionKey: "admin.quest.templates.delivery.description", requirementsKey: "admin.quest.templates.delivery.requirements" },
        { id: "expedition", icon: "⌖", nameKey: "admin.quest.templates.expedition.name", descriptionKey: "admin.quest.templates.expedition.description", requirementsKey: "admin.quest.templates.expedition.requirements" },
        { id: "intrigue", icon: "◆", nameKey: "admin.quest.templates.intrigue.name", descriptionKey: "admin.quest.templates.intrigue.description", requirementsKey: "admin.quest.templates.intrigue.requirements" }
    ];

    global.PhoenixQuestTemplates = {
        list: function () { return DESCRIPTORS.slice(); },
        create: function (id) { return id in FACTORIES ? FACTORIES[id]() : null; },
        t: translate,
        format: function (key) {
            var value = translate(key);
            for (var i = 1; i < arguments.length; i += 1) value = value.split("{" + (i - 1) + "}").join(arguments[i] == null ? "" : String(arguments[i]));
            return value;
        }
    };
})(window);


(function (global) {
    var rows = [
        ["admin.quest.objective.talk", "Porozmawiaj z NPC", "Talk to an NPC", "Sprich mit einem NPC", "Поговорить с NPC"],
        ["admin.quest.objective.kill", "Zabij NPC", "Kill an NPC", "Töte einen NPC", "Убить NPC"],
        ["admin.quest.objective.collect", "Zbierz przedmioty", "Collect items", "Sammle Gegenstände", "Собрать предметы"],
        ["admin.quest.objective.deliver", "Dostarcz przedmioty", "Deliver items", "Liefere Gegenstände", "Доставить предметы"],
        ["admin.quest.objective.reach", "Dotrzyj do miejsca", "Reach a location", "Erreiche einen Ort", "Добраться до места"],
        ["admin.quest.objective.interact", "Wejdź w interakcję", "Interact", "Interagiere", "Взаимодействовать"],
        ["admin.quest.objective.custom_event", "Zdarzenie niestandardowe", "Custom event", "Benutzerdefiniertes Ereignis", "Пользовательское событие"],
        ["admin.quest.reward.experience", "Doświadczenie", "Experience", "Erfahrung", "Опыт"],
        ["admin.quest.reward.currency", "Waluta", "Currency", "Währung", "Валюта"],
        ["admin.quest.reward.item", "Przedmiot", "Item", "Gegenstand", "Предмет"],
        ["admin.quest.reward.statistic", "Statystyka", "Statistic", "Attribut", "Характеристика"],
        ["admin.quest.reward.flag", "Flaga postaci", "Character flag", "Charakterflag", "Флаг персонажа"],
        ["admin.quest.role.giver", "Zleceniodawca", "Quest giver", "Auftraggeber", "Заказчик"],
        ["admin.quest.role.turn_in", "NPC oddania", "Turn-in NPC", "Abgabe-NPC", "NPC для сдачи"],
        ["admin.quest.role.talk_target", "Cel rozmowy", "Conversation target", "Gesprächsziel", "Цель разговора"],
        ["admin.quest.role.interact_target", "Cel interakcji", "Interaction target", "Interaktionsziel", "Цель взаимодействия"],
        ["admin.quest.ref.spawn", "Konkretny NPC z bazy", "Specific database NPC", "Bestimmter Datenbank-NPC", "Конкретный NPC из базы"],
        ["admin.quest.ref.preset", "Preset NPC", "NPC preset", "NPC-Vorlage", "Пресет NPC"],
        ["admin.quest.ref.instance", "Instancja", "Instance", "Instanz", "Экземпляр"],
        ["admin.quest.ref.tag", "Tag", "Tag", "Tag", "Тег"],
        ["admin.quest.stat.strength", "Siła", "Strength", "Stärke", "Сила"],
        ["admin.quest.stat.dexterity", "Zręczność", "Dexterity", "Geschicklichkeit", "Ловкость"],
        ["admin.quest.stat.learnPoints", "Punkty nauki", "Learning points", "Lernpunkte", "Очки обучения"],
        ["admin.quest.stat.hpMax", "Maksymalne zdrowie", "Maximum health", "Maximale Gesundheit", "Максимальное здоровье"],
        ["admin.quest.stat.manaMax", "Maksymalna mana", "Maximum mana", "Maximales Mana", "Максимальная мана"],
        ["admin.quest.objectiveMode.all", "Wszystkie cele", "All objectives", "Alle Ziele", "Все цели"],
        ["admin.quest.objectiveMode.any", "Dowolny cel", "Any objective", "Beliebiges Ziel", "Любая цель"],
        ["admin.quest.marker.continue", "Kontynuacja", "Continue", "Fortsetzung", "Продолжение"],
        ["admin.quest.marker.turn_in", "Oddanie questa", "Turn in quest", "Quest abgeben", "Сдать задание"],
        ["admin.quest.dialogMode.start", "Przed rozpoczęciem", "Before starting", "Vor dem Start", "Перед началом"],
        ["admin.quest.dialogMode.continue", "W trakcie questa", "During the quest", "Während der Quest", "Во время задания"],
        ["admin.quest.dialogMode.turn_in", "Przy oddaniu", "When turning in", "Bei der Abgabe", "При сдаче"],
        ["admin.quest.ui.key", "Klucz", "Key", "Schlüssel", "Ключ"],
        ["admin.quest.ui.type", "Typ", "Type", "Typ", "Тип"],
        ["admin.quest.ui.amount", "Ilość", "Amount", "Menge", "Количество"],
        ["admin.quest.ui.title", "Tytuł questa", "Quest title", "Questtitel", "Название задания"],
        ["admin.quest.ui.description", "Opis dla gracza", "Player-facing description", "Beschreibung für Spieler", "Описание для игрока"],
        ["admin.quest.ui.stageName", "Nazwa etapu", "Stage name", "Etappenname", "Название этапа"],
        ["admin.quest.ui.objectiveMode", "Tryb celów", "Objective mode", "Zielmodus", "Режим целей"],
        ["admin.quest.ui.terminal", "Zakończenie", "Ending", "Abschluss", "Завершение"],
        ["admin.quest.ui.success", "Sukces", "Success", "Erfolg", "Успех"],
        ["admin.quest.ui.failure", "Porażka", "Failure", "Fehlschlag", "Провал"],
        ["admin.quest.ui.transition", "Przejście do etapu", "Transition to stage", "Übergang zur Etappe", "Переход к этапу"],
        ["admin.quest.ui.objectives", "Cele", "Objectives", "Ziele", "Цели"],
        ["admin.quest.ui.transitions", "Przejścia", "Transitions", "Übergänge", "Переходы"],
        ["admin.quest.ui.rewards", "Nagrody", "Rewards", "Belohnungen", "Награды"],
        ["admin.quest.ui.dialogs", "Dialogi i odpowiedzi", "Dialogue and responses", "Dialoge und Antworten", "Диалоги и ответы"],
        ["admin.quest.ui.stages", "Etapy i cele", "Stages and objectives", "Etappen und Ziele", "Этапы и цели"],
        ["admin.quest.ui.basics", "Podstawowe informacje", "Basic information", "Grundinformationen", "Основная информация"],
        ["admin.quest.ui.requirements", "Wymagania rozpoczęcia", "Starting requirements", "Startvoraussetzungen", "Требования для начала"],
        ["admin.quest.ui.npcs", "Wybierz NPC", "Choose NPCs", "NPCs auswählen", "Выберите NPC"],
        ["admin.quest.ui.add", "Dodaj", "Add", "Hinzufügen", "Добавить"],
        ["admin.quest.ui.addStage", "Dodaj kolejny etap", "Add another stage", "Weitere Etappe hinzufügen", "Добавить этап"],
        ["admin.quest.ui.addReward", "Dodaj nagrodę", "Add reward", "Belohnung hinzufügen", "Добавить награду"],
        ["admin.quest.ui.player", "Gracz", "Player", "Spieler", "Игрок"],
        ["admin.quest.ui.npc", "NPC", "NPC", "NPC", "NPC"],
        ["admin.quest.ui.speaker", "Mówi", "Speaker", "Sprecher", "Говорит"],
        ["admin.quest.ui.dialogText", "Tekst wypowiedzi", "Dialogue text", "Dialogtext", "Текст реплики"],
        ["admin.quest.ui.answer", "Odpowiedź gracza", "Player response", "Spielerantwort", "Ответ игрока"],
        ["admin.quest.ui.afterAnswer", "Po odpowiedzi", "After response", "Nach der Antwort", "После ответа"],
        ["admin.quest.ui.endDialog", "Zakończ dialog i wykonaj etap", "End dialogue and perform the step", "Dialog beenden und Schritt ausführen", "Завершить диалог и выполнить шаг"],
        ["admin.quest.validation.valid", "Definicja gotowa do publikacji", "Definition is ready for publication", "Definition ist zur Veröffentlichung bereit", "Определение готово к публикации"],
        ["admin.quest.validation.invalid", "Draft zapisany, ale wymaga uzupełnienia", "The draft is saved but still incomplete", "Der Entwurf ist gespeichert, aber noch unvollständig", "Черновик сохранён, но требует заполнения"],
        ["admin.quest.validation.none", "Nie znaleziono problemów.", "No problems found.", "Keine Probleme gefunden.", "Проблем не обнаружено."],
        ["admin.quest.validation.generic", "Błąd walidacji", "Validation issue", "Validierungsproblem", "Ошибка проверки"],
        ["admin.quest.ui.basicHelp", "Nazwa i opis widoczne dla gracza.", "The name and description visible to the player.", "Name und Beschreibung, die Spieler sehen.", "Название и описание, видимые игроку."],
        ["admin.quest.ui.startStage", "Etap początkowy", "Starting stage", "Startetappe", "Начальный этап"],
        ["admin.quest.ui.addObjective", "Dodaj cel", "Add objective", "Ziel hinzufügen", "Добавить цель"],
        ["admin.quest.ui.emptyObjectives", "Brak celów w etapie.", "No objectives in this stage.", "Keine Ziele in dieser Etappe.", "В этом этапе нет целей."],
        ["admin.quest.ui.optionalRewards", "Nagrody są opcjonalne.", "Rewards are optional.", "Belohnungen sind optional.", "Награды необязательны."],
        ["admin.quest.ui.dialogOptional", "Dialogi są opcjonalne. Bez nich wybór questa u NPC wykona akcję od razu.", "Dialogue is optional. Without it, selecting the quest at an NPC performs the action immediately.", "Dialoge sind optional. Ohne Dialog wird die Aktion bei Auswahl der Quest sofort ausgeführt.", "Диалоги необязательны. Без них выбор задания у NPC сразу выполнит действие."],
        ["admin.quest.ui.saveValidatePublish", "Zapisz, sprawdź i opublikuj", "Save, validate and publish", "Speichern, prüfen und veröffentlichen", "Сохранить, проверить и опубликовать"],
        ["admin.quest.force.safeButton", "Usuń bezpiecznie", "Safe delete", "Sicher löschen", "Безопасно удалить"],
        ["admin.quest.force.button", "FORCE: usuń wraz z postępem", "FORCE: delete with progress", "FORCE: mit Fortschritt löschen", "FORCE: удалить с прогрессом"],
        ["admin.quest.force.archivedOnly", "Force delete wymaga zapisanej, zarchiwizowanej definicji.", "Force delete requires a saved, archived definition.", "Force Delete erfordert eine gespeicherte, archivierte Definition.", "Принудительное удаление требует сохранённого архивного определения."],
        ["admin.quest.force.operation", "wymusić usunięcie definicji", "force-delete the definition", "das Löschen der Definition zu erzwingen", "принудительно удалить определение"],
        ["admin.quest.force.title", "Force delete questa", "Force-delete quest", "Quest zwangsweise löschen", "Принудительно удалить задание"],
        ["admin.quest.force.warning", "Ta operacja usunie definicję, rewizje, postęp postaci, cele, historię, ledger nagród i mapowanie legacy. Przyznane wcześniej nagrody nie zostaną cofnięte.", "This removes the definition, revisions, character progress, objectives, history, reward ledger and legacy mapping. Previously granted rewards will not be reverted.", "Dies entfernt Definition, Revisionen, Charakterfortschritt, Ziele, Verlauf, Belohnungsledger und Legacy-Zuordnung. Bereits gewährte Belohnungen werden nicht zurückgenommen.", "Операция удалит определение, ревизии, прогресс персонажей, цели, историю, реестр наград и legacy-связи. Уже выданные награды не будут отозваны."],
        ["admin.quest.force.continue", "Rozumiem, kontynuuj", "I understand, continue", "Verstanden, fortfahren", "Понимаю, продолжить"],
        ["admin.quest.force.finalTitle", "Ostatnie potwierdzenie", "Final confirmation", "Letzte Bestätigung", "Последнее подтверждение"],
        ["admin.quest.force.finalMessage", "Nieodwracalnie usunąć {0} wraz z całym zapisanym postępem?", "Permanently delete {0} together with all saved progress?", "{0} zusammen mit sämtlichem gespeicherten Fortschritt unwiderruflich löschen?", "Безвозвратно удалить {0} вместе со всем сохранённым прогрессом?"],
        ["admin.quest.force.finalButton", "FORCE DELETE", "FORCE DELETE", "FORCE DELETE", "FORCE DELETE"],
        ["admin.quest.force.deleting", "Wymuszone usuwanie questa i powiązanych stanów", "Force-deleting quest and related states", "Quest und zugehörige Zustände werden zwangsweise gelöscht", "Принудительное удаление задания и связанных состояний"],
        ["admin.quest.force.deleted", "Quest i powiązane stany zostały nieodwracalnie usunięte", "Quest and related states were permanently deleted", "Quest und zugehörige Zustände wurden unwiderruflich gelöscht", "Задание и связанные состояния безвозвратно удалены"]
    ];
    var dictionaries = {};
    ["pl", "en", "de", "ru"].forEach(function (lang) { dictionaries[lang] = {}; });
    rows.forEach(function (row) { ["pl", "en", "de", "ru"].forEach(function (lang, index) { dictionaries[lang][row[0]] = row[index + 1]; }); });
    if (!global.PhoenixI18n || global.PhoenixI18n._questUiHook) return;
    global.PhoenixI18n._questUiHook = true;
    var original = global.PhoenixI18n.t;
    global.PhoenixI18n.t = function (key) {
        var lang = global.PhoenixI18n.getLang ? global.PhoenixI18n.getLang() : "pl";
        if (dictionaries[lang] && key in dictionaries[lang]) return dictionaries[lang][key];
        if (key in dictionaries.pl) return dictionaries.pl[key];
        return original(key);
    };
})(window);