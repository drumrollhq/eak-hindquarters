'use strict';

exports.up = (knex, Promise) ->
  fkey = (table, key, f-table, f-key, on-delete) ->
    knex.raw """
      ALTER TABLE "#table" ADD CONSTRAINT "#{table}_#{key}_fkey" FOREIGN KEY ("#key") REFERENCES "#f-table" ("#f-key") ON DELETE #on-delete
    """

  Promise.map [
    [\authed_action \user_id \user \id \cascade]
    [\game \user_id \user \id \cascade]
    [\game \active_stage \stage \id \restrict]
    [\level \stage_id \stage \id \cascade]
    [\oauth \user_id \user \id \cascade]
    [\stage \game_id \game \id \cascade]
  ], ((args) -> fkey ...args), concurrency: 1

exports.down = (knex, Promise) ->
  throw 'unimplemented'

