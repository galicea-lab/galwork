# ERPNext w Galicea – instrukcja instalacji

Ta instrukcja opisuje instalację **Frappe / ERPNext v16** bezpośrednio na serwerze (bez Dockera)
razem z aplikacjami Galicea:

| aplikacja | repozytorium | gałąź | rola |
|---|---|---|---|
| `frappe` | github.com/frappe/frappe | `version-16` | framework |
| `erpnext` | github.com/frappe/erpnext | `version-16` | ERP (księgowość, sprzedaż, zakupy, bank) |
| `education` | code.galicea.org/labc/erpnext-education (lustro: github.com/galicea-lab/education) | `develop` | **fork** frappe/education: portal API, POL-on, legitymacje, uprawnienia studentów i wykładowców |
| `erpnext_poland` | code.galicea.org/labc/erpnext_poland (lustro: github.com/galicea-lab/erpnext_poland) | `main` | polska lokalizacja: JPK_V7M, KSeF 2.0, dzienniki, wydruki faktur, polskie pola na kontach i fakturach, szkice płatności z wyciągu |
| `admissions_poland` | code.galicea.org/labc/admissions_poland | `main` | rekrutacja na studia (kampanie, kandydaci, kwalifikacja, decyzje, doręczenia) – wymaga `erpnext` i `education` |
| `hrms` (opcjonalnie) | github.com/frappe/hrms | `version-16` | kadry i płace |

Wzorcowa instancja (kopia bez bazy fundacji) jest w `/erp/erpnext-bench`. Działa na niej:
Python 3.14.8, Node 24, frappe 16.27, erpnext 16.28, hrms 16.13, bench 5.31, MariaDB 10.11, Redis 7.

Skrypty, które są tu opisane, leżą w `sh/setup/` (numeracja to kolejność uruchamiania).
Parametry instalacji ustawia się w `sh/setup/erp.env`. **W skryptach nie ma haseł.**
Bench i MariaDB pytają o nie interaktywnie.

---

## 1. Wymagania

### 1.1. Serwer

* Debian 13 (trixie) albo Ubuntu 24.04 LTS, 64-bit.
* Co najmniej 2 vCPU i 4 GB RAM. Zalecane 8 GB. Przy mniejszej pamięci trzeba dodać swap
  (`00_swap.sh`), bo `bench build` i `yarn` potrafią zająć kilka GB.
* Około 20 GB dysku plus miejsce na kopie bezpieczeństwa.
* Domena (rekord A/AAAA) wskazująca na serwer, np. `erp.example.org`. Nazwa witryny Frappe
  **musi być taka sama jak domena** obsługiwana przez nginx.
* Zwykły użytkownik z `sudo`. Bench **nie** działa jako root.

### 1.2. Wersje komponentów (Frappe v16)

| komponent | wymagana wersja | uwagi |
|---|---|---|
| **Python** | **>= 3.14, < 3.15** | wymóg `frappe` (`requires-python = ">=3.14,<3.15"`), także `erpnext_poland` i `admissions_poland` |
| Node.js | >= 24 | `engines.node` w frappe |
| yarn | 1.22+ | |
| MariaDB | 10.6+ (zalecane 11.4/11.8) | 10.11 z Ubuntu 24.04 działa poprawnie |
| Redis | 6+ | |
| wkhtmltopdf | 0.12.6 **with patched Qt** | wydruki PDF |
| xmlsec1 | z dystrybucji | podpis XAdES/XMLDSig dla KSeF i UPO (admissions_poland) |
| cron | | zadania harmonogramu, odnawianie certyfikatów |

### 1.3. Problem z Pythonem 3.14 (ważne!)

Frappe v16 wymaga **Pythona 3.14**. Żadna z popularnych dystrybucji serwerowych go jeszcze nie dostarcza:

* Debian 13 ma Pythona **3.13**,
* Ubuntu 24.04 ma Pythona **3.12**.

Przy instalacji pod Debianem dało to następujące objawy:

1. `bench init` tworzy środowisko `env/` z **systemowego** `python3`, nawet gdy aktywne jest
   inne venv. Instalacja frappe kończy się wtedy błędem w rodzaju
   `ERROR: Package 'frappe' requires a different Python: 3.13.x not in '<3.15,>=3.14'`.
2. W starszych notatkach pojawiała się rada, żeby podmienić `/usr/bin/python3` na 3.14.
   **Nie róbcie tego.** Od systemowego Pythona zależą `apt`, `certbot` i narzędzia
   dystrybucji, więc podmiana psuje system.

Poprawne rozwiązanie:

