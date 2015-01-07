require! {
  '../config'
  './aggregate'
  './express'
  './log'
  './models'
  './routes'
  './store'
  'bluebird': Promise
  'http'
}

exports.start = ->
  models.setup!
    .then -> store.setup!
    .then -> aggregate.setup store
    .then -> new Promise (resolve, reject) ->
      app = express models, store, routes, config, log
      server = http.create-server app
      log.info 'starting server...'
      err <- server.listen config.PORT
      if err
        log.info 'Error starting server!'
        reject err
      else resolve!
    .then -> log.info "#{process.pid} listening. Go to http://localhost:#{config.PORT}/"
    .catch (e) ->
      log.error "Error setting up." e
      console.error e
      console.dir e.stack
      process.exit 1
