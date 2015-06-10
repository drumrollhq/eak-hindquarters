require! {
  '../../../lib/errors'
  '../../../lib/store'
}

export endpoint = false

export fetch-session = (id, options = {}) ->
  projection = if options.min and options.events
    finished: true, user-id: true, start: true, duration: true, events: true
  else if options.min
    finished: true, user-id: true, start: true, duration: true
  else if not options.events
    {events: false}
  else {}

  store.collection \games
    .find-one-async {_id: id}, projection
    .then (session) ->
      unless session? then return errors.not-found 'that session doesn\'t exist'

      if options.device? and options.device isnt session.user-id
        return errors.forbidden 'You do not have permission to access this event'

      if options.open and session.finished
        return errors.bad-request 'That session is already finished!'

      session
