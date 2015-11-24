#!/bin/bash

# source env vars
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

# kill all bg jobs on exit
trap 'kill -9 $(jobs -p)' EXIT

oync_cleanup
node test/test-server.js &
./test/test_process_3_retrieve_rest.sh || exit 1