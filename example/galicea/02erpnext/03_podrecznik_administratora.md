# ERPNext w Galicea – podręcznik administratora

Podręcznik opisuje codzienną obsługę instancji ERPNext zainstalowanej według
[01_instalacja.md](01_instalacja.md): procesy i usługi, kopie bezpieczeństwa, aktualizacje,
aplikacje, wyciągi bankowe, KSeF i typowe problemy.

---

## 1. Środowisko

### 1.1. Gdzie co jest

| element | lokalizacja |
|---|---|
| katalog bench | `/erp/erpnext-bench` (`INST` w `sh/admin/erp.env`) |
| środowisko Pythona 3.14 | `/erp/erpnext-bench/env` |
| kod aplikacji (repozytoria git) | `/erp/erpnext-bench/apps/<aplikacja>` |
| konfiguracja wspólna | `sites/common_site_config.json` (porty redis, workery, `maintenance_mode`, `pause_scheduler`, `developer_mode`) |
| konfiguracja witryny | `sites/<witryna>/site_config.json`: **hasło bazy, `encryption_key`**, sekcje `keycloak`, `portal`, `admissions_poland` |
| pliki użytkowników | `sites/<witryna>/public/files`, `sites/<witryna>/private/files` (m.in. certyfikat KSeF) |
| kopie bench | `sites/<witryna>/private/backups` |
| kopie zbiorcze (`kopia.sh`) | `/erp/backup` (`BACKUP_DIR`) |
| logi | `/erp/erpnext-bench/logs` (`web.log`, `worker.log`, `worker.error.log`, `scheduler.log`, `frappe.log`, `bench.log`) |
| jednostki systemd | `config/systemd/*` → linki w `/etc/systemd/system/` |
| nginx | `config/nginx.conf` → `/etc/nginx/conf.d/` (lub `sites-enabled/`) |

### 1.2. Procesy

| proces | rola |
|---|---|
| web (gunicorn, port 8000) | obsługa żądań HTTP |
| socketio (node, port 9000) | powiadomienia na żywo |
| worker(y) | zadania w tle (import danych, e-maile, przetwarzanie KSeF, usuwanie transakcji) |
| schedule | zadania cykliczne (KSeF co 30 min i codziennie, kopie, przypomnienia) |
| redis_cache, redis_queue | cache i kolejki (w `/erp/erpnext-bench` porty 13001 i 11001) |

Produkcyjnie procesy działają pod `erpnext-bench.target` (systemd). W trybie deweloperskim
uruchamia je `bench start` na podstawie `Procfile`.

### 1.3. Skrypty administracyjne (`sh/admin`)

Wszystkie skrypty czytają `erp.env` (ścieżki, domyślna witryna, katalog kopii) i aktywują `env/`.
Inną witrynę wskazuje się opcją `-s <witryna>` podaną jako pierwszy argument.
**W skryptach nie ma haseł.** Bench pyta o nie interaktywnie.

| skrypt | do czego |
|---|---|
| `status.sh` | wersje, witryny, aplikacje, scheduler, `bench doctor`, flagi trybów, usługi, miejsce na dysku |
| `start_dev.sh` | `bench start` (tryb deweloperski; odmawia, gdy działa systemd) |
| `restart.sh` | restart procesów (systemd albo `bench restart`) i czyszczenie cache |
| `kopia.sh` | kopia witryny (baza + pliki + `site_config.json`) do `BACKUP_DIR` z rotacją; `--all` = wszystkie witryny |
| `przywroc.sh` | odtworzenie witryny z kopii (z potwierdzeniem i kopią stanu bieżącego) |
| `aktualizacja.sh` | aktualizacja aplikacji (`bench update`, `--patch`, `--reset`), migracja, build |
| `migracja.sh` | `clear-cache` + `migrate` (po zmianach w kodzie, hooks, fixtures) |
| `przebuduj.sh` | `bench build` (całość lub jedna aplikacja) + czyszczenie cache |
| `cache.sh` | czyszczenie cache witryny |
| `konsola.sh` | konsola Pythona witryny; z argumentem wykonuje przepis z `konsola/` |
| `baza.sh` | konsola MariaDB witryny, opcjonalnie z zapytaniem SQL |
| `tryb.sh` | `serwis` / `dev` / `scheduler` / `skrypty` → `on` / `off` |
| `wyloguj_wszystkich.sh` | zamknięcie wszystkich sesji i wyczyszczenie kolejek |
| `aplikacja_instaluj.sh` | instalacja aplikacji (z URL, z lokalnego katalogu albo z rejestru Frappe) |
| `aplikacja_usun.sh` | odinstalowanie aplikacji z witryny (opcjonalnie z bench) |
| `fixtures.sh` | eksport fixtures aplikacji i przeładowanie doctype (praca deweloperska) |
| `przeladuj_doctype.sh` | przeładowanie definicji doctype z plików aplikacji |
| `eksport_dokumentu.sh` | eksport dokumentu (Workspace, Print Format…) do JSON |
| `napraw_srodowisko.sh` | naprawa zależności Pythona; `--odtworz` = nowe `env/` na Pythonie 3.14 |
| `fork_synchronizuj.sh` | scalenie forka (np. education) z gałęzią upstream |
| `lint.sh` | `ruff check` kodu aplikacji |

