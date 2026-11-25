#!/bin/bash
# Zakończenie wszystkich sesji użytkowników i wyczyszczenie kolejek zadań w tle
# (np. przed pracami serwisowymi albo po zawieszeniu się workerów).
source "$(dirname "$0")/_wspolne.sh"
bench --site "${SITE}" destroy-all-sessions
bench purge-jobs --site "${SITE}"
