export filtered-import = (obj) ->
  obj = {[key, value] for key, value of obj when value}
  obj
