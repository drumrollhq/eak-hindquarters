require! {
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
        user = new User!

      user.set {
        first-name: profile.given_name or profile.first_name
        last-name: profile.family_name or profile.last_name
        email: profile.email
        gender: profile.gender
        assume-adult: true
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

auth-facebook = (models, access-token, refresh-token, profile, done) -->
  console.log profile

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
    profile-fields: <[id,first_name,last_name,email,gender]>
  }, auth-user models, 'facebook'

  passport.use google
  passport.use facebook
  passport.serialize-user (user, done) -> done null, user.id
  passport.deserialize-user (id, done) -> done null, User.find id

  app = express.Router!

  app.get '/register' (req, res) ->
    res.promise-render 'users/register'

  app.get '/google', set-oauth-redirect, passport.authenticate 'google'
  google-callback = passport.authenticate 'google', failure-redirect: '/v1/auth/register'
  app.get '/google/callback', google-callback, follow-oauth-redirect

  app.get '/facebook', set-oauth-redirect, passport.authenticate 'facebook'
  facebook-callback = passport.authenticate 'facebook', failure-redirect: '/v1/auth/register'
  app.get '/facebook/callback', facebook-callback, follow-oauth-redirect
