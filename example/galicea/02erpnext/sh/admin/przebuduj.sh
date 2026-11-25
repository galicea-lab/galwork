#!/bin/bash
# Przebudowa zasobów JS/CSS (po aktualizacji lub zmianach w public/).
# Użycie: ./przebuduj.sh [-s witryna] [aplikacja]
source "$(dirname "$0")/_wspolne.sh"
APP="${ARGS[0]:-}"
if [ -n "$APP" ]; then
  ( cd "apps/${APP}" && [ -f package.json ] && yarn install --frozen-lockfile || true )
  bench build --app "$APP" --force
else
  bench setup requirements --node
  bench build --force
fi
bench --site "${SITE}" clear-cache
bench --site "${SITE}" clear-website-cache
