'use strict';

exports.up = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.rename-column \country \user_country

exports.down = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.rename-column \user_country \country
