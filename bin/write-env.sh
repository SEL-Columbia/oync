#!/bin/bash

# standardize oync env variables
# and write to env file for subsequent processes to read (i.e. ruby script) 
cat - > .env <<EOF
export OYNC_OSM_API_URL="$OYNC_OSM_API_URL"
export OYNC_DB_HOST="$DB_PORT_5432_TCP_ADDR"
export OYNC_DB_USER=postgres
export OYNC_DB="$DB_ENV_POSTGRES_DB"
export OYNC_LOAD_DIR=/oync/load
export OYNC_STYLE_FILE=/oync/oync.style
export OYNC_INTERVAL="${OYNC_INTERVAL:-10}"
EOF
