#!/bin/bash -l

# Assumes this script is being run from the same dir as the sync_load.rb ruby script
if [ -z ${OYNC_DIR+x} ]
then
  echo "OYNC_DIR must be set"
  exit 1
fi

mkdir -p $OYNC_DIR
which osm2pgsql > /dev/null || { echo "Failed to find osm2pgsql in path"; exit 1; }

# get sync timestamp
# if none available, our best guess is the last timestamp from the point table
# It appears that osm2pgsql won't append duplicate changes, so it's OK if a changeset
# is added multiple times
if [ ! -e $OYNC_DIR/oync_load.ts ]
then 
  psql -d osm_grid -At -c "select max(osm_timestamp) from planet_osm_point;" > $OYNC_DIR/oync_load.ts
  # if results from above don't look right (i.e. table missing or no max timestamp)
  # go back to jan 1 1970 (i.e. get all changesets)
  if ! grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.*' $OYNC_DIR/oync_load.ts
  then 
    echo "1970-01-01T00:00:00+00:00" > $OYNC_DIR/oync_load.ts
  fi
fi

last_sync_timestamp=`cat $OYNC_DIR/oync_load.ts`

# get latest changesets
echo "`date +%Y-%m-%dT%H:%M:%s` getting latest changesets..."
ruby oync_load.rb -g "$last_sync_timestamp" -c oync_cfg.rb 2>> $OYNC_DIR/oync_load.log > $OYNC_DIR/oync_load.ts.tmp

# check whether output looks OK
if ! test $(wc -l $OYNC_DIR/oync_load.ts.tmp| cut -f 1 -d ' ') = 1 || ! grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.*' $OYNC_DIR/oync_load.ts.tmp
then
  echo "Failed to retrieve changesets.  Check $OYNC_DIR/oync_load.log"
  exit 1
fi

cp $OYNC_DIR/oync_load.ts.tmp $OYNC_DIR/oync_load.ts

# perform the update
echo "`date +%Y-%m-%dT%H:%M:%s` updating postgis with changesets..."
ruby oync_load.rb -u -c oync_load_cfg.rb >> $OYNC_DIR/oync_load.log 2>&1
[[ $? = 0 ]] || { echo "Failed to sync postgis db.  Check $OYNC_DIR/oync_load.log"; exit 1; }
