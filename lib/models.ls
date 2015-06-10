require! {
  'fs'
  './BaseModel'
  'acl': Acl
  'acl-knex': AclKnexBackend
  'assert'
  'bluebird'
  'bookshelf'
  'knex'
  'path'
  'node-uuid': uuid
}

exports.setup = (ctx, model-path) ->
  {config, log} = ctx
  db = exports.db = knex {
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
      directory: path.resolve __dirname, '../migrations'
      database: config.DB_NAME
  }

  orm = exports.orm = bookshelf db

  log = log.create 'db'

  if config.DEBUG_SQL
    db.client.on \start (builder) ->
      sql = builder.to-query!
      start = process.hrtime!
      id = uuid.v4!
      method = builder._method or \select

      log.trace {method, id, sql}, \start
      builder.on \end ->
        diff = process.hrtime start
        duration = (diff.0 * 1e3 + diff.1 * 1e-6).to-fixed 2
        log.debug {method, duration, id, sql}, \query

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
      exports.acl = new Acl backend
      create-models orm, db, exports, model-path, ctx

create-models = (orm, db, models, base-path, ctx) ->
  model-names = fs.readdir-sync base-path
    .filter ( .0 isnt '.' )
    .map ( .replace /\.[a-z]+$/, '' )
  base = BaseModel orm, db, models
  for name in model-names
    model-path = path.join base-path, name
    model-logger = ctx.log.child model: name
    models[name] = (require model-path)(orm, db, models, base, {} <<< ctx <<< {log: model-logger})
    model-logger.debug 'Registered model'
