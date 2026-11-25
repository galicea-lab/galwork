#!/bin/bash
# Odtworzenie witryny z kopii utworzonej przez kopia.sh / bench backup.
# Użycie: ./przywroc.sh [-s witryna] <katalog_kopii | plik-database.sql.gz>
# UWAGA: nadpisuje bazę witryny! Przed odtworzeniem robiona jest kopia bieżącego stanu.
source "$(dirname "$0")/_wspolne.sh"
SRC="${ARGS[0]:?podaj katalog kopii albo plik *-database.sql.gz}"
if [ -d "$SRC" ]; then DB=$(ls "$SRC"/*-database.sql.gz | head -1); else DB="$SRC"; fi
DB="$(realpath "$DB")"; PREFIX="${DB%-database.sql.gz}"
OPT=()
PUB=$(ls "${PREFIX}"-files.t* 2>/dev/null | head -1 || true)
PRIV=$(ls "${PREFIX}"-private-files.t* 2>/dev/null | head -1 || true)
[ -n "$PUB" ]  && OPT+=(--with-public-files "$PUB")
[ -n "$PRIV" ] && OPT+=(--with-private-files "$PRIV")

echo "Witryna: ${SITE}"; echo "Baza:    ${DB}"; echo "Pliki:   ${PUB:-brak} / ${PRIV:-brak}"
read -r -p "Nadpisać bazę witryny ${SITE}? Wpisz nazwę witryny, aby potwierdzić: " c
[ "$c" = "${SITE}" ] || { echo "Przerwano."; exit 1; }

bench --site "${SITE}" backup                # zabezpieczenie stanu sprzed odtworzenia
bench --site "${SITE}" set-maintenance-mode on
bench --site "${SITE}" restore "$DB" "${OPT[@]}"   # pyta o hasło roota MariaDB
bench --site "${SITE}" migrate
bench --site "${SITE}" set-maintenance-mode off
bench --site "${SITE}" clear-cache
restart_bench
echo "Jeśli kopia pochodzi z innego serwera: przenieś encryption_key z jej site_config.json."
