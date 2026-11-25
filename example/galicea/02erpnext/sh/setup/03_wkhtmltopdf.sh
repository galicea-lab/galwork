#!/bin/bash
# wkhtmltopdf 0.12.6 z "patched Qt" - wymagany do wydruków PDF (paczka z apt NIE ma patched Qt).
# Dla Debiana 13 / Ubuntu 24.04 nie ma jeszcze dedykowanej paczki - używamy wersji bookworm (Debian 12), działa.
set -euo pipefail
PKG="wkhtmltox_0.12.6.1-3.bookworm_amd64.deb"
cd /tmp
wget -N "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/${PKG}"
sudo apt install -y "./${PKG}" || { sudo apt --fix-broken install -y; sudo apt install -y "./${PKG}"; }
wkhtmltopdf --version   # powinno pokazać: wkhtmltopdf 0.12.6.1 (with patched qt)
