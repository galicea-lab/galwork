#!/bin/bash
# Kopia bezpieczeństwa witryny: baza + pliki publiczne/prywatne + site_config.json (zaszyfrowane hasła!),
# skopiowana do ${BACKUP_DIR}/<data>, z rotacją starszych niż BACKUP_KEEP_DAYS.
# Użycie: ./kopia.sh [-s witryna] [--all]   (--all = wszystkie witryny, tylko kopia w sites/*/private/backups)
# Do crona (codziennie 2:30):  30 2 * * * /ścieżka/sh/admin/kopia.sh >> /erp/backup/kopia.log 2>&1
source "$(dirname "$0")/_wspolne.sh"
if [ "${ARGS[0]:-}" = "--all" ]; then bench backup-all-sites; exit 0; fi

bench --site "${SITE}" backup --with-files --compress
SRC="sites/${SITE}/private/backups"
DEST="${BACKUP_DIR}/$(date +%Y%m%d_%H%M%S)_${SITE}"
mkdir -p "${DEST}"
# ostatni komplet (baza, pliki, kopia site_config)
LAST=$(ls -t "${SRC}"/*-database.sql.gz | head -1); PREFIX="${LAST%-database.sql.gz}"
cp -p "${PREFIX}"* "${DEST}/"
cp -p "sites/${SITE}/site_config.json" "${DEST}/site_config.json"   # zawiera encryption_key i hasło bazy
chmod 600 "${DEST}"/*
ls -lh "${DEST}"
find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime +"${BACKUP_KEEP_DAYS}" -exec rm -rf {} +
# Kopię warto przenieść poza serwer, np.: rsync -a "${BACKUP_DIR}/" backup@inny-host:/kopie/erp/