Przepisy dla konsoli (`sh/admin/konsola/`, opis w `konsola/README.md`):
`utworz_pola_custom.py`, `odlacz_roznice_kursowe.py`, `workspace_linki_na_content.py`,
`usun_transakcje_firmy.py`.

---

## 2. Czynności bieżące

### 2.1. Start, stop, restart

```bash
sudo systemctl status  erpnext-bench.target
sudo systemctl restart erpnext-bench.target          # całość
sudo systemctl restart erpnext-bench-frappe-web      # tylko serwer WWW (np. po zmianie kodu Pythona)
sudo systemctl stop    erpnext-bench.target
journalctl -u erpnext-bench-frappe-web -n 100        # dziennik usługi
```

albo `sh/admin/restart.sh`. Po zmianie kodu Pythona aplikacji wystarczy restart. Po zmianie
JS/CSS potrzebny jest `przebuduj.sh`, a po zmianie doctype, hooks lub fixtures `migracja.sh`.

### 2.2. Tryb serwisowy

```bash
./tryb.sh serwis on     # użytkownicy widzą komunikat o przerwie
./tryb.sh serwis off
```

> Po przerwanym `bench update` flaga `maintenance_mode: 1` potrafi zostać w
> `common_site_config.json`. Wtedy system „wisi” w trybie serwisowym, mimo że w witrynie
> tryb jest wyłączony. `tryb.sh serwis off` czyści obie flagi.

### 2.3. Scheduler (zadania cykliczne)

```bash
./tryb.sh scheduler on       # enable + resume + pause_scheduler=0
bench --site <witryna> scheduler status
```

Wyłączony scheduler oznacza, że **faktury z KSeF nie są pobierane**, a statusy wysłanych faktur
nie są aktualizowane. Pojedyncze zadanie można uruchomić ręcznie w
`/desk/scheduled-job-type` → *Execute*. Historia jest w `/desk/scheduled-job-log`.

### 2.4. Monitorowanie

* `./status.sh`: przegląd całości. `bench doctor` pokazuje workery i zaległe zadania.
* `/desk/error-log`: błędy aplikacji, m.in. „KSeF fetch error” i „KSeF - missing invoice number”.
* `/desk/rq-job`: zadania w kolejkach, a w nich nieudane (*failed*).
* `logs/worker.error.log`, `logs/web.error.log`: błędy procesów.
* Miejsce na dysku: kopie w `private/backups` i `BACKUP_DIR`, pliki XML z KSeF (punkt 7.3).

### 2.5. Użytkownicy

* Reset hasła: `bench --site <witryna> set-password <użytkownik>` (dla Administratora:
  `set-admin-password`).
* Wylogowanie wszystkich (np. po zmianie uprawnień albo przed pracami): `wyloguj_wszystkich.sh`.
* Zablokowane konto po nieudanych logowaniach: odblokowuje się samo po czasie z *System Settings*
  albo ręcznie w formularzu użytkownika.

---

## 3. Kopie bezpieczeństwa

### 3.1. Co trzeba zabezpieczyć

