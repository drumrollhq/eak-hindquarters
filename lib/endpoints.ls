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
    to-validate = ctx.{options, body, params}
    joi
      .validate-async to-validate, schema, (endpoint.validation-options or {})
      .then (validated) -> ctx <<< validated
      .catch (e) -> errors.bad-request format-validator-err e

export setup = (ctx, base-path) ->
  {log} = ctx
  errors := ctx.errors
  endpoints := exports.endpoints = flatten-obj walk base-path
  endpoints._info = './endpoint-info'
  for key, file of endpoints
    endpoint = require file
    if typeof! endpoint is \Object and endpoint.endpoint isnt false then
      endpoint.name = key
      endpoints[key] = endpoint
    else delete endpoints[key]

  for key, endpoint of endpoints
    unless endpoint.middleware then set-at exports, key, create-function-handler key, ctx
    log.debug "Registered endpoint #key"

  endpoints

export lookup-endpoint = (name = '') ->
  if name.0 is '_'
    us = true
    name .= replace /^_/ ''
  name = camelize name
  if us then name = '_' + name

  endpoint = endpoints[name]
  unless endpoint then throw new Error "No endpoint #name"
  endpoint

get-param-name = (param) ->
  | typeof param is \string => camelize param
  | typeof! param is \Array and param.length is 2 => camelize head param
  | otherwise => throw new TypeError 'Param must be string or array of length 2'

get-param-validator = (param) ->
  | typeof param is \string => joi.any!.required!
  | typeof! param is \Array and param.length = 2 => last param .required!
  | otherwise => throw new TypeError 'Param must be string or array of length 2'

create-handler-base = (endpoint) ->
  if endpoint.use
    [before-handler, before-endpoint] = create-middleware endpoint.use

    if before-endpoint.params
      if endpoint.params
        names = endpoint.params.map get-param-name
        for param in before-endpoint.params when (get-param-name param) not in names
          endpoint.params = endpoint.params.unshift param
      else
        endpoint.params = before-endpoint.params

    if before-endpoint.body
      if endpoint.body and endpoint.body.is-joi and before-endpoint.body.is-joi
        endpoint.body .= merge before-endpoint.body
      else if (not endpoint.body) or (endpoint.body and before-endpoint.body.is-joi)
        endpoint.body = before-endpoint.body

    if before-endpoint.options
      if endpoint.options and endpoint.options.is-joi and before-endpoint.options.is-joi
        endpoint.options .= merge before-endpoint.options
      else if (not endpoint.options) or (endpoint.options and before-endpoint.options.is-joi)
        endpoint.options = before-endpoint.options

  if endpoint.params and endpoint.params.use
    endpoint.params = lookup-endpoint endpoint.params.use .params

  if endpoint.params
    endpoint.param-list = []
    param-validator = {}
    for param in endpoint.params
      name = get-param-name param
      endpoint.param-list[*] = name
      param-validator[name] = get-param-validator param

    endpoint.param-validator = joi.object!.keys param-validator .required!

  validate = endpoint.validate = get-validator endpoint

  (ctx, ...args) ->
    Promise.resolve (if before-handler then before-handler ctx, ...args else ctx)
      .then (ctx) -> if validate then validate ctx else ctx
      .then (ctx) ->
        endpoint.handler ctx, ...args

export create-middleware = (spec) ->
  if typeof! spec is \String
    endpoint = lookup-endpoint spec
    handler = create-handler-base endpoint
    fn = (ctx, ...args) ->
      handler ctx, ...args
        .then (new-ctx = {}) -> {} <<< ctx <<< new-ctx
  else if typeof! spec is \Object
    unless keys spec .length is 1 then throw new Error "Bad middleware spec: #{JSON.stringify spec}. Object should have only one key."
    [handler, endpoint] = create-middleware first keys spec
    extra-args = first values spec
    if typeof! extra-args isnt \Array then extra-args = [extra-args]
    fn = (ctx, ...args) ->
      args .= concat extra-args
      handler ctx, ...args
  else
    throw new Error "Unknown middleware spec: #{JSON.stringify spec}"

  [fn, endpoint]

export create-handler = (name) ->
  endpoint = lookup-endpoint name

  if endpoint.middleware then throw new Error "Cannot use middleware endpoint #name as handler"
  fn = create-handler-base endpoint

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
