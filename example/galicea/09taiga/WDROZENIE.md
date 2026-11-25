# Wdrożenie integracji Taiga – galwork-pm – ERPNext: Fundacja Galicea

Data: 2026-11-21. Opis rozwiązania: podręcznik dewelopera, https://galwork.net/devbook/ (integracje, „Taiga – galwork-pm – ERPNext”). Kod: galwork-hub, gałąź `feature/jw/TG-57-taiga-adapter` (Etapy 1–5); galwork-pm – sekcja `/rozliczenia` (Etap 4); galwork-models – `projekty/przeglad-tygodnia` (Etap 5).

| System | Adres | Uwagi |
|---|---|---|
| Taiga | https://taiga.galicea.org | bez zmian; projekt `galwork` (id 7) |
| galwork-hub | bez zmian | baza huba bez zmian (zob. krok D) |
| ERPNext | **https://galicea.transmem.pl** | firma „Fundacja Galicea” (skrót FG) |

Pliki w tym katalogu:
- `erpnext_setup.sh` – konfiguracja ERPNext (rola, uprawnienia, ustawienia, pole). Domyślnie tylko sprawdza, zmienia z `--apply`;
- `seed_pm_taiga_galicea.json` – dane startowe (do uzupełnienia: `erp_project`).

Kolejność ma znaczenie: krok F (stan początkowy) **musi** być przed pierwszym `process`.

---

## A. ERPNext (galicea.transmem.pl)

1. **Activity Types** (rodzaje prac): `programowanie`, `dokumentowanie`, `testowanie`, `wdrażanie`.
   - Stawki `billing_rate` (sprzedaż) i `costing_rate` (koszt). ⚠️ Na instancji testowej były równe, co daje zerową marżę w raportach rentowności. Ustalić z księgowością.
   - Nieużywane typy domyślne (Communication, Execution, Planning, Proposal Writing, Research) wyłączyć (`disabled`), żeby nie pojawiały się w słowniku.
2. **Activity Cost** (opcjonalnie): stawki pracownik × rodzaj pracy. ⚠️ Brak stawki ERPNext przyjmuje po cichu jako 0, bez błędu.
3. **Pracownicy (Employee)** dla każdej osoby rozliczającej czas w Taidze, z polem **`user_id` (albo `company_email`) równym e-mailowi konta w Taidze**. Wtedy mapowanie osób zaproponuje się samo (krok E).
4. **Projekt (Project)** dla projektu Taigi `galwork`, status `Open`. Zanotować jego `name` (np. `PROJ-0001`) – trafi do seeda.
5. **Konto techniczne huba**, np. `galwork-hub@galicea.org` (ręcznie, w *User*):
   - typ *System User*, **bez profilu ról** (profil przy zapisie użytkownika odtwarza role – tak było z `demo5` na teście);
   - po kroku 6 – **tylko** rola `Galwork Integracja`;
   - *API Access → Generate Keys*: klucz i sekret trafiają do huba (krok C). Sekret jest pokazywany tylko raz.
6. **Konfiguracja skryptem** (klucz API administratora, nie konta technicznego):
   ```bash
   export ERP_URL=https://galicea.transmem.pl ERP_KEY=... ERP_SECRET=...
   export TECH_USER=galwork-hub@galicea.org
   export ACTIVITY_TYPES="programowanie,dokumentowanie,testowanie,wdrażanie"
   ./erpnext_setup.sh            # podgląd: co jest, czego brakuje
   ./erpnext_setup.sh --apply    # rola + uprawnienia, ignore_employee_time_overlap, pole galwork_ref
   ./erpnext_setup.sh            # kontrola: oczekiwane „do zrobienia=0, błędy=0”
   ```
   Skrypt ustawia:
   - **rolę `Galwork Integracja`**: Timesheet – read, write, create, submit, cancel, amend (bez delete); Employee, Project, Activity Type, Activity Cost – read. Uprawnienia nadaje przez Role Permission Manager, nie bezpośrednim zapisem Custom DocPerm;
   - **`Projects Settings.ignore_employee_time_overlap = 1`**. ⚠️ To ustawienie globalne: wyłącza kontrolę nakładania także dla Timesheetów wpisywanych ręcznie. Uzgodnić z osobami, które korzystają z ERPNext bezpośrednio;
   - **Custom Field `Timesheet.galwork_ref`**: bez `unique`, z indeksem.

   Skrypt sprawdzony 2026-11-21 na instancji testowej (podgląd → `--apply` → kontrola: 15 × OK, 0 do zrobienia).
7. **Sprawdzenie konta technicznego** (krok 5 + 6): `TECH_USER` w podglądzie skryptu – role, brak profilu, klucz API.

## B. Taiga (taiga.galicea.org)

