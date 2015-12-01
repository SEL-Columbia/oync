#!/bin/bash
# setup environment and kickoff oync
# assumes running from /oync dir

# do setup
./bin/setup-oync.sh
. .env

# run tests
./test/test-oync.sh
