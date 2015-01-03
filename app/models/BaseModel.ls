require! {
  'checkit'
  'prelude-ls': {camelize, dasherize, empty}
}

snakeify = (str) -> dasherize str .replace /-/g, '_'

cast = (type, value = '') ->
  | type is \boolean and typeof value is \boolean => value
  | type is \boolean and value.trim!.to-lower-case!.0 is 't' => true
  | type is \boolean and value.trim!.to-lower-case!.0 is 'f' => false
  | otherwise => null

module.exports = (orm, db, models) ->
  checkit.Validators.unique = (val, table, col, ...extras) ->
    val .= trim! if 'trim' in extras
    val .= to-lower-case! if 'lower' in extras
    db.select 'id'
      .from table
      .where col, '=', val
      .then (rows) ~>
        if @_target?.id? then rows = rows.filter ({id}) ~> id isnt @_target.id
        empty rows

  class BaseModel extends orm.Model
    initialize: ->
      @on 'change' ~> @_cast!

    parse: (attrs) -> {[(camelize key), value] for key, value of attrs}
    format: (attrs) ->
      attrs = {[(snakeify key), value] for key, value of attrs}
      if @formatters?.trim?
        for name in @formatters.trim when attrs[name]? => attrs[name] .= trim!

      if @formatters?.lower?
        for name in @formatters.lower when attrs[name]? => attrs[name] .= to-lower-case!

      attrs

    validate: (options = {}) ->
      unless @validations then return
      role = options.role or 'full'
      if typeof! role is 'Array'
        validations = {}
        for r in role => validations <<< @validations[r]
      else validations = @validations[role]
      checkit validations .run @to-JSON!

    _cast: ->
      attrs = @attributes
      for name, type of @cast
        attrs[name] = cast type, attrs[name]
