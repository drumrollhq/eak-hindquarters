require! {
  'prelude-ls': {camelize, dasherize}
}

snakeify = (str) -> dasherize str .replace /-/g, '_'

module.exports = (orm, db, models) ->
  class BaseModel extends orm.Model
    parse: (attrs) -> {[(camelize key), value] for key, value of attrs}
    format: (attrs) -> {[(snakeify key), value] for key, value of attrs}
