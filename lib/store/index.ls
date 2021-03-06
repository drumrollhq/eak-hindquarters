require! {
  '../../config'
  '../log'
  'bluebird'
  'mongoskin'
}

log = log.create 'store'

for key, value of mongoskin when typeof value is 'function'
  bluebird.promisify-all value
  bluebird.promisify-all value.prototype

store = mongoskin.db config.MONGO_URL, safe: true, auto_reconnect: true
store.setup = ->
  log.info 'Opening mongo connection'
  store.open-async!
    .tap -> log.info 'Mongo connection opened'
module.exports = store;