| element | gdzie | uwagi |
|---|---|---|
| baza danych witryny | `*-database.sql.gz` | wszystkie dokumenty i ustawienia |
| pliki publiczne i prywatne | `*-files.tar/tgz`, `*-private-files.tar/tgz` | załączniki, XML faktur KSeF, **certyfikat PFX** |
| `site_config.json` | `*-site_config_backup.json` | **`encryption_key`**: bez niego nie da się odszyfrować zapisanych haseł (hasło PFX, poczta, klucze API) |
| kod aplikacji | repozytoria git (code.galicea.org) | lokalne niezacommitowane zmiany w `apps/` nie trafiają do kopii bench |
| konfiguracja serwera | `/etc/nginx`, `/etc/letsencrypt`, `/etc/mysql/mariadb.conf.d/99-frappe.cnf`, `config/` bench | odtwarzalna skryptami `sh/setup` |

### 3.2. Kopia ręczna i automatyczna

```bash
./kopia.sh                       # witryna z erp.env
./kopia.sh -s inna.witryna.pl
./kopia.sh --all                 # bench backup-all-sites (tylko do private/backups)
```

`kopia.sh` wykonuje `bench backup --with-files --compress`, kopiuje komplet razem z
`site_config.json` do `BACKUP_DIR/<data>_<witryna>` z prawami `600` i usuwa katalogi starsze niż
`BACKUP_KEEP_DAYS`.

Codzienna kopia z crona (`crontab -e` użytkownika, z którego działa bench):

```cron
30 2 * * * /ścieżka/sh/admin/kopia.sh >> /erp/backup/kopia.log 2>&1
```

Frappe robi też własne kopie bazy co 6 godzin (`bench setup backups` / *System Settings →
Backups*). Te kopie zostają w `private/backups` i nie obejmują plików.

**Kopia musi trafić poza serwer**, np. `rsync -a /erp/backup/ backup@inny-host:/kopie/erp/`
albo do magazynu obiektowego (*S3 Backup Settings* w Frappe). Kopia trzymana na tym samym
dysku nie chroni przed awarią serwera.

### 3.3. Odtwarzanie

```bash
./przywroc.sh /erp/backup/20261125_023000_erp.example.org
```

Skrypt:

1. pokazuje, co odtworzy, i prosi o wpisanie nazwy witryny,
2. robi kopię bieżącego stanu,
3. włącza tryb serwisowy, wykonuje `bench restore` z plikami (pyta o hasło roota MariaDB),
4. wykonuje `migrate`, wyłącza tryb serwisowy, czyści cache i restartuje procesy.

Przy odtwarzaniu na **innym serwerze** lub do innej witryny trzeba przenieść `encryption_key`
z zachowanego `site_config.json`. Bez tego pojawi się błąd *Encryption key is invalid*
przy KSeF, poczcie i integracjach.

### 3.4. Test kopii

Raz na kwartał warto odtworzyć kopię na kopii deweloperskiej (np. `/erp/erpnext-bench`,
witryna `localhost`) i sprawdzić logowanie, raporty, wydruk PDF i załączniki.
Uwaga: kopia produkcyjna zawiera dane osobowe i certyfikat KSeF, więc instancja testowa
wymaga takiej samej ochrony. Przed testami trzeba wyłączyć scheduler, żeby kopia nie zaczęła
pobierać ani wysyłać faktur do KSeF (`tryb.sh scheduler off`).

---

## 4. Aktualizacje

### 4.1. Zasady

* Produkcja zostaje na gałęzi **`version-16`** (frappe, erpnext, hrms). Aktualizacje w obrębie
  wersji (16.x) to poprawki i można je robić regularnie, np. raz w miesiącu. Przejście na
  v17 to osobny projekt: testy na kopii, zgodność `erpnext_poland`, `education`
  i `admissions_poland`, ewentualnie nowa wersja Pythona.
* Aplikacje Galicea aktualizujemy z ich repozytoriów (`main` / `develop`) **po** testach na kopii.
* Zawsze najpierw kopia (`kopia.sh`). `bench update` też wykonuje kopie wszystkich witryn.
* Aktualizacje robimy poza godzinami pracy księgowości, w trybie serwisowym.

