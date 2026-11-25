#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

: "${BRANCH:?Brak zmiennej BRANCH w pliku env}"

git fetch origin
git rebase origin/main
git switch main
git pull --ff-only origin main
git merge --no-ff "$BRANCH"   # lub bez --no-ff, jeśli chcesz czysty fast-forward
git push origin main