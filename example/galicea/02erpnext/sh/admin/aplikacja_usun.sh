#!/bin/bash
# Odinstalowanie aplikacji z witryny (USUWA jej doctype i dane!) i opcjonalnie z bench.
# Użycie: ./aplikacja_usun.sh [-s witryna] <nazwa> [--z-bench]
source "$(dirname "$0")/_wspolne.sh"
APP="${ARGS[0]:?podaj nazwę aplikacji}"
read -r -p "Odinstalować ${APP} z ${SITE} (dane aplikacji zostaną usunięte)? [t/N] " c
[[ "$c" =~ ^[tTyY]$ ]] || exit 1
bench --site "${SITE}" uninstall-app "$APP"      # sam robi kopię bazy przed usunięciem
if [ "${ARGS[1]:-}" = "--z-bench" ]; then bench remove-app "$APP"; fi
# Gdy uninstall się nie udaje (aplikacja już usunięta z apps/, a wpis został w bazie):
#   bench --site "${SITE}" remove-from-installed-apps "$APP"
restart_bench
