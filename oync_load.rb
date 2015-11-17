# Class to implement one-way sync of a PostGIS DB from an OSM API 
# Wraps retrieval of changesets from the OSM changeset API and 
# PostGIS population via osm2pgsql

require 'nokogiri' 
require 'date'
require 'fileutils'
require 'logger'
require_relative 'changeset'

class OyncLoad

    logger = Logger.new(STDOUT)

    CHANGESET_DIR = "changesets"
    CHANGESET_ID_FILE = "changeset_ids.xml"

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
    def update_changset_ids()
    # get all changesets since last update
    # return the max DateTime value from all new changesets
    def get_changesets(last_sync_timestamp)

        # get the changeset ids created since last time
        changeset_id_url = @api_url + "/api/0.6/changesets?time=" + 
            last_sync_timestamp.to_s 
        system("curl #{changeset_id_url} > #{@changeset_id_file}")

        # parse them out and add all changeset files to CHANGESET_DIR
        doc = Nokogiri::XML(open(@changeset_id_file))
        ids = []
        closed_times = []    
        doc.xpath('//changeset').each do |ch| 
            ids << ch['id'] 
            if ch['closed_at']
                closed_times << DateTime::parse(ch['closed_at'])
            else # assumes changeset is still open, so use open time
                closed_times << DateTime::parse(ch['created_at'])
            end
        end

        # now get the changeset files themselves
        # make sure changeset dir has been created
        FileUtils.mkdir_p(@changeset_dir)
        ids.each do |id|
            changeset_url = @api_url + "/api/0.6/changeset/#{id}/download"
            id_file = File.join(@changeset_dir, id.to_s) + ".osc"
            system("curl #{changeset_url} > #{id_file}")
        end

        closed_times.max() || last_sync_timestamp
    end

    # update DB with changeset files
    def update_postgis_with_changesets

        # run osm2pgsql for each changeset file
        Dir[File.join(@changeset_dir, "*.osc")].each do |id_file|
            logger.info("appending #{id_file}")
            osm2pgsql_cmd = "osm2pgsql --host #{@postgis_host}"\
                            " --username #{@postgis_user}"\
                            " --database #{@postgis_db}"\
                            " --style #{@osm_pgsql_style_file}"\
                            " --slim #{id_file}"\
                            " --cache-strategy sparse"\
                            " --hstore-all --extra-attributes --append"
            logger.info("running #{osm2pgsql_cmd}")
            system(osm2pgsql_cmd, :err=>STDOUT, :out=>STDOUT)
            if $?.success?
                bak_file = id_file.sub("osc", "bak")
                FileUtils.mv id_file, id_file.sub("osc", "bak")
                logger.info("moved #{id_file} to #{bak_file}")
            end
        end
    end
end
