#!/bin/bash
# Stan systemu: wersje, aplikacje, scheduler, kolejki, usługi.  Użycie: ./status.sh [-s witryna]
source "$(dirname "$0")/_wspolne.sh"
set +e
echo "== Python: $(python --version)   Node: $(node -v 2>/dev/null)   bench: $(bench --version 2>/dev/null)"
bench version
echo "== Witryny:"; ls -1d sites/*/site_config.json | xargs -n1 dirname | xargs -n1 basename
echo "== Aplikacje w ${SITE}:"; bench --site "${SITE}" list-apps
bench --site "${SITE}" scheduler status
bench --site "${SITE}" doctor
grep -E '"(maintenance_mode|pause_scheduler|developer_mode)"' sites/common_site_config.json "sites/${SITE}/site_config.json"
is_systemd && systemctl --no-pager --plain list-units "${BENCH_NAME}*"
df -h "${INST}" | tail -1
