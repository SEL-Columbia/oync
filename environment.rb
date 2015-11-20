require 'dotenv'
require 'logger'
require 'active_record'

logger = Logger.new(STDOUT)

# load config from .env
Dotenv.load

# check if nec vars are defined
required_vars = ['OYNC_OSM_API_URL',
                 'OYNC_LOAD_DIR',
                 'OYNC_DB',
                 'OYNC_DB_HOST',
                 'OYNC_DB_USER',
                 'OYNC_STYLE_FILE']

not_found_vars = required_vars - ENV.keys
if not_found_vars.size > 1
    logger.fatal("All variables need to be defined: #{required_vars.join(', ')}")
    exit 1
end

# Establish AR Base conn
ActiveRecord::Base.establish_connection(adapter: "postgresql",
                                        host: ENV['OYNC_DB_HOST'],
                                        username: ENV['OYNC_DB_USER'],
                                        database: ENV['OYNC_DB'])
