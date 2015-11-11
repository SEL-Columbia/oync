# Docker image for oync server
# Setup and run synchronization between OSM API server and a Postgis DB
# (suitable for pointing a tiling server to)
FROM ubuntu:14.04
MAINTAINER Chris Natali

RUN apt-get -y update

# Add oync source
RUN mkdir /oync
ADD . /oync

# Add scripts that'll do the setup work and then run 'em 
ADD install-oync.sh /tmp/
RUN bash /tmp/install-oync.sh

ADD install-osm2pgsql.sh /tmp/
RUN bash /tmp/install-osm2pgsql.sh

# Add script to run on container startup
ADD run-oync.sh /tmp/

CMD ["./tmp/run-oync.sh"]
