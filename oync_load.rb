# Class to implement one-way sync of a PostGIS DB from an OSM API 
# Wraps retrieval of changesets from the OSM changeset API and 
# PostGIS population via osm2pgsql

require 'nokogiri' 
require 'date'
require 'fileutils'
require 'logger'

$logger = Logger.new(STDOUT)

class OyncLoad

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
            $logger.info("appending #{id_file}")
            osm2pgsql_cmd = "osm2pgsql --host #{@postgis_host}"\
                            " --username #{@postgis_user}"\
                            " --database #{@postgis_db}"\
                            " --style #{@osm_pgsql_style_file}"\
                            " --slim #{id_file}"\
                            " --cache-strategy sparse"\
                            " --hstore-all --extra-attributes --append"
            $logger.info("running #{osm2pgsql_cmd}")
            system(osm2pgsql_cmd, :err=>STDOUT, :out=>STDOUT)
            if $?.success?
                bak_file = id_file.sub("osc", "bak")
                FileUtils.mv id_file, id_file.sub("osc", "bak")
                $logger.info("moved #{id_file} to #{bak_file}")
            end
        end
    end
end

# When run from command line
if __FILE__ == $0

    require 'optparse'
    require 'dotenv'

    options = {}
    options[:env_file] = ".env"

    optparse = OptionParser.new do |opts|
        opts.on('-g', '--get-changesets TIMESTAMP', 'get changesets since last sync') do |timestamp|
            options[:get_changesets] = DateTime::parse(timestamp)
        end

        opts.on('-u', '--update-postgis', 'update postgis with changesets') do 
            options[:update_postgis] = true
        end

        opts.on('-e', '--env-file ENVFILE', 'alternate env file for config (default is .env)') do 
            options[:env_file] = envfile 
        end

        opts.on('-h', '--help', 'Display help') do
            puts opts
            exit
        end
    end

    begin
        optparse.parse!
        commands = [:get_changesets, :update_postgis]               
        selected_commands = commands.select{ |param| options[param] }
        if selected_commands.size < 1
            $logger.fatal("Need to select at least one command of: #{commands.join(', ')}")
            $logger.fatal(optparse)
            exit 1
        end

        # load config from .env
        Dotenv.load(options[:env_file])

        # check if nec vars are defined
        required_vars = ['OYNC_OSM_API_URL',
                         'OYNC_LOAD_DIR',
                         'OYNC_DB',
                         'OYNC_DB_HOST',
                         'OYNC_DB_USER',
                         'OYNC_STYLE_FILE']

        not_found_vars = required_vars - ENV.keys
        if not_found_vars.size > 1
            $logger.fatal("All variables need to be defined: #{required_vars.join(', ')}")
            exit 1
        end

        # make sure sync dir exists
        FileUtils.mkdir_p(ENV['OYNC_LOAD_DIR'])
        # Prevent multiple simultaneous runs
        lock_file = File.join(ENV['OYNC_LOAD_DIR'], "oync_load.lock") 
        if File.exists?(lock_file)
            $logger.warn("oync_load.lock exists...assuming already running, exiting")
            exit 1
        else
            File.open(lock_file, "w") {}
        end

        oync_load = OyncLoad.new(ENV['OYNC_OSM_API_URL'], 
                                 ENV['OYNC_LOAD_DIR'], 
                                 ENV['OYNC_DB'], 
                                 ENV['OYNC_DB_HOST'],
                                 ENV['OYNC_DB_USER'],
                                 ENV['OYNC_STYLE_FILE'])

        if options[:get_changesets]
            last_cs_ts = oync_load.get_changesets(options[:get_changesets])
            # write timestamp to stdout
            puts last_cs_ts.to_s
        end

        if options[:update_postgis]
            oync_load.update_postgis_with_changesets
        end

        File.delete(lock_file)

    rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
        $logger.fatal($!.to_s)  # Friendly output when parsing fails
        $logger.fatal(optparse)
        exit 1
    end 
end