### 4.2. Procedura

```bash
./kopia.sh
./aktualizacja.sh            # pull wszystkich aplikacji + requirements + migrate + build + restart
```

Skrypt najpierw pokazuje gałąź i liczbę niezacommitowanych zmian każdej aplikacji.
**Lokalne zmiany w `apps/*` blokują `git pull`**: trzeba je zacommitować i wypchnąć albo
odłożyć (`git stash`).

Warianty:

* `./aktualizacja.sh --patch`: tylko patche i migracja, bez pobierania kodu.
* `./aktualizacja.sh --reset`: pull z twardym resetem do stanu z repozytorium.
  **Kasuje lokalne zmiany w `apps/`**, więc używamy tego tylko świadomie.
* Pojedyncza aplikacja Galicea:
  ```bash
  cd /erp/erpnext-bench/apps/erpnext_poland && git pull
  cd ../../ && sh/admin/migracja.sh && sh/admin/przebuduj.sh erpnext_poland && sh/admin/restart.sh
  ```

Po aktualizacji: `status.sh`, logowanie, faktura testowa (wydruk), `register_from_ksef` (Execute)
i przegląd *Error Log*.

### 4.3. Wycofanie aktualizacji

1. `git -C apps/<aplikacja> log` → `git checkout <poprzedni commit>` dla aplikacji, która
   wprowadziła problem (albo dla wszystkich, według stanu sprzed aktualizacji),
2. `bench setup requirements`, `bench build`,
3. `przywroc.sh <kopia sprzed aktualizacji>`, bo migracja mogła zmienić schemat bazy,
4. `restart.sh`.

### 4.4. Zmiana gałęzi (np. beta → stabilna)

Instancja zaczynała na `version-16-beta`. `sites/apps.json` nadal pamięta tę gałąź, ale liczy
się gałąź bieżąca w repozytorium. Przejście na inną gałąź:

```bash
bench switch-to-branch version-16 frappe erpnext hrms --upgrade
bench --site <witryna> migrate && bench build
```

### 4.5. Fork education – synchronizacja z frappe/education

```bash
./fork_synchronizuj.sh education version-16-hotfix develop
```

Skrypt sprawdza, czy nie ma lokalnych zmian. Pobiera `upstream` (z `--unshallow`, bo
repozytorium pobrane przez bench jest płytkie i bez pełnej historii merge się nie uda),
tworzy gałąź `chore/upstream-…`, scala `upstream/version-16-hotfix` i przewija `develop`.
Przy konfliktach zatrzymuje się z instrukcją. Następnie: testy (w tym `admissions_poland`,
który korzysta z API forka), `git push origin develop` (i lustra na GitHub), a na produkcji
`git pull`, `migracja.sh` i `przebuduj.sh education`.

### 4.6. Python, Node, system

* **Python** w obrębie 3.14 (np. 3.14.2 → 3.14.8): `pyenv install 3.14.x`, ustaw `PY_VERSION`
  w `sh/setup/erp.env`, potem `napraw_srodowisko.sh --odtworz` (nowe `env/`, stare zostaje jako
  `env.bak.*`) i restart. Zmiana minor (3.15) dopiero wtedy, gdy frappe ją dopuści
  (`requires-python` w `apps/frappe/pyproject.toml`).
* **Node**: `nvm install 24` (nowsza poprawka), potem `bench setup requirements --node`,
  `bench build`, a w razie zmiany ścieżki node ponowne `bench setup systemd` (patrz instalacja, krok 10).
* **System**: `apt upgrade` obejmuje MariaDB, Redis i nginx. Po aktualizacji MariaDB:
  `systemctl status mariadb`, `status.sh`.
* **bench (CLI)**: `/erp/venv314/bin/pip install -U frappe-bench`.

---

## 5. Aplikacje

### 5.1. Instalacja i usuwanie

```bash
./aplikacja_instaluj.sh hrms "" version-16                      # z rejestru Frappe
./aplikacja_instaluj.sh nazwa https://host/repo.git main         # z repozytorium
./aplikacja_instaluj.sh admissions_poland                        # z istniejącego apps/admissions_poland (pip -e)
./aplikacja_usun.sh nazwa [--z-bench]
```

