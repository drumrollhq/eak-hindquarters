require! {
  'express'
}

module.exports = (models, store, config) ->
  app = express.Router!
  app.get '/' (req, res) -> res.send 'hello, world!'
  app
