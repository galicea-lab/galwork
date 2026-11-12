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

if [ $BRANCH ]; then
   git push --set-upstream origin $BRANCH
else
  # push std.:
  git push
fi


