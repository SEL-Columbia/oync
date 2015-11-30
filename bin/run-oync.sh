#!/bin/bash
# setup environment and kickoff oync
# assumes running from /oync dir

# do setup
./bin/setup-oync.sh
. .env

while true
do
    ./bin/oync.sh >> polling.log 2>&1
    sleep $OYNC_INTERVAL
done
