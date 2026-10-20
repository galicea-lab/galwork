# Galwork

Ideą projektu Galwork jest stworzenie serwisu łączącego różne systemy przedsiębiorstwa lub uczelni.
Centralnym elementem projektu jest hub integrujący: `galwork-hub`.

Korzystają z niego aplikacje frontendu, łączące się poprzez API.
Dla każdej aplikacji powstaje odrębny podprojekt:

- `galwork-dashboard` - może być podstawą zbudowania intranetu w przedsiębiorstwie lub jego elementem
- `galwork-pm` - zarządzanie projektami
- ....

Bieżący katalog zawiera jedynie ogólne informacje o projekcie. Poszczególne aplikacje są w podprojektach.

## galwork-hub
Zawiera on **konektory** do różnych systemów (erp, workflow, systemy rządowe, serwisy zewnętrzne, etc...).
Konektory są wykorzystywane w **aplikacjach**, które są sterowane poprzez API, 
albo zadania uruchamiane w systemie (`cron` - zobacz katalog `scripts`).

