require! {
  'express'
  './sessions': Sessions
}

module.exports = (models, store, config) ->
  app = express.Router!

  sessions = Sessions store

  app.post '/' (req, res) ->
    res.promise sessions.create req.session.device-id, req.session.user-id, req.body

  app.post '/:sessionId', (req, res) ->
    console.log req.session
    res.promise sessions.checkin req.params.session-id, req.session.device-id, req.body

  app.delete '/:sessionId', (req, res) ->
    res.promise sessions.stop req.params.session-id, req.session.device-id

  app.post '/:sessionId/events' (req, res) ->
    res.promise sessions.events.create req.params.session-id, req.session.device-id, req.body

  app.post '/:sessionId/events/:eventId' (req, res) ->
    res.promise sessions.events.update req.params.event-id, req.params.session-id, req.session.device-id, req.body

  app.delete '/:sessionId/events/:eventId' (req, res) ->
    res.promise sessions.events.stop req.params.event-id, req.params.session-id, req.session.device

  app
