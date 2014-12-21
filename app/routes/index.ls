require! {
  'express'
  './sessions'
}

module.exports = (models, store, config) ->
  router = express.Router!
  v1 = express.Router!

  router.use '/v1', v1
  v1.use '/sessions', sessions models, store, config

  router
