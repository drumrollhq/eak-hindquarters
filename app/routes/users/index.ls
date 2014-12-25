require! {
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

  app.get '/:username/exists' (req, res) ->
    username = req.params.username
    if username.match /^[0-9]*$/ then id = parse-int username
    res.promise User.exists (id or username)

