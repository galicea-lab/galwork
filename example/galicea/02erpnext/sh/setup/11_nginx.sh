#!/bin/bash
# Konfiguracja nginx dla witryny $SITE (DNS domeny musi wskazywać na serwer).
set -euo pipefail
source "$(dirname "$0")/_wspolne.sh"
bench_env

# nazwa witryny = domena, więc wystarczy tryb DNS multitenant (bez "bench setup add-domain")
bench config dns_multitenant on
bench setup nginx --yes

sudo ln -sf "${INST}/config/nginx.conf" "/etc/nginx/conf.d/${BENCH_NAME}.conf"
# nginx musi mieć dostęp do sites/assets: katalog domowy/instalacji z prawem x dla "others"
chmod o+x "${INST_ROOT}" "${INST}" "${INST}/sites"
sudo nginx -t
sudo systemctl reload nginx
