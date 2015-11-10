#!/bin/bash
# start postgis, setup db (if not already done) and kick off oync via cron

# Map docker-compose defined env variables to internal env variables
# and write to env file for subsequent processes to read (i.e. cron jobs) 
cat - /oync/oync.env <<EOF
export OYNC_OSM_API_URL="$OYNC_ENV_OSM_API_URL"
export OYNC_DB_HOST="$DB_PORT_5432_TCP_ADDR"
export OYNC_DB_USER=postgres
export OYNC_DB="$DB_ENV_POSTGRES_DB"
export OYNC_LOAD_DIR=/oync/load
EOF

# source it
. /oync/oync.env

# create empty tables via osm2pgsql
while ! psql -d "$OYNC_DB" -h "$OYNC_DB_HOST" -U "$OYNC_DB_USER" -c '\d' > /dev/null;
do
  echo "waiting for postgres..."
  sleep 1
done

osm2pgsql --host "$OYNC_DB_HOST" --database "$OYNC_DB" --username "$OYNC_DB_USER" --append --style /oync/oync.style --slim /oync/empty.osm --hstore-all --extra-attributes
crontab /oync/oync.crt
cron
