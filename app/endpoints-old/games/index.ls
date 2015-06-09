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
      stages: req.query.stages or false
      levels: req.query.levels or false
    }

  app.delete '/:id' (req, res) ->
    res.promise games.delete req.user.id, req.params.id

  app.put '/:id' (req, res) ->
    res.promise games.patch req.user.id, req.params.id, req.body

  app.post '/:id/stages' (req, res) ->
    res.promise games.find-or-create-stage req.user.id, req.params.id, req.body

  app.post '/:gameId/levels/:levelId/kittens' (req, res) ->
    res.promise games.save-kitten req.user.id, req.params.game-id, req.params.level-id, req.body.kitten

  app.put '/:id/state' (req, res) ->
    res.promise games.patch-state req.user.id, req.params.id, req.body

  app.put '/:gameId/stages/:stageId/state' (req, res) ->
    res.promise games.patch-stage-state req.user.id, req.params.game-id, req.params.stage-id, req.body

  app.put '/:gameId/levels/:levelId/state' (req, res) ->
    res.promise games.patch-level-state req.user.id, req.params.game-id, req.params.level-id, req.body
