exports.up = (knex, Promise) ->
  knex.schema.create-table 'authed_action' (table) ->
    table.increments 'id' .index!
    table.integer 'user_id' .index!
    table.string 'action'
    table.json 'args'
    table.string 'digest'
    table.boolean 'used'
    table.timestamps!

exports.down = (knex, Promise) ->
  knex.schema.drop-table 'authed_action'
