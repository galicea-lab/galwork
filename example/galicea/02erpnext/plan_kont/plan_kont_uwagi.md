# Uwagi do planu kont

Konflikt: ERPNext (anglosaski model) vs polska rachunkowość


## Konta „Zysk / strata” 

Konta typu "Zysk / strata" są powiązane z takimi polami w ustawieniach firmy. Na przykład pole disposal\_account. W polskiej rachunkowości księguje się odrębnie przychód a odrębnie koszt, natomiast zysk/strata dopiero sumarycznie przy rozliczeniu.   

Problem systemowy

ERPNext **nie rozumie pojęcia „wynik na transakcjach” **.  
Pola typu:

- `disposal_account`

- `gain_account`

- `loss_account`

oczekują **jednego konta**, na które księgowany jest *netto wynik* operacji.

To jest:

- sprzeczne z polską praktyką

- zgodne z IFRS / anglosaskim uproszczeniem

Jak to obejść *bez łamania logiki ERPNext*

Rekomendowane przez AI rozwiązanie: **tworzysz techniczne konto wynikowe**, np.:

`76-9 Wynik na sprzedaży środków trwałych (techniczne)`

- Typ: `Przychód`

- Raport: `Rachunek Zysków i Strat`

- Używane **tylko przez system**

W polskiej ewidencji:

- **przychód** ze sprzedaży ŚT → normalne konto przychodowe

- **koszt netto / wartość księgowa** → normalne konto kosztowe

- ERPNext *dodatkowo* wrzuci różnicę na konto techniczne

Przy zamknięciu okresu:

- saldo konta technicznego = **kontrola**

- nie jest podstawą księgowań zarządczych ani podatkowych

**To konto NIE jest „wynikiem finansowym”** – to bufor systemowy.


Czego nie robić

- Nie wskazuj tam kont typu „Zysk/Strata lat ubiegłych”

- Nie mieszaj tego z kontem 860


## VAT a stawka podatku na koncie

**Konto NIE wymaga stawki VAT.**

Jak działa ERPNext

- VAT **nie bierze się z konta**

- VAT bierze się z:

  - `Sales Taxes and Charges Template`

  - `Purchase Taxes and Charges Template`

- konto VAT to tylko **konto księgowe**, nie nośnik stawki



## „Wynagrodzenia do zapłaty” i „Zaliczki dla pracowników”

Polska praktyka

- klasycznie → jedno konto: **Rozliczenie wynagrodzeń**

ERPNext / HR

ERPNext:

- **rozdziela zobowiązania**

- chce osobno:

  - payable

  - advance

Co polecam (kompromis PL ↔ ERP)

Opcja A – jedno konto syntetyczne + analityka (NAJLEPSZA)

`23-0 Rozliczenie wynagrodzeń`

`├── 23-01 Wynagrodzenia do wypłaty`

`└── 23-02 Zaliczki pracownicze`

- Oba subkonta:

  - `Liability`

  - Balance Sheet

- ERPNext:

  - `Payroll Payable Account` → 23-01

  - `Employee Advance Account` → 23-02

**Syntetycznie masz „jedno konto”**, systemowo masz porządek.



## Rozliczenia międzyokresowe (czynne i bierne)

Tu ERPNext **niczego nie narzuca**, ale trzeba zachować konsekwencje.

AI poleca:

Czynne RMK (aktywa)

`64-0 Rozliczenia międzyokresowe czynne`

`├── 64-01 Ubezpieczenia`

`├── 64-02 Abonamenty`

`├── 64-03 Media`

`└── 64-09 Inne RMK czynne`

- `Asset`

- Balance Sheet

Bierne RMK (pasywa)

`64-5 Rozliczenia międzyokresowe bierne`

`├── 64-51 Usługi obce`

`├── 64-52 Media`

`└── 64-59 Inne RMK bierne`

- `Liability`

- Balance Sheet

ERPNext:

- nie rozlicza tego automatycznie

- robisz to **księgowaniem ręcznym lub Wpisem Do dziennika (Journal Entry)**

To jest **zgodne z UoR** i w pełni akceptowalne.

RMK, rezerwy, korekty – jak to robić

Przykład: RMK czynne (abonament roczny)

**PK / Journal Entry:**

| Konto | Wn | Ma |
| - | - | - |
| 64-01 RMK czynne | 12 000 |  |
| 40-xx Koszty |  | 12 000 |

Co miesiąc:

- odpis RMK → kolejny Journal Entry  
(albo jeden zbiorczy na koniec miesiąca)


RMK bierne

| Konto | Wn | Ma |
| - | - | - |
| 40-xx Koszty | 5 000 |  |
| 64-5x RMK bierne |  | 5 000 |


Koszty „4” + „7” (KWS)

Fakty:

- ERPNext:

  - promuje podział direct / indirect (bezpośrednie / pośrednie)

- Polska UoR:

  - dopuszcza:

    - tylko 4

    - 4 + 5

    - uproszczony KWS

Nasze rozwiązanie

- wszystkie koszty operacyjne w jednym miejscu

- osobno:

  - **Koszt własny sprzedaży** (7)

  - **Koszty rodzajowe** (4)

**To jest poprawne**  
**JPK RZiS da się z tego złożyć**  
ERPNext to „łyknie”, jeśli:

- wszystkie konta są `Expense`

- mają poprawne pozycje RZiS

