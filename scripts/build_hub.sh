#!/usr/bin/env bash
# Build i push obrazu galwork-hub.
# Użycie: scripts/build_hub.sh [tag]   (domyślnie 0013)
set -euo pipefail
TAG="${1:-0013}"
IMAGE="registry.galicea.org/galwork-hub:${TAG}"
cd "$(dirname "$0")/../../galwork-hub"
docker build -t "$IMAGE" .
docker push "$IMAGE"
