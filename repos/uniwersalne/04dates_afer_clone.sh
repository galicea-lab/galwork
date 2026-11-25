#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

echo "Natychmiast po clone!!"
cd $DIR

git ls-files -z | while IFS= read -r -d '' file; do
    touch -d "@$(git log -1 --format=%at -- "$file")" "$file"
done