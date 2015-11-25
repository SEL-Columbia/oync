#!/bin/bash -l

# Source the config/env vars from the dotenv in working dir
if [ ! -f .env ]; then
  echo ".env not found in working dir"
  exit 1
fi

. .env

# Assumes this script is being run from the same dir as the sync_load.rb ruby script
for var in OYNC_OSM_API_URL OYNC_DB_HOST OYNC_DB_USER OYNC_DB OYNC_LOAD_DIR; do
    if ! [ -n "${!var:-}" ]; then
        echo "$var is unset"
        exit 1
    fi
done

mkdir -p $OYNC_LOAD_DIR
which osm2pgsql > /dev/null || { echo "Failed to find osm2pgsql in path"; exit 1; }

echo "`date +%Y-%m-%dT%H:%M:%s` syncing changeset ids..."
ruby bin/oync_run.rb -u >> $OYNC_LOAD_DIR/oync_load.log
[[ $? = 0 ]] || { echo "Failed to sync changeset ids.  Check $OYNC_LOAD_DIR/oync_load.log"; exit 1; }

echo "`date +%Y-%m-%dT%H:%M:%s` retrieving NEW changesets..."
ruby bin/oync_run.rb -r >> $OYNC_LOAD_DIR/oync_load.log
[[ $? = 0 ]] || { echo "Failed to retrieve changesets.  Check $OYNC_LOAD_DIR/oync_load.log"; exit 1; }

echo "`date +%Y-%m-%dT%H:%M:%s` processing RETRIEVED changesets..."
ruby bin/oync_run.rb -p >> $OYNC_LOAD_DIR/oync_load.log
[[ $? = 0 ]] || { echo "Failed to process changesets.  Check $OYNC_LOAD_DIR/oync_load.log"; exit 1; }
