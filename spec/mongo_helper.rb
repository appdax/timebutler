
# Start mongo deamon before running the specs
system 'mongod --quiet &>/dev/null &'
# Shutdown mongo deamon after running the specs
at_exit { system 'mongod --shutdown &>/dev/null &' }
