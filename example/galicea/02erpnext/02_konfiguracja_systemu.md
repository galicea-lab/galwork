# ERPNext w Galicea – konfiguracja systemu

Ten dokument opisuje konfigurację wykonywaną **wewnątrz** systemu (w przeglądarce, w Desk)
po instalacji według [01_instalacja.md](01_instalacja.md). Obejmuje ustawienia ogólne,
firmę, plan kont, podatki, bank, waluty, aplikację `erpnext_poland` (dzienniki, JPK, KSeF)
oraz moduły uczelniane.

Konwencje:

* Ścieżki ekranów podano po polsku z nazwą angielską w nawiasie. Formularz można też
  otworzyć adresem `https://<witryna>/desk/<nazwa-doctype>`, np. `/desk/accounts-settings`.
* Fundacja Galicea korzysta obecnie z serwera ERPNext firmy Transmem (`galicea.transmem.pl`).
* Skrót firmy w przykładach to `FG`.

Kolejność ma znaczenie. Plan kont i konta domyślne muszą być gotowe **przed** pierwszym
księgowaniem i przed wprowadzeniem sald otwarcia. Późniejsza zmiana planu kont jest bardzo trudna.

---

## 1. Kreator i ustawienia systemowe

### 1.1. Kreator konfiguracji (Setup Wizard)

Przy pierwszym logowaniu Administratora:

* język: **Polski**; kraj: **Polska**; strefa czasowa: **Europe/Warsaw**; waluta: **PLN**,
* firma: pełna nazwa, **krótki skrót** (np. `FG`). Skrót jest doklejany do nazw wszystkich
  kont, centrów kosztów i szablonów podatków, np. `700 - Przychody ze sprzedaży - FG`,
  i późniejsza jego zmiana jest kłopotliwa,
* plan kont: wybieramy „Standard”. Zostanie zastąpiony własnym planem (punkt 3),
* rok obrachunkowy: np. 01.01.2026–31.12.2026.

### 1.2. Ustawienia systemu (System Settings) – `/desk/system-settings`

* Format daty `dd.mm.yyyy`, format liczb `#.###,##`, pierwszy dzień tygodnia: poniedziałek.
* Precyzja liczb i walut: 2.
* Polityka haseł i blokowanie konta po nieudanych logowaniach według polityki bezpieczeństwa fundacji.

### 1.3. Ustawienia kont (Accounts Settings) – `/desk/accounts-settings`

Zalecane ustawienia:

| pole | ustawienie | dlaczego |
|---|---|---|
| Check Supplier invoice number uniqueness | ✔ | ochrona przed podwójnym zaksięgowaniem faktury zakupu (także z KSeF) |
| Unlink Payment on cancellation of invoice | ✔ | anulowanie faktury nie blokuje się na powiązanej płatności |
| Delete Accounting and Stock Ledger entries on deletion of transaction | wg potrzeb | patrz niżej |
| Enable Immutable Ledger | ✘ (lub ✔ po zakończeniu wdrożenia) | patrz niżej |
| Auto reconcile Payments | wg potrzeb | półautomatyczne uzgadnianie płatności z fakturami |
| Enable Accounting Dimensions | ✔ gdy używamy wymiarów (projekty, źródła finansowania) | |

**Usuwanie dokumentów.** ERPNext co do zasady nie usuwa zatwierdzonych dokumentów, tylko je
anuluje. Anulowanie tworzy zapisy odwracające. Usuwanie *anulowanych* dokumentów razem
z zapisami w księdze umożliwia opcja *Delete Accounting and Stock Ledger entries on deletion
of transaction* oraz uprawnienie „Usuń” w roli. W okresie wdrożenia ułatwia to sprzątanie
pomyłek. Po zamknięciu okresu opcję warto wyłączyć, a zamknięte miesiące blokować
(*Accounts Frozen Till Date* / *Period Closing Voucher*).

---

## 2. Firma (Company) – `/desk/company/<nazwa>`

* **Dane**: nazwa, skrót, NIP (*Tax ID*), adres, kontakt. Pola dodane przez `erpnext_poland`
  służą do JPK: **JPK Kod Urzędu** (kod urzędu skarbowego), **JPK REGON**,
  **JPK Forma Opodatkowania**.
