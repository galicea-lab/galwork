#!/bin/bash
# Pobranie aplikacji do bench: erpnext, hrms (opcjonalnie), education (fork Galicea),
# erpnext_poland, admissions_poland. Repozytoria Galicea mogą wymagać logowania (git credentials).
set -euo pipefail
source "$(dirname "$0")/_wspolne.sh"
bench_env

bench get-app erpnext --branch "${BRANCH}"
# bench get-app hrms --branch "${BRANCH}"                       # kadry/płace - opcjonalnie

bench get-app education "${EDUCATION_URL}" --branch "${EDUCATION_BRANCH}"
bench get-app erpnext_poland "${ERPNEXT_POLAND_URL}" --branch "${ERPNEXT_POLAND_BRANCH}"
bench get-app admissions_poland "${ADMISSIONS_URL}" --branch "${ADMISSIONS_BRANCH}"

# Fork education - remote "upstream" do późniejszej synchronizacji z frappe/education
git -C apps/education remote get-url upstream >/dev/null 2>&1 || \
  git -C apps/education remote add upstream https://github.com/frappe/education.git

# zależności Pythona spoza pyproject.toml (KSeF w erpnext_poland)
bench pip install pycryptodome

cat sites/apps.txt
