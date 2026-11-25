#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

BRANCH="${BRANCH:-$(current_branch)}"
assert_not_main "$BRANCH"
assert_branch_is_current "$BRANCH"
BASE="${BASE:-origin/main}"

git status
git fetch origin

if ! git rev-parse --verify --quiet "$BASE" >/dev/null; then
    echo "Błąd: ref bazowy $BASE nie istnieje." >&2
    exit 1
fi

git add -A
assert_no_secrets_staged

if git diff --cached --quiet; then
    echo "Brak zmian do commita."
else
    : "${COMMIT:?Brak zmiennej COMMIT w pliku env}"
    git commit -m "$COMMIT"
fi

git rebase "$BASE"
git push --set-upstream origin "$BRANCH"
