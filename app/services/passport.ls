require! {
  'passport'
  'passport-google-oauth'
  'passport-facebook'
}

var log
module.exports = passport

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

module.exports.setup = ({config, models}) ->
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
