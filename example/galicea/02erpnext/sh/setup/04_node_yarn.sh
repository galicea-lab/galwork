#!/bin/bash
# Node.js 24 (przez nvm) + yarn 1.x - Frappe v16 wymaga node >= 24.
set -euo pipefail
source "$(dirname "$0")/erp.env"
if [ ! -s "${HOME}/.nvm/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
set +u; source "${HOME}/.nvm/nvm.sh"; set -u
nvm install "${NODE_VERSION}"
nvm alias default "${NODE_VERSION}"
npm install -g yarn
node -v; npm -v; yarn -v
