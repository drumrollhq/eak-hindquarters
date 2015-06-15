require! 'joi'

export options = joi.object!.keys {
  min: joi.boolean!.default false # Show minimized session info
  events: joi.boolean!.default false # Should we include events?
  open: joi.boolean!.default false # Should we check the session is open?
  device: joi.string!.guid!.optional!
}

export params = [
  [\session-id, joi.string!.guid!]
]

export handler = ({store, params: {session-id}, options, errors, session}) ->
  if session?.device-id? then options.device = session.device-id

  projection = if options.min and options.events
    finished: true, user-id: true, start: true, duration: true, events: true
  else if options.min
    finished: true, user-id: true, start: true, duration: true
  else if not options.events
    {events: false}
  else {}

  store.collection \games
    .find-one-async {_id: session-id}, projection
    .then (session) ->
      unless session? then return errors.not-found 'that session doesn\'t exist'

      if options.device? and options.device isnt session.user-id
        return errors.forbidden 'You do not have permission to access this event'

      if options.open and session.finished
        return errors.bad-request 'That session is already finished!'

      session
