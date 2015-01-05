require! {
  './actions': Actions
  'express'
}

module.exports = (models, store, config) ->
  app = express.Router!

  actions = Actions models, store, config

  {AuthedAction} = models

  get-action = (type) -> (req, res, next) ->
    AuthedAction.use req.params.key
      .then (action) ->
        if action.action isnt type
          res.promise errors.bad-request 'action-type and url do not match!'
        else
          req.action = action
          next!
      .catch next

  app.get '/verify-email/:key', (get-action 'verify-email'), (req, res, next) ->
    actions.verify-email req.action.user
      .then -> res.promise-render 'actions/verify-email'
      .catch next

