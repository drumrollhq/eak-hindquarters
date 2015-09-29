'use strict';

exports.up = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.json \eak_settings, true .default-to '{}'

exports.down = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.drop-column \eak_settings
