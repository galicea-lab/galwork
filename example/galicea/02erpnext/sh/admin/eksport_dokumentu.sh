#!/bin/bash
# Eksport dokumentu (np. Workspace, Print Format, Report) do JSON - przeniesienie między witrynami.
# Użycie: ./eksport_dokumentu.sh [-s witryna] <DocType> <nazwa> [plik.json]
# Import w witrynie docelowej:  bench --site <cel> import-doc <plik.json>
source "$(dirname "$0")/_wspolne.sh"
DT="${ARGS[0]:?DocType}"; NAME="${ARGS[1]:?nazwa dokumentu}"
OUT="${ARGS[2]:-${ADMIN_DIR}/$(echo "${DT}_${NAME}" | tr ' /' '__').json}"
bench --site "${SITE}" export-json "$DT" "$OUT" --name "$NAME"
echo "Zapisano: $OUT"
