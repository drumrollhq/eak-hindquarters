require! {
  'bluebird': Promise
  'body-parser'
  'compression'
  'cookie-parser'
  'cookie-session'
  'express'
  'express-cors'
  'node-uuid': uuid
  'passport'
}

module.exports = (router, config, log, templates) ->
  log = log.create 'express'

  session = cookie-session {
    keys: [config.SECURE_COOKIE_1, config.SECURE_COOKIE_2]
    name: config.SESSION_NAME
    maxage: config.SESSION_MAXAGE
  }

  app = express!
    .use request-logger log
    .use express-promise templates
    .use express-cors allowed-origins: ['localhost:*' '*.eraseallkittens.com' '*.drumrollhq.com']
    .use compression!
    .use express.static __dirname + '/../public'
    .use cookie-parser!
    .use body-parser.json!
    .use body-parser.urlencoded extended: true
    .use session
    .use passport.initialize!
    .use passport.session!
    .use user-id
    .use router
    .use four-oh-four
    .use error-handler

express-promise = (views) -> (req, res, next) ->
  res.promise = (p) ->
    p = if typeof! p is 'Array' then Promise.all p else p
    p
      .then (value) ->
        req.log.debug 'express-promise: resolve'
        res.json value
      .catch (e) ->
        req.log.debug 'express-promise: reject'
        error-handler e, req, res

  res.promise-render = (view-name, data = {}) ->
    if views[view-name]?
      views[view-name].stream data .pipe res
    else next "Cannot find view #{view-name}. Available views: #{Object.keys views .join ', '}"

  next!

user-id = (req, res, next) ->
  unless req.session.device-id?
    req.session.device-id = uuid.v4!
    req.log.debug req.session.{device-id} "Created device-id"

  req.session.user-id ?= \GUEST

  next!

error-handler = (err, req, res, next) ->
  req.log.debug 'error-handler' err, err.stack
  if req._errd then return
  req._errd = true
  if err.status?
    send-err req, res, err.status, err
  else
    send-err req, res, 500, status: 500, reason: \unknown, details: (err.message or err)

four-oh-four = (req, res, next) ->
  send-err req, res, 404, status: 404, reason: 'Not Found', details: 'That endpoint doesn\'t exist'

send-err = (req, res, status, err) ->
  res._log-err = err
  res.status status .json err

request-logger = (log) -> (req, res, next) ->
  req._start-at = process.hrtime!
  req._start-time = Date.now!
  req._remote-address = req.headers.'x-forwarded-for' or req.ip
  req.req-id = uuid.v4!
  req.log = log.child req.{req-id}

  logger = ->
    res.remove-listener 'close', logger
    res.remove-listener 'finish', logger
    diff = process.hrtime req._start-at
    ms = (diff.0 * 1e3 + diff.1 * 1e-6)
    status = res.status-code
    content-length = res._headers?.'content-length'
    method = req.method
    url = req.original-url or req.url
    device-id = req.session?.device-id
    remote-address = req._remote-address

    a1 = {ms, status, content-length, method, url, device-id, remote-address}
    a2 = "#{method} #{url} -> #status [#{if content-length then format-length content-length else 'streaming'}] #{ms.to-fixed 2}ms"
    if res._log-err
      a3 = res._log-err

    s = Math.floor status / 100
    if s is 5
      req.log.error a1, a2, a3
    else if s is 4
      req.log.warn a1, a2, a3
    else
      req.log.info a1, a2, a3

  res.on 'close' logger
  res.on 'finish' logger

  req.log.debug "Start request #{req.method} #{req.url}"

  next!

format-length = (bytes) ->
  i = Math.floor (Math.log bytes) / (Math.log 1024)
  n = (bytes / (Math.pow 1024, i)).to-fixed 2
  "#n #{<[B kB MB GB TB]>[i]}"
