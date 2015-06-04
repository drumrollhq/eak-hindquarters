require! {
  '../../version-info.js'
  'express'
  'moment'
  'os'
}

module.exports = (models, store, config) ->
  router = express.Router!
  v1 = express.Router!

  router.use '/v1', v1
  <[action auth count sessions users cards games subscriptions]> .for-each (name) ->
    v1.use "/#name" (require "./#name")(models, store, config)

  start = Date.now!
  packaged = new Date version-info.packaged * 1000
  router.get '/v1', (req, res) ->
    d = moment.duration Date.now! - start
    res.json {
      tag: version-info.tag
      hash: version-info.hash
      packaged: packaged
      uptime: "#{d.days!}:#{d.hours!}:#{d.minutes!}:#{d.seconds!}"
      host: os.hostname!
    }

  router
