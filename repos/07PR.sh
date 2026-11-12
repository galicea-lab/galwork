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
    echo "Błąd: nie tworzymy PR z gałęzi głównej $BRANCH." >&2
    exit 1
fi

git status

git fetch origin

git add -A

if git diff --cached --name-only | grep -Eq '(^|/)(\.env|TOKENY)$'; then
    echo "Błąd: do commita trafił .env lub plik TOKENY. Przerywam." >&2
    git reset -q
    exit 1
fi

if git diff --cached --quiet; then
    echo "Brak zmian do commita."
else
    git commit -m "${COMMIT:?Brak zmiennej COMMIT w pliku env}"
fi

git rebase origin/main

git push -u origin "$BRANCH"
