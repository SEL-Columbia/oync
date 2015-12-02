#!/bin/bash
# setup environment and kickoff oync
# assumes running from /oync dir

# do setup
./bin/setup-oync.sh
. .env

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 1; }

# wait for test-server to start
NUM_TRIES = 10
cur_time = 0
while ! curl $OYNC_OSM_API_URL/api/0.6/changesets > /dev/null 2>&1 
do 
  [ $cur_time -gt $WAIT_TIME ] && die "$OYNC_OSM_API_URL never came up after $NUM_TRIES tries"
  sleep 1
done

# run tests
./test/test-oync.sh
