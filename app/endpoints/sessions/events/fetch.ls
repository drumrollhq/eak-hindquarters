require! {
  'joi'
  'prelude-ls': {filter, first}
}

export options = joi.object!.keys {
  min: joi.boolean!.default true # Show minimized session info
  open: joi.boolean!.default false # Should we check the event is open
  device: joi.string!.guid!.optional!
}

export params = [
  [\session-id, joi.string!.guid!]
  [\event-id, joi.string!.guid!]
]

export handler = ({params: {session-id, event-id}, options, store, errors, session, endpoints}) ->
  if session?.device-id? then options.device = session.device-id
  options.events = true
  endpoints.sessions.fetch session-id, options
    .then (session) ->
      for event, i in session.events => event._index = i
      event = session.events |> filter ( .id is event-id) |> first
      unless event? then return errors.not-found 'That event doesn\'t exist on that session'

      if options.open and event.finished
        return errors.bad-request 'That event is already finished'

      event
