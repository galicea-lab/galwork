# Dokumentacja

- [01_instalacja.md](01_instalacja.md) – instalacja serwera ERPNext v16 z aplikacjami Galicea (skrypty: `sh/setup`)
- [02_konfiguracja_systemu.md](02_konfiguracja_systemu.md) – konfiguracja w systemie: firma, plan kont, VAT, bank, waluty, KSeF, JPK, moduły uczelniane
- [03_podrecznik_administratora.md](03_podrecznik_administratora.md) – administracja: usługi, kopie, aktualizacje, wyciągi bankowe, KSeF, problemy (skrypty: `sh/admin`)

# Plan kont

Najtrudniejszą częścią wdrożenia jest przygotowanie planu kont.
Konta muszą być z jednej strony zgodne z polskimi standardami rachunkowości, a z drugiej - zawierać kategoryzację taką, jaką narzuca system.
Czyli podział na:
- Aktywa
- Pasywa
- Fundusze
- Przychody
- Koszty
Każde konto musi należeć do jednej z tych kategorii.
To może sprawiać problemy przy kontach rozliczeniowych.
Więcej o tych problemach w pliku doc/plan_kont.md

W katalogu plan_kont zawarto projekt takiego planu kont dla fundacji.

Konta można wczytać do systemu. 
Trzeba jednak wziąć pod uwagę następujące problemy:
- automat wczytujący wymaga, by dane do których konto się odwołuje były już w systemie - dlatego trzeba te dane wczytywać systematycznie: najpierw konta nadrzedne, a potem pochodne;
- stare konta trzeba usunąć, ale należy uważać, by nie usunąć kont systemowych wyliczonych powyżej - ponadto obowiązuje podobna zasada jak przy wczytywaniu: najpier podrzędne

W pliku plan_wdrozony.csv są dane wdrożonego planu (eksport z systemu). Plik do importu (właściwa kolejność, grupy, typy kont głównych, skrót firmy) przygotowuje skrypt `plan_kont/przygotuj_import_planu.py` – zob. 02_konfiguracja_systemu.md, punkt 3.4.

Po wczytaniu planu kont trzeba ustawić parametry księgowania w ustawieniach systemowych.


# Bank

W ErpNext jest funkcja wczytywania wyciagów z banku z opcją MT940.
Jednak przyjmowane jest tylko zestawienie csv o określonej strukturze.
W katalogu bank jest przygotowany skrypt, który taki plik wyciągu przygotowuje.
Dodatkowo plik z banku (PeKaO) z przykładową operacją i jej wynik.

# Faktury zagraniczne i różnice kursowe

W ErpNext nie można na jednym koncie rozliczać faktur złotówkowych i walutowych.
Musi to być rozdzielone - zarówno na planie kont (osobne konta rozrachunkowe walutowe), jak i w kartotekach kontrahentów oraz w ustawieniach KSeF (konto zobowiązań USD) – zob. 02_konfiguracja_systemu.md, punkt 6.

# Ksef

Zobacz podkatalog ksef
