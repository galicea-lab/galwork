# Skrypty pracy z repozytoriami

Pełny opis zasad jest w Podręczniku dewelopera ([galwork.net/devbook](https://galwork.net/devbook/)),
rozdział `czesc-2-zasady-wytwarzania/04-wersjonowanie-i-wydania.md`. Poniżej jest skrót.

Skrypty są podzielone według ról:

- `uniwersalne/` – podgląd historii, kontrole, przełączanie na tag/gałąź/hash,
- `programista/` – gałąź, commit, push i przygotowanie PR,
- `reviewer/` – zatwierdzanie PR i sprzątanie po PR,
- `owner/` – wydanie wersji tagiem `v*` (`01release_tag.sh`),
- `lib/common.sh` – wspólna obsługa `.env` i operacji na gałęziach,
- `varia/` – skrypty awaryjne spoza standardowego przepływu (patrz niżej).

Skrypty można uruchamiać z dowolnego katalogu. Bez argumentu czytają `.env` z bieżącego
katalogu, a z argumentem przyjmują ścieżkę do pliku `.env`. Wzór zmiennych: `.env-example`
(skopiuj do katalogu repozytorium jako `.env`; `DIR` jest liczone względem katalogu pliku `.env`).
Plików `.env` i `TOKENY` nie wolno commitować.

<!-- AI 2026-11-25: podsumowanie zasad według ról, gałąź a tag -->
## Gałąź a tag

| | **gałąź (branch)** | **tag** |
|---|---|---|
| czym jest | ruchomy wskaźnik: przesuwa się z każdym nowym commitem | stały wskaźnik na jeden commit; z adnotacją ma autora, datę i opis |
| do czego służy | **obszar pracy programisty** nad jednym zadaniem | **wydanie (release)**: wersja produkcyjna `vMAJOR.MINOR.PATCH` |
| kto tworzy | programista (`<typ>/<inicjały>/TG-<ref>-<opis>`, np. `feat/jw/TG-27-login`) | wyłącznie **owner** (tagi `v*`) |
| czas życia | krótki: od zadania do scalenia PR, potem usuwana | stały: tagu wydania nie przesuwa się ani nie usuwa |
| zmiany | commity, `rebase` na bazę, `push`, w razie potrzeby `push --force-with-lease` na **własnej** gałęzi | żadnych; poprawka = nowa wersja (`PATCH`) |
| skutek wypchnięcia | widoczna w Forgejo, można z niej otworzyć PR | uruchamia workflow wydania (rejestr paczek, publikacja na GitHubie i npm) |

Zasady operowania przez git:

* **Gałąź tworzymy od świeżego stanu serwera**, nie od lokalnego `main`:
  `git fetch origin && git switch -c "$BRANCH" --no-track origin/main`
  (dla hotfixa bazą jest `origin/release/x.y`).
* Na gałęzi `main` (i `release/x.y`) **nie commitujemy bezpośrednio**. Zmiany trafiają tam
  wyłącznie przez PR scalany w Forgejo metodą *Squash and merge*.
* Gałąź wypychamy z upstreamem (`git push -u origin "$BRANCH"`), a po scaleniu PR usuwamy ją
  lokalnie (`git branch -D`, bo po squashu Git nie rozpoznaje scalenia) i zdalnie.
* Tag wydania jest zawsze **z adnotacją** (`git tag -a v1.2.0 -m "Wersja 1.2.0"`), na aktualnym
  commicie `main` (albo `release/x.y` dla hotfixa), i wypychany pojedynczo
  (`git push origin v1.2.0`, nie `--tags`).
* Tagu ani gałęzi wydania **nie przepisujemy** (`tag -f`, `push --force`). Pomyłkę naprawia
  następna wersja.
* Tag lub cudzą gałąź tylko oglądamy w trybie *detached HEAD* (`uniwersalne/03switch_ref.sh`).
  Żeby coś zmienić, najpierw tworzymy własną gałąź (`git switch -c ...`).
* **Nigdy nie robimy `git push` z repozytorium roboczego na GitHub.** Kod trafia tam
  wyłącznie przez workflow wydania jako jeden commit na wersję, bez historii roboczej.
  Wyjątek: samo repozytorium `galwork` (informacje o projekcie, nie kod) jest publikowane
  bezpośrednio przez remote `github`.

## Role

### Programista – praca na gałęzi

1. Zadanie w Taiga i gałąź od `origin/main`: `programista/01new_branch.sh`
   (`BRANCH`, opcjonalnie `BASE` w `.env`).
2. Zmiany, kontrole (`uniwersalne/02check.sh`), commit (`programista/02commit.sh`, `COMMIT`).
3. Publikacja gałęzi: `programista/03push.sh` albo od razu `programista/04pr.sh`
   (commit + rebase na `BASE` + push). Skrypty odmawiają pracy na `main`/`master`
   i blokują commit `.env`/`TOKENY`.
4. PR w Forgejo z linku zwróconego przez push: baza `main` (hotfix: `release/x.y`).
5. Poprawki po review – kolejne commity na tej samej gałęzi i `git push`.

### Recenzent – akceptacja PR

1. Pobranie i podgląd zmian: `REF=<gałąź>` w `.env`, `uniwersalne/03switch_ref.sh`
   (detached HEAD), `uniwersalne/02check.sh`, przegląd `git diff origin/main...HEAD`.
2. Uwagi w PR albo akceptacja i **Squash and merge** w Forgejo (jeden commit na zadanie,
   z czytelnym komunikatem – z tych komunikatów powstaje `CHANGELOG.md`).
3. Sprzątanie: `reviewer/03cleanup_local.sh` (powrót na `TARGET`, usunięcie gałęzi lokalnej)
   i `reviewer/04cleanup_remote.sh` (gałąź zdalna, jeśli Forgejo jej nie usunęło).
4. `reviewer/01merge_local.sh` **nie służy** do scalania PR – tylko do gałęzi pomocniczych.

### Owner – wydanie (release) i publikacja na GitHubie

1. Wszystkie karty z etykietą wersji są *Zrobione*, CI na `main` przechodzi.
2. `CHANGELOG.md` i numer wersji w plikach projektu (`pyproject.toml`, `package.json`)
   aktualizuje się zwykłym PR (typ `chore`). Listę zmian od poprzedniej wersji daje
   `git log --oneline v1.1.0..main`.
3. Tag: `TAG=v1.2.0`, `TAG_DESCRIPT="Wersja 1.2.0"`, `TARGET=main` w `.env`, potem
   `owner/01release_tag.sh`. Skrypt sprawdza czyste drzewo, zgodność z `origin`, format `v*`
   i unikalność taga, a następnie tworzy tag z adnotacją i wysyła go do Forgejo.
4. Wysłanie taga `v*` uruchamia workflow w Forgejo (`.forgejo/workflows/…`), który:
   publikuje paczki w rejestrze Forgejo, a dla podprojektów otwartych eksportuje pliki
   z `.public-paths`, skanuje je pod kątem sekretów i wysyła na GitHub **jeden commit
   `Release vX.Y.Z` z tagiem** (pakiety npm także na npmjs.com).
5. Po wydaniu owner tworzy **Release** dla taga z treścią sekcji `CHANGELOG.md`: w Forgejo
   (zakładka *Releases*), a na GitHubie z opublikowanego tam taga.
6. **Hotfix:** gałąź `release/x.y` od taga produkcyjnego (`git switch -c release/1.2 --no-track v1.2.0`),
   PR hotfixa do `release/1.2`, tag `v1.2.1` z `TARGET=release/1.2`, a potem cherry-pick
   poprawki na `main` osobnym PR.

Wersje wstępne (`v1.2.0-rc.1`) trafiają tylko do rejestru Forgejo, nie na GitHub ani npm.

## Pozostałe skrypty

* `uniwersalne/01display.sh` – aktywna gałąź i graf wszystkich gałęzi oraz tagów.
* `uniwersalne/04dates_afer_clone.sh` – ustawia daty modyfikacji plików według ostatniego
  commita. Uruchamiać zaraz po `git clone`.
* `varia/` – skrypty awaryjne **poza zasadami** powyżej, tylko w uzasadnionych przypadkach:
  `merge_no_pr.sh` (scalenie do `main` z pominięciem PR), `removetag.sh` (usunięcie taga
  lokalnie - uwaga - wbrew zasadom), `storepass.sh` (pamięć podręczna
  poświadczeń Git na 8 h).

## Logowanie do serwera Git

Jeśli Git pyta o login i hasło (albo token), a chcesz tego uniknąć, masz dwa rozwiązania:

- zapamiętaj je w Gicie: `git config --global credential.helper cache` (w pamięci, czasowo –
  zob. `varia/storepass.sh`) albo `store` (zapisuje je **jawnym tekstem** w `~/.git-credentials`),
- przejdź na SSH (`git remote set-url origin git@code.galicea.org:labc/<repozytorium>.git`),
  o ile serwer ma Twój klucz.
