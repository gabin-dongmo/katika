#!/bin/sh
set -e

DB_NAME="${DJANGO_DB_NAME:-katika}"
DB_USER="${DJANGO_DB_USER:-katika}"
DB_PASSWORD="${DJANGO_DB_PASSWORD:-katika}"
DB_HOST="${DJANGO_DB_HOST:-db}"
DB_PORT="${DJANGO_DB_PORT:-5432}"

export PGPASSWORD="$DB_PASSWORD"

# Set a timeout for DB wait to avoid hanging forever
WAIT_TIMEOUT=30
COUNTER=0
if [ "${DJANGO_WAIT_FOR_DB:-1}" = "1" ]; then
  echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."
  while ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; do
    sleep 1
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -ge $WAIT_TIMEOUT ]; then
      echo "Error: Database not ready after $WAIT_TIMEOUT seconds. Attempting to proceed anyway..."
      break
    fi
  done
fi

# Ensure PostGIS extension exists
echo "Ensuring PostGIS extension exists..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -c "CREATE EXTENSION IF NOT EXISTS postgis;" || echo "Warning: Could not create postgis extension. It might already exist or you lack permissions."

# Configure french_unaccent
echo "Configuring french_unaccent..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -f /app/config_french_unaccent.sql || echo "Warning: Could not configure french_unaccent."

if [ "${DJANGO_RUN_MIGRATIONS:-1}" = "1" ]; then
  echo "Running migrations..."
  python manage.py migrate --noinput
fi

if [ "${DJANGO_AUTO_POPULATE:-1}" = "1" ]; then
  echo "Populating database..."
  python populate_db.py || echo "Warning: Database population failed."
fi

exec "$@"
