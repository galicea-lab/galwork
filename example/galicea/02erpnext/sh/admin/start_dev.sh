#!/bin/bash
# Uruchomienie w trybie deweloperskim (wszystkie procesy z Procfile na pierwszym planie, port 8000).
# NIE używać, gdy działają usługi systemd - najpierw: sudo systemctl stop <bench>.target
source "$(dirname "$0")/_wspolne.sh"
if is_systemd && systemctl is-active --quiet "${BENCH_NAME}.target"; then
  echo "Działa ${BENCH_NAME}.target (systemd). Zatrzymaj: sudo systemctl stop ${BENCH_NAME}.target"; exit 1
fi
bench start
