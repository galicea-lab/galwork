#!/bin/sh
# 2026-11-25: założenie bazy i użytkownika huba dla instancji (PostgreSQL >= 13, np. DigitalOcean).
# Hasła czytane z plików poza repozytorium. Skrypt wypisuje polecenia SQL i otwiera psql administratora.
DB_HOST="${DB_HOST:-<host-bazy>}"
DB_PORT="${DB_PORT:-25060}"
DB_ADMIN="${DB_ADMIN:-doadmin}"
DB_ADMIN_PASSWORD=$(cat ~/.hasla/doadmin.txt)
DB_NAME="${DB_NAME:-galicea}"
DB_USER="${DB_USER:-galicea_user}"

echo "Wykonaj w psql (hasło użytkownika - z menedżera haseł):"
echo "  CREATE USER $DB_USER WITH PASSWORD '...';"
echo "  CREATE DATABASE $DB_NAME OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
echo "  \\c $DB_NAME"
echo "  ALTER SCHEMA public OWNER TO $DB_USER;   -- PG 15+"
PGPASSWORD=$DB_ADMIN_PASSWORD psql "postgresql://$DB_ADMIN@$DB_HOST:$DB_PORT/defaultdb?sslmode=require"
