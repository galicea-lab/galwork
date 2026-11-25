#!/bin/bash
# Python 3.14 przez pyenv (lokalnie dla użytkownika, NIE podmieniamy /usr/bin/python3!).
# Debian 13 ma Pythona 3.13, Ubuntu 24.04 - 3.12; Frappe v16 wymaga >=3.14,<3.15.
# Pakiety do kompilacji instaluje 01_pakiety_systemowe.sh.
set -euo pipefail
source "$(dirname "$0")/erp.env"

if [ ! -d "${HOME}/.pyenv" ]; then
  curl -fsSL https://pyenv.run | bash
  cat >> "${HOME}/.bashrc" <<'RC'
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
RC
fi
export PYENV_ROOT="${HOME}/.pyenv"; export PATH="${PYENV_ROOT}/bin:${PATH}"

pyenv install --list | grep -E '^\s*3\.14\.[0-9]+$' | tail -3
pyenv install -s "${PY_VERSION}"
"${PYTHON314}" --version

# Alternatywa (oficjalnie zalecana przez Frappe) - uv:
#   curl -LsSf https://astral.sh/uv/install.sh | sh
#   uv python install 3.14
#   uv python find 3.14      # -> ścieżkę wpisz do PYTHON314 w erp.env
