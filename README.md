# Galwork

wersja: 0.1.0

Ideą projektu Galwork jest stworzenie serwisu łączącego różne systemy przedsiębiorstwa lub uczelni.
Centralnym elementem projektu jest hub integrujący: `galwork-hub`.

Korzystają z niego aplikacje frontendu, łączące się poprzez API.
Bieżący katalog zawiera jedynie ogólne informacje o projekcie. 
Szczegółowe informacje znajdziesz są w podprojektach.

Dla każdej aplikacji powstaje odrębny podprojekt:

- `galwork-dashboard` - może być podstawą zbudowania intranetu w przedsiębiorstwie lub jego elementem
- `galwork-edu` - intranet dla szkół i uczelni
- `galwork-pm` - zarządzanie projektami
- ....


Ponadto realizujemy projekty wspomgające:
- `galwork-arena` - konfiguracja obiegów
- `galwork-react` - komponenty react używane do konstruowania aplikacji

Publikacje oraz informacje dodatkowe: [https://galwork.net](https://galwork.net)

## galwork-hub

Zawiera on **konektory** do różnych systemów (erp, workflow, systemy rządowe, serwisy zewnętrzne, etc...).
Konektory są wykorzystywane w **aplikacjach**, które są sterowane poprzez API, 
albo zadania uruchamiane w systemie (`cron` - zobacz katalog `scripts`).


## Wdrożenie i budowanie (ten katalog)

Podprojekty są klonowane obok siebie w jednym katalogu roboczym (`../galwork-*`).
Definicje obejmujące całość są tutaj:

- `docker-compose.yml` - usługi `hub`, `arena`, `bpmn-files` (uruchamiaj z tego katalogu;
  `docker-compose.yml-with_dashboard` - wariant budujący obrazy lokalnie, z dashboardem),
- `.env.example` - szablon `.env` (`.env` i `secrets/npmrc` są poza repozytorium),
- `deploy/nginx/galwork_arena.conf` - vhost nginx hosta (arena + `/bpmn-files/` z hasłem),
- `scripts/build_hub.sh [tag]`, `scripts/build_arena.sh [tag]` - budowa i push obrazów,
- `scripts/publish_react.sh` - publikacja pakietu `nextjs-keycloak-auth`.

`.dockerignore` musi zostać w katalogu roboczym (`../.dockerignore`) - to kontekst builda
obrazów areny i dashboardu.
