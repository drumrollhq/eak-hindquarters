require! {
  'mongoskin'
  '../../config'
  'bluebird'
}

for key, value of mongoskin when typeof value is 'function'
  bluebird.promisify-all value
  bluebird.promisify-all value.prototype

store = mongoskin.db config.MONGO_URL, safe: true, auto_reconnect: true
store.setup = -> store.open-async!
module.exports = store;
