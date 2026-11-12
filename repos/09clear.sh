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

git switch main
git pull --ff-only origin main

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git branch -D "$BRANCH"
else
    echo "Gałąź lokalna $BRANCH nie istnieje - pomijam."
fi

git remote prune origin
