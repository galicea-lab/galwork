#!/bin/bash
# Kontrola po instalacji: wersje, usługi, aplikacje, scheduler, odpowiedź HTTP.
set -uo pipefail
source "$(dirname "$0")/_wspolne.sh"
set +e
bench_env
echo "== Python:  $(env/bin/python --version)"; echo "== Node: $(node -v 2>/dev/null)"
bench version
bench --site "${SITE}" list-apps
bench --site "${SITE}" scheduler status
bench --site "${SITE}" doctor
systemctl --no-pager --plain list-units "${BENCH_NAME}*"
sudo ss -plnt | grep -E 'redis|:8000|:9000|nginx' 
curl -sI "https://${SITE}/api/method/ping" | head -1
