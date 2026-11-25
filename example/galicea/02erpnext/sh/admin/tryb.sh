#!/bin/bash
# Przełączanie trybów witryny.
# Użycie: ./tryb.sh [-s witryna] <serwis|dev|scheduler|skrypty> <on|off>
#   serwis    - maintenance mode (użytkownicy widzą komunikat o przerwie; administrator ma dostęp)
#   dev       - developer_mode (edycja standardowych doctype, eksport fixtures) - NIE na produkcji
#   scheduler - zadania cykliczne (m.in. pobieranie faktur z KSeF, sprawdzanie statusów wysyłki)
#   skrypty   - server_script_enabled (Server Script w Desk)
source "$(dirname "$0")/_wspolne.sh"
WHAT="${ARGS[0]:?serwis|dev|scheduler|skrypty}"; VAL="${ARGS[1]:?on|off}"
case "$VAL" in on) N=1 ;; off) N=0 ;; *) echo "on|off"; exit 1 ;; esac
case "$WHAT" in
  serwis)    bench --site "${SITE}" set-maintenance-mode "$VAL"
             # flaga globalna (common_site_config) potrafi "zostać" po przerwanym bench update:
             [ "$N" = 0 ] && bench set-config -g maintenance_mode 0 ;;
  dev)       bench --site "${SITE}" set-config developer_mode "$N" ;;
  scheduler) if [ "$N" = 1 ]; then bench --site "${SITE}" enable-scheduler; bench --site "${SITE}" scheduler resume
                                  bench set-config -g pause_scheduler 0
             else bench --site "${SITE}" disable-scheduler; fi
             bench --site "${SITE}" scheduler status ;;
  skrypty)   bench --site "${SITE}" set-config server_script_enabled "$N" ;;
  *) echo "Nieznany tryb: $WHAT"; exit 1 ;;
esac
bench --site "${SITE}" clear-cache
