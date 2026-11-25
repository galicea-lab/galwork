#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

: "${TAG:?Brak zmiennej TAG w pliku env}"

git tag -f $TAG
git push origin $TAG --force
git commit --allow-empty -m "$TAG" 
git push origin "$TAG"