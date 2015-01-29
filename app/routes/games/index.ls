require! {
  './games': Games
  'express'
}

module.exports = (models, store, config) ->
  app = express.Router!
  games = Games models, store, config

  {User} = models

  app.get '/mine', (req, res) -> res.promise games.for-user req.user.id
  app.post '/', (req, res) -> res.promise games.create req.user.id, req.body
  app.get '/:id' (req, res) -> res.promise games.get req.user.id, req.params.id
