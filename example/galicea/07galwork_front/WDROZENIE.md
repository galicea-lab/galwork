# Wdrożenie komponentów galwork dla organizacji galicea

Procedura obejmuje trzy frontendy Next.js utrzymywane w repozytorium `galwork`:

| Komponent | Katalog źródłowy | Plik zmiennych | Katalog na serwerze | Domena | Tryb |
| --- | --- | --- | --- | --- | --- |
| PM | `galwork-pm` | `pm.env.production` | `/var/www/galicea/pm` | `pm.galicea.org` | Next.js standalone + systemd |
| Edu | `galwork-edu` | `edu.env.production` | `/var/www/galicea/akademia` | `akademia.galicea.org` | static export + nginx |
| Dashboard | `galwork-dashboard` | `dashboard.env.production` | `/var/www/galicea/centrum` | `centrum.galicea.org` | static export + nginx |

`galwork-pm` nie jest aplikacją statyczną: ma trasy dynamiczne i dane pobierane w czasie rzeczywistym, więc jest budowany jako `output: "standalone"` i uruchamiany jako usługa Node. `galwork-edu` i `galwork-dashboard` używają `output: "export"` i są serwowane jako pliki przez nginx.

Źródła: https://nextjs.org/docs/app/api-reference/config/next-config-js/output , https://nextjs.org/docs/app/guides/static-exports , https://nextjs.org/docs/app/guides/self-hosting#reverse-proxy

## Wymagania

### Maszyna kontrolna (ta, na której uruchamiasz Ansible)

- repozytorium `galwork` wyciągnięte do `/projekty/galwork`,
- Node.js 22 LTS lub 24, Yarn 1.22.x, Ansible 2.19+, `tar`,
- dostęp SSH do serwera i uprawnienia `sudo`,
- pliki zmiennych w `galicea/03galwork/`.

### Serwer

- system Linux z `systemd`, nginx i Node.js 22 LTS lub 24 dostępnym systemowo jako `node`,
- katalog `/var/www/galicea` może być pusty,
- nginx z certyfikatami certbot jest już skonfigurowany — playbook domyślnie go nie rusza (`manage_nginx: false`, `install_nginx: false`),
- DNS i certyfikaty dla domen z tabeli pozostają po stronie istniejącej konfiguracji nginx/certbot.

## Przygotowanie jednorazowe

1. W `galwork-pm/next.config.ts` ustawione jest:

   ```ts
   const nextConfig: NextConfig = {
     output: "standalone",
   };
   ```

   Dzięki temu wynik budowy trafia do `galwork-pm/.next/standalone` i zawiera minimalny zestaw zależności razem z `server.js`.

2. Połączenie SSH jest już skonfigurowane w `ansible/inventory/hosts.ini` i `ansible/group_vars/galwork.yml`:

   ```ini
   [galwork]
   galicea ansible_host=203.0.113.10 ansible_user=deploy
   ```

   Klucz prywatny jest ustawiony jako `ansible_ssh_private_key_file: "{{ lookup('env', 'HOME') }}/.ssh/galwork_deploy"`, co odpowiada komendzie `ssh -i ~/.ssh/galwork_deploy deploy@203.0.113.10`. Ansible domyślnie weryfikuje host key — skoro połączenie `ssh` już działa, nie trzeba niczego wyłączać. Jeśli `deploy` nie ma passwordless `sudo`, uruchamiaj playbook z `-K` (`--ask-become-pass`) i podawaj hasło sudo.

3. Pliki `pm.env.production`, `edu.env.production` i `dashboard.env.production` pozostaw w `galicea/03galwork/`. Nie edytuj `.env.production` bezpośrednio w katalogach aplikacji — playbook nadpisze je przy każdym wdrożeniu.

4. Na serwerze z Debianem Trixie zainstaluj Node.js 22 LTS systemowo (repozytorium NodeSource, bo `apt` ma wersję 20):

   ```bash
   ssh -i ~/.ssh/galwork_deploy deploy@203.0.113.10
   sudo apt update
   sudo apt install -y ca-certificates curl gnupg
   curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
   sudo apt install -y nodejs
   node -v
   ```

   Wynik powinien zaczynać się od `v22.`. Instalacja systemowa jest ważna, bo jednostka systemd znajduje `node` przez `which node`. Nie używaj tu `nvm` w profilu użytkownika — systemd nie odziedziczy `PATH` z logowania.

   Źródła: https://nodejs.org/en/download/package-manager , https://deb.nodesource.com/setup_22.x , https://docs.ansible.com/ansible/latest/inventory_guide/connection_details.html#setting-up-ssh-keys

## Procedura wdrożenia

Z katalogu `galicea/03galwork/ansible` uruchom:

```bash
ansible-playbook deploy.yml --check -K
ansible-playbook deploy.yml -K
```

`-K` (`--ask-become-pass`) jest potrzebne, jeśli `deploy` nie ma passwordless `sudo`; w przeciwnym razie można pominąć tę flagę. Jeśli klucz SSH ma passphrase, najpierw wykonaj `ssh-add ~/.ssh/galwork_deploy`.

