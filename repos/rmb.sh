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

: "${BRANCH:?Brak zmiennej BRANCH w pliku env}"

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "Błąd: odmowa usunięcia gałęzi głównej $BRANCH." >&2
    exit 1
fi

git push origin --delete "$BRANCH"
git fetch --prune origin
