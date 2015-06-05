'use strict';

exports.up = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.text \plan .default-to \free

exports.down = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.drop-column \plan
