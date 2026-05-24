# TODO: Admin Panel Fixes

## ✅ 1. Lista przedmiotów nie powinna się refreshować po wybraniu itemu
- `onItemClick` w script.js wywoływał `render()` co resetowało wszystkie meshe.
- Fix: `onItemClick` aktualizuje teraz tylko klasę `is-selected`, label wybranego itemu, input `data-bind="selectedScheme"` oraz preview w `renderItemRenderDebug` przez `updateItemSelectionDom()`. Bez pełnego rerendera.

## ✅ 2. Zioła w osobnej zakładce
- Top-level zakładka `herbs` w `TABS` istniała i już ładuje `herbCatalog`/`herbList`.
- Usunięto wpis `herbs` z `subTabs` w `renderNpc()`, gałąź `view === "herbs"` oraz request `herbCatalog/herbList` w akcji `npc-view`.
- Zioła są teraz wyłącznie w głównej zakładce „Zioła".

## ✅ 3. NPC kreator — bez resetu podglądu przy zmianie ekwipunku
- Akcja `human-equip-pick` nie woła już `render()`. Wysyła `adminNpcPreviewUpdate` przez `syncHumanPreview()`, a DOM aktualizuje przez `updateHumanEquipPickerDom(slot)`.
- Picker zamyka się in-place (usunięcie tylko grida z DOM), label slotu jest aktualizowany. Meshe innych pickerów i kreator pozostają nietknięte.

## Pliki zmienione
- `gamemodes/phoenix/web/admin/script.js`
