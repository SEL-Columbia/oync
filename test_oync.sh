#!/bin/bash -l

# Source the config/env vars from the dotenv
SRC_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $SRC_DIR/.env

# Assumes this script is being run from the same dir as the sync_load.rb ruby script
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

# start mock server
node test/test-server.js

oync_cleanup

./test/test_process_3_retreive_rest.sh || exit 1
