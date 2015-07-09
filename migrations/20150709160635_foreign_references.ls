'use strict';

exports.up = (knex, Promise) ->
  fkey = (table, key, f-table, f-key, on-delete) ->
    knex.raw """
      ALTER TABLE "#table" ADD CONSTRAINT "#{table}_#{key}_fkey" FOREIGN KEY ("#key") REFERENCES "#f-table" ("#f-key") ON DELETE #on-delete
    """

  Promise.all [
    fkey \authed_action \user_id \user \id \cascade
    fkey \game \user_id \user \id \cascade
    fkey \game \active_stage \stage \id \restrict
    fkey \level \stage_id \stage \id \cascade
    fkey \oauth \user_id \user \id \cascade
    fkey \stage \game_id \game \id \cascade
  ]

exports.down = (knex, Promise) ->
  throw 'unimplemented'

