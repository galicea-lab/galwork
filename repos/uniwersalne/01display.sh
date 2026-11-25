#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

branch="$(git branch --show-current)"
echo "Repozytorium: $DIR"
echo "Aktywna gałąź: ${branch:-HEAD (detached)}"
git log --all --graph --decorate --oneline
