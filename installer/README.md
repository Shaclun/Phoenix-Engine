# Phoenix Engine Setup

Graficzny instalator i konfigurator Phoenix Engine dla Windows oraz Linux.
Runtime korzysta wyłącznie z biblioteki standardowej Python 3.10+ (`tkinter`).

## Funkcje

- kreator PL/EN/DE/RU z automatycznym wykrywaniem katalogu projektu,
- domyślnie czarny motyw interfejsu z opcjonalnym jasnym wariantem i przełącznikiem w nagłówku,
- pełna edycja `config.xml`: widoczność prywatna/publiczna, debug, nazwa, opis
  HTML z paskiem formatowania, podglądem na żywo i limitem G2O 400 znaków,
  sloty, port gry, master URL oraz świat,
- kontrola źródła CEF i automatyczny wybór `file://` albo `cef://index.html`,
- bezpieczne pakowanie `gamemodes/phoenix/web` do
  `addons/PhoenixWeb.zip` ze strukturą `_WORK/DATA/WEB/`; wszystkie ścieżki
  w ZIP-ie są zapisywane wielkimi literami wymaganymi przez G2O, a publiczny
  zasób używa `<resource zip="…" />` z `<compress>false</compress>`, dzięki
  czemu klient pobiera jedno `phoenixweb.zip`, a nie zagnieżdżone `.zip.zip`,
- wykrywanie istniejących instalacji i kontenerów Compose; port zajęty przez
  uruchomioną usługę projektu nie blokuje trybu edycji,
- diagnostyka wymaganych plików, CEF, architektury, Dockera, Compose i portów,
- instalacja Dockera wyłącznie po pokazaniu komendy i uzyskaniu zgody,
- atomowa, sparowana konfiguracja `.env` i `config/mysql.env` z backupami,
- zarządzanie Compose, health-check, logi i uruchamianie serwera,
- migracje `01–26` wykonywane przez runtime G2O przy każdym starcie serwera;
  ledger i blokada zapobiegają powtórzeniom/równoległemu wykonaniu, a moduły
  zależne zaczynają pracę dopiero po `phoenix.database.OnReady`,
- dwustopniowo potwierdzany reset bazy z opcjonalnym `mysqldump`,
- brak telemetrii i wysyłania danych.

## Uruchomienie ze źródeł

Z katalogu `installer/`:

```text
python phoenix_setup.py
```

Python musi zawierać moduł `tkinter` (na części dystrybucji Linux jest on osobnym
pakietem systemowym, np. `python3-tk`). Instalator nie instaluje bibliotek runtime.

## Budowanie samodzielnej paczki

Zależność build jest przypięta dokładnie w `requirements-build.txt`. Zainstaluj ją
ręcznie w przeznaczonym do budowania środowisku, a następnie uruchom właściwy skrypt:

Windows PowerShell:

```powershell
python -m pip install -r requirements-build.txt
.\build-windows.ps1
```

Linux:

```sh
python3 -m pip install -r requirements-build.txt
sh ./build-linux.sh
```

Wyniki trafiają do `dist/`: `PhoenixEngineSetup.exe` na Windows oraz
`PhoenixEngineSetup` i terminalowy `PhoenixEngineSetupCLI` na Linux. Każdą
platformę należy budować natywnie na tej platformie. GUI używa `--onefile
--windowed`, a wersja terminalowa Linux `--onefile --console`.

## Uprawnienia i bezpieczeństwo

Na Windows Docker Desktop jest instalowany przez `winget` z oficjalnym identyfikatorem
`Docker.DockerDesktop`. Gdy `winget` nie istnieje, otwierana jest wyłącznie oficjalna
strona Docker — instalator nie pobiera plików EXE.

Na Linux używane są natywne menedżery `apt`, `dnf`, `pacman` lub `zypper` oraz
`pkexec`. `sudo` jest dopuszczone tylko w interaktywnym terminalu. Dodanie użytkownika
do grupy `docker` ma osobne potwierdzenie, ponieważ daje uprawnienia równoważne root.
Po tej zmianie trzeba wylogować się i zalogować ponownie.

Hasła nie są wypisywane do logu GUI. Pliki konfiguracji otrzymują na POSIX tryb 0600.
Reset wykonuje kolejno: uruchomienie/weryfikację Dockera, kontrolę właściciela
portu z `.env`, opcjonalne i osobno potwierdzone zatrzymanie obcego kontenera,
ponowną kontrolę portu, a dopiero później `docker compose down -v` bieżącego
projektu. Usługa hosta nie jest zatrzymywana automatycznie, a konflikt zawsze
anuluje operację przed usunięciem wolumenu. Błędy Compose zawierają komendę,
kod wyjścia oraz pełne stdout/stderr. Kopie SQL trafiają do katalogu projektu
`backups/` dopiero na żądanie.

## Struktura

- `phoenix_setup.py` — punkt wejścia GUI,
- `phoenix_setup_cli.py` — punkt wejścia terminalowego tylko dla Linux,
- `phoenix_installer/app.py` — GUI, wątki i kolejka zdarzeń,
- `phoenix_installer/cli.py` — interaktywne menu terminalowe Linux,
- `phoenix_installer/core.py` — diagnostyka i operacje systemowe,
- `phoenix_installer/i18n.py` — centralne tłumaczenia,
- `assets/pe.png` — logo Phoenix Engine,
- `version_info.txt` — metadane Windows z Copyright © 2026 Shaclow.

Copyright © 2026 Shaclow

## CEF i tryby publikacji

Zgodnie z [dokumentacją protokołów modułu G2O CEF](https://g2o.gitlab.io/modules/cef/script-reference/manual/1.supported-protocols/), projekt prywatny używa lokalnego `file://`, a projekt publiczny przełącza interfejs na `cef://index.html`, buduje addon ZIP i deklaruje go jako `<resource zip="addons/PhoenixWeb.zip" />`. Powrót do projektu prywatnego usuwa z `config.xml` zarówno ten wpis, jak i błędne wpisy `<addon>` utworzone przez starszy instalator. Opcja debug pozostaje niezależnym ustawieniem serwera i umożliwia również [zdalne debugowanie CEF](https://g2o.gitlab.io/modules/cef/script-reference/manual/6.remote-debugger/).