require! {
  'acl': Acl
  'acl-knex': AclKnexBackend
}

exports.up = (knex, Promise) -> new Promise (resolve, reject) ->
  backend = new AclKnexBackend knex, 'acl_'
  backend.setup [null, null, null, 'acl_', null, null, null, knex], (err) ->
    if err then reject! else resolve!

exports.down = (knex, Promise) -> new Promise (resolve, reject) ->
  backend = new AclKnexBackend knex, 'acl_'
  backend.teardown [null, null, null, 'acl_', null, null, null, knex], (err) ->
    if err then reject! else resolve!
