#!/bin/bash
# Pakiety systemowe dla Frappe/ERPNext v16 (Debian 13 / Ubuntu 24.04).
set -euo pipefail
sudo apt update

# narzędzia, serwer WWW, certyfikaty, redis, cron
sudo apt install -y git curl wget sudo cron lsb-release gpg nginx certbot python3-certbot-nginx \
  redis-server pkg-config net-tools

# MariaDB + nagłówki klienta (budowa mysqlclient)
sudo apt install -y mariadb-server mariadb-client default-libmysqlclient-dev

# kompilacja Pythona 3.14 przez pyenv (libzstd-dev - moduł compression.zstd z 3.14)
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev llvm libncurses-dev xz-utils tk-dev libffi-dev liblzma-dev libzstd-dev

# generowanie PDF (wkhtmltopdf instaluje 03_wkhtmltopdf.sh) i fonty
sudo apt install -y xvfb libfontconfig fontconfig xfonts-75dpi xfonts-base

# KSeF (erpnext_poland): podpis XAdES/XMLDSig wymaga xmlsec1
sudo apt install -y xmlsec1 libxml2-dev libxslt1-dev libxmlsec1-dev

# opcjonalnie: klient PostgreSQL (np. Frappe Insights łączące się z zewnętrzną bazą)
# sudo apt install -y libpq-dev postgresql-client

sudo systemctl enable --now mariadb redis-server nginx cron
