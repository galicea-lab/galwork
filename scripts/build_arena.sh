#!/usr/bin/env bash
# NEXT_PUBLIC_* są wklejane do statycznego bundla w czasie
# `next build`, więc muszą trafić do builda jako --build-arg (wartości z .env).
# Bez NEXT_PUBLIC_BPMN_FILES_URL edytory BPMN/formularzy w arena są wyłączone.
# Użycie: scripts/build_arena.sh [tag]   (domyślnie 0003)
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

TAG="${1:-0003}"
IMAGE="registry.galicea.org/galwork-arena:${TAG}"

env_value() {
  grep -E "^$1=" .env | tail -1 | cut -d= -f2- || true
}

# pusty adres NIE wyłącza edytorów - klient woła wtedy
# względne /api/bpmn/files, które trafia do areny (404). Przerywamy build.

BPMN_FILES_URL="$(env_value NEXT_PUBLIC_BPMN_FILES_URL)"
if [ -z "$BPMN_FILES_URL" ]; then
  echo "Brak NEXT_PUBLIC_BPMN_FILES_URL w .env (np. /bpmn-files)." >&2
  exit 1
fi

docker build -t "$IMAGE" -f galwork-arena/Dockerfile \
  --build-arg NEXT_PUBLIC_API_URL="$(env_value NEXT_PUBLIC_API_URL)" \
  --build-arg NEXT_PUBLIC_KEYCLOAK_URL="$(env_value NEXT_PUBLIC_KEYCLOAK_URL)" \
  --build-arg NEXT_PUBLIC_KEYCLOAK_CLIENT="$(env_value NEXT_PUBLIC_KEYCLOAK_CLIENT)" \
  --build-arg NEXT_PUBLIC_BPMN_FILES_URL="$BPMN_FILES_URL" \
  .

# Kontrola: adres serwera plików musi być wklejony do statycznego bundla.
if ! docker run --rm --entrypoint grep "$IMAGE" -rqF "$BPMN_FILES_URL" /usr/share/nginx/html/_next; then
  echo "W bundlu obrazu $IMAGE nie ma adresu $BPMN_FILES_URL - nie publikuję." >&2
  exit 1
fi
docker push "$IMAGE"
