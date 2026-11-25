# Wymusza utworzenie pól niestandardowych zdefiniowanych w hooks.py aplikacji (słownik custom_fields).
# Przydatne, gdy po migracji brakuje pól JPK/KSeF na Account, Sales Invoice, Purchase Invoice itd.
APP = "erpnext_poland"

import importlib
from frappe.custom.doctype.custom_field.custom_field import create_custom_fields

hooks = importlib.import_module(f"{APP}.hooks")
create_custom_fields(hooks.custom_fields, update=True)
frappe.db.commit()
print("Utworzono/zaktualizowano pola dla:", ", ".join(hooks.custom_fields))
