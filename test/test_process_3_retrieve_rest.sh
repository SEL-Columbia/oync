#!/bin/bash
# assumes the following ENV vars
printf "%s\n" "${OYNC_OSM_API_URL:?Need to set OYNC_OSM_API_URL}"
printf "%s\n" "${OYNC_LOAD_DIR:?Need to set OYNC_LOAD_DIR}"
printf "%s\n" "${OYNC_TEST_DATA_DIR:?Need to set OYNC_TEST_DATA_DIR}"
printf "%s\n" "${OYNC_DB:?Need to set OYNC_DB}"
printf "%s\n" "${OYNC_DB_HOST:?Need to set OYNC_DB_HOST}"
printf "%s\n" "${OYNC_DB_USER:?Need to set OYNC_DB_USER}"

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 1; }

# create LOAD_DIR dir if not already
mkdir -p $OYNC_LOAD_DIR/changesets

# ensure no load data
[[ "$(ls -A "$OYNC_LOAD_DIR/changesets" 2> /dev/null)" ]] && die "$OYNC_LOAD_DIR/changesets not empty"

# ensure nothing in DB
count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets;" | sed 's/^[^0-9]*//')
[[ $count -eq "0" ]] || die "changeset table not empty"

count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from planet_osm_point;" | sed 's/^[^0-9]*//')
[[ $count -eq "0" ]] || die "planet_osm_point table not empty"

# ensure test api is up
curl $OYNC_OSM_API_URL/api/0.6/changesets > /dev/null 2>&1 || die "$OYNC_OSM_API_URL is not available for tests"

# process changesets 1..3
for i in {1..3};
do 
    cp $OYNC_TEST_DATA_DIR/$i.osc $OYNC_LOAD_DIR/changesets/$i.osc
    psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -c "insert into changesets (id, file_location, status) values ($i, '$OYNC_LOAD_DIR/changesets/$i.osc', 'RETRIEVED');"
done

echo "processing 1st 3"
./bin/oync_run.rb -p || die  "Failed to process changesets.  Check $OYNC_LOAD_DIR/oync_load.log"

count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets;" | sed 's/^[^0-9]*//')
[[ $count -eq "3" ]] || die "Failed to process 3 changesets"

echo "syncing the ids for the rest"
./bin/oync_run.rb -u || die "Failed to sync changeset ids.  Check $OYNC_LOAD_DIR/oync_load.log"

count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets;" | sed 's/^[^0-9]*//')
[[ $count -eq "10" ]] || die "Failed to sync changeset ids"

echo "retrieving the rest"
./bin/oync_run.rb -r || die "Failed to process changesets.  Check $OYNC_LOAD_DIR/oync_load.log"
count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets where status='RETRIEVED';" | sed 's/^[^0-9]*//')
[[ $count -eq "7" ]] || die "Failed to retrieved changesets"


echo "processing the rest"
./bin/oync_run.rb -p || die "Failed to process changesets.  Check $OYNC_LOAD_DIR/oync_load.log"
count=$(psql -d $OYNC_DB -h $OYNC_DB_HOST -U $OYNC_DB_USER -tc "select count(*) from changesets where status='PROCESSED';" | sed 's/^[^0-9]*//')
[[ $count -eq "10" ]] || die "Failed to process changesets"

echo "Processed changesets successfully"
