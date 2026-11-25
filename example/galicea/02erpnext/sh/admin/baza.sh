#!/bin/bash
# Konsola MariaDB witryny (logowanie danymi z site_config.json).
# Użycie: ./baza.sh [-s witryna] ["zapytanie SQL"]
#   np. ./baza.sh "DESCRIBE tabAccount"
# Przy UPDATE/DELETE bez klucza w trybie interaktywnym: SET SQL_SAFE_UPDATES = 0;
# Zmiany bezpośrednio w bazie omijają walidacje ERPNext - najpierw kopia (kopia.sh)!
source "$(dirname "$0")/_wspolne.sh"
if [ -n "${ARGS[0]:-}" ]; then bench --site "${SITE}" mariadb -e "${ARGS[0]}"; else bench --site "${SITE}" mariadb; fi