* **Konta domyślne** (zakładka *Accounts*) ustawiamy **po** imporcie planu kont (punkt 3.5).

---

## 3. Plan kont

### 3.1. Najważniejszy problem

Przygotowanie planu kont to najtrudniejsza część wdrożenia. Konta muszą jednocześnie:

* odpowiadać polskiemu planowi kont (UoR, ewidencja kosztów w zespole 4, sprawozdanie fundacji),
* należeć do jednej z pięciu kategorii głównych (*root type*), które wymusza ERPNext:

| konto główne | root type | raport |
|---|---|---|
| Aktywa | Asset | Bilans |
| Pasywa | Liability | Bilans |
| Fundusze | Equity | Bilans |
| Przychody | Income | Rachunek zysków i strat |
| Koszty | Expense | Rachunek zysków i strat |

Konta **rozrachunkowe** sprawiają kłopot, bo w polskim planie mogą mieć saldo po obu stronach,
a ERPNext każe je przypisać do aktywów albo pasywów. Szczegóły i przyjęte kompromisy są
w `doc/plan_kont.md` i `plan_kont/plan_kont_uwagi.md`. Najważniejsze z nich:

* **Konta „zysk/strata”** (pola firmy *Gain/Loss Account on Asset Disposal*, *Exchange Gain / Loss
  Account* itd.) oczekują jednego konta na wynik netto operacji. Rozwiązanie: **konto techniczne**
  (np. `76-9 Wynik na sprzedaży środków trwałych (techniczne)`), używane tylko przez system.
  Przy zamknięciu okresu jego saldo służy do kontroli. Nie wskazujemy tu kont wyniku
  finansowego (860, wynik lat ubiegłych).
* **Stawka VAT nie jest cechą konta**. Bierze się z szablonów podatków (punkt 4), a konto VAT
  jest tylko kontem księgowym.
* **Rozliczenie wynagrodzeń**: jedno konto syntetyczne z analityką, np.
  `23-01 Wynagrodzenia do wypłaty` (→ *Payroll Payable Account*) i `23-02 Zaliczki pracownicze`
  (→ *Employee Advance Account*). Oba subkonta to Liability.
* **RMK czynne** (Asset) i **bierne** (Liability) to osobne grupy. ERPNext ich nie rozlicza
  automatycznie, odpisy księgujemy przez *Polecenie księgowania (Journal Entry)*.
* **Koszty**: konta zespołu 4 (rodzajowe) i koszt własny sprzedaży (zespół 7) mają root type
  Expense i poprawne pozycje RZiS. Z tego da się złożyć JPK.
* **Waluty**: rozrachunki w PLN i w walutach obcych muszą być na **osobnych kontach** (punkt 6).

### 3.2. Pliki planu kont

| plik | zawartość |
|---|---|
| `plan_kont/plan20260101.csv` | projekt planu fundacji od 2026 r.: numer, nazwa, typ konta, znaczniki JPK |
| `plan_kont/plan_wdrozony.csv` | eksport planu wdrożonego w systemie (ID z sufiksem ` - FG`, firma, konto nadrzędne, typ, znaczniki JPK) – **wzorzec do importu** |
| `plan_kont/przygotuj_import_planu.py` | przygotowanie pliku do importu (kolejność, grupy, root type, zmiana firmy/skrótu) |
| `doc/plan_kont.md` | opis polskiego planu kont w ERPNext 16 |
| `plan_kont/plan_kont_uwagi.md` | konflikty modelu anglosaskiego z polską rachunkowością |

### 3.3. Pola JPK na koncie

`erpnext_poland` dodaje do konta (Account) pola:

* **JPK Znacznik Konta** (`jpk_znacznik_konta`): `1`…`8`, `K_0_1`, `K_0_2`, `K_1_1`, `K_2_1`, `W_4`, `W_5`, `W_7`,
* **JPK Tag Podatkowy** (`jpk_podatek_tag`): `P_P_D` przychód podatkowy, `P_N_P` przychód
  niepodatkowy, `K_P_D` koszt uzyskania przychodu, `K_N_P` koszt niepodatkowy (NKUP), `R_T_D`, `R_P_U`,
* **JPK Pozycja Bilansu** (`jpk_bilans_pozycja`) i **JPK Pozycja RZiS** (`jpk_rzis_pozycja`), np. `A.I`.

