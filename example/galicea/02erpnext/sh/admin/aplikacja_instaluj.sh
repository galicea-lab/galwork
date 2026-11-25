#!/bin/bash
# Instalacja aplikacji Frappe w witrynie.
# Użycie: ./aplikacja_instaluj.sh [-s witryna] <nazwa> [url_repozytorium] [gałąź]
#   - z URL: pobiera aplikację (bench get-app) i instaluje,
#   - bez URL, gdy apps/<nazwa> istnieje: instaluje lokalny kod (pip -e) - np. po ręcznym git clone,
#   - bez URL i bez katalogu: bench get-app <nazwa> (rejestr Frappe, np. hrms, insights).
source "$(dirname "$0")/_wspolne.sh"
APP="${ARGS[0]:?podaj nazwę aplikacji}"; URL="${ARGS[1]:-}"; BR="${ARGS[2]:-}"
if [ -n "$URL" ]; then
  bench get-app "$APP" "$URL" ${BR:+--branch "$BR"}
elif [ -d "apps/${APP}" ]; then
  pip install -e "apps/${APP}"
  grep -qx "$APP" sites/apps.txt || echo "$APP" >> sites/apps.txt
else
  bench get-app "$APP" ${BR:+--branch "$BR"}
fi
bench --site "${SITE}" install-app "$APP"
bench --site "${SITE}" migrate
bench build --app "$APP"
restart_bench
bench --site "${SITE}" list-apps
