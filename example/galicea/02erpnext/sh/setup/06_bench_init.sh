#!/bin/bash
# Instalacja narzędzia bench i utworzenie katalogu bench z frappe v16 na Pythonie 3.14.
set -euo pipefail
source "$(dirname "$0")/erp.env"

sudo mkdir -p "${INST_ROOT}"
sudo chown "${FRAPPE_USER}:" "${INST_ROOT}"
cd "${INST_ROOT}"

# osobne venv tylko dla narzędzia bench (CLI)
[ -d venv314 ] || "${PYTHON314}" -m venv venv314
source venv314/bin/activate
pip install -U pip frappe-bench
bench --version

set +u; source "${HOME}/.nvm/nvm.sh"; nvm use "${NODE_VERSION}"; set -u

# KLUCZOWE: --python wskazuje interpreter 3.14 dla env/ wewnątrz bench.
# Bez tego bench użyje systemowego python3 (3.12/3.13) i instalacja frappe się wyłoży
# ("requires a different Python: ... not in '<3.15,>=3.14'").
bench init "${BENCH_NAME}" --frappe-branch "${BRANCH}" --python "${PYTHON314}"

"${INST}/env/bin/python" --version
# Jeśli env/ powstało na złym Pythonie - odtworzenie:
#   cd $INST && rm -rf env && $PYTHON314 -m venv env && env/bin/pip install -U pip && bench setup requirements