* Zainstalować Pythona 3.14 **lokalnie dla użytkownika** przez `pyenv` (`05_python314.sh`)
  albo przez `uv` (`uv python install 3.14`).
* Wskazać ten interpreter jawnie przy tworzeniu bench:
  `bench init ... --python ~/.pyenv/versions/3.14.x/bin/python3` (robi to `06_bench_init.sh`).
* Jeśli `env/` powstało już na złym Pythonie, odtworzyć je:
  ```bash
  cd /erp/erpnext-bench
  rm -rf env
  ~/.pyenv/versions/3.14.2/bin/python3 -m venv env
  env/bin/pip install -U pip
  source env/bin/activate && bench setup requirements
  ```
  To samo robi `sh/admin/napraw_srodowisko.sh --odtworz`.
* Do kompilacji Pythona przez pyenv potrzebne są pakiety `-dev` (instaluje je
  `01_pakiety_systemowe.sh`). Bez `libssl-dev`, `libffi-dev`, `libsqlite3-dev` i `libbz2-dev`
  Python się skompiluje, ale `pip` albo frappe nie zadziałają. `libzstd-dev` jest potrzebny
  modułowi `compression.zstd`, który pojawił się w 3.14.

> Po aktualizacji Pythona w obrębie 3.14 (np. 3.14.2 → 3.14.8) trzeba odtworzyć `env/`
> według powyższej procedury. Venv jest związany z konkretną ścieżką interpretera.

---

## 2. Instalacja krok po kroku

Najpierw ustawiamy parametry w `sh/setup/erp.env`:

```bash
INST_ROOT="/erp"                 # katalog główny
BENCH_NAME="erpnext-bench"       # katalog bench -> /erp/erpnext-bench
SITE="erp.example.org"           # witryna = domena
PY_VERSION="3.14.2"              # wersja Pythona instalowana przez pyenv
BRANCH="version-16"
# adresy repozytoriów education / erpnext_poland / admissions_poland i ich gałęzie
```

Następnie uruchamiamy skrypty po kolei z katalogu `sh/setup`.

### Krok 0. Swap (opcjonalnie) – `00_swap.sh`

Dla maszyn z ≤ 8 GB RAM. Tworzy `/swapfile` (domyślnie 8 GB) i dopisuje go do `/etc/fstab`.

### Krok 1. Pakiety systemowe – `01_pakiety_systemowe.sh`

Instaluje git, nginx, certbot, redis-server, cron, MariaDB z nagłówkami klienta
(`default-libmysqlclient-dev`, `pkg-config`), pakiety do kompilacji Pythona, xvfb/fonty do PDF
oraz `xmlsec1` z bibliotekami (KSeF). Klienta PostgreSQL (`libpq-dev`, `postgresql-client`)
potrzebujemy tylko wtedy, gdy np. Frappe Insights ma się łączyć z zewnętrzną bazą PostgreSQL.

### Krok 2. MariaDB – `02_mariadb.sh`

* Zapisuje `/etc/mysql/mariadb.conf.d/99-frappe.cnf` z kodowaniem `utf8mb4` / `utf8mb4_unicode_ci`.
  Frappe tego wymaga, a bez tego pojawiają się błędy przy polskich znakach i emoji.
* Uruchamia `mariadb-secure-installation`, w którym ustawiamy **hasło roota MariaDB**.
  Bench pyta o nie przy `new-site`, `restore` i `drop-site`. Hasło trzymamy w menedżerze haseł,
  nie w skryptach.

Ręczna alternatywa:

```sql
-- sudo mariadb
ALTER USER 'root'@'localhost' IDENTIFIED BY '<hasło roota>';
FLUSH PRIVILEGES;
```

### Krok 3. wkhtmltopdf – `03_wkhtmltopdf.sh`

Wersja z repozytorium dystrybucji **nie ma patched Qt**, przez co nagłówki i stopki wydruków
się rozjeżdżają. Instalujemy paczkę z github.com/wkhtmltopdf/packaging. Dla Debiana 13
i Ubuntu 24.04 nie ma osobnej paczki, ale działa wersja `bookworm`. Sprawdzamy:
`wkhtmltopdf --version` powinno pokazać `(with patched qt)`.

### Krok 4. Node.js 24 i yarn – `04_node_yarn.sh`

Node instalujemy przez `nvm` (wersja z apt jest za stara), a potem `npm install -g yarn`.
Gdy bench działa przez systemd, usługi muszą widzieć `node`. `bench setup systemd` wpisuje
ścieżkę z bieżącego PATH, więc generujemy go w powłoce z aktywnym nvm (dbają o to skrypty).

