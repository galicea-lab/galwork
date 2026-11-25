#!/bin/bash
# Certyfikat Let's Encrypt dla witryny (certbot sam dopisze sekcje SSL do konfiguracji nginx).
# UWAGA: ponowne "bench setup nginx" nadpisze config/nginx.conf - wtedy uruchom ten skrypt jeszcze raz.
set -euo pipefail
source "$(dirname "$0")/erp.env"
sudo certbot --nginx -d "${SITE}"
sudo systemctl list-timers | grep -i certbot || echo "Sprawdź automatyczne odnawianie: sudo certbot renew --dry-run"
