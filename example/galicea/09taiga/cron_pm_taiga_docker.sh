#!/bin/bash
# 2026-11-25: wariant scripts/cron_pm_taiga.sh dla huba uruchomionego w docker compose
# (instancja galicea: /setup/galicea/galwork). Polecenia pm_taiga.py wykonuje kontener `hub`.
#   */20 * * * *  /setup/galicea/cron_pm_taiga_docker.sh
#   15 6 * * *    /setup/galicea/cron_pm_taiga_docker.sh --daily
#   0 7 * * 1     /setup/galicea/cron_pm_taiga_docker.sh --weekly-review
#   0 9 * * 4     /setup/galicea/cron_pm_taiga_docker.sh --remind
COMPOSE_DIR=${COMPOSE_DIR:-/setup/galicea/galwork}
LOG=${LOG:-/var/log/galwork/cron_pm_taiga.log}
mkdir -p "$(dirname "$LOG")"
cd "$COMPOSE_DIR" || exit 1

pm() { docker compose exec -T hub python3 scripts/pm_taiga.py "$@" >> "$LOG" 2>&1; }

echo "[$(date '+%F %T')] pm_taiga.py ${1:-reconcile/process}" >> "$LOG"
pm reconcile
pm process
pm erp-sync            # bez zapisu do ERPNext, dopóki [taiga] erp_sync=false
case "${1:-}" in
  --weekly-review) pm review-start ;;
  --remind)        pm remind ;;
  --daily)         pm audit; pm erp-check; pm purge ;;
esac
exit 0