### Krok 5. Python 3.14 – `05_python314.sh`

Instaluje pyenv (dopisuje inicjalizację do `~/.bashrc`) i kompiluje `PY_VERSION`.
Alternatywa przez uv jest opisana w komentarzu skryptu. Wtedy w `erp.env` ustawiamy
`PYTHON314="$(uv python find 3.14)"`.

### Krok 6. Bench – `06_bench_init.sh`

* Tworzy `/erp` (właściciel: bieżący użytkownik).
* Tworzy `/erp/venv314` na Pythonie 3.14 i instaluje w nim narzędzie `frappe-bench`.
  Alternatywa: `uv tool install frappe-bench`.
* `bench init erpnext-bench --frappe-branch version-16 --python <python3.14>`. Ta komenda
  pobiera frappe, tworzy `env/`, instaluje zależności node i buduje zasoby.

Struktura bench:

```
erpnext-bench/
├── apps/          kod aplikacji (repozytoria git)
├── config/        redis_*.conf, nginx.conf, systemd/
├── env/           środowisko Pythona 3.14 (bench + wszystkie aplikacje)
├── logs/          logi web, worker, scheduler
├── sites/
│   ├── apps.txt, apps.json, common_site_config.json
│   ├── assets/    zbudowane JS/CSS
│   └── <witryna>/ site_config.json, public/, private/ (pliki, kopie)
└── Procfile       procesy trybu deweloperskiego
```

> Od tej chwili głównym narzędziem jest `bench`. Uruchamiamy go z katalogu bench
> i z aktywnym `env/` (`source env/bin/activate`). Skrypty z `sh/setup` i `sh/admin`
> robią to same (plik `_wspolne.sh`).

### Krok 7. Aplikacje – `07_aplikacje.sh`

```bash
bench get-app erpnext --branch version-16
# bench get-app hrms --branch version-16                         # opcjonalnie
bench get-app education         <EDUCATION_URL>      --branch develop
bench get-app erpnext_poland    <ERPNEXT_POLAND_URL> --branch main
bench get-app admissions_poland <ADMISSIONS_URL>     --branch main
bench pip install pycryptodome     # KSeF (erpnext_poland) – nie ma go w pyproject.toml
```

Uwagi:

* Repozytoria `code.galicea.org` są prywatne. `git` potrzebuje dostępu przez klucz SSH
  (wtedy adres `git@code.galicea.org:labc/...`) albo przez zapisany token (git credential helper).
* **Fork education**: skrypt dodaje remote `upstream` → `github.com/frappe/education`.
  Przez niego synchronizujemy fork z oficjalnymi poprawkami (`sh/admin/fork_synchronizuj.sh`,
  opis w podręczniku administratora).
* Nie instalujemy oficjalnego `education` z rejestru Frappe. Aplikacja `admissions_poland`
  korzysta z API forka (`education.education.api.create_student`, numeracja albumów, portal).

### Krok 8. Witryna – `08_witryna.sh`

```bash
bench new-site erp.example.org --db-type mariadb     # pyta o hasło roota MariaDB i hasło Administratora
bench use erp.example.org
bench --site erp.example.org install-app erpnext
bench --site erp.example.org install-app education
bench --site erp.example.org install-app erpnext_poland
bench --site erp.example.org install-app admissions_poland
bench --site erp.example.org set-config server_script_enabled 1
bench --site erp.example.org enable-scheduler
bench --site erp.example.org migrate
```

Kolejność instalacji ma znaczenie: `erpnext` → `education` → `erpnext_poland` → `admissions_poland`.
Przy instalacji `erpnext_poland` dodaje pola niestandardowe (JPK, KSeF, miesiąc VAT) do
`Account`, `Sales Invoice`, `Purchase Invoice`, `Item` i `Company`, a także wydruki faktur,
dzienniki i obszary robocze **FK** i **JPK**. `admissions_poland` tworzy role
`Admissions Manager`, `Admissions Committee Chair` i `Admissions Committee Member`.

Po instalacji kreator konfiguracji (Setup Wizard) w przeglądarce prosi o język (polski),
kraj (Polska), walutę (PLN), firmę i rok obrachunkowy. Dalej postępujemy według
[02_konfiguracja_systemu.md](02_konfiguracja_systemu.md).

#### Konfiguracja `site_config.json` dla rekrutacji i portalu (education / admissions_poland)

W `sites/<witryna>/site_config.json` (sekretów nie commitujemy!):

