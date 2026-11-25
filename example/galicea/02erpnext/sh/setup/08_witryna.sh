#!/bin/bash
# Utworzenie witryny i instalacja aplikacji (kolejność ma znaczenie: zależności najpierw).
# Hasła (root MariaDB, Administrator) bench pobiera interaktywnie.
set -euo pipefail
source "$(dirname "$0")/_wspolne.sh"
bench_env

bench new-site "${SITE}" --db-type mariadb
bench use "${SITE}"

bench --site "${SITE}" install-app erpnext
# bench --site "${SITE}" install-app hrms
bench --site "${SITE}" install-app education
bench --site "${SITE}" install-app erpnext_poland
bench --site "${SITE}" install-app admissions_poland

bench --site "${SITE}" set-config server_script_enabled 1      # skrypty serwerowe (używane w konfiguracji)
bench --site "${SITE}" enable-scheduler                         # KSeF: zadania cykliczne erpnext_poland
bench --site "${SITE}" migrate
bench --site "${SITE}" list-apps
