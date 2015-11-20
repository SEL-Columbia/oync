#!/bin/bash

# * assumes these are already installed via Dockerfile
# everything else needed for postgres/osm2pgsql
# note: postgresql only for psql
# apt-get -y install git make cmake g++ libboost-dev libboost-system-dev \
#   libboost-filesystem-dev libboost-thread-dev libexpat1-dev zlib1g-dev \
#   libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev lua5.2 \
#   liblua5.2-dev postgresql
 
# build osm2pgsql to get the latest since apt pkg version doesn't apply data diffs
git clone https://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql
mkdir build && cd build
cmake ..
make
make install
cd ..
