# Docker image for oync server
# Setup and run synchronization between OSM API server and a Postgis DB
# (suitable for pointing a tiling server to)

FROM ubuntu:14.04
MAINTAINER Chris Natali

RUN apt-get -y update

# Add oync source
RUN mkdir /oync
ADD . /oync
WORKDIR /oync

# run scripts for setup
RUN bash install-oync.sh
RUN bash install-osm2pgsql.sh

# run oync on startup
CMD ["./run-oync.sh"]
