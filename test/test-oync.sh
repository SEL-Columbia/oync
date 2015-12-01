#!/bin/bash

# Source the config/env vars from the dotenv in working dir
if [ ! -f .env ]; then
  echo ".env not found in working dir"
  exit 1
fi

. .env

# Assumes this script is being run from the same dir as the oync_load.rb ruby script
for var in OYNC_OSM_API_URL OYNC_DB_HOST OYNC_DB_USER OYNC_DB OYNC_LOAD_DIR; do
    if ! [ -n "${!var:-}" ]; then
        echo "$var is unset"
        exit 1
    fi
done

function oync_cleanup {
    # cleanup working data
    rm -rf $OYNC_LOAD_DIR/*
    # clear out DB
    psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -f clear.sql
}

oync_cleanup
./test/test_process_3_retrieve_rest.sh || exit 1
