exports.up = (knex, Promise) ->
  knex.schema
    .table 'game' (table) ->
      table.drop-column 'kittens'
      table.json 'state' true
      table.drop-column 'active_area'
    .then -> knex.schema.table 'game' (table) ->
      table.integer 'active_area' .index! .nullable!

exports.down = (knex, Promise) ->
  knex.schema.table 'game' (table) ->
    table.integer 'kittens'
    table.drop-column 'state'

