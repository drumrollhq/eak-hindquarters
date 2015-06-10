require! {
  '../../../services/passport'
  'bluebird': Promise
}

export endpoint = false

export authenticate = (provider) ->
  passport-handler = passport.authenticate provider
  {
    page: true
    handler: ({http: {req, res, next}, session, options}) -> new Promise (resolve, reject) ->
      if options.redirect?
        session.oauth-redirect = options.redirect

      err <- passport-handler req, res
      if err then return reject err
      resolve!
  }

export callback = (provider) ->
  passport-handler = passport.authenticate provider, failure-redirect: '/v1/auth/register'
  {
    page: true
    handler: ({http: {req, res, next}, session}) -> new Promise (resolve, reject) ->
      err <- passport-handler req, res
      if err then return reject err

      if session.oauth-redirect
        res.redirect session.oauth-redirect
        delete session.oauth-redirect
      else
        res.redirect '/v1/auth/register'

      resolve!
  }
