<!-- AI 2026-11-25: indeks materiałów wdrożenia w Fundacji Galicea (rozdział e-booka https://galwork.net/ebook/) -->
# Przykład wdrożenia: Fundacja Galicea

Skrypty i konfiguracje, do których odwołuje się rozdział **„Przykład: wdrożenie Galwork
w Fundacji Galicea”** e-booka [https://galwork.net/ebook/](https://galwork.net/ebook/)
(część „Przykłady”).
Materiał pochodzi z roboczego katalogu wdrożenia. **Sekrety usunięto**: hasła, klucze, PIN-y,
certyfikaty, adres skrzynki e-Doręczeń, adres IP serwera i host bazy zastąpiono wartościami
przykładowymi. Pliki `*.example` to wzory plików, które w prawdziwym wdrożeniu leżą poza repozytorium.

| katalog | zawartość | rozdział, punkt |
|---|---|---|
| `galwork_url.txt` | domeny i usługi wdrożenia | 2 |
| `01keycloak/` | eksport realmu `galicea` i klienta `galwork`, grupy, uwagi (`UWAGI.md`) | 4 |
| `03server/` | vhosty nginx, certbot, katalog `/var/www/galicea`, Node 22 | 5 |
| `05baza/` | zakładanie bazy huba, migracje, dane startowe (`slowniki_startowe.sql`) | 6 |
| `06galwork_hub/` | `docker-compose.yml` (hub, arena, pieczęć), `env.example`, ansible, konfiguracja pieczęci (`deploy/seal/`), lista sekretów (`secrets.md`) | 7, 12 |
| `07galwork_front/` | wdrożenie frontów (PM, Edu, Dashboard) ansiblem, `*.env.production` | 8 |
| `02erpnext/` | ERPNext v16: instalacja, konfiguracja, podręcznik administratora, skrypty `sh/setup` i `sh/admin`, plan kont, bank, KSeF | 9 |
| `04edoreczenia/` | test skrzynki e-Doręczeń (auth-sdk), `config.ini.example` | 10 |
| `08paperless-ngx/` | Paperless-ngx z logowaniem przez Keycloak, `wzor.env.example` | 11 |
| `09taiga/` | integracja Taiga – galwork-pm – ERPNext (**w realizacji**): runbook, `erpnext_setup.sh`, seed, cron, zmienne | 13 |

Uruchamianie skryptów: z ich katalogu, po uzupełnieniu plików `*.env` / `*.example` własnymi wartościami.
Ścieżki (`/setup/galicea/galwork`, `/var/www/galicea`, `/erp/erpnext-bench`) są ścieżkami instancji galicea.
