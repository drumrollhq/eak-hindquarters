require! {
  '../../config'
  '../log'
  'acl': Acl
  'acl-knex': AclKnexBackend
  'assert'
  'bluebird'
  'knex'
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
  debug: config.DEBUG_SQL
}

log = log.create 'db'

module.exports = models = {
  setup: ->
    db.raw 'select 1 as ping'
      .then ({rows}) ->
        assert rows.0.ping is 1
        db.migrate.currentVersion!
      .then (version) -> log.info {version} "Running migrations"
      .then -> db.migrate.latest!
      .then -> db.migrate.current-version!
      .then (version) -> log.info {version} "Migrations completed"
      .then ->
        backend = new AclKnexBackend db, 'acl_'
        bluebird.promisify-all Acl.prototype
        models.acl = new Acl backend

  db: db
}
