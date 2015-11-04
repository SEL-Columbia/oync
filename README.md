# OYNC (Osm sYNC)

Lightweight synchronization of Openstreetmap data.  

Alternative to setting up Minutely infrastructure.  

Useful for working with OSM data forks (with low update rate)

    --------------          -------------
    | OSM Server |   -------| Postgis   |
    | (Fork)     |-->| OYNC |           |
    --------------   --------------------

## Setup

Requires Ruby, postgresql, postgis extension and osm2pgsql.  

- Create postgis db
- Initialize postgis db for loading data into