```json
{
  "portal":   {"service_users": ["hub@uczelnia.example"]},
  "keycloak": {
    "server_url": "https://sso.example.org",
    "realm": "rekrutacja",
    "issuer": "https://sso.example.org/realms/rekrutacja",
    "allowed_clients": ["galwork-edu", "hub-konto"],
    "client_id": "hub-konto",
    "client_secret": "<sekret klienta>",
    "groups": {"Kandydat": ["kandydaci"], "Student": ["studenci"], "Instructor": ["wykladowcy"]}
  },
  "admissions_poland": {
    "xml_signing_key": "/ścieżka/key.pem",
    "xml_signing_cert": "/ścieżka/cert.pem"
  }
}
```

* `portal.service_users` to konta usługowe (galwork-hub) wywołujące API portalu kluczem API.
* `keycloak` służy do weryfikacji tokenów użytkowników (nagłówek `X-User-Token`). Bez tej sekcji
  żądania z tokenem użytkownika są odrzucane.
* `admissions_poland.xml_signing_*` to klucz i certyfikat do podpisu UPO/UPD. Gdy włączone jest
  „Require Signed Confirmations”, decyzji nie da się opublikować bez klucza.

Szczegóły są w `apps/admissions_poland/README.md`.

### Krok 9. Przeniesienie danych z kopii (opcjonalnie) – `09_przywroc_kopie.sh`

Gdy zamiast pustej witryny przenosimy istniejącą (np. z innego serwera):

```bash
./09_przywroc_kopie.sh 20260108_161117-site-database.sql.gz \
                       20260108_161117-site-files.tar 20260108_161117-site-private-files.tar
```

* Pliki `*.tgz` z `bench backup --compress` (i `*.tar.gz`) można podawać bezpośrednio. Ręczne
  `gzip -d`, jak w starych skryptach, nie jest potrzebne.
* **`encryption_key`**: zaszyfrowane pola (hasło certyfikatu KSeF, hasła kont pocztowych,
  klucze API) są szyfrowane kluczem z `site_config.json` serwera źródłowego. Ten klucz
  trzeba przenieść do `site_config.json` nowej witryny. Bez tego pojawi się błąd
  „Encryption key is invalid”.
* Jeżeli kopia ma inną nazwę witryny niż docelowa (np. `localhost` → domena), przywracamy ją
  do witryny `$SITE`. Zmiana nazwy katalogu w `sites/` (`mv sites/localhost sites/<domena>`)
  też zadziała, ale wtedy trzeba sprawdzić `sites/currentsite.txt` i ponownie wygenerować nginx.
* Na koniec skrypt wykonuje `migrate`, `build` i `clear-cache`.

### Krok 10. Usługi systemd – `10_systemd.sh`

W Galicea zamiast supervisora (`sudo bench setup production`) używamy systemd:

```bash
bench --site <witryna> set-config developer_mode 0
bench setup systemd --yes                       # generuje config/systemd/*.service, *.target
sudo ln -sf $PWD/config/systemd/*.service /etc/systemd/system/
sudo ln -sf $PWD/config/systemd/*.target  /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now erpnext-bench.target
```

Powstają jednostki `erpnext-bench-web.target` (gunicorn i socketio), `erpnext-bench-workers.target`
(workery i scheduler) oraz `erpnext-bench-redis.target`. Sterujemy całością przez
`erpnext-bench.target`.

> Redis bench (porty 11000/13000 z `config/redis_*.conf`) to osobne instancje.
> Systemowy `redis-server` (port 6379) nie jest wtedy potrzebny, choć nie przeszkadza.
> W `/erp/erpnext-bench` zmieniono porty na 11001/13001, żeby nie kolidowały z drugim benchem
> na tym samym serwerze (`common_site_config.json`: `redis_cache`, `redis_queue`, `redis_socketio`).

### Krok 11. nginx – `11_nginx.sh`

```bash
bench config dns_multitenant on
bench setup nginx --yes
sudo ln -sf $PWD/config/nginx.conf /etc/nginx/conf.d/erpnext-bench.conf
sudo nginx -t && sudo systemctl reload nginx
```

Przykładowa wynikowa konfiguracja (z SSL dodanym przez certbot) jest w
`sh/setup/nginx_witryna.conf.przyklad`.

* Gdy na jednym bench działa kilka witryn (np. `erp.`, `ipda.`, `erpnext.`), `bench setup nginx`
  generuje jeden plik ze wszystkimi witrynami. Do osobnej obsługi SSL przez certbot wygodnie
  jest go podzielić na pliki per witryna w `/etc/nginx/sites-enabled/`.
