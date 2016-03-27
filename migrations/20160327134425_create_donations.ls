exports.up = (knex) ->
  knex.schema.create-table 'donations' (table) ->
    table.increments 'id' .index!
    table.string 'email' .index!
    table.string 'stripe_id' .index!
    table.integer 'amount'
    table.string 'ip_country'
    table.string 'card_country'
    table.string 'user_country'
    table.timestamps!

exports.down = (knex) ->
  knex.schema.drop-table 'donations'
