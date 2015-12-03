#!/bin/bash
# setup environment for oync
# assumes running from /oync dir

# write/source env vars
./bin/write-env.sh
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

# if changeset table doesn't exist, create it
if psql -d  "$OYNC_DB" -h "$OYNC_DB_HOST" -U "$OYNC_DB_USER" -c '\d' | grep changesets > /dev/null;
then
  echo "changesets table exists"
else
  echo "setting up changesets table..."
  psql -d "$OYNC_DB" -h "$OYNC_DB_HOST" -U "$OYNC_DB_USER" -f oync_schema.sql 
fi
