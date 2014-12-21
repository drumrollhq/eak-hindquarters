require! {
  'assert'
  'knex'
  '../../config'
  '../log'
  'path'
}

db = knex {
  client: \pg
  connection:
    host: config.DB_HOST
    user: config.DB_USER
    password: config.DB_PW
    database: config.DB_NAME
    ssl: config.DB_SSL
  migrations:
    table-name: '_migrations'
    extension: 'ls'
    directory: path.resolve __dirname, '../../migrations'
    database: config.DB_NAME
}

log = log.create 'db'

module.exports = {
  setup: ->
    db.raw 'select 1 as ping'
      .then ({rows}) ->
        assert rows.0.ping is 1
        db.migrate.currentVersion!
      .then (version) ->
        log.info "Current db version: #version" {version}

  db: db
}
