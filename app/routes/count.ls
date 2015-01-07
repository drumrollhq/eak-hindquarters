require! {
  'express'
  '../aggregate'
}

parse-list = (list) ->
  if typeof list isnt 'string' or list.trim! is ''
    return []

  list
    .split ','
    .map ( .trim! )
    .filter ( isnt '' )

filter-extras = (obj) ->
  obj = {[key, value] for key, value of obj when key not in <[_id interval t]>}
  obj

filter-types = (types, obj) -->
  types = parse-list types
  if types.length is 0 then return obj
  obj = {[key, value] for key, value of obj when key in types}
  obj

module.exports = (models, store, config) ->
  app = express.Router!
  model = store.collection 'aggregate'

  app.get '/:id' (req, res, next) ->
    result = model.find-one-async _id: req.params.id
      .then filter-extras >> filter-types req.query.types
      .then (obj) -> {"#{req.params.id}": obj}

    res.promise result
