require! {
  '../../errors'
  'express'
  'passport'
  'prelude-ls': {min}
}

module.exports = (models, store, config) ->
  app = express.Router!

  User = models.User

  app.get '/usernames' (req, res) ->
    n = min 100, (req.query.n or 10)
    fn = if req.query.unused then User.unused-username else User.username
    res.promise [fn! for i from 1 to n]

  app.get '/me' (req, res) ->
    if req.user?
      resp = req.user
        .fetch with-related: <[oauths]>, require: true
        .then (user) -> {logged-in: true, user: user.to-safe-json!, device: req.session.device-id}
        .catch User.NotFoundError, -> errors.unauthorized 'Your user does not exist'
      res.promise resp
    else
      res.json {logged-in: false, device: req.session.device-id}

  app.get '/me/customer' (req, res) ->
    resp = req.user.fetch require: true
      .then (user) ->
        user.find-or-create-stripe-customer!

    res.promise resp

  app.get '/:username/exists' (req, res) ->
    username = req.params.username
    if username.match /^[0-9]*$/ then id = parse-int username
    res.promise User.exists (id or username)
