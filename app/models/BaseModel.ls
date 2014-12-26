require! {
  'prelude-ls': {camelize, dasherize}
}

snakeify = (str) -> dasherize str .replace /-/g, '_'

module.exports = (orm, db, models) ->
  class BaseModel extends orm.Model
    parse: (attrs) -> {[(camelize key), value] for key, value of attrs}
    format: (attrs) ->
      attrs = {[(snakeify key), value] for key, value of attrs}
      if @formatters?.trim?
        for name in @formatters.trim when attrs[name]? => attrs[name] .= trim!

      if @formatters?.lower?
        for name in @formatters.lower when attrs[name]? => attrs[name] .= to-lower-case!

      attrs
