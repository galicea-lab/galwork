#!/bin/bash
# Aktualizacja aplikacji (pull z repozytoriów), migracja, przebudowa zasobów.
# Użycie: ./aktualizacja.sh [-s witryna] [--patch | --reset]
#   (bez opcji) - pełna: bench update (pull + requirements + migrate + build)
#   --patch     - tylko patche/migracja bez pobierania kodu
#   --reset     - pull z twardym resetem lokalnych zmian w apps/* (UWAGA: kasuje niezacommitowane zmiany!)
# Kopia witryny wykonywana jest przed aktualizacją (bench update robi kopie wszystkich witryn).
source "$(dirname "$0")/_wspolne.sh"
MODE="${ARGS[0]:-}"

echo "== Stan repozytoriów aplikacji (niezacommitowane zmiany blokują pull):"
for a in apps/*/; do
  [ -d "$a/.git" ] || continue
  printf '%-22s %-18s %s\n' "$(basename "$a")" "$(git -C "$a" branch --show-current)" \
    "$(git -C "$a" status --porcelain | wc -l) zmian"
done
read -r -p "Kontynuować? [t/N] " c; [[ "$c" =~ ^[tTyY]$ ]] || exit 1

bench --site "${SITE}" set-maintenance-mode on
case "$MODE" in
  --patch) bench update --patch ;;
  --reset) bench update --reset ;;
  *)       bench update ;;
esac
bench --site "${SITE}" migrate
bench build
bench --site "${SITE}" clear-cache
bench --site "${SITE}" clear-website-cache
bench --site "${SITE}" set-maintenance-mode off
restart_bench
bench version
