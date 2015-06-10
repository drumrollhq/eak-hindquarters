require! {
  '../../utils': {filter-keys, parse-list}
}

export params = <[id]>

export handler = ({store, options: {types}, params: {id}, errors}) ->
  types = parse-list types
  if types.length > 0
    filter-fn = (key) -> (key not in <[_id interval t]>) and key in types
  else
    filter-fn = (key) ->
      console.log 'test key' key
      (key not in <[_id interval t]>)

  store.collection \aggregate
    .find-one-async _id: id
    .tap (obj) -> unless obj? then return errors.not-found "Count #id doesn't exist"
    .then filter-keys filter-fn
    .then (obj) -> {"#id": obj}
