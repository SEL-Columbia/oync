#!/usr/bin/env ruby

require 'optparse'
require 'dotenv'
require_relative '../lib/oync/initialize'
require_relative '../lib/oync/oync_load'

logger = Logger.new(STDOUT)

# When run from command line
if __FILE__ == $0

    options = {}

    optparse = OptionParser.new do |opts|
        opts.on('-u', '--update-changeset-ids', 'sync up changeset ids from remote') do
            options[:update_changeset_ids] = true
        end

        opts.on('-r', '--retrieve-changesets', 'get all "NEW" changeset files from remote') do
            options[:retrieve_changesets] = true
        end

        opts.on('-p', '--process-changesets', 'process all "RETRIEVED" changesets into postgis db') do
            options[:process_changesets] = true
        end

        opts.on('-h', '--help', 'Display help') do
            puts opts
            exit
        end
    end

    begin
        optparse.parse!
        commands = [:update_changeset_ids, :retrieve_changesets, :process_changesets]               
        selected_commands = commands.select{ |param| options[param] }
        if selected_commands.size < 1
            logger.fatal("Need to select at least one command of: #{commands.join(', ')}")
            logger.fatal(optparse)
            exit 1
        end

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
        
        oync_load = Oync::Load.new(ENV['OYNC_OSM_API_URL'], 
                                   ENV['OYNC_LOAD_DIR'], 
                                   ENV['OYNC_DB'], 
                                   ENV['OYNC_DB_HOST'],
                                   ENV['OYNC_DB_USER'],
                                   ENV['OYNC_STYLE_FILE'],
                                   (ENV['OYNC_READ_TIMEOUT'] || 
                                   Oync::Load::DEFAULT_HTTP_READ_TIMEOUT).to_i
                                  )

        if options[:update_changeset_ids]
            oync_load.update_changeset_ids
        end

        if options[:retrieve_changesets]
            oync_load.retrieve_changesets
        end

        if options[:process_changesets]
            oync_load.process_changesets
        end

        File.delete(lock_file)

    rescue => e
        if File.exists?(lock_file)
            File.delete(lock_file)
        end    
 
        logger.fatal($!.to_s)  # Friendly output when parsing fails
        raise e
    end 
end
