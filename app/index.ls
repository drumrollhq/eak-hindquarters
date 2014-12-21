require! {
  '../config'
  './log'
  './models'
  './routes'
  './store'
  './express'
  'http'
}

models.setup!
  .then ->
    store.setup!
  .then ->
    app = express models, store, routes, config, log
    server = http.create-server app
    <- server.listen config.PORT
    console.log arguments
    log.info "#{process.pid} listening. Go to http://localhost:#{config.PORT}/"
  .catch (e) ->
    log.error "Error setting up." e
    process.exit 1
