#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

: "${COMMIT:?Brak zmiennej COMMIT w pliku env}"

git add -A
assert_no_secrets_staged

if git diff --cached --quiet; then
    echo "Brak zmian do commita."
    exit 0
fi

git diff --cached
git commit -m "$COMMIT"
