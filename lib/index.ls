require! {
  './endpoints'
  './log'
  './models'
  './routes'
  './services'
  './store'
  './express'
  'path'
  'http'
}

export start = (config, root) ->
  Promise
    .all [
      models.setup config, log, path.join root, 'app/models'
      store.setup!
    ]
    .then -> services.setup {config, store, models, log}, path.join root, 'app/services'
    .then -> endpoints.setup {config, store, models, log, services}, path.join root, 'app/endpoints'
    .then -> new Promise (resolve, reject) ->
      router = routes.setup {config, store, models, log, services, endpoints}, path.join root, 'app/routes'
      templates = require path.join root, 'app/templates'
      express-app = express router, config, log, templates
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
