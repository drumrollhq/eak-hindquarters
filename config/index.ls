# Start with the defaults...
config = require './defaults'

# Overwrite defaults with environment-specific defaults
try
  config <<< require "./#{process.env.NODE_ENV or 'dev'}"
catch e
  console.log 'Couldn\'t load config for node_env:' e

# Overwrite with private credentials:
try
  config <<< require './credentials'
catch e
  # meh

# Overwrite with config from the host env
config <<< process.env

module.exports = config
