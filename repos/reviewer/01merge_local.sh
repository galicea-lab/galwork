#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

: "${BRANCH:?Brak zmiennej BRANCH w pliku env}"
TARGET="${TARGET:-main}"
assert_not_protected "$BRANCH"
if [ "$BRANCH" = "$TARGET" ]; then
    echo "Błąd: BRANCH i TARGET nie mogą być takie same." >&2
    exit 1
fi
assert_clean_tree

if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Błąd: gałąź lokalna $BRANCH nie istnieje." >&2
    exit 1
fi

git fetch origin
git switch "$TARGET"
git pull --ff-only origin "$TARGET"
git merge --no-ff "$BRANCH"
git status