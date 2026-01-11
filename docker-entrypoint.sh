#!/bin/sh
set -e

DB_NAME="${DJANGO_DB_NAME:-katika}"
DB_USER="${DJANGO_DB_USER:-katika}"
DB_PASSWORD="${DJANGO_DB_PASSWORD:-katika}"
DB_HOST="${DJANGO_DB_HOST:-db}"
DB_PORT="${DJANGO_DB_PORT:-5432}"

export PGPASSWORD="$DB_PASSWORD"

if [ "${DJANGO_WAIT_FOR_DB:-1}" = "1" ]; then
  echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."
  while ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; do
    sleep 1
  done
fi

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -c "CREATE EXTENSION IF NOT EXISTS postgis;"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -f /app/config_french_unaccent.sql

if [ "${DJANGO_RUN_MIGRATIONS:-1}" = "1" ]; then
  python manage.py migrate --noinput
fi

if [ "${DJANGO_AUTO_POPULATE:-1}" = "1" ]; then
  python populate_db.py
fi

exec "$@"
