# !!! NIEODWRACALNE !!! Usuwa wszystkie transakcje firmy (faktury, płatności, zapisy księgowe,
# transakcje bankowe, ...). Dane podstawowe (plan kont, kontrahenci, asortyment) zostają.
# Odpowiednik: Firma -> "Usuń wszystkie transakcje dla tej firmy" (Transaction Deletion Record).
# Używać wyłącznie na kopii testowej lub przed startem produkcyjnym. Najpierw ./kopia.sh!
COMPANY = "Nazwa Firmy"    # <- dokładna nazwa firmy (Company)
CONFIRM = False            # <- zmień na True, aby wykonać

# (ERPNext v16: dawne delete_transactions() zastąpiono rekordem Transaction Deletion Record)
from erpnext.setup.doctype.transaction_deletion_record.transaction_deletion_record import is_deletion_doc_running

if not CONFIRM:
    print("Ustaw CONFIRM = True, aby usunąć transakcje firmy", COMPANY)
else:
    is_deletion_doc_running(COMPANY)
    tdr = frappe.get_doc({"doctype": "Transaction Deletion Record", "company": COMPANY})
    tdr.insert()
    tdr.generate_to_delete_list()      # lista doctype do usunięcia - można ją przejrzeć w formularzu
    tdr.reload()
    tdr.submit()
    tdr.start_deletion_tasks()         # zadania w tle (musi działać worker)
    frappe.db.commit()
    print("Zlecono usunięcie transakcji firmy", COMPANY, "- postęp: /app/transaction-deletion-record")
