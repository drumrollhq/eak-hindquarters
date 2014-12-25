exports.up = (knex, Promise) ->
  knex.schema.table 'user' (table) ->
    table.boolean 'assume_adult'

exports.down = (knex, Promise) ->
  knex.schema.table 'user' (table) ->
    table.drop-column 'assume_adult'
