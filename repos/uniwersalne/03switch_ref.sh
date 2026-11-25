#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

REF="${REF:-${TAG:-}}"
if [ -z "$REF" ]; then
    echo "Błąd: brak zmiennej REF (lub TAG) w pliku env." >&2
    exit 1
fi

git fetch origin --tags --prune

if git rev-parse --verify --quiet "refs/tags/$REF" >/dev/null; then
    git switch --detach "$REF"
elif git rev-parse --verify --quiet "refs/remotes/origin/$REF" >/dev/null; then
    git switch --detach "origin/$REF"
else
    git switch --detach "$REF"
fi
