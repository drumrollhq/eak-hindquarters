'use strict';

exports.up = (knex, Promise) ->
  knex.schema.table 'area' (table) ->
    table.enum 'type' <[cutscene area level game]>

exports.down = (knex, Promise) ->
  knex.schema.table 'area' (table) ->
    table.drop-column 'type'
