#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

: "${BRANCH:?Brak zmiennej BRANCH w pliku env}"
assert_not_main "$BRANCH"
BASE="${BASE:-origin/main}"

git fetch origin

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Błąd: gałąź lokalna $BRANCH już istnieje." >&2
    exit 1
fi

if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    echo "Błąd: gałąź $BRANCH już istnieje w origin." >&2
    exit 1
fi

git switch -c "$BRANCH" --no-track "$BASE"
