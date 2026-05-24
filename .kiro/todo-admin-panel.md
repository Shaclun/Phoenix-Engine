# TODO: Admin Panel — postęp

## ✅ 1. Lista przedmiotów nie odświeża się po wybraniu itemu
- `onItemClick` aktualizuje tylko klasę `is-selected`, label, input bind i preview przez `updateItemSelectionDom()`. Bez rerendera.

## ✅ 2. Zioła w osobnej zakładce
- Top-level `herbs` w `TABS`. Usunięto z subTabs NPC.

## ✅ 3. NPC kreator — bez resetu podglądu przy zmianie ekwipunku
- `humanPayload()` nie wstawia pustych slotów; `human-equip-pick` wysyła delta payload (`humanEquipPayload(slot)`).
- `phoenix.admin.Model.previewUpdate`:
  - pomija `setPlayerInstance` poza recreate
  - `setPlayerVisual` wywołuje **tylko jeśli faktycznie się zmienił** body/head/tex (porównanie z cache w `preview.bodyModel/headModel/bodyTex/headTex`)
  - po `setPlayerVisual` re-equipuje cachowane sloty (engine drops eq po rebind)
  - `previewPlace()` wywołuje tylko gdy zmieniła się pozycja albo recreate
- `previewAutoStat(instance)` auto-podbija strength/dexterity przed ekwipowaniem broni (mirror `phoenix.npc.Spawn._autoStats`).
- `previewStart` honoruje pozycję z payloadu (gdy edytujemy istniejącego NPC).

## ✅ 4. Cleanup preview przy zmianie zakładki / subview
- `npc-view` przy opuszczaniu human/catalog/spawn-edit wyłącza preview.
- Top-level `buildTabs` przy wyjściu z NPC stoppuje preview.

## ✅ 5. Edycja NPC otwiera Human Creator z prefilled danymi i pozycją NPC
- `npc-edit` hydruje `state.humanCreator` z spawnu (`hydrateHumanCreatorFromSpawn`), `state.npcEditingId = sid`, subview `human`, payload zawiera pozycję NPC.
- W trybie edycji Human Creator pokazuje "Anuluj" i "Zapisz" (zamiast Reset/Spawn) — wysyła `npcUpdate` z metadata.
- `phoenix.npc.Spawn.listAll` zwraca dodatkowo `weapon, armor, ranged, voice, strength, dexterity, merchantItems, metadata`.

## ✅ 6. Panel admina: przeglądanie i edycja bazy danych
- Zakładka `db`. Backend dispatchersy: `dbTables`, `dbTableSchema`, `dbRows`, `dbRowUpdate`, `dbRowInsert`, `dbRowDelete`. Mutacje tylko na `phoenix_*`. Walidacja identyfikatorów + audyt w `phoenix_admin_log`.
- UI:
  - szeroki układ z paskiem tabel po lewej (sticky, scroll)
  - tabela danych z poziomym scrollem, sticky headerem, ✎/🗑 przy każdym wierszu
  - **modal edycji** wiersza (szeroki, do 92vw) — pola w gridzie, textarea dla TEXT/długich VARCHAR, input number dla typów numerycznych
  - **modal nowego wiersza** z auto-pomijaniem AUTO_INCREMENT PK
  - paginacja (← Strona X/Y →)

## ✅ 7. Lobby / kamery startowe / spawny postaci
- Migracja `21-admin-config.sql`: tabela `phoenix_admin_config` (configKey/payload).
- Backend admin dispatchers: `spawnConfigGet`, `spawnConfigSave`, `spawnConfigCapture`. Capture zwraca aktualną pozycję admina + kąt + świat.
- Po stronie serwera (`gamemodes/phoenix/modules/player/server/lobbyConfig.nut`):
  - moduł `phoenix.player.LobbyConfig` cache'uje DB
  - `phoenix.database.OnReady` ładuje config przy starcie
  - `onPlayerJoin` pcha config do gracza (po 500ms)
  - `phoenix.player.LobbyConfig.broadcast()` rozsyła do wszystkich po zmianie
- Po stronie klienta (`phoenix.player.Lobby.applyServerConfig`):
  - bind na `phoenix.player.Message.LobbyConfig`
  - parsuje JSON (prymitywny parser: ekstrakcja par `"klucz":wartość` per-obiekt) i nadpisuje `cameraSpots`
  - jeśli config pusty, używa wbudowanych defaults
- UI nowa zakładka „Lobby/Spawny":
  - sekcja **Kamery lobby**: lista X/Y/Z + rotX/rotY/rotZ, przycisk „Dodaj z mojej pozycji" (capture), „Zapisz lobby"
  - sekcja **Domyślny respawn**: świat + X/Y/Z/angle, capture + zapis
  - sekcja **Alternatywne punkty startowe**: lista X/Y/Z/angle, capture + zapis

### Pozostałe (ograniczenia)
- `characterDefaultSpawn` i `characterScenarios` są **zapisane** w DB i broadcastowane, ale **nie są jeszcze konsumowane** po stronie serwera w `phoenix.character.Structure.createDefault`. To fix typu „zaczytaj z `phoenix.player.LobbyConfig.cache.characterDefaultSpawn` przy tworzeniu domyślnego rekordu" — nie zrobione w tej iteracji bo wymaga zmiany flow tworzenia postaci. Lobby cameras działają w pełni.
- Klient parsuje JSON ręcznie (Squirrel nie ma natywnego JSON.parse). Format jest sztywny: `[{"x":...,"y":...,"z":...,"rotX":...,"rotY":...,"rotZ":...}, ...]`.

## Pliki zmienione / dodane
- `gamemodes/phoenix/web/admin/script.js`
- `gamemodes/phoenix/web/admin/style.css`
- `gamemodes/phoenix/modules/admin/client/model.nut`
- `gamemodes/phoenix/modules/admin/server/handlers.nut`
- `gamemodes/phoenix/modules/npc/server/spawn.nut`
- `gamemodes/phoenix/modules/player/shared/messages.nut` (dodana `LobbyConfig`)
- `gamemodes/phoenix/modules/player/server/lobbyConfig.nut` (nowy)
- `gamemodes/phoenix/modules/player/client/lobby.nut` (consumes LobbyConfig)
- `gamemodes/phoenix/modules/player/index.xml` (rejestracja `lobbyConfig.nut`)
- `migrations/21-admin-config.sql` (nowy)
