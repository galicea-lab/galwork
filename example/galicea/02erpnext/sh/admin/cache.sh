#!/bin/bash
# Czyszczenie cache witryny (po zmianach konfiguracji, tłumaczeń, uprawnień, szablonów).
source "$(dirname "$0")/_wspolne.sh"
bench --site "${SITE}" clear-cache
bench --site "${SITE}" clear-website-cache