Pola muszą istnieć **przed** importem planu, czyli `erpnext_poland` musi być już zainstalowany.
Inaczej import kończy się błędem *Field not found*. Gdy pól brakuje mimo instalacji, wykonujemy
`sh/admin/konsola.sh konsola/utworz_pola_custom.py`.

### 3.4. Import planu kont – procedura

Importer ERPNext ma dwa ograniczenia:

1. Konto nadrzędne musi już istnieć w systemie. Dane trzeba więc wczytywać od kont
   nadrzędnych do podrzędnych. Konto z podkontami musi mieć `is_group = 1`, a konto główne
   musi mieć `root_type`.
2. Stare konta (z planu „Standard”) trzeba usunąć, ale **nie wolno usunąć kont systemowych**
   wskazanych w ustawieniach firmy, w szablonach podatków ani na kontach bankowych.
   Usuwamy w odwrotnej kolejności: najpierw podrzędne, potem grupy.

Procedura:

1. **Przygotuj plik**:
   ```bash
   cd plan_kont
   python3 przygotuj_import_planu.py plan_wdrozony.csv import_planu.csv \
           --firma "Fundacja Galicea" --skrot FG
   ```
   Skrypt ustawia kolejność (przejście drzewa od korzeni), `is_group`, `root_type` kont głównych
   (Aktywa→Asset, Pasywa→Liability, Fundusze→Equity, Przychody→Income, Koszty→Expense),
   podmienia firmę i skrót, a kolumny nazywa nazwami pól. Importer rozpoznaje je niezależnie
   od języka interfejsu. Przy eksporcie z innej instancji usuwamy sufiks skrótu starej firmy
   (`--stary-skrot`). Inaczej powstaną nazwy typu `Przychody - TM - FG`.
2. **Import**: *Import danych (Data Import)* → Nowy → Typ dokumentu **Account**,
   *Insert New Records* → załącz `import_planu.csv` → sprawdź podgląd i ostrzeżenia → *Start Import*.
   Przy błędach: *Pobierz wiersze z błędami*, popraw je i zaimportuj ponownie tylko te wiersze.
3. **Przenieś lub zastąp konta systemowe** ze starego planu, a nowe wskaż w ustawieniach
   (punkt 3.5). Dopiero potem usuń stare konta, od liści w górę drzewa. Wygodnie robi się to
   w widoku drzewa *Plan kont (Chart of Accounts)*. Kont z zapisami nie da się usunąć,
   można je najwyżej wyłączyć (*Disabled*).
4. **Kontrola**: drzewo planu kont, raport *Zestawienie obrotów i sald (Trial Balance)* (pusty,
   ale z kompletną strukturą) oraz wyrywkowo znaczniki JPK na kontach przychodów i kosztów.

### 3.5. Konta domyślne i parametry księgowania

Po wczytaniu planu ustawiamy konta w **Firmie** (zakładka *Accounts*). Przykład według `plan_wdrozony.csv`:

| pole firmy | konto |
|---|---|
| Default Bank Account | `111.001 - Rachunek bieżący` |
| Default Cash Account | `100.001 - Kasa główna` |
| Default Receivable Account | `200.001 - Rozrachunki z odbiorcami` |
| Default Payable Account | `201.001 - Rozrachunki z dostawcami krajowymi` |
| Round Off Account | `798.001 - Zaokrąglenia bieżące` |
| Round Off for Opening | konto typu *Round Off for Opening* |
| Exchange Gain / Loss Account | konto różnic kursowych (techniczne, punkt 6) |
| Unrealized Exchange Gain/Loss Account | jw., dla wyceny bilansowej |
| Default Income Account / Default Cost of Goods Sold Account | domyślne konto przychodów / kosztu własnego |
| Default Cost Center, Round Off Cost Center | główne centrum kosztów (MPK) |
| Default Advance Received / Paid Account | konta zaliczek (gdy zaliczki mają iść na osobne konta) |
| Gain/Loss Account on Asset Disposal, konta amortyzacji | konta techniczne i konta zespołu 0/4 (gdy ewidencjonujemy środki trwałe) |

Następnie:

* **Ustawienia księgowości polskiej (Polish Accounting Settings)** (`/desk/polish-accounting-settings`):
  sekcje *VAT* (konto VAT naliczonego, MPK, opis) i *Bank* (konto i MPK prowizji bankowych),
  a sekcję *KSeF* według punktu 8.
