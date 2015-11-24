#!/bin/bash
# setup environment and kickoff oync
# assumes running from /oync dir

# write/source env vars
./write-env.sh
. .env

# create empty tables via osm2pgsql
while ! psql -d "$OYNC_DB" -h "$OYNC_DB_HOST" -U "$OYNC_DB_USER" -c '\d' > /dev/null;
do
  echo "waiting for postgres..."
  sleep 1
done

# if planet_osm_point exists, append (we don't want to overwrite) otherwise create new
if psql -d  "$OYNC_DB" -h "$OYNC_DB_HOST" -U "$OYNC_DB_USER" -c '\d' | grep planet_osm_point > /dev/null;
then
  echo "osm db already instantiated"
else
  echo "setting up osm db..."
  psql -d "$OYNC_DB" -h "$OYNC_DB_HOST" -U "$OYNC_DB_USER" -c "CREATE EXTENSION hstore;" 
  osm2pgsql --host "$OYNC_DB_HOST" --database "$OYNC_DB" --username "$OYNC_DB_USER" --create --style /oync/oync.style --slim /oync/empty.osm --hstore-all --extra-attributes
fi

while true
do
    ./oync.sh >> polling.log 2>&1
    sleep $OYNC_INTERVAL
done
