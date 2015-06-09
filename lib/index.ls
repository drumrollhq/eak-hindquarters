require! {
  './models'
  './log'
  './store'
  './endpoints'
  './services'
  'path'
}

export start = (config, root) ->
  Promise
    .all [
      models.setup config, log, path.join root, 'app/models'
      store.setup!
    ]
    .then -> services.setup {config, store, models, log}, path.join root, 'app/services'
    .then ->
      console.log 'endpoints.setup pew'
      endpoints.setup {config, store, models, log, services}
    .then -> new Promise (resolve, reject) ->
      routes = require path.join root, 'app/routes'
      express-app = express app, routes
      server = http.create-server express-app
      log.info 'starting server...'
      err <- server.listen config.PORT
      if err
        log.info 'Error starting server!'
        reject err
      else resolve!
    .then -> log.info "#{process.pid} listening. Go to http://localhost:#{config.PORT}/"
    .catch (e) ->
      log.fatal "Error setting up." e
      console.error e
      console.dir e.stack
      process.exit 1
