exports.up = (knex, Promise) ->
  knex.schema.table 'user' (table) ->
    table.boolean 'verified_email'

exports.down = (knex, Promise) ->
  knex.schema.table 'user' (table) ->
    table.drop-column 'verified_email'
