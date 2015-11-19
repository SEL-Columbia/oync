# Class to implement one-way sync of a PostGIS DB from an OSM API 
# Wraps retrieval of changesets from the OSM changeset API and 
# PostGIS population via osm2pgsql

require 'nokogiri' 
require 'date'
require 'fileutils'
require 'logger'
require 'net/http'
require_relative 'changeset'

class OyncLoad

    logger = Logger.new(STDOUT)

    CHANGESET_DIR = "changesets"
    CHANGESET_ID_FILE = "changeset_ids.xml"
    NO_CHANGESETS = -1
    MIN_CHANGESET_ID = 0
    MIN_CHANGESET_TIMESTAMP = DateTime::parse("1970-01-01T00:00:00")
    STATUS_NEW        = "NEW"
    STATUS_RETRIEVED  = "RETRIEVED"
    STATUS_PROCESSED  = "PROCESSED"
    STATUS_NOT_CLOSED = "NOT_CLOSED"
    STATUS_NOT_FOUND  = "NOT_FOUND"
    STATUS_FAILED     = "FAILED"

    def initialize(api_url, oync_dir, postgis_db, postgis_host, postgis_user, osm_pgsql_style_file)
        @api_url = api_url
        @oync_dir = oync_dir
        @postgis_db = postgis_db
        @postgis_host = postgis_host
        @postgis_user = postgis_user
        @osm_pgsql_style_file = osm_pgsql_style_file
        @changeset_dir = File.join(@oync_dir, CHANGESET_DIR)
        @changeset_id_file = File.join(@oync_dir, CHANGESET_ID_FILE)
    end

    # update the status of all changeset ids
    def update_local_changeset_ids()
        
        # get the last cs id we've synced and compare with last cs id 
        # from server, filling in the middle
        last_cs_id = Changeset.maximum(:id)
        last_cs_ts = Changeset.maxmimum(:timestamp)

        # if changesets are not populated, its possible that a planet
        # file has been loaded, in which case we take the last cs id
        # from the planet_osm_point table 
        if not last_cs_id 
            sql = "select max(tags->'osm_changeset') as max_cs, max(tags->'osm_timestamp') as max_ts from planet_osm_point"
            records = ActiveRecord::Base.connection.execute(sql)
            if records.count == 1
                last_cs_id = records[0]['max_cs'].to_i
                last_cs_ts = DateTime::parse(records[0]['max_ts'])
                # populate all missing changesets
                (0..last_cs_id).each do |cs_id|
                    Changeset.create(id: cs_id, closed_at: last_cs_ts, status: STATUS_PROCESSED)
                end
            else # we've got nothing yet
                last_cs_id = MIN_CHANGESET_ID
                last_cs_ts = MIN_CHANGESET_TIMESTAMP
            end
        end
        
        remote_last_cs_id = get_remote_max(last_cs_ts)

        # add all changesets that we haven't seen as "NEW" to our table
        # ASSUMPTION:  changeset ids are sequential
        if last_cs_id < remote_last_cs_id
            (last_cs_id..remote_last_cs_id).each do |cs_id|
                Changeset.create(id: cs_id, status: STATUS_NEW)
        elsif remote_last_cs_id == NO_CHANGESETS
            logger.warn("No changesets in osm db at host #{@api_url}")
        elsif last_cs_id > remote_last_cs_id
            logger.error("Local changeset ids ( #{last_cs_id} ) have moved past remote changeset id ( #{remote_last_cs_id} ) from host #{@api_url}")
        elseif last_cs_id == remote_last_cs_id
            logger.info("No new changesets")
        end
    end

    # get the max changeset id/timestamp from remote system
    def get_remote_max(last_cs_timestamp)

        changeset_uri = URI(@api_url + "/api/0.6/changesets?time=" + 
            last_cs_timestamp.to_s)
        
        response = Net::HTTP.get_response(changeset_uri)
        if response.is_a?(Net::HTTPSuccess)
            # parse them out and add all changeset files to CHANGESET_DIR
            doc = Nokogiri::XML(response.body)
            ids = []
            closed_times = []    
            doc.xpath('//changeset').each do |ch| 
                ids << ch['id'].to_i
            end
            ids.max
        else 
            NO_CHANGESETS
        end
    end

    # retrieve all "new" changesets
    def retrieve_changesets 
        # now get the changeset files themselves
        # make sure changeset dir has been created
        FileUtils.mkdir_p(@changeset_dir)
        Changeset.where("status = \'#{STATUS_NEW}\'").each do |cs|
            changeset_uri = @api_url + "/api/0.6/changeset/#{cs.id}/download"
            response = Net::HTTP.get_response(changeset_uri)
            if response.is_a?(Net::HTTPSuccess)
                osc_file = File.join(@changeset_dir, cs.id.to_s) + ".osc"
                File.open(osc_file, 'w') { |file| file.write(response.body) }
                cs.file_location = osc_file
                cs.status = STATUS_RETRIEVED
            else
                logger.error("failed to retrieve changeset (id #{cs.id}) from #{changeset_uri}")
                cs.status = STATUS_NOT_FOUND # other cases to handle?
            end
            cs.save
        end
    end

    # process all changesets we've retrieved
    def process_changesets
        Changeset.where("status = \'#{STATUS_RETRIEVED}\'").each do |cs|
            
            logger.info("processing #{cs.file_location}")
            osm2pgsql_cmd = "osm2pgsql --host #{@postgis_host}"\
                            " --username #{@postgis_user}"\
                            " --database #{@postgis_db}"\
                            " --style #{@osm_pgsql_style_file}"\
                            " --slim #{cs.file_location}"\
                            " --cache-strategy sparse"\
                            " --hstore-all --extra-attributes --append"
            logger.info("running #{osm2pgsql_cmd}")
            system(osm2pgsql_cmd, :err=>STDOUT, :out=>STDOUT)
            if $?.success?
                bak_file = cs.file_location.sub("osc", "bak")
                FileUtils.mv cs.file_location, bak_file
                logger.info("moved #{cs.file_location} to #{bak_file}")
                cs.file_location = bak_file
                cs.status = STATUS_PROCESSED
            else 
                logger.error("failed #{id_file} to #{bak_file}")
                cs.status = STATUS_FAILED
            end
            cs.save
        end
    end
end