1. Konto techniczne `galwork` (id **9**) – członek projektu `galwork` z flagą **Admin** (bez niej brak dostępu do webhooków i ich logu; audyt zgłasza `technical_not_admin`).
2. Atrybuty „Czas [h]” w projekcie `galwork` już są (zadanie id 1, US id 1). Dla kolejnych projektów: `python3 scripts/pm_taiga.py register <slug> --apply` (przy pustym `webhook_url` tworzy tylko atrybuty i powiązanie).
3. Webhook: **nie zakładamy** (decyzja: webhook opcjonalny, zmiany z timeline'u). Jeśli w projekcie jest stary webhook do n8n – usunąć.
4. Role w projekcie (UX 37, Design 38, Front 39, Back 40, Product Owner 41, Stakeholder 42) – przypisać osobom role odpowiadające rodzajowi pracy, jeśli słownik ma korzystać z ról (krok G).

## C. Konfiguracja huba (`galwork-hub/config/config.ini`)

```ini
[taiga]
base_url=https://taiga.galicea.org
username=galwork
# hasło: zmienna środowiskowa TAIGA_PASSWORD (zalecane) albo tutaj
password=
technical_user_id=9
# puste = bez webhooka, zmiany tylko z timeline'u
webhook_url=
timeout=30
activity_types=programowanie,dokumentowanie,testowanie,wdrażanie
# zapis Timesheetów do ERPNext - włączyć dopiero w kroku L
erp_sync=false

[erpnext]
base_url=https://galicea.transmem.pl
# klucz konta technicznego z kroku A.5 (albo ERPNEXT_API_KEY / ERPNEXT_API_SECRET)
api_key=...
api_secret=...
```

Kontrola połączeń (z katalogu `galwork-hub`):
```bash
python3 -c "from connector.taiga.taiga import TaigaConnector as T; t=T(); print('Taiga', t.test_connection(), t.technical_user_id)"
python3 -c "from connector.erpnext.erpnext import ErpNextConnector as E; e=E(); print('ERPNext', e.test_connection(), [x['name'] for x in e.get_list('Employee', fields=['name'])])"
```
⚠️ Inne funkcje huba korzystające z `[erpnext]` (np. widget „Faktury do zatwierdzenia”) też przejdą na galicea.transmem.pl i na konto techniczne z samą rolą `Galwork Integracja`. Jeśli potrzebują innych uprawnień, trzeba je dodać do konta albo rozdzielić konfigurację.

## D. Baza huba

1. Migracje: `cd galwork-hub && alembic upgrade head` (Etap 1: `b7c1d9e2f4a8`, Etap 2: `c4e2a8f1d3b6`, Etap 3: `d6f3b9a2c5e7`).
2. **Dane testowe.** Jeśli produkcja używa tej samej bazy, w której testowano (seed testowy, zdarzenia, dziennik z identyfikatorami testowego ERPNext), trzeba je usunąć przed seedem produkcyjnym. Dziennik jest chroniony wyzwalaczem (append-only), więc usunięcie wymaga wyjątku administracyjnego w tej samej transakcji:
   ```sql
   BEGIN;
   SET LOCAL galwork.allow_purge = 'on';
   DELETE FROM pm_erp_posting;
   DELETE FROM pm_erp_timesheet;
   DELETE FROM pm_work_ledger;
   DELETE FROM pm_taiga_item;
   DELETE FROM pm_activity_map;
   DELETE FROM pm_week_approval;
   DELETE FROM pm_period_close;
   DELETE FROM pm_taiga_event;
   DELETE FROM pm_person_link;
   DELETE FROM pm_taiga_project_link;
   COMMIT;
   ```
   Przed wykonaniem sprawdzić, co jest w tabelach (`SELECT count(*) ...`). Te tabele zawierają tylko dane integracji.

## E. Dane startowe i osoby

1. Uzupełnić `erp_project` w `seed_pm_taiga_galicea.json` (krok A.4), potem:
   ```bash
   python3 scripts/pm_taiga.py seed ../galwork/example/galicea/09taiga/seed_pm_taiga_galicea.json
   ```
2. Mapowanie osób po e-mailu (Taiga `memberships.user_email` ↔ `Employee.user_id` / `company_email`):
   ```bash
   python3 scripts/pm_taiga.py persons 7            # podgląd: new / exists / no_match / no_email
   python3 scripts/pm_taiga.py persons 7 --apply    # propozycje jako niezatwierdzone
   python3 scripts/pm_taiga.py confirm-person <taiga_user_id> <HR-EMP-xxxxx>   # dla każdej osoby
   ```
   Osoby `no_match` dopisać przez `confirm-person` ręcznie albo poprawić e-mail w Employee. Konto techniczne (id 9) jest pomijane.

## F. Stan początkowy – PRZED pierwszym `process`

```bash
python3 scripts/pm_taiga.py baseline 7
```
Rejestruje bieżące godziny wszystkich zadań i US jako już istniejące – **nie będą zaksięgowane**. Bez tego kroku zdarzenia projektu czekają w kolejce. Uruchomić możliwie blisko `billing_from` (2026-11-30).

## G. Słownik rodzajów prac

Kolejność rozstrzygania: zadanie → US → epika → rola wykonawcy → domyślny rodzaj pracy projektu → triaż. Każda zmiana najpierw jako podgląd, potem `--apply`:
```bash
python3 scripts/pm_taiga.py map 7 role 40 programowanie            # podgląd skutków
python3 scripts/pm_taiga.py map 7 role 40 programowanie --apply    # Back -> programowanie
python3 scripts/pm_taiga.py map 7 role 39 programowanie --apply    # Front -> programowanie
python3 scripts/pm_taiga.py map 7 epic <id epiki> dokumentowanie --apply
python3 scripts/pm_taiga.py map 7 userstory <id US> testowanie --apply
python3 scripts/pm_taiga.py map 7                                   # bieżący słownik
```
Przypisania ról UX/Design/PO/Stakeholder – do decyzji (brak odpowiadającego Activity Type). Bez przypisania pozycje trafiają do triażu (`anomalies`: `no_activity_type`).

## H. Uruchomienie cykliczne

`scripts/cron_pm_taiga.sh` (ścieżki `PROJECT_HOME`, `VIRTUALENV` dopasować do serwera):
```cron
*/20 * * * *  /srv/galwork/galwork-hub/scripts/cron_pm_taiga.sh
15 6 * * *    /srv/galwork/galwork-hub/scripts/cron_pm_taiga.sh --daily
```
- co 20 min: `reconcile` (timeline + wykrywanie usunięć), `process` (dziennik) i `erp-sync` (bez zapisu, dopóki `erp_sync=false`);
- raz dziennie: `audit`, `erp-check` i `purge` (retencja surowych zdarzeń 90 dni).

## I. Kontrola po uruchomieniu

```bash
python3 scripts/pm_taiga.py audit           # oczekiwane: tylko [info] webhook_disabled
python3 scripts/pm_taiga.py summary 7       # tydzień × osoba × projekt × rodzaj pracy
python3 scripts/pm_taiga.py anomalies 7     # do przeglądu przez PM raz w tygodniu
```

## J. Zamknięcie miesiąca (D11)

Po rozliczeniu miesiąca (termin ustala księgowość):
```bash
python3 scripts/pm_taiga.py close-month 2026-12
```
Tygodnie miesiąca (według czwartku) zostają zamrożone, a późniejsze korekty trafiają do najstarszego otwartego tygodnia jako nowe wpisy.

## K. Przed produkcją – formalności (RODO)

Zgodnie z opracowaniem RODO projektu:
- wpis do rejestru czynności przetwarzania;
- klauzula informacyjna dla zespołu (w tym: Timesheet z integracji nie jest ewidencją czasu pracy);
- okresy retencji;
- zakres wglądu;
- ocena IOD dotycząca dziennika zmian.

## L. Timesheety w ERPNext (Etap 3) – włączenie

1. Kontrola danych w ERPNext:
   ```bash
   python3 scripts/pm_taiga.py erp-check     # oczekiwane: brak [error]
   ```
2. Plan bez zapisu – co hub wyśle:
   ```bash
   python3 scripts/pm_taiga.py erp-sync --dry-run
   ```
   Pokazuje dokumenty (osoba × projekt × tydzień), korekty niezrealizowane i godziny „nie do wysłania” (brak pracownika, projektu albo rodzaju pracy – zob. `anomalies 7`).
3. Włączenie: `[taiga] erp_sync=true` w `config.ini`, potem `python3 scripts/pm_taiga.py erp-sync` (dalej robi to cron).
4. Cykl tygodnia:
   - hub utrzymuje Draft;
   - PM zatwierdza tydzień: `python3 scripts/pm_taiga.py approve-week 7 2026-W49`;
   - następny `erp-sync` zatwierdza dokumenty (Submit).

   Korekta po zatwierdzeniu: hub anuluje dokument, tworzy poprawkę `…-1` (Draft) i cofa zatwierdzenie tygodnia, więc PM zatwierdza ponownie.
5. Dokumenty zafakturowane i tygodnie zamkniętych miesięcy nie są zmieniane. Różnice przechodzą na najbliższy otwarty tydzień, a ujemne bez pokrycia czekają jako korekta niezrealizowana (do decyzji PM, np. faktura korygująca).
6. Pusty Draft (wszystkie godziny przeniesione gdzie indziej) trzeba usunąć ręcznie – konto techniczne nie ma prawa usuwania.

## M. Ekrany galwork-pm „Rozliczenia” (Etap 4)

1. **Keycloak** – w kliencie używanym przez galwork-pm dopuścić adres przekierowania `https://<adres galwork-pm>/login` (oraz *Web Origins*).
2. **Budowanie galwork-pm** ze zmiennymi (wklejane do bundla w czasie `yarn build`):
   ```bash
   NEXT_PUBLIC_API_BASE=https://<adres huba>/v1/pm
   NEXT_PUBLIC_KEYCLOAK_URL=https://<keycloak>/realms/<realm>
   NEXT_PUBLIC_KEYCLOAK_CLIENT=<klient>
   ```
   Zależność `@galicea-lab/nextjs-keycloak-auth` pochodzi z rejestru `code.galicea.org` (`.npmrc`: `@galicea-lab:registry=...`).
3. **Hub:**
   - adres galwork-pm w `[app] cors_origins`;
   - administratorzy = `[keycloak] admin_groups` (opcjonalnie dodatkowe `[taiga] admin_groups`).
4. **PM projektu:** w ekranie „Konfiguracja” projektu (albo w seedzie) `triage_group` = grupa Keycloak PM-ów. Jej członkowie widzą projekt, edytują słownik i zatwierdzają tygodnie.
5. **Pracownicy:** „Mój tydzień” rozpoznaje osobę po e-mailu konta Keycloak = `Employee.user_id` albo `company_email` w ERPNext.

## N. Przegląd tygodnia – proces BPMN (Etap 5)

1. **Model** `galwork-models/projekty/przeglad-tygodnia` (klucz `pm-przeglad-tygodnia`) musi trafić do huba. Jeśli hub używa profilu obiegów (`[wf] process_profile`, np. `cyfryzacja`), dopisać do pliku profilu wiersz:
   ```
   projekty/przeglad-tygodnia
   ```
   Potem synchronizacja z dysku (galwork-dashboard: „Synchronizuj z dysku” albo `python3 scripts/seed_process_model.py --sync-all`) i **publikacja** wersji. `--sync-all` tworzy tylko szkic, więc publikuje się w dashboardzie albo poleceniem:
   ```bash
   python3 scripts/seed_process_model.py ../galwork-models/projekty/przeglad-tygodnia --key pm-przeglad-tygodnia --name "Przegląd tygodnia rozliczeń"
   ```
2. **Użytkownik kroków systemowych:** `[wf] system_user` (ten sam co dla `wf_wake.py`).
3. **Grupa PM:** `triage_group` projektu = grupa Keycloak. Jej członkowie dostają zadania „Przegląd tygodnia” i „Korekta” w galwork-dashboard.
4. **Link w przypomnieniach:** `[taiga] pm_url=https://<adres galwork-pm>` (opcjonalnie).
5. **Cron** (obok wpisów z kroku H):
   ```cron
   0 7 * * 1   /srv/galwork/galwork-hub/scripts/cron_pm_taiga.sh --weekly-review   # poniedziałek: przegląd poprzedniego tygodnia
   0 9 * * 4   /srv/galwork/galwork-hub/scripts/cron_pm_taiga.sh --remind          # czwartek: przypomnienie o godzinach
   ```
   Ręcznie: `python3 scripts/pm_taiga.py review-start --week 2026-W49 --project 7`.
6. **Wysyłka do ERPNext z procesu** działa tylko przy `[taiga] erp_sync=true` (krok L). Przy wyłączonej flaga proces kończy się zatwierdzeniem tygodni, a Timesheety wyśle synchronizacja po włączeniu.

## N2. Zespół i analizy (Etap 6)

- Przed startem przekazać zespołowi instrukcję **„Rozliczanie czasu w Taidze”** (podręcznik dewelopera https://galwork.net/devbook/, część II). W każdym projekcie założyć stałe historyjki organizacyjne („Spotkania i planowanie”, „Administracja projektu”, „Utrzymanie i drobne poprawki”) i przypisać im rodzaj pracy w słowniku.
- Budżet w zakładce „Analiza” wymaga powiązania projektu Taigi z projektem galwork-pm (`pm_project_id`) i WBS z godzinami. Bez tego analiza pokazuje tylko wykonanie i wskaźniki.

## O. Jeszcze nie w tym wdrożeniu

- Zapis tagów rodzaju pracy do Taigi (`taiga.tag_user_story`) – świadomie pominięty.

## Wycofanie

- Wyłączyć cron.
- Integracja nie zapisuje nic w Taidze (poza `register --apply`). W ERPNext zapisuje tylko przy `erp_sync=true` – wyłączenie flagi zatrzymuje zapis. Dokumenty już utworzone zostają (rozpoznawalne po `galwork_ref` = `pm:…`).
- Dane integracji: tabele `pm_*` z kroku D.2.
- Migracje: `alembic downgrade 63de9f44de14`.
