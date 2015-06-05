require! {
  'bluebird': Promise
}

change-types = (knex, table-name, data-type, columns) ->
  Promise.map columns, (column-name) ->
    knex.raw """alter table "#table-name" alter column "#column-name" type #data-type"""

exports.up = (knex, Promise) ->
  Promise.all [
    change-types knex, \authed_action \text <[action digest]>
    change-types knex, \oauth \text <[provider provider_id]>
    change-types knex, \user \text <[username email password_digest remember_digest first_name last_name stripe_customer_id stripe_card_country user_country ip_country]>
  ]

exports.down = (knex, Promise) ->
  Promise.all [
    change-types knex, \authed_action 'character varying(255)' <[action digest]>
    change-types knex, \oauth 'character varying(255)' <[provider provider_id]>
    change-types knex, \user 'character varying(255)' <[username email password_digest remember_digest first_name last_name stripe_customer_id stripe_card_country user_country ip_country]>
  ]
