#!/bin/bash
# Synchronizacja forka aplikacji z repozytorium źródłowym (np. galicea education <- frappe/education).
# Użycie: ./fork_synchronizuj.sh <aplikacja> <gałąź_upstream> [gałąź_lokalna]
#   np. ./fork_synchronizuj.sh education version-16-hotfix develop
# Wymaga remote "upstream" (git -C apps/education remote add upstream https://github.com/frappe/education.git).
# Po scaleniu: testy na kopii, push do origin, potem migracja.sh i przebuduj.sh education na produkcji.
source "$(dirname "$0")/_wspolne.sh"
APP="${ARGS[0]:?aplikacja}"; UP="${ARGS[1]:?gałąź upstream}"; LOCAL="${ARGS[2]:-develop}"
cd "apps/${APP}"
[ -z "$(git status --porcelain)" ] || { echo "Są niezacommitowane zmiany - zrób commit lub git stash -u"; exit 1; }
# repo pobrane przez bench bywa płytkie (shallow_clone) - bez pełnej historii merge się nie uda
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then git fetch upstream --unshallow; else git fetch upstream; fi
BR="chore/upstream-$(echo "$UP" | tr '/' '-')-$(date +%Y%m%d)"
git switch -c "$BR" "$LOCAL"
git merge --no-ff "upstream/${UP}" || { echo "Konflikty - rozwiąż, git commit, potem: git switch $LOCAL && git merge --ff-only $BR"; exit 1; }
git switch "$LOCAL" && git merge --ff-only "$BR"
git log --oneline -5
