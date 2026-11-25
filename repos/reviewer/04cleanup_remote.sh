#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

: "${BRANCH:?Brak zmiennej BRANCH w pliku env}"
assert_not_protected "$BRANCH"

if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
    git push origin --delete "$BRANCH"
else
    echo "Gałąź zdalna $BRANCH nie istnieje - pomijam."
fi

git fetch --prune origin
