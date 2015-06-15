require! {
  'joi'
  'fs'
  'path'
  'prelude-ls': {filter, partition, concat, pairs-to-obj, camelize, keys, first, values, split-at, head, tail, last}
  'bluebird': Promise
}

var endpoints, errors

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

set-at = (obj, key, val) ->
  | typeof key is \string => set-at obj, (camelize key .split '.'), val
  | typeof! key is \Array and key.length is 1 => obj[key] = val
  | typeof! key is \Array => obj[head key] = set-at (obj[head key] or {}), (tail key), val
  | otherwise => throw new TypeError "Bad key type: #{typeof! key}"

  return obj

format-validator-err = (err) ->
  err.details?.0?.message or err.message

joi.validate-async = Promise.promisify joi.validate

get-validator = (endpoint) ->
  schema = {}
  if endpoint.param-validator then schema.params = endpoint.param-validator

  if endpoint.options and endpoint.options.is-joi
    schema.options = endpoint.options
  else if endpoint.options then schema.options = joi.object!

  if endpoint.body and endpoint.body.is-joi
    schema.body = endpoint.body
  else if endpoint.body then schema.body = joi.object!.required!

  schema = joi.object!.keys schema .unknown!

  (ctx) ->
    joi.validate-async ctx, schema .catch (e) -> errors.bad-request format-validator-err e

export setup = (ctx, base-path) ->
  {log} = ctx
  errors := ctx.errors
  endpoints := flatten-obj walk base-path
  for key, file of endpoints
    endpoint = require file
    if typeof! endpoint is \Object and endpoint.endpoint isnt false then
      endpoints[key] = endpoint
      unless endpoint.middleware then set-at exports, key, create-function-handler key, ctx
      log.debug "Registered endpoint #key"

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
  endpoint = {} <<< lookup-endpoint name

  if endpoint.middleware then throw new Error "Cannot use middleware endpoint #name as handler"
  if endpoint.use then before = create-middleware endpoint.use
  if endpoint.params
    endpoint.param-list = []
    param-validator = {}
    for param in endpoint.params
      if typeof! param is \String
        name = camelize param
        param-validator[name] = joi.string!.required!
      else if typeof! param is \Array
        name = camelize head param
        param-validator[name] = last param .required!
      else throw new TypeError "Bad type for param list item: #{typeof! param} #param"
      endpoint.param-list[*] = name

    endpoint.param-validator = joi.object!.keys param-validator .required!

  validate = endpoint.validate = get-validator endpoint

  fn = (ctx) ->
    Promise.resolve (if before then before ctx else ctx)
      .then (ctx) -> if validate then validate ctx else ctx
      .then (ctx) ->
        endpoint.handler ctx

  [fn, endpoint]

export create-function-handler = (name, base-ctx) ->
  [handler, endpoint] = create-handler name
  (...args) ->
    # Use first arguments as parameters:
    if endpoint.param-list
      [param-args, args] = split-at endpoint.param-list.length, args
      params = {[key, param-args[i]] for key, i in endpoint.param-list}
    else params = {}

    if endpoint.body
      [[body], args] = split-at 1, args
    body ?= {}

    if endpoint.options
      [[options], args] = split-at 1, args
    options ?= {}

    if args.length > 0
      [[ctx], args] = split-at 1, args
    ctx ?= {}

    ctx = {} <<< base-ctx <<< {params, body, options} <<< ctx
    handler ctx
