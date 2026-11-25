#!/bin/bash
# Kontrola stylu kodu aplikacji (ruff) - przed commitem do repozytorium aplikacji.
# Użycie: ./lint.sh <aplikacja> [--fix]
source "$(dirname "$0")/_wspolne.sh"
APP="${ARGS[0]:?aplikacja}"
command -v ruff >/dev/null || pip install ruff
export RUFF_CACHE_DIR="/tmp/ruff-cache-${APP}"
cd "apps/${APP}"
ruff check . ${ARGS[1]:+--fix}
