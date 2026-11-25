#!/bin/sh
# 2026-11-25: konsola psql bazy huba (hasło z pliku poza repozytorium).
DB_HOST="${DB_HOST:-<host-bazy>}"
DB_PORT="${DB_PORT:-25060}"
DB_NAME="${DB_NAME:-galicea}"
DB_USER="${DB_USER:-galicea_user}"
PGPASSWORD=$(cat ~/.hasla/galicea_db_user.txt) psql "postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=require"
