# OYNC (Osm sYNC)

System for synchronizing an Openstreetmap server with a PostGIS database in real time.  
A simple alternative to setting up the "minutely" file based synchronization infrastructure.
Complements lightweight OSM data gathering deployments by providing PostGIS access to the data (for simpler analysis, visualization, etc)

    --------------          -------------
    | OSM Server |   -------| Postgis   |
    | (Fork)     |-->| OYNC |           |
    --------------   --------------------

## Setup

Checkout repo and run:

```
docker-compose -f docker-compose.yml up 
```

## Customization

Customization is done via environment variables.  These can be set in docker-compose.yml:

- OYNC_STYLE_FILE:  

Defines how the osm data is mapped to the PostGIS tables.  
Details [here](http://wiki.openstreetmap.org/wiki/Osm2pgsql#Import_style)

- OYNC_OSM_API_URL environment variable:

This variable defines which OSM instance to synchronize with.
