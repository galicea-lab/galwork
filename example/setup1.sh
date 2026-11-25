#!/bin/bash
# 2026-11-25: katalog definicji obiegów (BPMN + formularze) montowany do huba
# (SPIFFWORKFLOW_DIR w .env). Źródło: galwork-hub/spiffworkflow albo galwork-models.
# Użycie (z katalogu example/): ./setup1.sh [katalog_źródłowy] [katalog_docelowy]
set -euo pipefail
SRC="${1:-../../galwork-hub/spiffworkflow}"
DEST="${2:-/srv/galwork/spiffworkflow}"
[ -d "$SRC" ] || { echo "Brak katalogu źródłowego: $SRC"; exit 1; }
sudo mkdir -p "$DEST"
sudo cp -p -R "$SRC"/. "$DEST"/
# uid 1000 = użytkownik `galwork` w kontenerze huba (odczyt i zapis z edytorów areny)
sudo chown -R 1000:1000 "$DEST"
