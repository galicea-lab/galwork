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

: "${TAG:?Brak zmiennej TAG w pliku env}"

git fetch origin --tags --prune

if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    git switch --detach "$TAG"
elif git rev-parse --verify --quiet "refs/remotes/origin/$TAG" >/dev/null; then
    git switch --detach "origin/$TAG"
else
   #: "${TAG_DESCRIPT:?Brak zmiennej TAG_DESCRIPT w pliku env}"
   #git tag -a "$TAG" -m "$TAG_DESCRIPT"
   git switch --detach "$TAG"
fi
