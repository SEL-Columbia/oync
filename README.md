# OYNC (Osm sYNC)

[![Build Status](https://travis-ci.org/SEL-Columbia/oync.svg?branch=master)](https://travis-ci.org/SEL-Columbia/oync)

System for synchronizing an Openstreetmap server with a PostGIS database in real time.  
A simple alternative to setting up the "minutely" file based synchronization infrastructure.
Complements lightweight OSM data gathering deployments by providing PostGIS access to the data (for simpler analysis, visualization, etc)

    --------------          -------------
    | OSM Server |   -------| Postgis   |
    | (Fork)     |-->| OYNC |           |
    --------------   --------------------

## Setup

Checkout repo, cd into it and run:

```
docker build -t selcolumbia/oync .
docker-compose run test
```

To start up a dev instance pointing to your local source dir run
```
docker-compose run dev bash
```

## Customization

Customization is done via environment variables.  These can be set in docker-compose.yml:

- OYNC_STYLE_FILE:  

Defines how the osm data is mapped to the PostGIS tables.  
Details [here](http://wiki.openstreetmap.org/wiki/Osm2pgsql#Import_style)

- OYNC_OSM_API_URL environment variable:

This variable defines which OSM instance to synchronize with.

## Troubleshooting

Oync is a lightweight sync tool and therefore is designed to fail fast when there are issues synchronizing with the OSM server.
This prevents it from overloading the main OSM server.

The first place to look for issues is in the changesets table. A query such as the following will list all changesets that haven't been processed
(running via the docker db container named oynctilemill_db_1...YMMV):  

```
docker exec -ti oynctilemill_db_1 psql -U postgres -d osm -c "select * from changesets where status != 'PROCESSED';"
```

Any changesets not processed can be reattempted via resetting their status to 'NEW' via:  

```
docker exec -ti oynctilemill_db_1 psql -U postgres -d osm -c "update changesets set status='NEW' where status = 'NOT_CLOSED';"
```

You can also check the ```polling.log``` and ```load/oync_load.log``` log files within your main oync docker container for more detailed error messages.