* `uninstall-app` **usuwa doctype i dane aplikacji** z witryny. Przed usunięciem bench robi
  kopię bazy.
* Gdy katalog aplikacji usunięto, a wpis w bazie został (błędy `ModuleNotFoundError` przy
  `migrate`): `bench --site <witryna> remove-from-installed-apps <aplikacja>`.
* Lista: `bench --site <witryna> list-apps`, wersje: `bench version`.
* Wykluczenie aplikacji z aktualizacji: `sites/excluded_apps.txt`.

### 5.2. Praca deweloperska nad aplikacjami Galicea

Wyłącznie na kopii deweloperskiej z `developer_mode` (`tryb.sh dev on`):

* zmiany w doctype zapisują się do plików JSON aplikacji,
* pola niestandardowe i Client Scripty, które wchodzą w skład aplikacji, eksportujemy jako fixtures:
  ```bash
  ./fixtures.sh erpnext_poland "Sales Invoice" "Purchase Invoice" Account Item Company
  ```
  wynik (`apps/erpnext_poland/erpnext_poland/fixtures/*.json`) commitujemy,
* pola z `custom_fields` w `hooks.py` można wymusić przepisem `konsola/utworz_pola_custom.py`,
* przed commitem: `./lint.sh <aplikacja>` (ruff; w repozytoriach jest też `pre-commit`),
* teksty widoczne dla użytkownika piszemy po angielsku w `_()`, a polskie tłumaczenie dopisujemy
  do `translations/pl.csv` aplikacji.

---

## 6. Wyciągi bankowe

### 6.1. Jak to działa w ERPNext

1. *Import wyciągów bankowych (Bank Statement Import)* (`/desk/bank-statement-import`): firma,
   **konto bankowe firmy**, plik CSV/XLSX → podgląd i mapowanie kolumn → *Start Import*.
   Powstają *Transakcje bankowe (Bank Transaction)*.
2. Rozliczenie transakcji: dopasowanie do płatności lub faktur w *Narzędziu do uzgadniania
   bankowego (Bank Reconciliation Tool)* albo przez szkice z `erpnext_poland` (punkt 6.4).

### 6.2. Problem: MT940 i polskie banki

Formularz importu ma opcję **„Import MT940 Fromat”** (literówka w ERPNext), ale z polskimi
wyciągami w praktyce **nie działa poprawnie**. Konwerter ERPNext:

* bierze opis transakcji z pola `extra_details` rekordu `:61:`, a nie z `:86:`. Tytuły przelewów
  i dane kontrahenta, które polskie banki umieszczają w `:86:` w podpolach `^00…^63` / `~20…~25`,
  **giną**,
* nie rozpoznaje kodowania (ISO-8859-2, CP852, CP1250), więc polskie znaki się psują,
* nie obsługuje niestandardowych elementów niektórych banków (czas operacji w `:61:`,
  dodatkowe tagi jak `:26:`). Parser kończy się wtedy błędem „Failed to parse MT940 format”,
* numer referencyjny bywa pusty.

Faktycznie działa więc tylko import **CSV o strukturze oczekiwanej przez ERPNext**.

### 6.3. Konwersja wyciągu: `bank/ipko940e.py`

Skrypt przygotowuje taki plik CSV z dwóch źródeł:

```bash
cd /katalog/z/wyciągami
/ścieżka/bank/ipko940e.sh wyciag.sta                       # MT940
/ścieżka/bank/ipko940e.sh --csv Lista_operacji_RRRRMMDD.csv  # eksport "Lista operacji" (Pekao)
```

* **MT940**: wykrywa kodowanie, składa opis z podpól `:86:` (`20–25`, awaryjnie `00`),
  obsługuje `:61:` z czasem operacji, ignoruje `:26:`. Wynik: `zestawienie_RRRR_MM.csv`.
* **CSV z bankowości** (separator `;`, kwoty z przecinkiem, numery rachunków poprzedzone `'`):
  opis bierze z „Tytułem”, awaryjnie z „Typ operacji” lub „Nadawca / Odbiorca”. Dzieli
  operacje na miesiące, po jednym pliku `zestawienie_RRRR_MM.csv` na miesiąc.
