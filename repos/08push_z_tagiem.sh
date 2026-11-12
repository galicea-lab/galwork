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
: "${TAG_DESCRIPT:?Brak zmiennej TAG_DESCRIPT w pliku env}"


case "$TAG" in
    v[0-9]*) ;;
    *)
        echo "Błąd: TAG musi mieć postać vMAJOR.MINOR.PATCH (np. v1.2.0)." >&2
        exit 1
        ;;
esac

git fetch origin
git switch main
git pull --ff-only origin main

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Błąd: katalog roboczy nie jest czysty. Zacommituj zmiany przed wydaniem." >&2
    exit 1
fi

if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    echo "Błąd: tag $TAG już istnieje lokalnie." >&2
    exit 1
fi

if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
    echo "Błąd: tag $TAG już istnieje w origin." >&2
    exit 1
fi

git tag -a "$TAG" -m "$TAG_DESCRIPT"
git push origin "$TAG"
