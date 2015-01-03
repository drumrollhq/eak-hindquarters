require! {
  '../errors'
  'bluebird': Promise
  'checkit'
  'express'
  'passport'
  'passport-google-oauth'
  'passport-facebook'
}

auth-user = (models, provider, access-token, refresh-token, profile, done) -->
  {User, OAuth} = models

  profile = profile._json
  OAuth.find provider, profile.id
    .fetch with-related: ['user']
    .then (oauth) ->
      if oauth?
        user = oauth.related 'user'
      else
        oauth = new OAuth {provider: provider, provider-id: profile.id}
        user = new User status: 'creating'

      user.set {
        first-name: profile.given_name or profile.first_name
        last-name: profile.family_name or profile.last_name
        email: profile.email
        gender: profile.gender
        assume-adult: true
        verified-email: !!profile.email
      }

      user.save!
        .then ->
          if (oauth.get 'userId')?
            oauth.update-data profile
          else
            oauth.set user-id: user.id, provider-data: profile .save!
        .then -> user

    .then (user) -> done null, user
    .catch (err) -> done err

set-oauth-redirect = (req, res, next) ->
  if req.query.redirect?
    req.session.oauth-redirect = req.query.redirect

  next!

follow-oauth-redirect = (req, res) ->
  if req.session.oauth-redirect
    res.redirect req.session.oauth-redirect
    delete req.session.oauth-redirect
  else
    res.redirect '/v1/auth/register'

filtered-import = (obj) ->
  obj = {[key, value] for key, value of obj when value}
  obj

module.exports = (models, store, config) ->
  {User} = models

  google = new passport-google-oauth.OAuth2Strategy {
    client-ID: config.GOOGLE_CLIENT_ID
    client-secret: config.GOOGLE_CLIENT_SECRET
    callback-URL: "#{config.APP_ROOT}/v1/auth/google/callback"
    scope: ['https://www.googleapis.com/auth/plus.login' 'email']
  }, auth-user models, 'google'

  facebook = new passport-facebook.Strategy {
    client-ID: config.FACEBOOK_CLIENT_ID
    client-secret: config.FACEBOOK_CLIENT_SECRET
    callback-URL: "#{config.APP_ROOT}/v1/auth/facebook/callback"
    scope: ['public_profile' 'email']
    profile-fields: <[id first_name last_name email gender age_range]>
  }, auth-user models, 'facebook'

  passport.use google
  passport.use facebook
  passport.serialize-user (user, done) -> done null, user.id
  passport.deserialize-user (id, done) -> done null, User.find id

  app = express.Router!

  app.get '/register' (req, res) ->
    res.promise-render 'users/register'

  app.post '/register' (req, res, next) ->
    first-name = req.body.first-name
    assume-adult = req.body.over-thirteen
    unless first-name then err = 'You need to tell us your name!'
    unless assume-adult then err ?= 'You need to say whether or not you\'re over thirteen!'
    if err then return res.promise-render 'users/register', {err}

    user = new User {first-name, assume-adult, status: 'creating'}
      .save!
      .then (user) ->
        req.session.passport = user: user.id
        res.redirect '/v1/auth/register/manual'
      .catch (err) -> next err

  register-next = (password, manual) -> (req, res) ->
    user = req.user.fetch!
    res.promise-render 'users/register-next' {
      username: User.unused-username!
      usernames: Promise.all [til 3].map -> User.unused-username!
      saved-user: user
      user: user
      password: password
      manual: manual
    }

  app.get '/register/manual' register-next true true
  app.get '/register/oauth' register-next false false

  app.post '/register/complete' (req, res, next) ->
    data = filtered-import req.body.{username, password, password-confirm, email, gender, subscribed-newsletter}
    usernames = Promise.all [til 3].map -> User.unused-username!
    {has-password, has-manual} = req.body
    req.user
      .fetch!
      .then (saved-user) ->
        user = saved-user.clone!.set data
        username = User.unused-username!
        user.validate role: (if has-password then <[full password]> else 'full')
          .then ->
            user
              .set 'status' if user.get 'verifiedEmail' then 'active' else 'pending'
              .save!
              .then -> res.promise-render 'users/show', user: user
          .catch checkit.Error, (err) ->
            res.promise-render 'users/register-next' {username, usernames, saved-user, user, err, password: has-password, manual: has-manual}
      .catch next

  app.get '/google', set-oauth-redirect, passport.authenticate 'google'
  google-callback = passport.authenticate 'google', failure-redirect: '/v1/auth/register'
  app.get '/google/callback', google-callback, follow-oauth-redirect

  app.get '/facebook', set-oauth-redirect, passport.authenticate 'facebook'
  facebook-callback = passport.authenticate 'facebook', failure-redirect: '/v1/auth/register'
  app.get '/facebook/callback', facebook-callback, follow-oauth-redirect

  app.get '/js-return' (req, res) ->
    res.promise-render 'users/js-return', {
      user: req.user.fetch with-related: <[oauths]> .then (user) -> user.to-safe-json!
    }

  app.post '/login' (req, res) ->
    result = User.find req.body.username
      .fetch!
      .tap (user) ->
        if user is null
          errors.not-found "Oh no! We don't seem to have a #{req.body.username}. Have you tried asking next door?"
        else
          user.check-password req.body.password
      .then (user) ->
        req.session.passport = user: user.id
        {logged-in: true, user: user}

    res.promise result

  app.get '/logout' (req, res) ->
    req.logout!
    res.json success: true
