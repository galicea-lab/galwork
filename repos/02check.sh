#!/bin/bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "Nie podano parametrów" >&2
    if [ ! -f ".env" ]; then
        echo "Plik .env nie istnieje"
        exit 1
    fi
    source .env
else
    source "$1"
    : "${DIR:?Brak zmiennej DIR w pliku env}"
    cd "$DIR"
fi

if [ -f "./scripts/check-ai-comments.mjs" ]; then
    node ./scripts/check-ai-comments.mjs
fi

if [ -f "./tests/__init__.py" ]; then
    export RUFF_CACHE_DIR=/tmp/.ruff-cache
    ruff check .

    pytest
fi
