#!/bin/bash
# assumes the following ENV vars
printf "%s\n" "${OYNC_OSM_API_URL:?Need to set OYNC_OSM_API_URL}"
printf "%s\n" "${OYNC_LOAD_DIR:?Need to set OYNC_LOAD_DIR}"
printf "%s\n" "${OYNC_TEST_DATA_DIR:?Need to set OYNC_TEST_DATA_DIR}"
printf "%s\n" "${OYNC_DB:?Need to set OYNC_DB}"
printf "%s\n" "${OYNC_DB_HOST:?Need to set OYNC_DB_HOST}"
printf "%s\n" "${OYNC_DB_USER:?Need to set OYNC_DB_USER}"

# ensure no load data
[[ "$(ls -A "$OYNC_LOAD_DIR" 2> /dev/null)" ]] && echo "$OYNC_LOAD_DIR not empty"; exit 1

# ensure nothing in DB
count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets;" | sed 's/^[^0-9]*//')
[[ $count -eq "0" ]] || echo "changeset table not empty"; exit 1

count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from planet_osm_point;" | sed 's/^[^0-9]*//')
[[ $count -eq "0" ]] || echo "planet_osm_point table not empty"; exit 1

# process changesets 1..3
for i in {1..3};
do 
    cp $OYNC_TEST_DATA_DIR/$i.osc $OYNC_LOAD_DIR/$i.osc
done

oync_run.rb -p 
[[ $? = 0 ]] || { echo "Failed to process changesets.  Check $OYNC_LOAD_DIR/oync_load.log"; exit 1; }

count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets;" | sed 's/^[^0-9]*//')
[[ $count -eq "3" ]] || echo "Failed to process 3 changesets"; exit 1

# now try to retrieve/process the rest
oync_run.rb -u
[[ $? = 0 ]] || { echo "Failed to sync changeset ids.  Check $OYNC_LOAD_DIR/oync_load.log"; exit 1; }

count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets;" | sed 's/^[^0-9]*//')
[[ $count -eq "10" ]] || echo "Failed to retrieve changesets"; exit 1

# now try to retrieve/process the rest
oync_run.rb -p
[[ $? = 0 ]] || { echo "Failed to process changesets.  Check $OYNC_LOAD_DIR/oync_load.log"; exit 1; }

count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets where status='PROCESSED';" | sed 's/^[^0-9]*//')
[[ $count -eq "10" ]] || echo "Failed to process changesets"; exit 1

echo "Processed changesets successfully"