* Kolumny wyniku: `Data, Wpłata, Wypłata, Opis, Numer referencyjny, Rachunek bankowy, Waluta`.
  To polskie etykiety pól *Bank Transaction*, więc przy polskim interfejsie importer mapuje je
  automatycznie. Przy interfejsie angielskim trzeba zmienić nagłówki na `Date, Deposit,
  Withdrawal, Description, Reference Number, Bank Account, Currency` albo zmapować kolumny
  w podglądzie importu.
* „Rachunek bankowy” zostaje pusty, bo importer bierze konto wybrane w formularzu importu.
* Skrypt wywołuje Pythona ze środowiska bench (`/erp/erpnext-bench/env/bin/python`, ma pakiet
  `mt-940`). Inny interpreter wskazuje zmienna `PYTHON=...`.
* Przykład wejścia (`bank/Lista_operacji_….csv`) daje
  `"2026-07-06","0","5.00","Opłata za rachunek pomocniczy…","PKOB1/2026/07/01","","PLN"`.

Ograniczenia i uwagi:

* **Numer referencyjny** jest generowany jako `PKOB1/RRRR/MM/NN` (stała `REFERENCE_PREFIX`
  w skrypcie). Dla kilku rachunków warto używać różnych prefiksów. Numer z banku (kolumna
  „Numer referencyjny” w CSV Pekao) nie jest obecnie wykorzystywany.
* **ERPNext nie wykrywa duplikatów.** Ponowny import tego samego pliku tworzy drugi komplet
  transakcji. Każdy miesiąc importujemy raz. W razie pomyłki anulujemy i usuwamy zbędne
  *Bank Transaction* (lista z filtrem po dacie i koncie).
* Waluta w pliku musi odpowiadać walucie konta bankowego.
* Gdy import kończy się częściowo, *Show Failed Logs* pokazuje błędne wiersze, a
  *Pobierz wiersze z błędami* daje plik do poprawy i ponownego importu tylko tych wierszy.

### 6.4. Rozliczanie: szkice z `erpnext_poland`

Na formularzu zatwierdzonej *Transakcji bankowej* jest grupa przycisków **Utwórz szkic (Create Draft)**:

* **Płatność**: wybór typu strony (Supplier/Customer/Employee) i kontrahenta (podpowiadany
  po IBAN z jego *Bank Account*) oraz lista otwartych dokumentów. Faktury, których numery
  występują w tytule przelewu, są zaznaczone automatycznie. Powstaje szkic *Payment Entry*.
* **Polecenie księgowania (prowizja, odsetki…)**: szkic *Journal Entry* na dowolne konto.
  Domyślne konto prowizji ustawia się w *Polish Accounting Settings → Bank*.
* **Przelew między własnymi rachunkami**: wyszukuje przeciwstawną transakcję o tej samej kwocie
  na innym rachunku firmy (±5 dni) i tworzy jeden szkic *Contra Entry* dla obu.

Szkice pamiętają transakcję źródłową. Proces jest dwuosobowy: osoba importująca wyciąg
przygotowuje szkice, a księgowa je sprawdza i **zatwierdza**. Dopiero przy zatwierdzeniu
transakcja bankowa zostaje uzgodniona. Anulowanie lub usunięcie szkicu przywraca transakcję
do rozliczenia. Formularz transakcji pokazuje listę szkiców czekających na zatwierdzenie.

Typowe komunikaty:

| komunikat | przyczyna / rozwiązanie |
|---|---|
| *Bank Account … has no ledger account set* | w *Bank Account* brak konta księgowego (02_konfiguracja, punkt 5) |
| *Bank Transaction … is not submitted* | transakcje zaimportowano jako szkice: zatwierdź je albo importuj z *Submit After Import* |
| *Bank Transaction … is already fully reconciled* | transakcja jest już rozliczona; sprawdź powiązane płatności w zakładce transakcji |
| kontrahent nie jest podpowiadany | brak IBAN kontrahenta w jego *Bank Account* |

---

## 7. KSeF – obsługa

### 7.1. Kontrola codzienna

