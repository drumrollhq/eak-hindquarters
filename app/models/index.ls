require! {
  '../../config'
  '../log'
  './BaseModel'
  'acl': Acl
  'acl-knex': AclKnexBackend
  'assert'
  'bluebird'
  'bookshelf'
  'knex'
  'path'
}

db = knex {
  client: \pg
  connection:
    host: config.DB_HOST
    port: config.DB_PORT
    user: config.DB_USER
    password: config.DB_PW
    database: config.DB_NAME
    ssl: config.DB_SSL
  migrations:
    table-name: '_migrations'
    extension: 'ls'
    directory: path.resolve __dirname, '../../migrations'
    database: config.DB_NAME
  debug: config.DEBUG_SQL
}

orm = bookshelf db

log = log.create 'db'

module.exports = models = {
  setup: ->
    log.info 'pinging database'
    db.raw 'select 1 as ping'
      .then ({rows}) ->
        assert rows.0.ping is 1
        log.info 'Ping successful!'
        db.migrate.currentVersion!
      .then (version) -> log.info {version} "Running migrations"
      .then -> db.migrate.latest!
      .then -> db.migrate.current-version!
      .then (version) -> log.info {version} "Migrations completed"
      .then ->
        backend = new AclKnexBackend db, 'acl_'
        bluebird.promisify-all Acl.prototype
        models.acl = new Acl backend
        create-models!

  db: db
  orm: orm
}

create-models = ->
  model-names = <[User OAuth AuthedAction Game Stage]>
  base = BaseModel orm, db, models
  for name in model-names
    models[name] = (require "./#{name}")(orm, db, models, base)
