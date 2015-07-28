'use strict';

exports.up = (knex, Promise) ->
  knex
    .raw 'ALTER TABLE stage DROP CONSTRAINT area_type_check'
    .then -> knex.raw '''
      ALTER TABLE stage
      ADD CONSTRAINT area_type_check
      CHECK (type = ANY (ARRAY['cutscene'::text, 'area'::text, 'minigame'::text]))'''

exports.down = (knex, Promise) ->
  knex
    .raw 'ALTER TABLE stage DROP CONSTRAINT area_type_check'
    .then -> knex.raw '''
      ALTER TABLE stage
      ADD CONSTRAINT area_type_check
      CHECK (type = ANY (ARRAY['cutscene'::text, 'area'::text, 'level'::text, 'game'::text]))'''

