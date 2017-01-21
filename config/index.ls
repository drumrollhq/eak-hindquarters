# Start with the defaults...
config = require './defaults'
config.NODE_ENV = process.env.NODE_ENV or config.NODE_ENV

# Overwrite defaults with environment-specific defaults
try
  config <<< require "./#{process.env.NODE_ENV or 'dev'}"
catch e
  console.log 'Couldn\'t load config for node_env:' e

# Overwrite with private credentials:
try
  config <<< require './credentials'
  console.log config.{NODE_ENV}
  config <<< require "./credentials-#{config.NODE_ENV}"
catch e
  # meh

# Overwrite with config from the host env
config <<< process.env

module.exports = config
