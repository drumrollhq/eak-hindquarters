require! {
  './endpoint-info'
  './endpoints'
  './errors'
  './express'
  './log'
  './models'
  './routes'
  './services'
  './store'
  './stripe'
  'bluebird': Promise
  'http'
  'path'
  'repl'
}

ctx = {store, models, log, services, endpoints, errors, stripe, Promise}

repl-eval = (default-eval) -> (cmd, context, filename, callback) ->
  err, result <- default-eval.call this, cmd, context, filename
  if err then return callback err, result
  Promise
    .resolve result
    .then (res) -> callback null, res
    .catch (err) -> callback err

start-repl = (ctx) ->
  repl-server = require 'repl'
    .start prompt: '> ', useColors: true, terminal: true

  repl-server.context <<< ctx
  repl-server.eval = repl-eval repl-server.eval

export start = (config, root) ->
  process.on \uncaughtException (err) ->
    log.fatal \uncaughtException, err, stack: err.stack
    # Give things a little time to log this to slack, not sure its needed but w/e
    <- set-timeout _, 10
    process.exit 1

  process.on \unhandledRejection (err) ->
    log.fatal \unhandledRejection, err, stack: err.stack
    <- set-timeout _, 10
    process.exit 1

  ctx.config = config
  log.info 'Version info: ' require '../version-info.js'
  log.info 'NODE_ENV:' config.NODE_ENV
  Promise
    .all [
      models.setup ctx, path.join root, 'app/models'
      store.setup!
    ]
    .then -> services.setup ctx, path.join root, 'app/services'
    .then -> endpoints.setup ctx, path.join root, 'app/endpoints'
    .then -> new Promise (resolve, reject) ->
      endpoint-info.set-routes path.join root, 'app/routes'
      router = routes.setup ctx, path.join root, 'app/routes'
      templates = require path.join root, 'app/templates'
      express-app = express router, config, log, templates
      server = http.create-server express-app
      log.info 'starting server...'
      err <- server.listen config.PORT
      if err
        log.info 'Error starting server!'
        reject err
      else resolve ctx
    .tap ->
      log.info "#{process.pid} listening. Go to http://localhost:#{config.PORT}/"
      if config.REPL then start-repl ctx
    .catch (e) ->
      console.error e
      console.dir e.stack
      process.exit 1
      log.fatal "Error setting up." e
