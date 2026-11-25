#!/bin/bash
# Konfiguracja MariaDB dla Frappe: utf8mb4 + hasło roota (podawane interaktywnie, nie zapisywane).
set -euo pipefail

sudo tee /etc/mysql/mariadb.conf.d/99-frappe.cnf >/dev/null <<'CNF'
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
innodb_file_per_table = 1
innodb_buffer_pool_size = 1G

[mysql]
default-character-set = utf8mb4
CNF
sudo systemctl restart mariadb

echo "Ustawienie hasła roota MariaDB (bench new-site / restore go wymagają)."
echo "Zalecane: sudo mariadb-secure-installation  (odpowiedz: hasło roota - TAK, usuń anonimowych - TAK, zdalny root - NIE)"
read -r -p "Uruchomić mariadb-secure-installation teraz? [t/N] " a
if [[ "$a" =~ ^[tTyY]$ ]]; then sudo mariadb-secure-installation; fi
mariadb --version