* Szablony podatków (punkt 4), konta bankowe (punkt 5), konta walutowe (punkt 6).

### 3.6. Salda otwarcia

* Wprowadzamy wyłącznie konta **bilansowe**: *Polecenie księgowania* z zaznaczonym
  *Is Opening*, a dla należności i zobowiązań *Opening Invoice Creation Tool*, żeby powstały
  otwarte faktury do rozliczenia.
* Różnica trafia na konto techniczne **Temporary Opening**. Po wprowadzeniu wszystkiego jego
  saldo musi wynosić **0,00**.
* Najprościej startować od początku roku obrachunkowego.

---

## 4. Podatki VAT

* **Szablony podatków sprzedaży** (*Sales Taxes and Charges Template*): np. „VAT 23%”, konto
  `220.001 - VAT należny`. Stawki 8%, 5%, 0%, „zw” i „np” obsługujemy przez *Item Tax Template*
  przypięte do pozycji asortymentu albo przez osobne szablony.
* **Szablony podatków zakupu** (*Purchase Taxes and Charges Template*): konto VAT naliczonego
  (to samo, które ustawiamy w *Polish Accounting Settings → VAT*. Faktury z KSeF dostają
  podatki według tych ustawień).
* **Kategorie podatkowe i reguły** (*Tax Category*, *Tax Rule*), gdy dla kontrahentów
  zagranicznych mają się podstawiać inne szablony (np. odwrotne obciążenie).
* Pola JPK na fakturach (zakładka **JPK i KSeF**): *JPK Procedure* (`EE`, `TP`, `MR_UZ`, …),
  *JPK_VAT Transaction Type*, *JPK_VAT GTU*, *Split Payment Mechanism (MPP)*, a na pozycji
  *Kod GTU*. Na asortymencie (*Item*) można ustawić domyślny GTU.
* Faktury mają pola **miesiąca ewidencyjnego** i **miesiąca VAT** (`custom_month`,
  `custom_vat_month` w formacie RRRRMM). Na ich podstawie powstaje JPK_V7M.

---

## 5. Bank i kasa

1. *Bank* (`/desk/bank`): np. „Pekao SA”.
2. *Konto bankowe (Bank Account)*: ✔ *Is Company Account*, firma, **konto księgowe**
   (np. `111.001 - Rachunek bieżący`, typ *Bank*), IBAN, waluta. Osobny rekord zakładamy dla
   każdego rachunku: bieżącego, pomocniczego, VAT i walutowego.
3. Konta bankowe **kontrahentów** (*Bank Account* z *Party Type* = Supplier/Customer i IBAN)
   pozwalają `erpnext_poland` rozpoznać kontrahenta po numerze rachunku przy rozliczaniu
   wyciągu.
4. *Sposób płatności (Mode of Payment)*: przelew, gotówka, karta, z kontami domyślnymi dla firmy.
5. Prowizje bankowe: konto i MPK w *Polish Accounting Settings → Bank*.

Import wyciągów i ich rozliczanie opisuje [03_podrecznik_administratora.md](03_podrecznik_administratora.md)
(rozdział „Wyciągi bankowe”).

---

## 6. Waluty, faktury zagraniczne i różnice kursowe

**W ERPNext nie można na jednym koncie rozrachunkowym rozliczać faktur złotówkowych i walutowych.**
Konto kontrahenta ma walutę. Jeśli faktura jest w USD, a konto rozrachunkowe w PLN, system
przelicza ją na PLN i nie da się jej rozliczyć w walucie. Rozdzielenie trzeba zrobić w trzech
miejscach:

1. **Plan kont**: osobne konta rozrachunkowe dla walut, np. `201.001 - Rozrachunki z dostawcami
   krajowymi` (PLN) i `201.002 - Rozrachunki z dostawcami zagranicznymi`, a w razie potrzeby
   analityka per waluta (np. `210.01.2 … - USD`). Pole **Waluta** konta ustawiamy przed
   pierwszym zapisem. Później nie da się go zmienić.
2. **Kontrahent**: w kartotece dostawcy lub odbiorcy, w tabeli *Konta (Accounts)*, wskazujemy
   dla firmy konto rozrachunkowe w jego walucie. Dostawca walutowy powinien mieć
   *Domyślną walutę* ustawioną na swoją walutę.
