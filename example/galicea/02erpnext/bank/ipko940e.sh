#!/bin/bash
# Konwersja wyciągu bankowego do CSV dla "Import wyciągów bankowych" ERPNext.
# Użycie:
#   ./ipko940e.sh <plik_MT940>            - wyciąg MT940
#   ./ipko940e.sh --csv <Lista_operacji.csv>  - eksport listy operacji z bankowości (Pekao)
# Wynik: zestawienie_RRRR_MM.csv w bieżącym katalogu (dla CSV - po jednym pliku na miesiąc).
# Wymaga pakietu mt-940 - jest w środowisku bench; można też wskazać inny Python zmienną PYTHON.
PYTHON="${PYTHON:-/erp/erpnext-bench/env/bin/python}"
exec "$PYTHON" -I "$(dirname "$(realpath "$0")")/ipko940e.py" "$@"
