exports.up = (knex, Promise) ->
  tables = []
  tables[*] = knex.schema.create-table 'game' (table) ->
    table.increments 'id' .index!
    table.integer 'user_id' .index! .not-nullable!
    table.integer 'active_area' .not-nullable!
    table.text 'name'
    table.integer 'kittens'
    table.timestamps!

  tables[*] = knex.schema.create-table 'area' (table) ->
    table.increments 'id' .index!
    table.integer 'game_id' .index! .not-nullable!
    table.text 'url' .index! .not-nullable!
    table.integer 'player_x'
    table.integer 'player_y'
    table.json 'state', true
    table.timestamps!

  tables[*] = knex.schema.create-table 'level' (table) ->
    table.increments 'id' .index!
    table.integer 'area_id' .index! .not-nullable!
    table.text 'url' .index! .not-nullable!
    table.json 'state' true
    table.text 'html'

  tables[*] = knex

  Promise.all tables

exports.down = (knex, Promise) ->
  Promise.all [
    knex.schema.drop-table 'game'
    knex.schema.drop-table 'area'
    knex.schema.drop-table 'level'
  ]
