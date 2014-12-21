require! {
  'body-parser'
  'compression'
  'cookie-parser'
  'cookie-session'
  'express'
  'express-cors'
  'node-uuid': uuid
}

module.exports = (models, store, routes, config, log) ->
  log = log.create 'app'

  session = cookie-session {
    keys: [config.SECURE_COOKIE_1, config.SECURE_COOKIE_2]
    name: config.SESSION_NAME
    maxage: config.SESSION_MAXAGE
  }

  app = express!
    .use request-logger log
    .use express-cors allowed-origins: ['localhost:*' '*.eraseallkittens.com' '*.drumrollhq.com']
    .use compression!
    .use cookie-parser!
    .use body-parser.json!
    .use body-parser.urlencoded extended: true
    .use session
    .use user-id
    .use routes models, store, config

user-id = (req, res, next) ->
  req.session.user-id ?= uuid.v4!
  next!

request-logger = (log) -> (req, res, next) ->
  req._start-at = process.hrtime!
  req._start-time = Date.now!
  req._remote-address = req.headers.'x-forwarded-for' or req.ip
  req.log = log.child req-id: uuid.v4!

  logger = ->
    res.remove-listener 'close', logger
    res.remove-listener 'finish', logger
    diff = process.hrtime req._start-at
    ms = (diff.0 * 1e3 + diff.1 * 1e-6)
    status = res.status-code
    content-length = res._headers?.'content-length'
    method = req.method
    url = req.url
    user = req.session.user-id
    remote-address = req._remote-address
    req.log.info {ms, status, content-length, method, url, user, remote-address},
      "#{req.method} #{req.url} -> #status [#{format-length content-length}] #{ms.to-fixed 2}ms"

  res.on 'close' logger
  res.on 'finish' logger

  req.log.trace "Start request #{req.method} #{req.url}"

  next!

format-length = (bytes) ->
  i = Math.floor (Math.log bytes) / (Math.log 1024)
  n = (bytes / (Math.pow 1024, i)).to-fixed 2
  "#n #{<[B kB MB GB TB]>[i]}"
