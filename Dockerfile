# Docker image for oync server
# Setup and run synchronization between OSM API server and a Postgis DB
# (suitable for pointing a tiling server to)

FROM ubuntu:14.04
MAINTAINER Chris Natali

RUN apt-get -y update

# Add oync source required for setup
RUN mkdir /oync
ADD install-oync.sh /oync/
ADD install-osm2pgsql.sh /oync/
ADD "Gemfile" "Gemfile.lock" /oync/

# run scripts for setup
RUN bash /oync/install-oync.sh
RUN bash /oync/install-osm2pgsql.sh

# add rest of source
ADD oync_load.rb /oync/
ADD oync.sh /oync/
ADD run-oync.sh /oync/
ADD empty.osm /oync/
ADD oync.style /oync/

WORKDIR /oync

# run oync on startup
CMD ["./run-oync.sh"]
