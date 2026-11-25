#!/bin/bash
# Przeładowanie definicji doctype z plików JSON aplikacji (gdy formularz nie pokazuje zmian po migracji).
# Użycie: ./przeladuj_doctype.sh [-s witryna] "Sales Invoice" [Budget ...]
source "$(dirname "$0")/_wspolne.sh"
[ ${#ARGS[@]} -gt 0 ] || { echo "Podaj co najmniej jeden DocType"; exit 1; }
for dt in "${ARGS[@]}"; do bench --site "${SITE}" reload-doctype "$dt"; done
bench --site "${SITE}" clear-cache