3. **KSeF**: w *Polish Accounting Settings* pola **USD Liability Account** (`credit_to_usd`) i
   **Default Expense Account**. Faktury zakupu z KSeF w USD dostają to konto zobowiązań.
   Obecnie automat obsługuje tylko USD. Faktury w innych walutach trzeba przepiąć ręcznie,
   a rozszerzenie wymaga zmiany w `erpnext_poland` (`register_from_ksef`).

Różnice kursowe:

* Kursy: *Ustawienia wymiany walut (Currency Exchange Settings)*. Domyślne źródło
  (frankfurter) podaje kursy EBC. Do celów podatkowych obowiązuje **średni kurs NBP z dnia
  poprzedzającego**. Można ustawić dostawcę *Custom* z API NBP
  (`https://api.nbp.pl/api/exchangerates/rates/a/{from_currency}/{transaction_date}/?format=json`,
  klucz wyniku `rates` → `0` → `mid`). API NBP nie zwraca kursu dla dni wolnych, więc
  rozwiązanie trzeba przetestować. Bezpieczniejsze jest ręczne wprowadzanie kursu
  (*Currency Exchange*) albo jego korekta na dokumencie.
* Zrealizowane różnice (przy płatności) księgowane są automatycznie na *Exchange Gain / Loss
  Account* jako osobne *Polecenie księgowania* powiązane z płatnością. Polska praktyka
  rozdziela dodatnie i ujemne różnice, a ERPNext używa jednego konta. Stosujemy więc konto
  techniczne, a przy zamknięciu miesiąca przeksięgowujemy saldo na przychody/koszty finansowe
  (`750…`/`751…`).
* Niezrealizowane różnice na dzień bilansowy: *Exchange Rate Revaluation*.
* Problem z anulowaniem płatności walutowej, która wskazuje na nieistniejący zapis różnic
  kursowych, opisuje podręcznik administratora.

---

## 7. Księgowość polska (`erpnext_poland` → obszar roboczy **FK**)

* **Dzienniki** (*Dziennik definicja*): kod dziennika, dozwolone typy dokumentów źródłowych
  (Sales Invoice, Purchase Invoice, Payment Entry, Journal Entry…) i dozwolone typy poleceń
  księgowania. Przykład: SPR (sprzedaż), ZAK (zakup), BANK, KASA, PK (polecenia księgowania).
  Raport **Dziennik GL Entries** pokazuje zapisy w podziale na dzienniki.
* **Wydruki faktur**: `FV PL`, `FV PL z VAT`, `PL FV std`, `FV PL NIP`. Domyślny wydruk ustawiamy
  w *Dostosuj formularz (Customize Form)* → Sales Invoice → *Default Print Format*.
* **Faktury korygujące**: `erpnext_poland` poprawia fakturę korygującą (`fix_correction_invoice`)
  i zapisy storna (`fix_gl_for_storno`). Korekty wystawiamy przez *Zwrot / Korekta* na fakturze.
* **Szkice płatności z wyciągu**: przyciski na *Transakcji bankowej*, opis w podręczniku administratora.

---

## 8. KSeF (Krajowy System e-Faktur)

Pełny opis techniczny jest w katalogu `ksef/`: `ksef_ogolnie.md` (protokół KSeF 2.0)
i `README.md` (procedura). Tutaj zebrano kroki konfiguracyjne.

### 8.1. Certyfikat

* Do uwierzytelnienia w KSeF potrzebny jest certyfikat **kwalifikowany** od dostawcy z listy
  zaufanej UE (EUTL). Może to być pieczęć kwalifikowana z `organizationIdentifier =
  VATPL-<NIP>` albo, jak w fundacji, certyfikat podpisu do Węzła Krajowego (login.gov.pl).
  Certyfikat *self-signed* nadaje się wyłącznie do testów lokalnych, KSeF go odrzuci.
* Procedura fundacji: klucz prywatny i CSR generujemy **u siebie** (`ksef/01_pfx/01key_csr.sh`),
  na podstawie CSR kupujemy certyfikat, a potem składamy plik PFX (`ksef/01_pfx/02pfx.sh`).
  Mamy wtedy komplet plików bez kart i czytników. Tak uzyskany certyfikat nie służy do
  składania kwalifikowanych podpisów.
