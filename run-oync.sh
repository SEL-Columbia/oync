#!/bin/bash
# start postgis, setup db (if not already done) and kick off oync via cron

# create empty tables via osm2pgsql
service postgresql start
while ! psql -d osm -c '\d' > /dev/null;
do
  echo "waiting for postgres..."
  sleep 1
done

osm2pgsql --database osm -a --style /oync.d/oync.style --slim /oync.d/empty.osm --hstore-all --extra-attributes
crontab /oync.d/oync.crt
cron
