exports.up = (knex, Promise) ->
  knex.schema.create-table 'oauth' (table) ->
    table.string 'provider' .index!
    table.string 'provider_id' .index!
    table.integer 'user_id' .index!
    table.json 'provider_data'
    table.primary ['provider' 'provider_id']

exports.down = (knex, Promise) ->
  knex.schema.drop-table 'oauth'
