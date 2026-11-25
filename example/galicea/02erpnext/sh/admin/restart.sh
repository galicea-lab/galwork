#!/bin/bash
# Restart procesów bench (systemd lub bench restart) + czyszczenie cache.  ./restart.sh [-s witryna]
source "$(dirname "$0")/_wspolne.sh"
restart_bench
bench --site "${SITE}" clear-cache
is_systemd && systemctl --no-pager --plain list-units "${BENCH_NAME}*" || true