* `/desk/scheduled-job-log`: wykonania `register_from_ksef` (codziennie)
  i `check_sent_invoices_status` (co 30 min),
* `/desk/error-log`: wpisy „KSeF fetch error” i „KSeF - missing invoice number”.
  Ten drugi oznacza, że KSeF nie nadał jeszcze numeru. Faktura zostanie pobrana przy następnym
  uruchomieniu (okno 30 dni), więc interwencja nie jest potrzebna,
* faktury sprzedaży ze statusem `Sent` dłużej niż kilka godzin albo `Rejected`/`Error`:
  komunikat w zakładce **JPK i KSeF** i w *Error Log*.

### 7.2. Certyfikat

* Data ważności: `openssl pkcs12 -in cert.pfx -nodes | openssl x509 -noout -enddate`. Odnowienie
  planujemy z wyprzedzeniem: nowy CSR (`ksef/01_pfx/01key_csr.sh`), PFX (`02pfx.sh`), potem
  podmiana załącznika i hasła w *Polish Accounting Settings*.
* Błąd odszyfrowania hasła PFX po przeniesieniu witryny oznacza inny `encryption_key`
  (patrz kopie). Przenieś klucz albo wpisz hasło ponownie.

### 7.3. Pliki XML

Pobierane faktury zapisują się jako `<ksefID>.xml` w katalogu roboczym procesu (katalog
bench lub `sites/`) i są dołączane do faktury zakupu jako załącznik. Po dołączeniu kopie
w katalogu bench nie są potrzebne. Można je okresowo przenosić do archiwum, ale nie
usuwamy ich z `sites/<witryna>/private/files`.

### 7.4. Pozycje faktur zakupu

Faktury z KSeF trafiają jako **szkice** *Purchase Invoice* z pozycjami według trybu
z ustawień (02_konfiguracja, punkt 8.3). Przed zatwierdzeniem księgowa uzupełnia konta
kosztowe i MPK. Tryb KSeF-PENDING wymaga istniejącego asortymentu o kodzie z ustawień.
Przy jego braku import kończy się błędem.

---

## 8. Typowe problemy

| objaw | przyczyna | rozwiązanie |
|---|---|---|
| `requires a different Python … not in '<3.15,>=3.14'` przy `bench init`/`update` | `env/` na systemowym Pythonie 3.12/3.13 | `napraw_srodowisko.sh --odtworz` (01_instalacja, punkt 1.3) |
| po aktualizacji `bench` nie działa, błędy importu `click` | stary `click` w `env/` | `env/bin/pip install -U "click>=8.3.1"` (robi to `napraw_srodowisko.sh`) |
| `ModuleNotFoundError: frappe` / uszkodzona paczka frappe | przerwana instalacja | `env/bin/pip uninstall -y frappe`, `bench setup env`, `bench setup requirements` (albo `napraw_srodowisko.sh`) |
| `bench build` się wywala na `esbuild-plugin-vue3` | niezgodność wtyczki z Vue 3.5+ | `cd apps/frappe && yarn add esbuild-plugin-vue3@latest --dev && yarn install`, potem `bench build --force` |
| `bench build` kończy się *Killed* | brak pamięci | swap (`sh/setup/00_swap.sh`) |
| 502 Bad Gateway | nie działa web (gunicorn) | `systemctl status erpnext-bench-frappe-web`, `logs/web.error.log`, `restart.sh` |
| strona bez stylów, 404 na `/assets` | brak builda albo nginx nie ma dostępu do `sites/assets` | `przebuduj.sh`; `chmod o+x` na katalogach do `sites` |
| „System w trakcie konserwacji” nie znika | `maintenance_mode` w `common_site_config.json` | `tryb.sh serwis off` |
| KSeF nie pobiera faktur, przypomnienia nie wychodzą | scheduler wyłączony lub `pause_scheduler: 1` | `tryb.sh scheduler on`, `bench doctor` |
| zadania w tle nie ruszają (import, usuwanie transakcji) | worker nie działa lub zawieszona kolejka | `bench doctor`, `/desk/rq-job`, restart; w ostateczności `wyloguj_wszystkich.sh` (czyści kolejki) |
| konflikt portów redis przy `bench start` | działa systemowy `redis-server` lub drugi bench na tych samych portach | zmień porty w `config/redis_*.conf` i `common_site_config.json` albo `sudo systemctl stop redis-server` |
| po migracji brak pól JPK/KSeF na formularzach | pola z `hooks.py` nie zostały utworzone | `konsola.sh konsola/utworz_pola_custom.py`, `przeladuj_doctype.sh "Sales Invoice" "Purchase Invoice" Account`, `cache.sh` |
| formularz nie pokazuje zmian w doctype | cache / stara definicja | `przeladuj_doctype.sh <DocType>`, `cache.sh`, odświeżenie przeglądarki (Ctrl+Shift+R) |
| pusty obszar roboczy (np. JPK) po aktualizacji | stary format Workspace (`links` bez `content`) | `konsola/workspace_linki_na_content.py` |
| *Encryption key is invalid* | witryna odtworzona bez oryginalnego `encryption_key` | przywróć klucz w `site_config.json` albo wpisz ponownie hasła (PFX, poczta) |
| nie można anulować płatności walutowej, bo wskazuje na zapis różnic kursowych | powiązanie `exchange_gain_loss_journal` z anulowanym lub usuniętym zapisem | `konsola/odlacz_roznice_kursowe.py` (ustaw numer płatności), potem ewentualnie ręczny zapis różnic |
| nie można usunąć dokumentu | ERPNext anuluje zamiast usuwać | anulowanie; usuwanie anulowanych według ustawień (02_konfiguracja, punkt 1.3) |
| trzeba wyczyścić dane testowe firmy przed startem | | Firma → *Delete all transactions for this company* albo `konsola/usun_transakcje_firmy.py` (**nieodwracalne**, najpierw kopia) |
| PDF bez nagłówków/stopek, rozjechany | wkhtmltopdf bez patched Qt | `sh/setup/03_wkhtmltopdf.sh` |
| podwojone transakcje bankowe | ponowny import tego samego wyciągu | punkt 6.3 |