### Kiedy uruchamiać `--check -K`

`--check` to suchy test: pokazuje, co Ansible zmieniłby, nic nie zapisując na serwerze. Używaj go:

- przed pierwszym wdrożeniem na nowym serwerze,
- po zmianie `hosts.ini`, klucza SSH, użytkownika albo uprawnień `sudo`,
- po zmianie `group_vars/galwork.yml` — ścieżki, domeny, port, `manage_nginx`, `keep_releases`,
- po zmianie playbooka albo szablonów `systemd`/nginx,
- gdy nie jesteś pewien, czy `/var/www/galicea/pm`, `/var/www/galicea/akademia` i `/var/www/galicea/centrum` są symlinkami, czy zwykłymi katalogami.

`--check` nie restartuje usługi ani nie wykonuje handlerów — sprawdza głównie łączność, uprawnienia i listę zmian, nie działanie aplikacji po restarcie.

Można też uruchomić tylko etap lokalny (`ansible-playbook deploy.yml --tags build`) albo tylko wdrożenie na serwerze (`ansible-playbook deploy.yml --tags deploy`), gdy artefakty już istnieją.

Playbook wykonuje w kolejności:

1. Kopiuje pliki zmiennych do katalogów aplikacji, np.:

   ```bash
   cp pm.env.production ../galwork-pm/.env.production
   ```

2. Instaluje/odświeża zależności z `yarn.lock` i buduje każdą aplikację:

   ```bash
   cd galwork-pm && yarn build
   cd galwork-edu && yarn build
   cd galwork-dashboard && yarn build
   ```

3. Przygotowuje standalone dla PM: kopiuje `.next/static`, `public` i `.env.production` do `galwork-pm/.next/standalone`, po czym pakuje wyniki do:

   ```text
   ansible/artifacts/pm.tar.gz
   ansible/artifacts/edu.tar.gz
   ansible/artifacts/dashboard.tar.gz
   ```

4. Wysyła artefakty na serwer do `/var/www/galicea/artifacts`, rozpakowuje je do katalogów `/var/www/galicea/releases/<komponent>-<timestamp>` i przełącza symlinki:

   ```text
   /var/www/galicea/pm        -> releases/pm-<timestamp>
   /var/www/galicea/akademia  -> releases/edu-<timestamp>
   /var/www/galicea/centrum   -> releases/dashboard-<timestamp>
   ```

   Katalogi docelowe są symlinkami, żeby wdrożenie było atomowe i odwracalne. Jeśli któryś z nich istnieje jako zwykły katalog, playbook zatrzyma się z komunikatem o błędzie.

5. Instaluje usługę `galwork-pm.service` i restartuje PM. Konfiguracja nginx, `nginx -t` oraz reload nginx są wykonywane tylko wtedy, gdy `manage_nginx: true`.

Zmienne konfiguracyjne znajdują się w `ansible/group_vars/galwork.yml`. Można tam zmienić domeny, port PM, katalogi docelowe, liczbę zachowywanych wydań (`keep_releases`) oraz `install_nginx` / `manage_nginx`. Domyślnie oba są `false`, więc istniejąca konfiguracja z certbotem nie jest nadpisywana. Nie włączaj `manage_nginx: true` na serwerze z certbotem — dołączone szablony obsługują tylko port `80` i zastąpiłyby pliki w `/etc/nginx/conf.d`.

## Weryfikacja po wdrożeniu

Na serwerze:

```bash
systemctl status galwork-pm
journalctl -u galwork-pm -n 100 --no-pager
nginx -t
systemctl status nginx
ls -l /var/www/galicea/pm /var/www/galicea/akademia /var/www/galicea/centrum
curl -I http://127.0.0.1:3000
```

Z maszyny kontrolnej:

```bash
curl -I https://pm.galicea.org
curl -I https://akademia.galicea.org
curl -I https://centrum.galicea.org
```

Po wdrożeniu sprawdź też logi aplikacji i działanie kluczowych widoków: listy projektów, formularzy i dashboardu w PM oraz stron głównych Edu i Centrum.

## Powrót do poprzedniego wydania

Playbook zapisuje poprzedni symlink jako `/var/www/galicea/<komponent>-previous`. Aby wrócić do poprzedniej wersji:

```bash
cd galicea/03galwork/ansible
ansible-playbook rollback.yml
```

Rollback przełącza symlinki, restartuje `galwork-pm` i — tylko przy `manage_nginx: true` — przeładowuje nginx. Nie wycofuje zmian w bazie danych huba ani w konfiguracji Keycloak.

## Uwagi o bezpieczeństwie

- Pliki `.env.production` są kopiowane z uprawnieniami `0600`.
- Obecnie zawierają tylko publiczne adresy API i konfigurację Keycloak; jeśli pojawią się sekrety, przenieś je do Ansible Vault i nie trzymaj w repozytorium.
- Nginx powinien być zabezpieczony certyfikatami TLS; szablony nie konfigurują certów.
- Artefakty w `ansible/artifacts` zawierają skompilowany kod i zmienne środowiskowe — nie publikuj ich.
