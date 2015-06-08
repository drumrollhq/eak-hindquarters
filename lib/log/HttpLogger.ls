require! {
  'request'
}

name-from-level = {
  10: \trace
  20: \debug
  30: \info
  40: \warn
  50: \error
  60: \fatal
}

module.exports = class HttpLogger
  (endpoint, method = \POST) ->
    @endpoint = endpoint
    @method = method

  write: (record) ->
    if typeof record is \string
      record = JSON.parse record

    record.level-name = name-from-level[record.level]

    request {
      uri: @endpoint
      method: @method
      json: record
    }
