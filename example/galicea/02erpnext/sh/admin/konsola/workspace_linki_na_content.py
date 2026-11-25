# Przebudowa pola "content" obszaru roboczego (Workspace) na podstawie tabeli links.
# Objaw: po aktualizacji obszar roboczy (np. JPK, FK) jest pusty, choć ma zdefiniowane linki.
WORKSPACE = "JPK"          # <- nazwa obszaru roboczego
MODULE = "JPK"             # <- moduł, do którego należy (do eksportu pliku JSON; None = bez eksportu)

import json

ws = frappe.get_doc("Workspace", WORKSPACE)
content = []
for link in ws.links:
    if link.type == "Card Break":
        content.append({"type": "header", "data": {"text": link.label, "col": 12}})
    elif link.type == "Link":
        content.append({"type": "shortcut", "data": {
            "shortcut_name": link.label, "label": link.label,
            "type": link.link_type, "link_to": link.link_to, "col": 4}})
ws.content = json.dumps(content)
ws.db_update()                     # zapis z pominięciem walidacji UI
if MODULE and frappe.conf.developer_mode:
    from frappe.modules.export_file import export_to_files
    export_to_files(record_list=[["Workspace", ws.name]], record_module=MODULE)
frappe.db.commit()
print(f"Workspace {WORKSPACE}: zapisano {len(content)} bloków")
