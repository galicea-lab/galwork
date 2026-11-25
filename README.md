# Galwork

wersja: 0.1.4

<!-- 2026-11-25: odnośniki do publikacji, opis repozytorium i przykładowego wdrożenia -->
**Strona projektu: [https://galwork.net](https://galwork.net/)**

Publikacje o projekcie (repozytoria źródłowe tych publikacji nie są udostępnione na GitHubie):

| publikacja | adres | dla kogo |
|---|---|---|
| e-book **„Galwork”** – strategia cyfryzacji, architektura, poradnik wdrożeniowca, przykłady (w tym opis wdrożenia w Fundacji Galicea) | [https://galwork.net/ebook/](https://galwork.net/ebook/) | decydenci, analitycy, wdrożeniowcy |
| **Podręcznik dewelopera** – implementacja, integracje, zasady wytwarzania (gałęzie, wersje, wydania) | [https://galwork.net/devbook/](https://galwork.net/devbook/) | programiści, administratorzy |

## O projekcie

Galwork to otwarty zestaw aplikacji, który łączy systemy przedsiębiorstwa albo uczelni
(ERP, obieg dokumentów, systemy państwowe, magazyn dokumentów, zarządzanie projektami)
w jedną całość. Centralnym elementem jest hub integrujący **`galwork-hub`**: silnik obiegów
BPMN, formularze, sprawy i **konektory** do systemów zewnętrznych. Aplikacje frontendowe
łączą się z hubem przez API, a tożsamość zapewnia Keycloak (OIDC).

To repozytorium zawiera ogólne informacje o projekcie, definicje wdrożenia obejmujące całość
oraz przykładowe wdrożenie. Szczegóły są w podprojektach.

## Podprojekty

| repozytorium | rola | dostępność |
|---|---|---|
| `galwork-hub` | hub: obiegi BPMN, formularze, sprawy, konektory (ERPNext, Frappe Education, e-Doręczenia, Paperless-ngx, KSeF, pieczęć, Taiga, …), API | [GitHub](https://github.com/galicea-lab/galwork-hub) |
| `galwork-dashboard` | intranet: zadania obiegów, sprawy, pulpit z widżetami | [GitHub](https://github.com/galicea-lab/galwork-dashboard) |
| `galwork-edu` | portal dla szkół i uczelni (studenci, kandydaci, dziekanat) | [GitHub](https://github.com/galicea-lab/galwork-edu) |
| `galwork-arena` | projektowanie i testowanie obiegów, formularzy i słowników | [GitHub](https://github.com/galicea-lab/galwork-arena) |
| `galwork-react` | komponenty React (m.in. `nextjs-keycloak-auth`, widżety formularzy RJSF) | [GitHub](https://github.com/galicea-lab/galwork-react) |
| `galwork-pm` | zarządzanie projektami i rozliczenia czasu pracy | code.galicea.org |
| `galwork-models` | biblioteka modeli obiegów (BPMN + formularze) | code.galicea.org |
| `galwork-seal` | usługa pieczęci elektronicznej (PAdES, klucz w PKCS#11) | code.galicea.org |

Aplikacje Frappe/ERPNext rozwijane razem z Galwork:

| repozytorium | rola | dostępność |
|---|---|---|
| `erpnext_poland` | polska lokalizacja ERPNext v16: JPK_V7M, KSeF 2.0, dzienniki, wydruki faktur | [GitHub](https://github.com/galicea-lab/erpnext_poland) |
| `education` | fork Frappe Education: API portalu, POL-on, legitymacje, uprawnienia | [GitHub](https://github.com/galicea-lab/education) |
| `admissions_poland` | rekrutacja na studia według polskich przepisów | code.galicea.org |
| `endesive` | fork biblioteki podpisów: PAdES (`ETSI.CAdES.detached`), `pypdf<7` | [GitHub](https://github.com/galicea-lab/endesive) |

Podprojekty klonuje się obok siebie w jednym katalogu roboczym (`../galwork-*`). Skrypty
i pliki compose z tego repozytorium zakładają taki układ.

## galwork-hub

Hub zawiera **konektory** do różnych systemów: ERP, obieg dokumentów, systemy państwowe
i serwisy zewnętrzne. Konektory są wykorzystywane w **aplikacjach** sterowanych przez API
albo w zadaniach uruchamianych cyklicznie (`cron`, katalog `scripts` w `galwork-hub`).
Konfiguracja huba: `config/config.ini` albo zmienne środowiskowe `<SEKCJA>_<KLUCZ>`
(opis w `config/config.ini.example` w `galwork-hub`).

## Zawartość tego repozytorium

| ścieżka | zawartość |
|---|---|
| `example/docker-compose.yml` | minimalne wdrożenie: `hub` i `arena` z obrazów z rejestru; baza PostgreSQL i Keycloak są zewnętrzne |
| `example/docker-compose.yml-with_dashboard` | wariant budujący obrazy lokalnie (hub, dashboard, arena) |
| `example/.env.example` | szablon `.env` dla `example/docker-compose.yml` |
| `example/setup1.sh`, `example/setup2.sh` | katalog definicji obiegów (`/srv/galwork/spiffworkflow`, kopia z `galwork-hub/spiffworkflow` albo `galwork-models`) i konfiguracja nginx |
| `example/nginx/` | vhosty nginx hosta dla huba, areny i dashboardu |
| `example/galicea/` | **przykładowe wdrożenie w Fundacji Galicea** (opis niżej) |
| `.env.example` | szablon `.env` do budowania obrazów (`NPM_TOKEN`, `NEXT_PUBLIC_*`) |
| `deploy/nginx/galwork_arena.conf` | vhost nginx areny |
| `deploy/seal/seal.toml` | konfiguracja usługi pieczęci `galwork-seal` (bez sekretów) |
| `secrets/npmrc.example` | wzór `secrets/npmrc` dla rejestru npm `code.galicea.org` |
| `scripts/build_hub.sh [tag]`, `scripts/build_arena.sh [tag]` | budowa i wypchnięcie obrazów do `registry.galicea.org` |
| `scripts/publish_react.sh` | publikacja pakietu `@galicea/nextjs-keycloak-auth` |
| `scripts/check-ai-comments.mjs` | kontrola znaczników `AI RRRR-MM-DD:` w komentarzach |
| `repos/` | skrypty pracy z repozytoriami: gałęzie, commity, PR, wydania (opis w `repos/README.md` i w podręczniku dewelopera) |

Pliki z sekretami są poza repozytorium (`.gitignore`): `.env`, `repos/.env*`, `secrets/npmrc`
oraz `secrets/seal/` (hasła Valkey, PIN-y tokenu, ACL, łańcuch certyfikatów).

## Uruchomienie minimalne

```bash
cd example
cp .env.example .env          # uzupełnij: DATABASE_URL, KEYCLOAK_*, APP_*, SPIFFWORKFLOW_DIR
./setup1.sh                   # definicje obiegów z ../../galwork-hub/spiffworkflow -> /srv/galwork/spiffworkflow
docker compose pull
docker compose up -d
```

* Tagi obrazów w `example/docker-compose.yml` ustaw na aktualne wydania
  (`registry.galicea.org/galwork-hub:<tag>`, `galwork-arena:<tag>`).
* Migracje bazy huba (Alembic) wykonują się przy starcie kontenera.
* Pełna procedura z Keycloakiem, bazą, frontami, pieczęcią i integracjami jest opisana
  w przykładowym wdrożeniu (niżej) i w podręczniku dewelopera.

## Budowanie obrazów

```bash
cp .env.example .env                 # NPM_TOKEN, NEXT_PUBLIC_* (wklejane do bundla przy buildzie)
cp secrets/npmrc.example secrets/npmrc
scripts/build_hub.sh 0011
cp .env .. && scripts/build_arena.sh 0009   # kontekst builda = katalog roboczy (..)
```

Plik `.dockerignore` musi leżeć w katalogu roboczym (`../.dockerignore`), bo to kontekst
builda obrazów areny i dashboardu.

## Przykładowe wdrożenie: Fundacja Galicea

Katalog **`example/galicea/`** zawiera skrypty i konfiguracje z rzeczywistego wdrożenia
w Fundacji Galicea (2026). Sekrety, adresy IP i hosty baz zastąpiono wartościami
przykładowymi. Pliki `*.example` to wzory plików, które w prawdziwym wdrożeniu leżą poza
repozytorium. Opis wdrożenia dla inżynierów („Przykład: wdrożenie Galwork w Fundacji
Galicea”) jest w części „Przykłady” [e-booka](https://galwork.net/ebook/).

| katalog | krok wdrożenia |
|---|---|
| `01keycloak/` | realm `galicea`, klient publiczny `galwork` (PKCE), grupy, ochrona przed zgadywaniem haseł |
| `03server/` | serwer: vhosty nginx, certbot, Node 22 dla usług systemd |
| `05baza/` | baza huba w PostgreSQL, migracje, dane startowe (słowniki) |
| `06galwork_hub/` | hub, arena i pieczęć w docker compose, ansible, `env.example`, lista sekretów |
| `07galwork_front/` | fronty (PM jako Next.js standalone, edu i dashboard statycznie) wdrażane ansiblem z wydaniami i rollbackiem |
| `02erpnext/` | ERPNext v16 z `erpnext_poland`, `education`, `admissions_poland`: instalacja (Python 3.14), konfiguracja (plan kont, VAT, KSeF, JPK), podręcznik administratora, skrypty `sh/setup` i `sh/admin` |
| `04edoreczenia/` | e-Doręczenia: certyfikat, test skrzynki |
| `08paperless-ngx/` | Paperless-ngx z logowaniem przez Keycloak |
| `09taiga/` | integracja Taiga – galwork-pm – ERPNext (**w realizacji**): runbook, konfiguracja ERPNext, dane startowe, cron |

Indeks plików: `example/galicea/README.md`.

## Licencje

Licencje są określone w poszczególnych podprojektach: `galwork-hub`, `galwork-arena`, `galwork-edu` – MPL 2.0, `galwork-dashboard` – Apache 2.0, `galwork-react` – MIT. To repozytorium nie ma jeszcze pliku `LICENSE`.
