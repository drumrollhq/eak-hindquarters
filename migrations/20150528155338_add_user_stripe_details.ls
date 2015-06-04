'use strict';

exports.up = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.string \stripe_customer_id .index!.unique!
    table.string \stripe_card_country .comment 'Required for VATMOSS'
    table.string \country .comment 'Required for VATMOSS'
    table.string \ip_country .comment 'Required for  VATMOSS'

exports.down = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.drop-columns \stripe_customer_id \stripe_card_country \country \ip_country

