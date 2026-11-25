#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

if [ -f "./scripts/check-ai-comments.mjs" ]; then
    node ./scripts/check-ai-comments.mjs
fi

if [ -f "./tests/__init__.py" ]; then
    export RUFF_CACHE_DIR=/tmp/.ruff-cache
    ruff check .
    pytest
fi
