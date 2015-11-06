# Docker image for oync server
# Setup and run synchronization between OSM API server and a Postgis DB
# (suitable for pointing a tiling server to)
FROM ubuntu:14.04
MAINTAINER Chris Natali

# Add scripts that'll do the setup work and then run 'em 
ADD install-ruby.sh /tmp/
RUN bash /tmp/install-ruby.sh

ADD install-osm2pgsql.sh /tmp/
RUN bash /tmp/install-osm2pgsql.sh

# Add script to run on container startup
# This will pickup:
# -  oync.style:  style mapping file (maps osm xml to postgis db)
# -  oync_cfg.rb:  oync config file (which api server, local db, style file to use)
# -  oync.crt file:  
# from oync.d dir and start the synchronization to the postgis DB
ADD run-oync.sh /tmp/
