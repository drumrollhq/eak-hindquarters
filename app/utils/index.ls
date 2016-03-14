export filtered-import = (obj) ->
  obj = {[key, value] for key, value of obj when value}
  obj

export parse-list = (list) ->
  if typeof list isnt 'string' or list.trim! is ''
    return []

  list
    .split ','
    .map ( .trim! )
    .filter ( isnt '' )

export filter-keys = (fn, obj) -->
  obj = {[key, value] for key, value of obj when fn key}
  obj
