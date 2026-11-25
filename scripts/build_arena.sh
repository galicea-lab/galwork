#!/usr/bin/env bash
# NEXT_PUBLIC_* są wklejane do statycznego bundla w czasie
# `next build`, więc muszą trafić do builda jako --build-arg (wartości z .env).
# Użycie: scripts/build_arena.sh [tag]   (domyślnie 0009)
# .env czytany z galwork/, kontekst builda = katalog roboczy (..), bo
# obraz potrzebuje też galwork-react/ (zob. ../.dockerignore).

set -euo pipefail
cd "$(dirname "$0")/../.."

# pamiętaj o .env
# cp galwork/.env .
# aplikacja musi być zbudowana
#cd ./galwork-arena
#yarn install
#yarn build
#cd ..

TAG="${1:-0009}"
IMAGE="registry.galicea.org/galwork-arena:${TAG}"

env_value() {
  grep -E "^$1=" .env | tail -1 | cut -d= -f2- || true
}

docker build -t "$IMAGE" -f galwork-arena/Dockerfile \
  --build-arg NEXT_PUBLIC_API_URL="$(env_value NEXT_PUBLIC_API_URL)" \
  --build-arg NEXT_PUBLIC_KEYCLOAK_URL="$(env_value NEXT_PUBLIC_KEYCLOAK_URL)" \
  --build-arg NEXT_PUBLIC_KEYCLOAK_CLIENT="$(env_value NEXT_PUBLIC_KEYCLOAK_CLIENT)" \
  .

docker push "$IMAGE"
