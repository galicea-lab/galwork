# Odłączenie od płatności (Payment Entry) automatycznie utworzonego zapisu różnic kursowych.
# Objaw: nie można anulować / ponownie rozliczyć płatności walutowej, bo wskazuje na
# Journal Entry różnic kursowych, który został już anulowany lub usunięty.
# Po odłączeniu - sprawdź i w razie potrzeby utwórz zapis różnic ręcznie.
PAYMENT_ENTRY = "PL/2026/02/00008-2"     # <- numer płatności

doc = frappe.get_doc("Payment Entry", PAYMENT_ENTRY)
print("Było:", doc.get("exchange_gain_loss_journal"))
doc.db_set("exchange_gain_loss_journal", None)
frappe.db.commit()
print("Odłączono zapis różnic kursowych od", PAYMENT_ENTRY)
