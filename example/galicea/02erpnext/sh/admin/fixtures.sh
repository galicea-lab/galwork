#!/bin/bash
# Eksport fixtures aplikacji (Custom Field, Client Script itd. zdefiniowane w hooks.py -> fixtures)
# z bazy do apps/<app>/<app>/fixtures/*.json, a następnie przeładowanie wskazanych doctype.
# Użycie: ./fixtures.sh [-s witryna] <aplikacja> [DocType ...]
#   np. ./fixtures.sh erpnext_poland "Sales Invoice" "Purchase Invoice" Account Item Company
# Tylko w trybie developer_mode i na kopii deweloperskiej - wynik commitujemy do repozytorium aplikacji.
source "$(dirname "$0")/_wspolne.sh"
APP="${ARGS[0]:?podaj aplikację}"
bench --site "${SITE}" clear-cache
bench --site "${SITE}" export-fixtures --app "$APP"
for dt in "${ARGS[@]:1}"; do bench --site "${SITE}" reload-doctype "$dt"; done
bench --site "${SITE}" clear-cache
git -C "apps/${APP}" status --short -- "${APP}/fixtures"