* Hasło do PFX trzymamy poza repozytorium (skrypty czytają je z `~/.hasla/…`).
* Weryfikacja: `openssl pkcs12 -in cert.pfx -nodes | openssl x509 -noout -subject`
  albo `ksef/02_py/weryfikuj.sh <plik.xades>`.

### 8.2. Pierwsze logowanie i uprawnienia w KSeF

1. W `ksef/02_py`: uzupełnij `config.ini` (ścieżka do PFX, hasło, NIP, adresy API), pobierz
   bibliotekę (`git_clone.sh`), zainstaluj pakiety (`pip install -r requirements.txt`)
   i sprawdź połączenie (`./test_rsv.sh`).
2. Na `https://ap.ksef.mf.gov.pl/web/` wpisz NIP i pobierz żądanie autoryzacyjne
   (np. `authv2_….xml`), podpisz je (`./sign.sh authv2_….xml`), a plik `.xades` wyślij na stronę KSeF.
3. Po zalogowaniu nadaj uprawnienia (np. dodaj siebie jako administratora).

### 8.3. Ustawienia w ERPNext – `/desk/polish-accounting-settings`, sekcja KSeF

| pole | wartość |
|---|---|
| Certificate (PFX) | załącznik PFX (zapisywany w `sites/<witryna>/private/files`) |
| Certificate password | hasło PFX (szyfrowane kluczem `encryption_key` witryny) |
| API URL | `https://api.ksef.mf.gov.pl` |
| Test API URL | `https://api-test.ksef.mf.gov.pl` |
| NIP | NIP firmy |
| USD Liability Account | konto zobowiązań w USD (punkt 6) |
| Default Expense Account | domyślne konto kosztów dla pozycji faktur z KSeF |
| Purchase Invoice Item Source | `KSeF-PENDING` / `Previous supplier invoice` / `KSeF form items` |
| Item Code, Description | kod i opis pozycji technicznej (dla trybu KSeF-PENDING) |

Źródło pozycji faktury zakupu:

* **KSeF form items**: pozycje faktury przepisywane z XML KSeF.
* **Previous supplier invoice**: pozycje jak na poprzedniej fakturze dostawcy.
* **KSeF-PENDING**: faktura dostaje jedną pozycję techniczną (kod i opis z ustawień).
  Asortyment o tym kodzie **trzeba założyć ręcznie** (pozycja niemagazynowa), system go nie
  tworzy. Wyjątek: przy fakturach z 1–2 pozycjami używane są dane pierwszej pozycji (opis,
  ilość, cena), a kartoteka asortymentu jest zakładana automatycznie.

Dostawcy nieznani w systemie są zakładani automatycznie według NIP.

### 8.4. Zadania cykliczne

| zadanie | harmonogram | co robi |
|---|---|---|
| `erpnext_poland.ksef_utils.register_from_ksef` | codziennie | pobiera faktury zakupu z KSeF (okno 30 dni), tworzy szkice *Purchase Invoice* z dołączonym XML |
| `erpnext_poland.ksef_utils.check_sent_invoices_status` | co 30 min | sprawdza status wysłanych faktur sprzedaży i zapisuje numer KSeF |

Scheduler musi być włączony (`sh/admin/tryb.sh scheduler on`).

### 8.5. Test

1. `/desk/scheduled-job-type` → odszukaj `erpnext_poland.ksef_utils.register_from_ksef` → *Action → Execute*.
2. `/desk/scheduled-job-log` (oraz *Error Log*) → sprawdź, czy zadanie wykonało się poprawnie.
3. *Faktury zakupu*: powinny pojawić się szkice z numerem KSeF (`ksef_numer`) i załącznikiem XML.
4. Sprzedaż: zatwierdzona *Faktura sprzedaży* → przycisk wysyłki do KSeF → status w zakładce
   **JPK i KSeF** (`Pending` → `Sent` → `Accepted`/`Rejected`/`Error`), a po przyjęciu numer KSeF.
   Pierwsze testy wysyłki najlepiej robić na środowisku testowym KSeF.

---

## 9. JPK_V7M (`erpnext_poland` → obszar roboczy **JPK**)

