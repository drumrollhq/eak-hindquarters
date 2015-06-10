require! {
  'prelude-ls': {keys, initial, last, dasherize, camelize}
  'express'
}

walk = (obj, cb, parts = []) ->
  for key, value of obj
    if typeof value is \object
      walk value, cb, (parts ++ [key])
    else
      cb (parts ++ [key]), value

methods = {
  GET: \get
  POST: \post
  PUT: \put
  DEL: \delete
  DELETE: \delete
}

parse-parts = (parts) ->
  url-parts = initial parts
  method = methods[last parts]
  params = []
  url = ''

  unless method then throw new Error "Bad route #{parts.join '.'} - last key must be one of #{keys methods .join ', '}"
  for part in url-parts
    if part.0  is '_'
      # url parameter
      param = camelize part.replace /^_/, ''
      params[*] = param
      url += "/:#param"
    else
      # normal url segment:
      url += "/#{dasherize part}"

  if url is '' then url = '/'

  {method, url, params}

export setup = ({config, models, store, services, endpoints, log}, base-path) ->
  routes = require base-path
  router = express.Router!
  route-log = log.create 'route'
  walk routes, (parts, endpoint-name) ->
    route = parse-parts parts
    route-log.debug "#{route.method.to-upper-case!} #{route.url} -> #endpoint-name"
    [handler, endpoint] = endpoints.create-handler endpoint-name
    router[route.method] route.url, (req, res, next) ->
      ctx = {
        config, models, store, services, endpoints,
        log: req.log
        http: {req, res}
        options: req.query
        body: req.body
        params: req.params
      }

      if endpoint.page
        # Let the endpoint handle rendering:
        req.log.debug "Starting page handler #endpoint-name"
        ctx.render = res.promise-render
        handler ctx
          # Fallback to JSON error page. TODO: proper error pages
          .catch (e) -> res.promise Promise.reject e
      else # Send the result directly:
        req.log.debug "Starting JSON handler #endpoint-name"
        res.promise handler ctx
          .tap (res) -> req.log.debug 'Finished:', res

  router
