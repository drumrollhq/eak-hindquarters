'use strict';

exports.up = (knex, Promise) ->
  knex.raw """
    ALTER TABLE "user" DROP CONSTRAINT "user_gender_check"
  """


exports.down = (knex, Promise) ->
  # meh

