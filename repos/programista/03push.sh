#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

BRANCH="${BRANCH:-$(current_branch)}"
assert_not_main "$BRANCH"
assert_branch_is_current "$BRANCH"

git push --set-upstream origin "$BRANCH"