* **Każde ponowne `bench setup nginx` nadpisuje `config/nginx.conf`** razem z wpisami certbota.
  Po takiej regeneracji trzeba ponownie uruchomić `12_certbot.sh`.
* Osadzanie ERPNext w ramce innej aplikacji (CORS / iframe) wymaga zmiany nagłówków
  `X-Frame-Options` i `Content-Security-Policy: frame-ancestors ...` (patrz `doc/frappe_02_instalacja.md`).

### Krok 12. Certyfikat SSL – `12_certbot.sh`

`sudo certbot --nginx -d <witryna>`. Odnawianie obsługuje timer `certbot.timer`.
Można to sprawdzić przez `sudo certbot renew --dry-run`.

### Krok 13. Test – `13_test.sh`

Sprawdza wersje (Python 3.14, node 24), `bench version`, `list-apps`, `scheduler status`,
`doctor` (stan workerów i kolejek), jednostki systemd, porty oraz odpowiedź
`https://<witryna>/api/method/ping`, która powinna zwrócić `{"message":"pong"}`.

---

## 3. Instalacja deweloperska (lokalnie)

Jak wyżej, kroki 1–8, z witryną `localhost`, a potem:

```bash
bench --site localhost set-config developer_mode 1
bench start          # wszystkie procesy z Procfile; http://localhost:8000
```

Bez kroków 10–12. W `/erp/erpnext-bench` (kopia wzorcowa) włączone są `developer_mode`
i `live_reload`. **Uwaga**: w jej `common_site_config.json` są też ustawione
`maintenance_mode: 1` i `pause_scheduler: 1`. Przed użyciem trzeba je wyłączyć
(`sh/admin/tryb.sh serwis off`, `sh/admin/tryb.sh scheduler on`).

Uruchamianie testów jednostkowych aplikacji bez witryny opisuje `apps/admissions_poland/README.md`.
Testy z witryną: `bench --site localhost run-tests --app <aplikacja>`.

---

## 4. Instalacja w Dockerze (wzmianka)

Frappe utrzymuje oficjalny zestaw obrazów **frappe_docker** (github.com/frappe/frappe_docker),
a także skrypt `easy-install.py`, który stawia kontenery z MariaDB, Redis i nginx
(np. `python3 easy-install.py deploy --app=erpnext --version=version-16 --sitename=...`).
Dla własnych aplikacji (erpnext_poland, admissions_poland, fork education) trzeba zbudować
własny obraz z plikiem `apps.json`:

```json
[
  {"url": "https://github.com/frappe/erpnext",                        "branch": "version-16"},
  {"url": "https://code.galicea.org/labc/erpnext-education.git",     "branch": "develop"},
  {"url": "https://code.galicea.org/labc/erpnext_poland.git",        "branch": "main"},
  {"url": "https://code.galicea.org/labc/admissions_poland.git",     "branch": "main"}
]
```

i poleceniem `docker build --build-arg APPS_JSON_BASE64=$(base64 -w0 apps.json) ...`
według `docs/container-setup/02-build-setup.md` w frappe_docker. Zaleta: obraz ma już Pythona 3.14
i Node 24, więc znika problem z wersją Pythona w dystrybucji. Wady: trudniejszy dostęp do plików
(certyfikat KSeF, pliki XML z KSeF, `site_config.json`), a każda poprawka aplikacji wymaga
przebudowy obrazu. Dlatego produkcja Galicea działa w instalacji bezpośredniej. Robocze pliki
dockerowe są w `/erp/docker`.

---

## 5. Lista kontrolna po instalacji

- [ ] `env/bin/python --version` → 3.14.x
- [ ] `bench --site <witryna> list-apps` pokazuje frappe, erpnext, education, erpnext_poland, admissions_poland
- [ ] `bench --site <witryna> scheduler status` → *enabled*; `common_site_config.json` bez `pause_scheduler: 1` i `maintenance_mode: 1`
- [ ] `systemctl status erpnext-bench.target` → active
- [ ] strona otwiera się po HTTPS, logowanie Administratora działa
- [ ] wydruk faktury do PDF działa (wkhtmltopdf patched Qt)
- [ ] `xmlsec1 --version` działa (KSeF)
- [ ] skonfigurowana kopia bezpieczeństwa (cron z `sh/admin/kopia.sh`, patrz podręcznik administratora)
- [ ] hasło roota MariaDB, hasło Administratora i `encryption_key` z `site_config.json` są w menedżerze haseł

Dalej: [02_konfiguracja_systemu.md](02_konfiguracja_systemu.md) i
[03_podrecznik_administratora.md](03_podrecznik_administratora.md).