Bezpośrednie zmiany w bazie (`baza.sh`) omijają walidacje ERPNext. Stosujemy je tylko wtedy,
gdy nie ma innej drogi, zawsze po kopii i najlepiej najpierw na kopii testowej. Przy
`UPDATE`/`DELETE` bez klucza w konsoli MariaDB potrzebne jest `SET SQL_SAFE_UPDATES = 0;`.

---

## 9. Bezpieczeństwo

* Na zewnątrz otwarte są tylko porty 80 i 443 (nginx). MariaDB i Redis słuchają na `127.0.0.1`.
  Zapora: `ufw allow OpenSSH; ufw allow 'Nginx Full'; ufw enable`.
* Logowanie SSH kluczem, bez logowania roota.
* Hasła (root MariaDB, Administrator, hasło PFX, sekrety Keycloak) trzymamy w menedżerze haseł.
  **Nie wpisujemy ich do skryptów ani do repozytoriów.** `site_config.json` ma prawa `600`.
* Uwierzytelnianie dwuskładnikowe dla kont z rolą *System Manager* i *Accounts Manager*
  (*System Settings → Enable Two Factor Auth*).
* `developer_mode` i `server_script_enabled` tylko tam, gdzie są potrzebne. `developer_mode`
  nigdy na produkcji.
* Dane osobowe (studenci, kandydaci, PESEL): kopie i instancje testowe chronimy tak samo jak produkcję.

---

## 10. Kalendarz czynności

| kiedy | czynność |
|---|---|
| codziennie (automatycznie) | `kopia.sh` z crona, kopia poza serwer |
| codziennie | przegląd *Error Log* i szkiców faktur z KSeF |
| co tydzień | `status.sh`, miejsce na dysku, nieudane zadania w `/desk/rq-job` |
| co miesiąc | aktualizacja (`aktualizacja.sh`) po teście na kopii; import wyciągów i rozliczenie transakcji bankowych przed JPK_V7M |
| co kwartał | test odtworzenia kopii; synchronizacja forka education z upstream |
| przed wygaśnięciem | odnowienie certyfikatu KSeF (PFX); certyfikat SSL odnawia się sam (sprawdź `certbot renew --dry-run`) |
