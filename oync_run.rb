require 'environment'
require 'optparse'
require 'oync_load'

logger = Logger.new(STDOUT)

# When run from command line
if __FILE__ == $0

    options = {}

    optparse = OptionParser.new do |opts|
        opts.on('-g', '--get-changesets TIMESTAMP', 'get changesets since last sync') do |timestamp|
            options[:get_changesets] = DateTime::parse(timestamp)
        end

        opts.on('-u', '--update-postgis', 'update postgis with changesets') do 
            options[:update_postgis] = true
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
            logger.fatal("Need to select at least one command of: #{commands.join(', ')}")
            logger.fatal(optparse)
            exit 1
        end

        # By including environment above, we have set ENV vars that we need
        # make sure sync dir exists
        FileUtils.mkdir_p(ENV['OYNC_LOAD_DIR'])
        # Prevent multiple simultaneous runs
        lock_file = File.join(ENV['OYNC_LOAD_DIR'], "oync_load.lock") 
        if File.exists?(lock_file)
            logger.warn("oync_load.lock exists...assuming already running, exiting")
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
        logger.fatal($!.to_s)  # Friendly output when parsing fails
        logger.fatal(optparse)
        exit 1
    end 
end
