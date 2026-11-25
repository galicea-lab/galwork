# Wymagania systemowe

Moduł signing korzysta z programu xmlsec1 - musi on być dostępny w systemie! Certyfikat musi być kwalifikowany.
Biblioteka xmlsec może wymagać instalacji dodatkowych pakietów systemowych.
W systemach Debian/Ubuntu: 
```
sudo apt-get install build-essential libxml2-dev libxslt1-dev xmlsec1-dev
```

W systemach RedHat/Fedora: 
```
sudo dnf install gcc libxml2-devel libxslt-devel xmlsec1-devel xmlsec1-openssl-devel
```

Na macOS (z Homebrew): 
```
brew install libxml2 libxslt xmlsec1


# Przygotowanie podpisu

Fundacja dysponuje certyfikatami do łączenia się z Węzłem Krajowym  (WK, login.gov.pl).

Do połączenia z KSef można wykorzystać certyfikat do podpisu z WK (sign).

Ważne: 
Taki certyfikat zakupiono przesyłając do wystawcy (CA) plik CSR.
Czyli generujemy u siebie klucz prywatny oraz CSR i na tej podstawie kupujemy certyfikaty.
Dzięki temu mamy pełny zestaw potrzebnych plików, bez konieczności używania dodatkowych urządzeń i wpisywania haseł.

Oczywiście tak uzyskany certyfikat - choć jest kwalifikowany - nie umożliwia składania kwalifikowanych podpisów.

Klucz i CSR można stworzyć skryptem `01_pfx/01key_csr.sh`

Po uzyskaniu certyfikatu - tworzymy plik pfx (`galicea_sign.pfx`) skryptem `01_pfx/02pfx.sh`

# Logowanie do KSeF

W katalogu 03_py:

1) po stworzeniu pfx (zob. wyżej) ustawiamy config.ini 

2) kopiujemy bibliotekę skryptem git_clone.sh 

3) Instalujemy potrzebne paczki pythona:
 `pip install -r requirements.txt`

4) Sprawdź programem ./test_rsv.sh

5) Zaloguj certyfikaterm. Na stronie https://ap.ksef.mf.gov.pl/web/ - wpisz NIP i przejdź dalej (potwierdx, że ma NIP).
Pobież żadanie autoryzacyjne na przykład  authv2_20261125092339.xml 

6) Wykonaj ./sign.sh authv2_20261125092339.xml  i otrzymany plik xades (na przykład authv2_20261125092339.xml.xades) wyślij na tronę ksef.
W razie problemów - zweryfikuj podpisany plik
`./weryfikuj.sh authv2_20261125092339.xml.xades'

Przy okazji zobaczysz, czy w pieczeci jest wymagany numer VAT. W tym wypadku `VATPL-<NIP fundacji>`


7) Po zalogowaniu może dodać siebie jako administratora


# Konfiguracja ErpNext

## Warunki wstępne

W systemie musi być zainstalowana aplikacja erpnext_poland.

Galicea korzysta z serwera ErpNext firmy Transmem (galicea.transmem.pl). 

Konfiguracja fundacji jest w katalogu:
 erpnext-bench/sites/galicea.transmem.pl/private/files

## Ustawienia

W ustawieniach aplikacji erpnext_poland, na stronie: 
`https://galicea.transmem.pl/desk/polish-accounting-settings`

Ustawiamy Certyfikat (PFX) - zostanie on przesłany do pliku w katalogu:
 erpnext-bench/sites/galicea.transmem.pl/private/files

Ponadto ustawiamy:
- hasło do pliku pfx
- adres API: https://api.ksef.mf.gov.pl
- NIP
- testowy adres API: https://api-test.ksef.mf.gov.pl
- Źródło pozycji faktury zakupu: `Pozycje formularza KSEF`
- kod i opis asortymentu - jeśli nie chcemy by faktury zawierały szczegóły (wybraliśmy powyżej Ksef-PENDING)
- konta

## Test

Na stronie /desk/scheduled-job-type/ odszukujemy `erpnext_poland.ksef_utils.register_from_ksef` i wybieramy Action -> Execute
W dzienniku `/desk/scheduled-job-log` sprawdzamy, czy wykonało się to poprawnie

W fakturach zakupu sprawdź, czy wczytane zostały faktury

