require! {
  'bunyan'
  '../../config'
  './HttpLogger'
}

streams = []

if config.LOG_STDOUT
  streams[*] = level: config.LOG_STDOUT, stream: process.stdout

if config.LOG_FILE
  streams[*] = level: \info, path: config.LOG_FILE

if config.LOG_ERR
  streams[*] = level: \error, path: config.LOG_ERR

if config.LOG_SLACK_ENDPOINT
  streams[*] = level: config.LOG_SLACK_LEVEL, stream: new HttpLogger config.LOG_SLACK_ENDPOINT

log = bunyan.create-logger name: 'default', streams: streams
log.create = (name) -> bunyan.create-logger name: name, streams: streams
log.info 'Logger setup'

module.exports = log
