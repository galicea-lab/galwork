# shellcheck shell=bash
# Wspólny nagłówek skryptów administracyjnych: source "$(dirname "$0")/_wspolne.sh"
# Obsługuje opcję -s <witryna> (nadpisuje SITE z erp.env).
set -euo pipefail
ADMIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=erp.env
source "${ADMIN_DIR}/erp.env"
if [ "${1:-}" = "-s" ]; then SITE="${2:?podaj nazwę witryny po -s}"; shift 2; fi
ARGS=("$@")

cd "${INST}"
# shellcheck disable=SC1091
source "${INST}/env/bin/activate"
if [ -s "${HOME}/.nvm/nvm.sh" ]; then
  set +u; source "${HOME}/.nvm/nvm.sh"; nvm use "${NODE_VERSION}" >/dev/null 2>&1 || true; set -u
fi

# czy bench działa przez systemd (produkcja), czy przez "bench start" (dev)
is_systemd() { systemctl list-unit-files "${BENCH_NAME}.target" >/dev/null 2>&1 && \
               systemctl is-enabled "${BENCH_NAME}.target" >/dev/null 2>&1; }

restart_bench() {
  if is_systemd; then sudo systemctl restart "${BENCH_NAME}.target"; else bench restart || true; fi
}
