'use strict';

exports.up = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.timestamp \plan_end

exports.down = (knex, Promise) ->
  knex.schema.table \user (table) ->
    table.drop-column \plan_end

