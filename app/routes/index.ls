require! {
  'express'
  './action'
  './auth'
  './count'
  './sessions'
  './users'
}

module.exports = (models, store, config) ->
  router = express.Router!
  v1 = express.Router!

  router.use '/v1', v1
  <[action auth count sessions users games]> .for-each (name) ->
    v1.use "/#name" (require "./#name")(models, store, config)

  router
