require! {
  'express'
  './auth'
  './sessions'
  './users'
}

module.exports = (models, store, config) ->
  router = express.Router!
  v1 = express.Router!

  router.use '/v1', v1
  v1.use '/auth', auth models, store, config
  v1.use '/sessions', sessions models, store, config
  v1.use '/users', users models, store, config

  router
