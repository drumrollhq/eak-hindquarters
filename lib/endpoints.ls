require! {
  'fs'
  'path'
  'prelude-ls': {filter, partition, concat, pairs-to-obj, camelize, keys, first, values}
  'bluebird': Promise
}

var endpoints

is-dir = (dir, file) -->
  fs.stat-sync path.join dir, file .is-directory!

normalise-name = (name) ->
  name.replace /\.[a-z]+$/, ''
    |> camelize

walk = (dir) ->
  [folders, files] = fs.readdir-sync dir
    |> filter ( .0 isnt '.' )
    |> partition is-dir dir

  files .= map (name) -> [(normalise-name name), path.join dir, name]
  folders .= map (name) -> [(normalise-name name), walk path.join dir, name]

  files ++ folders
    |> pairs-to-obj

flatten-obj = (obj, pre = []) ->
  flat = {}
  for key, value of obj
    if typeof value is \object
      flat <<< flatten-obj value, (pre ++ [key])
    else if key is 'index'
      flat[pre.join '.'] = value
    else
      flat[(pre ++ [key]).join '.'] = value

  flat

export setup = ({config, store, models, log, services}, base-path) ->
  endpoints := flatten-obj walk base-path
  for key, file of endpoints =>
    endpoints[key] = require file
    if typeof! endpoints[key] is \Object and endpoints[key].endpoint isnt false then
      log.debug "Registered endpoint #key"
    else
      delete endpoints[key]

  endpoints

export lookup-endpoint = (name = '') ->
  name = camelize name
  endpoint = endpoints[name]
  unless endpoint then throw new Error "No endpoint #name"
  endpoint

export create-middleware = (spec) ->
  if typeof! spec is \String
    endpoint = lookup-endpoint spec
    if endpoint.use then before = create-middleware endpoint.use
    return (ctx, ...args) ->
      Promise.resolve (if before then before ctx, ...args else ctx)
        .then (ctx) ->
          endpoint.handler ctx, ...args
        .then (new-ctx = {}) -> ctx <<< new-ctx
  else if typeof! spec is \Object
    unless keys spec .length is 1 then throw new Error "Bad middleware spec: #{JSON.stringify spec}. Object should have only one key."
    handler = create-middleware first keys spec
    extra-args = first values spec
    if typeof! extra-args isnt \Array then extra-args = [extra-args]
    return (ctx, ...args) ->
      args .= concat extra-args
      handler ctx, ...args
  else
    throw new Error "Unknown middleware spec: #{JSON.stringify spec}"

export create-handler = (name) ->
  endpoint = lookup-endpoint name

  if endpoint.middleware then throw new Error "Cannot use middleware endpoint #name as handler"

  if endpoint.use then before = create-middleware endpoint.use

  fn = (ctx) ->
    Promise.resolve (if before then before ctx else ctx)
      .then (ctx) ->
        endpoint.handler ctx

  [fn, endpoint]
