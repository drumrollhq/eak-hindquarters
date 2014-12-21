require! {
  'bunyan'
  '../../config'
}

streams = []

if config.LOG_STDOUT
  streams[*] = level: config.LOG_STDOUT, stream: process.stdout

if config.LOG_FILE
  streams[*] = level: \info, path: config.LOG_FILE

if config.LOG_ERR
  streams[*] = level: \error, path: config.LOG_ERR

log = bunyan.create-logger name: 'default', streams: streams
log.create = (name) -> bunyan.create-logger name: name, streams: streams
log.info 'Logger setup'

module.exports = log
