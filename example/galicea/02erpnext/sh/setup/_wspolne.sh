# shellcheck shell=bash
# Wspólny nagłówek skryptów setup - dołączany przez: source "$(dirname "$0")/_wspolne.sh"
set -euo pipefail
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=erp.env
source "${SETUP_DIR}/erp.env"

# Aktywacja środowiska wirtualnego bench (env/) - po wykonaniu 06_bench_init.sh
bench_env() {
  cd "${INST}"
  # shellcheck disable=SC1091
  source "${INST}/env/bin/activate"
  # nvm (node) - bench build potrzebuje node/yarn w PATH
  if [ -s "${HOME}/.nvm/nvm.sh" ]; then
    set +u; source "${HOME}/.nvm/nvm.sh"; nvm use "${NODE_VERSION}" >/dev/null || true; set -u
  fi
}
