# Czysta baza danych dla instancji galicea

Schemat tworzy Alembic (`galwork-hub/alembic/versions`, łańcuch liniowy,
head = `e8a4c2f6b1d9`). Dane startowe to osobny krok (skrypty seed + SQL).

## 0. Baza i użytkownik (PostgreSQL ≥ 13)

Jako administrator klastra (`doadmin` na DigitalOcean albo `postgres`):

```sql
CREATE USER galicea_user WITH PASSWORD '...';
CREATE DATABASE galicea OWNER galicea_user ENCODING 'UTF8' TEMPLATE template0;
\c galicea
-- PG 15+: bez tego zwykły użytkownik nie może tworzyć tabel w public
ALTER SCHEMA public OWNER TO galicea_user;
```

Użytkownik huba musi być **właścicielem** bazy/schematu - migracja
`a9d4e2b7c316_immutability_triggers` zakłada funkcje i triggery.
Rozszerzenia nie są potrzebne (`gen_random_uuid()` jest wbudowane od PG 13).

Baza galicea powinna być osobną bazą i osobnym użytkownikiem - nie
współdzielić `galwork`/`galwork_user` z innymi instancjami (zob. uwaga
o umowie powierzenia w `galwork_url.txt`).

## 1. Konfiguracja huba

W `06galwork_hub/galwork/.env`:

```
DATABASE_URL=postgresql+psycopg://galicea_user:HASLO@HOST:PORT/galicea?sslmode=require
```

Wdrożenie: `06galwork_hub/ansible.sh` (kopiuje `.env`, robi `up -d`).

## 2. Migracje (Alembic)

Nie trzeba ich uruchamiać ręcznie: `docker-entrypoint.sh` wykonuje
`alembic upgrade head` przy każdym starcie kontenera `hub`.
Na serwerze (`/setup/galicea/galwork`):

```bash
sudo docker compose logs hub | grep -A3 alembic   # przebieg migracji
sudo docker compose exec hub alembic current      # oczekiwane: e8a4c2f6b1d9 (head)
```

Ręcznie (np. przed startem API albo po błędzie):

```bash
sudo docker compose run --rm hub alembic upgrade head
```

Kontrola, że baza jest pusta przed pierwszą migracją:
`alembic current` nie wypisuje rewizji, a w bazie nie ma tabeli
`alembic_version`. Jeśli migracja przerwie się w połowie, łatwiej
usunąć i założyć bazę od nowa (krok 0) niż naprawiać częściowy schemat.

## 3. Dane startowe

Kolejność ma znaczenie tylko dla kroku 3.3 (jeśli wolisz wartości
z SQL, uruchom go przed 3.1 - oba są idempotentne, istniejący
`dictionary_key + code` jest pomijany).

Przez ansible (z `06galwork_hub/ansible`; kroki 3.1-3.4 poniżej, SQL
wykonywany w kontenerze huba, `psql` na serwerze niepotrzebny):

```bash
ansible-playbook deploy.yml -K --tags seed -e seed_dry_run=true   # podgląd
ansible-playbook deploy.yml -K --tags seed
```

Zwykłe `ansible-playbook deploy.yml -K` seedów nie uruchamia (tag `never`).

Ręcznie na serwerze:

```bash
cd /setup/galicea/galwork

# 3.1 słowniki o wartościach "z natury" (rodzaj pisma studenta, dni tygodnia,
#     powód skreślenia, kategoria archiwalna, rodzaje urlopów)
sudo docker compose exec hub python3 scripts/seed_flat_dictionaries.py --dry-run
sudo docker compose exec hub python3 scripts/seed_flat_dictionaries.py

# 3.2 zakupy: OrgUnit "Dział zamówień" (grupa Keycloak dzial_zakupow)
#     + słownik rodzaj-wydatku
sudo docker compose exec hub python3 scripts/seed_zakupy.py

# 3.3 słowniki ogólne - patrz slowniki_startowe.sql (psql na serwerze:
#     apt install postgresql-client; URL bez "+psycopg")
psql "postgresql://galicea_user:HASLO@HOST:PORT/galicea?sslmode=require" \
     -v ON_ERROR_STOP=1 -f slowniki_startowe.sql

# 3.4 e-Doręczenia: model procesu edr-korespondencja
sudo docker compose exec hub python3 scripts/seed_edr_process.py --dry-run
sudo docker compose exec hub python3 scripts/seed_edr_process.py
```

Pozostałe modele procesów publikuje się przez API/arenę albo
`scripts/seed_process_model.py <katalog w spiffworkflow/>`.

Użytkownicy (`users`) zakładają się sami przy pierwszym zalogowaniu
(`get_or_create_user_from_token`) - nie seedować.

Słownik `dzialy` ma w SQL tylko jeden wpis ("fundacja"). Nie seedujemy innych
słowników specyficznych dla organizacji:
`projekt-mpk`, `jrwa`, `sale`, `budynki`, `grupy-ad`, `zbiory-rodo`,
`oferta-edukacyjna` - wprowadza je administrator (ekran „Słowniki”
w arenie) albo dopisuje się je do `slowniki_startowe.sql`.

## 4. Kontrola

```sql
SELECT version_num FROM alembic_version;
SELECT dictionary_key, count(*) FROM dictionary_entry GROUP BY 1 ORDER BY 1;
```
