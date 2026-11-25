#!/usr/bin/env bash
# Build i push obrazu galwork-hub.
# Użycie: scripts/build_hub.sh [tag]   (domyślnie 0011)
set -euo pipefail
TAG="${1:-0011}"
IMAGE="registry.galicea.org/galwork-hub:${TAG}"
cd "$(dirname "$0")/../../galwork-hub"
docker build -t "$IMAGE" .
docker push "$IMAGE"
