require! {
  './subscriptions': Subscriptions
  'express'
}

module.exports = (models, store, config) ->
  app = express.Router!
  subs = Subscriptions models, store, config

  app.post '/' (req, res) ->
    res.promise subs.create req.user.id, req.body
