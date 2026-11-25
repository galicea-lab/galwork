#!/bin/bash
# Odtworzenie witryny z kopii (np. przeniesienie z innego serwera).
# Użycie: ./09_przywroc_kopie.sh <plik-database.sql.gz> [files.tar(.gz)] [private-files.tar(.gz)]
set -euo pipefail
source "$(dirname "$0")/_wspolne.sh"
DB="${1:?podaj plik *-database.sql.gz}"; PUB="${2:-}"; PRIV="${3:-}"
DB="$(realpath "$DB")"; [ -n "$PUB" ] && PUB="$(realpath "$PUB")"; [ -n "$PRIV" ] && PRIV="$(realpath "$PRIV")"
bench_env

ARGS=()
[ -n "$PUB" ]  && ARGS+=(--with-public-files "$PUB")
[ -n "$PRIV" ] && ARGS+=(--with-private-files "$PRIV")

# Witryna musi istnieć (08_witryna.sh) lub zostanie utworzona przez restore.
# Jeśli kopia pochodzi z innej domeny/nazwy witryny - przywracamy do $SITE, a potem:
#   - w site_config.json docelowej witryny zachowaj "encryption_key" z serwera źródłowego
#     (inaczej hasła zapisane w systemie - np. hasło certyfikatu KSeF, poczta - nie dadzą się odszyfrować)
bench --site "${SITE}" restore "$DB" "${ARGS[@]}"
bench --site "${SITE}" migrate
bench build
bench --site "${SITE}" clear-cache
