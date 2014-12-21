require! {
  '../config'
  './aggregate'
  './express'
  './log'
  './models'
  './routes'
  './store'
  'http'
}

models.setup!
  .then -> store.setup!
  .then -> aggregate.setup store
  .then ->
    app = express models, store, routes, config, log
    server = http.create-server app
    <- server.listen config.PORT
    log.info "#{process.pid} listening. Go to http://localhost:#{config.PORT}/"
  .catch (e) ->
    log.error "Error setting up." e
    process.exit 1
