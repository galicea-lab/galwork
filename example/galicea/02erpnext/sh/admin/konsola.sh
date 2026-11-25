#!/bin/bash
# Konsola Pythona (IPython) w kontekście witryny. Przepisy w katalogu konsola/.
# Użycie: ./konsola.sh [-s witryna]                       - tryb interaktywny
#         ./konsola.sh [-s witryna] konsola/plik.py       - wykonanie skryptu
source "$(dirname "$0")/_wspolne.sh"
if [ -n "${ARGS[0]:-}" ]; then
  F="$(cd "${ADMIN_DIR}" && realpath "${ARGS[0]}")"
  bench --site "${SITE}" console < "$F"
else
  bench --site "${SITE}" console
fi
