# Przepisy dla konsoli Frappe

Uruchamianie: `../konsola.sh [-s witryna] konsola/<plik>.py` (z katalogu `sh/admin`)
albo interaktywnie (`./konsola.sh`) i wklejenie treści.

Przed uruchomieniem **każdego** z nich: `./kopia.sh`. Parametry ustawia się na początku pliku.

| plik | do czego |
|---|---|
| `utworz_pola_custom.py` | wymusza utworzenie pól `custom_fields` z `hooks.py` aplikacji (gdy migracja ich nie utworzyła) |
| `odlacz_roznice_kursowe.py` | odłącza od Payment Entry zapis różnic kursowych (Journal Entry), który blokuje anulowanie/korektę płatności |
| `workspace_linki_na_content.py` | naprawa Workspace (stary układ `links` -> nowy `content`), gdy obszar roboczy jest pusty po aktualizacji |
| `usun_transakcje_firmy.py` | usuwa WSZYSTKIE transakcje firmy (testy, ponowny start wdrożenia) - dane podstawowe zostają |
