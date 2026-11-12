#!/usr/bin/env bash
# Publikacja pakietu @galicea/nextjs-keycloak-auth (dawny /projekty/galwork/publish.sh).
set -euo pipefail
cd "$(dirname "$0")/../../galwork-react/packages/nextjs-keycloak-auth"
npm publish --registry=https://code.galicea.org/api/packages/galicea/npm/
