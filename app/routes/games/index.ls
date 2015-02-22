require! {
  './games': Games
  'express'
}

module.exports = (models, store, config) ->
  app = express.Router!
  games = Games models, store, config

  {User} = models

  app.get '/mine', (req, res) ->
    res.promise games.for-user req.user.id

  app.post '/', (req, res) ->
    res.promise games.create req.user.id, req.body

  app.get '/:id' (req, res) ->
    res.promise games.get req.user.id, req.params.id, {
      areas: req.query.areas or false
    }

  app.delete '/:id' (req, res) ->
    res.promise games.delete req.user.id, req.params.id

  app.put '/:id' (req, res) ->
    res.promise games.patch req.user.id, req.params.id, req.body

  app.post '/:id/stages' (req, res) ->
    res.promise games.find-or-create-stage req.user.id, req.params.id, req.body
