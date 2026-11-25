#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

load_env "$@"

: "${TAG:?Brak zmiennej TAG w pliku env}"
: "${TAG_DESCRIPT:?Brak zmiennej TAG_DESCRIPT w pliku env}"
TARGET="${TARGET:-main}"

case "$TARGET" in
    main|master|release/*) ;;
    *)
        echo "Błąd: TARGET musi mieć postać main, master lub release/x.y." >&2
        exit 1
        ;;
esac

case "$TAG" in
    v[0-9]*) ;;
    *)
        echo "Błąd: TAG musi mieć postać vMAJOR.MINOR.PATCH (np. v1.2.0)." >&2
        exit 1
        ;;
esac

assert_clean_tree

git fetch origin
git switch "$TARGET"
git pull --ff-only origin "$TARGET"
assert_clean_tree

if [ "$(git rev-list --count "origin/$TARGET..$TARGET")" -ne 0 ]; then
    echo "Błąd: lokalna gałąź $TARGET ma commity niewypchnięte do origin. Wypchnij je przed wydaniem." >&2
    exit 1
fi

if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    echo "Błąd: tag $TAG już istnieje lokalnie." >&2
    exit 1
fi

if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
    echo "Błąd: tag $TAG już istnieje w origin." >&2
    exit 1
fi

git tag -a "$TAG" -m "$TAG_DESCRIPT"
git push origin "$TAG"
