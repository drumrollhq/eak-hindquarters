require! {
  './endpoints'
  './log'
  './models'
  './routes'
  './services'
  './store'
  './express'
  './errors'
  'bluebird': Promise
  'path'
  'http'
}

ctx = {store, models, log, services, endpoints, errors, Promise}

export start = (config, root) ->
  ctx.config = config
  Promise
    .all [
      models.setup ctx, path.join root, 'app/models'
      store.setup!
    ]
    .then -> services.setup ctx, path.join root, 'app/services'
    .then -> endpoints.setup ctx, path.join root, 'app/endpoints'
    .then -> new Promise (resolve, reject) ->
      router = routes.setup ctx, path.join root, 'app/routes'
      templates = require path.join root, 'app/templates'
      express-app = express router, config, log, templates
      server = http.create-server express-app
      log.info 'starting server...'
      err <- server.listen config.PORT
      if err
        log.info 'Error starting server!'
        reject err
      else resolve!
    .then ->
      log.info "#{process.pid} listening. Go to http://localhost:#{config.PORT}/"
      if config.REPL
        require 'repl' .start '> ' .context <<< ctx
    .catch (e) ->
      console.error e
      console.dir e.stack
      process.exit 1
      log.fatal "Error setting up." e
