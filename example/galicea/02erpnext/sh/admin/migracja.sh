#!/bin/bash
# Migracja witryny (po zmianach w kodzie aplikacji, hooks.py, doctype, fixtures, patches).
# Użycie: ./migracja.sh [-s witryna]
source "$(dirname "$0")/_wspolne.sh"
bench --site "${SITE}" clear-cache      # żeby nowy hooks.py został wczytany
bench --site "${SITE}" migrate          # patche, synchronizacja doctype, import fixtures
bench --site "${SITE}" clear-cache