1. *Urzędy skarbowe (JPK Tax Office)*: słownik kodów urzędów.
2. *Ustawienia JPK firmy (JPK Company Settings)*: firma, NIP, urząd skarbowy (kod uzupełnia
   się sam), e-mail i telefon kontaktowy.
3. *JPK V7M*: nowy dokument na rok i miesiąc (korekta: *Is it amendment?* plus przyczyny
   korekty), nadwyżka VAT z poprzedniego okresu. Plik jest generowany **wprost z faktur
   sprzedaży i zakupu** z danego miesiąca VAT, więc przed generowaniem warto skontrolować
   pola JPK na fakturach (punkt 4).

---

## 10. Moduły uczelniane

### 10.1. Education (fork Galicea)

* *Education Settings*: bieżący rok akademicki i semestr, sposób nazywania studentów.
* Słowniki: *Academic Year*, *Academic Term*, *Program*, *Course*, *Student Category*,
  *Fee Structure* (gdy opłaty idą przez ERPNext; tworzą należności na koncie odbiorców).
* Numery albumów nadaje `education.education.album_number`: jedna sekwencja, pięć cyfr.
* Portal (galwork-hub / galwork-edu) wymaga sekcji `portal` i `keycloak` w `site_config.json`
  ([01_instalacja.md](01_instalacja.md), krok 8).

### 10.2. Rekrutacja (`admissions_poland`)

1. Role: przydziel `Admissions Manager` (dział rekrutacji), `Admissions Committee Chair`
   i `Admissions Committee Member` (komisje).
2. Słowniki: *Admission Exam* (przedmioty i poziomy egzaminów), *Admission Document Type*,
   *Admission Consent Clause*.
3. *Admission Campaign*: uchwała senatu (podstawa prawna), tryb kwalifikacji, limity,
   wymagalność zweryfikowanych wyników.
4. *Admission Programme* w kampanii: limity, opłata, tury (*Admission Round*), wymagane
   dokumenty, formuły kwalifikacji i rankingu. Po otwarciu programu formuły są zamrożone.
5. *Admission Committee* z członkami.
6. *Admission Decision Template* dla każdego typu decyzji. Szablony domyślne zawierają
   znaczniki `[DO UZUPEŁNIENIA …]` dla działu prawnego. Zatwierdzony szablon jest zamrożony.
7. *Admission Decision Settings*: parametry doręczeń elektronicznych (art. 358a PSWiN).
   Klucz do podpisu UPO/UPD ustawiamy w `site_config.json`.

Szczegóły (formuły, algorytm kwalifikacji, immatrykulacja, decyzje) są w
`apps/admissions_poland/README.md`.

---

## 11. Użytkownicy i uprawnienia

* Księgowość: role *Accounts User* (wprowadzanie) i *Accounts Manager* (zatwierdzanie,
  zamykanie okresów, ustawienia). Import wyciągów może robić *Accounts User*, a zatwierdzanie
  szkiców płatności *Accounts Manager*. Ten podział wspiera mechanizm szkiców z `erpnext_poland`.
* *System Manager* przydzielamy tylko administratorom.
* Uczelnia: *Academics User*, *Instructor*, *Student* (portal), role rekrutacyjne.
* Profile ról (*Role Profile*) ułatwiają nadawanie zestawów uprawnień.

---

## 12. Lista kontrolna konfiguracji

- [ ] ustawienia systemu (język, strefa, formaty) i ustawienia kont
- [ ] firma: NIP, REGON, kod US, forma opodatkowania
- [ ] plan kont zaimportowany, znaczniki JPK uzupełnione, stare konta usunięte
- [ ] konta domyślne firmy i *Polish Accounting Settings* (VAT, Bank)
- [ ] szablony VAT sprzedaży i zakupu
- [ ] banki, konta bankowe firmy (z kontami księgowymi), sposoby płatności
- [ ] konta rozrachunkowe walutowe i konto różnic kursowych
- [ ] dzienniki, domyślny wydruk faktury
- [ ] KSeF: PFX, ustawienia, asortyment KSeF-PENDING, test `register_from_ksef`
- [ ] JPK: urzędy skarbowe, ustawienia JPK firmy
- [ ] salda otwarcia, Temporary Opening = 0,00
- [ ] użytkownicy i role
- [ ] (uczelnia) Education Settings, kampania rekrutacyjna, szablony decyzji
