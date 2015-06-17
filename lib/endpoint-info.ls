require! {
  'prelude-ls': {Obj, camelize}
}

recursive-map = (fn, val) -->
  | typeof val is \object => {[key, recursive-map fn, value, key] for key, value of val}
  | otherwise => fn val

recursive-filter = (fn, obj) -->
  result = {}
  for key, value of obj
    if typeof value is \object
      value = recursive-filter fn, value

    if fn value
      result[key] = value
    else
      console.log \reject value

  result

var routes
export set-routes = (p) ->
  routes := {} <<< require p

export handler = ({endpoints}) ->
  endpoints = endpoints.endpoints
    |> Obj.reject (endpoint) ->
      typeof endpoint isnt \object or endpoint.page or endpoint.middleware or endpoint.name.0 is '_'
    |> Obj.map (endpoint) -> {
      param-list: endpoint.param-list
      body: !!endpoint.body
      options: !!endpoint.options
      http-only: endpoint.http-only
    }

  filtered-routes = routes
    |> recursive-map camelize
    |> recursive-filter (name) ->
       | typeof name is \string => endpoints[name]
       | typeof name is \object => not Obj.empty name

  {endpoints, routes: filtered-routes}
