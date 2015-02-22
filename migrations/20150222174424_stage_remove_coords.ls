'use strict';

exports.up = (knex, Promise) ->
  knex.schema.table \stage (table) ->
    table.drop-column \player_x
    table.drop-column \player_y

exports.down = (knex, Promise) ->
  knex.schema.table \stage (table) ->
    table.integer \player_x
    table.integer \player_y

