#!/bin/bash
# Naprawa środowiska Pythona bench (np. po nieudanej aktualizacji: ImportError, zła wersja frappe/click,
# "No module named ..." lub env/ zbudowane na złym Pythonie).
# Użycie: ./napraw_srodowisko.sh [--odtworz]
#   bez opcji  - reinstalacja zależności wszystkich aplikacji w istniejącym env/
#   --odtworz  - usunięcie i odtworzenie env/ na Pythonie 3.14 (PYTHON314 z ../setup/erp.env)
source "$(dirname "$0")/_wspolne.sh"
python --version
if [ "${ARGS[0]:-}" = "--odtworz" ]; then
  source "${ADMIN_DIR}/../setup/erp.env"
  deactivate || true
  mv env "env.bak.$(date +%Y%m%d%H%M)"
  "${PYTHON314}" -m venv env
  source env/bin/activate
  pip install -U pip
fi
bench setup requirements --python
pip install -U "click>=8.3.1"       # znany konflikt: stary click psuje polecenia bench
bench pip install pycryptodome       # wymagane przez KSeF w erpnext_poland
bench --site "${SITE}" migrate
restart_bench
