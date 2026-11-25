#!/usr/bin/env python3
"""Przygotowanie pliku CSV planu kont do importu w ERPNext (Import danych -> Account -> Insert New Records).

Wejście: eksport planu kont z działającej instancji (format plan_wdrozony.csv):
    "ID","Nazwa konta","Firma","Konto nadrzędne","JPK Znacznik Konta","Numer konta","Typ konta",
    "JPK Tag Podatkowy","JPK Pozycja Bilansu","JPK Pozycja RZiS",...

Co robi skrypt (problemy opisane w README.md):
  * porządkuje wiersze tak, by konto nadrzędne zawsze było przed podrzędnym
    (importer wymaga, by konto nadrzędne już istniało),
  * ustawia is_group=1 dla kont, które mają konta podrzędne,
  * ustawia root_type dla kont głównych (Aktywa/Pasywa/Fundusze/Przychody/Koszty),
  * podmienia nazwę firmy i jej skrót (sufiks " - FG" w nazwach kont),
  * kolumny nazywa nazwami pól (fieldname) - działa niezależnie od języka interfejsu.

Użycie:
    python3 przygotuj_import_planu.py plan_wdrozony.csv import_planu.csv \
        --firma "Fundacja Galicea" --skrot FG [--stary-skrot FG]
"""

import argparse
import csv
import sys

# nazwa konta głównego -> root_type ERPNext
ROOT_TYPES = {
    "Aktywa": "Asset",
    "Pasywa": "Liability",
    "Fundusze": "Equity",
    "Kapitały": "Equity",
    "Przychody": "Income",
    "Koszty": "Expense",
}

OUT_COLUMNS = [
    "account_name", "account_number", "company", "parent_account", "is_group",
    "root_type", "account_type",
    "jpk_znacznik_konta", "jpk_podatek_tag", "jpk_bilans_pozycja", "jpk_rzis_pozycja",
]


def resuffix(name, old, new):
    """'700 - Przychody - FG' -> '700 - Przychody - NEW'."""
    if not name:
        return ""
    suffix = f" - {old}"
    if name.endswith(suffix):
        name = name[: -len(suffix)]
    return f"{name} - {new}"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("wejscie")
    ap.add_argument("wyjscie")
    ap.add_argument("--firma", required=True, help="nazwa firmy (Company) w docelowym systemie")
    ap.add_argument("--skrot", required=True, help="skrót firmy w docelowym systemie")
    ap.add_argument("--stary-skrot", default="FG", help="skrót firmy w pliku wejściowym (domyślnie FG)")
    args = ap.parse_args()

    with open(args.wejscie, encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.DictReader(fh))

    by_id = {r["ID"]: r for r in rows}
    parents = {r["Konto nadrzędne"] for r in rows if r["Konto nadrzędne"]}
    missing = parents - by_id.keys()
    if missing:
        sys.exit(f"Brak kont nadrzędnych w pliku: {sorted(missing)}")

    # kolejność: przejście drzewa od korzeni (stabilne względem kolejności w pliku)
    children = {}
    for r in rows:
        children.setdefault(r["Konto nadrzędne"], []).append(r)
    ordered = []

    def walk(parent_id):
        for r in children.get(parent_id, []):
            ordered.append(r)
            walk(r["ID"])

    walk("")
    if len(ordered) != len(rows):
        sys.exit("Plik zawiera cykl w hierarchii kont")

    with open(args.wyjscie, "w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=OUT_COLUMNS, quoting=csv.QUOTE_ALL)
        w.writeheader()
        for r in ordered:
            is_root = not r["Konto nadrzędne"]
            root_type = ROOT_TYPES.get(r["Nazwa konta"].strip(), "") if is_root else ""
            if is_root and not root_type:
                sys.exit(f"Nieznany typ konta głównego: {r['Nazwa konta']!r} - uzupełnij ROOT_TYPES")
            w.writerow({
                "account_name": r["Nazwa konta"].strip(),
                "account_number": r["Numer konta"].strip(),
                "company": args.firma,
                "parent_account": resuffix(r["Konto nadrzędne"], args.stary_skrot, args.skrot),
                "is_group": 1 if (r["ID"] in parents or is_root) else 0,
                "root_type": root_type,
                "account_type": r["Typ konta"].strip(),
                "jpk_znacznik_konta": r.get("JPK Znacznik Konta", "").strip(),
                "jpk_podatek_tag": r.get("JPK Tag Podatkowy", "").strip(),
                "jpk_bilans_pozycja": r.get("JPK Pozycja Bilansu", "").strip(),
                "jpk_rzis_pozycja": r.get("JPK Pozycja RZiS", "").strip(),
            })

    print(f"Zapisano {len(ordered)} kont ({len(parents)} grup) do {args.wyjscie}")


if __name__ == "__main__":
    main()
