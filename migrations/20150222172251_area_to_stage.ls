'use strict';

exports.up = (knex, Promise) ->
  Promise.all [
    knex.schema.table \game (table) -> table.rename-column \active_area \active_stage
    knex.schema.table \level (table) -> table.rename-column \area_id \stage_id
    knex.schema.rename-table \area \stage
  ]

exports.down = (knex, Promise) ->
  Promise.all [
    knex.schema.table \game (table) -> table.rename-column \active_stage \active_area
    knex.schema.table \level (table) ->
      console.log table.rename-column
      table.rename-column \stage_id \area_id
    knex.schema.rename-table \stage \area
  ]
