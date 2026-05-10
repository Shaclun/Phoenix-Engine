# Phoenix Engine - uruchomienie serwera od zera

Ta instrukcja opisuje najprostszy sposób postawienia lokalnego serwera z folderu `Main-Server`.

## 1. Wymagania

Zainstaluj:

- Gothic II: Noc Kruka z Gothic 2 Online
- Docker Desktop

## 2. Pliki, które muszą być w folderze

W głównym folderze serwera powinny istnieć między innymi:

- `G2O_Server.x64.exe`
- `config.xml`
- `data.xml`
- `mds.xml`
- `faceani.xml`
- `docker-compose.yml`
- `.env`
- `config/mysql.env`
- folder `gamemodes/phoenix`
- folder `migrations`

Jeżeli brakuje `data.xml`, serwer G2O może nie działać poprawnie. Wtedy trzeba go wygenerować z gry:

1. W `config.xml` ustaw `<debug>true</debug>`.
2. Uruchom czysty/defaultowy G2O Server.
3. Wejdź na serwer klientem gry.
4. Otwórz konsolę debug w grze klawiszem tyldy `~`.
5. Wpisz:

```text
generate data
```

6. Skopiuj wygenerowany plik z:

```text
GOTHIC_PATH\Multiplayer\data.xml
```

do:

```text
Main-Server\data.xml
```

## 3. Konfiguracja bazy danych

Serwer Phoenix czyta dane połączenia z pliku `.env`.

Jeżeli nie masz `.env`, skopiuj przykład:

```powershell
Copy-Item .env.example .env
```

Domyślna konfiguracja lokalna:

```env
DATABASE_HOST=127.0.0.1
DATABASE_PORT=3306
DATABASE_USERNAME=phoenix
DATABASE_PASSWORD=phoenix_dev
DATABASE_DBNAME=phoenix
DATABASE_ENCODING=utf8mb4
```

Docker MySQL używa pliku `config/mysql.env`:

```env
MYSQL_USER=phoenix
MYSQL_PASSWORD=phoenix_dev
MYSQL_ROOT_PASSWORD=root_dev
MYSQL_DATABASE=phoenix
```

Te dane muszą pasować do `.env`.

## 4. Start MySQL

W folderze `Main-Server` uruchom bazę:

```powershell
docker compose up -d
```

Przy pierwszym starcie Docker utworzy bazę i zaimportuje migracje z folderu `migrations`.

Sprawdzenie, czy baza działa:

```powershell
docker compose ps
```

Logi bazy:

```powershell
docker compose logs mysql-server
```

## 5. Start serwera G2O

Po uruchomieniu MySQL odpal serwer:

```powershell
.\G2O_Server.x64.exe
```

Jeżeli potrzebujesz wersji 32-bit:

```powershell
.\G2O_Server.x86.exe
```

Serwer powinien wystartować na porcie z `config.xml`:

```xml
<config public=false host_name="Gothic Online" max_slots=32 port=28970 />
```

Domyślnie świat ustawiony jest na:

```xml
<world name="NEWWORLD\NEWWORLD.ZEN" />
```

## 6. Wejście do gry

W kliencie Gothic 2 Online dodaj lokalny serwer:

```text
127.0.0.1:28970
```

Jeżeli serwer stoi na VPS, wpisz IP VPS i port `28970`.

## 7. Reset bazy od zera

Jeżeli chcesz wyczyścić bazę i wgrać migracje od nowa:

```powershell
docker compose down -v
docker compose up -d
```

Uwaga: `down -v` usuwa dane bazy.

## 8. Zatrzymanie serwera

Serwer G2O zatrzymaj w jego konsoli przez `CTRL + C`.

Bazę zatrzymasz komendą:

```powershell
docker compose down
```

## 9. Najczęstsze problemy

### Brak połączenia z bazą

Sprawdź:

- czy Docker działa,
- czy `docker compose ps` pokazuje `mysql-server`,
- czy `.env` ma takie same dane jak `config/mysql.env`,
- czy port `3306` nie jest zajęty przez innego MySQL.

### Serwer nie widzi świata albo modeli

Sprawdź, czy w głównym folderze są:

- `data.xml`
- `mds.xml`
- `faceani.xml`

Po zmianach w skryptach Gothica albo modelach `data.xml` trzeba wygenerować ponownie.

### Zmiany w bazie się nie pojawiają

Migracje z `migrations` importują się automatycznie tylko przy pierwszym utworzeniu wolumenu bazy. Aby wymusić import od zera, użyj:

```powershell
docker compose down -v
docker compose up -d
```

### Port gry nie działa

Sprawdź w `config.xml` port serwera:

```xml
port=28970
```

Na VPS odblokuj port `28970` w firewallu.

## 10. Szybka checklista

1. Wejdź do folderu `Main-Server`.
2. Utwórz `.env` z `.env.example`.
3. Uruchom MySQL: `docker compose up -d`.
4. Uruchom serwer: `.\G2O_Server.x64.exe`.
5. Wejdź klientem na `127.0.0.1:28970`.
