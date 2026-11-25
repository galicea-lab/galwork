#!/bin/bash
# Uruchomienie produkcyjne przez systemd (zamiast supervisora z "bench setup production").
set -euo pipefail
source "$(dirname "$0")/_wspolne.sh"
bench_env

bench set-config -g developer_mode 0 || true
bench --site "${SITE}" set-config developer_mode 0
bench setup systemd --yes

sudo ln -sf "${INST}"/config/systemd/*.service /etc/systemd/system/
sudo ln -sf "${INST}"/config/systemd/*.target  /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable "${BENCH_NAME}.target"     # start po restarcie serwera
sudo systemctl start  "${BENCH_NAME}.target"

systemctl --no-pager status "${BENCH_NAME}.target" | head -15
systemctl --no-pager list-units "${BENCH_NAME}-*" 
