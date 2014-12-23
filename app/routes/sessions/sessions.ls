require! {
  'prelude-ls': {filter, first}
  'node-uuid': uuid
  'bluebird': Promise
  '../../aggregate'
  '../../errors'
}

module.exports = (store) ->
  model = store.collection 'games'
  create = (device, user, data) ->
    data <<< {user-id: device, registered-user: user, _id: uuid.v4!,
    finished: false, duration: 0, start: Date.now!, events: []}

    Promise.all [(model.insert-async data), (aggregate.add-event \session)]
      .spread (session) -> {id: session.0._id, user: session.0.registered-user, device: session.0.user-id}

  checkin = (session-id, device, data = {}) ->
    unless data.ids then return errors.bad-request 'you must supply a list of ids'
    sessions.fetch session-id, device: device, open: true, events: true
      .then (session) ->
        update = {["events.#{i}.duration", Date.now! - event.start] for event, i in session.events when event.id in data.ids}
        update.duration = Date.now! - session.start

        model.update-async {_id: session-id}, $set: update
      .then -> success: true

  fetch = (id, options = {}) ->
    projection = if options.min and options.events
      finished: true, user-id: true, start: true, duration: true, events: true
    else if options.min
      finished: true, user-id: true, start: true, duration: true
    else if not options.events
      {events: false}
    else {}

    model.find-one-async {_id: id}, projection
      .then (session) ->
        unless session? then return errors.not-found 'that session doesn\'t exist'

        if options.device? and options.device isnt session.user-id
          return errors.forbidden 'You do not have permission to access this event'

        if options.open and session.finished
          return errors.bad-request 'That session is already finished!'

        session

  stop = (id, device) ->
    sessions.fetch id, device: device, open: true, min: true, events: true
      .then (session) ->
        update = {
          duration: Date.now! - session.start
          finished: true
        }

        for event, i in session.events when not event.finished
          update <<< {
            "events.#{i}.finished": true
            "events.#{i}.duration": Date.now! - event.start
          }

        model.update-async {_id: id}, $set: update
          .then -> sessions.fetch id, min: true

  events = {
    create: (session, device, data) ->
      unless data.type? and data.data? and typeof data.data is \object
        return errors.bad-request 'Event must have type and data'

      event = {id: uuid.v4!, start: Date.now!, finished: !data.has-duration,
      duration: (0 if data.has-duration), type: data.type, data: data.data}

      sessions.fetch session, device: device, open: true
        .then -> Promise.all [
          model.update-async {_id: session}, $push: events: event
          aggregate.add-event data.type
        ] .then -> event

    fetch: (event-id, session-id, options = {}) ->
      options = {} <<< options
      options.min ?= true
      options.events = true
      sessions.fetch session-id, options
        .then (session) ->
          for event, i in session.events => event._index = i
          event = session.events |> filter ( .id is event-id) |> first
          unless event? then return errors.not-found 'That event doesn\'t exist on that session'

          if options.open and event.finished
            return errors.bad-request 'That event is already finished'

          event

    update: (event-id, session-id, device, data) ->
      events.fetch event-id, session-id, open: true, device: device
        .then (event) ->
          update = {["events.#{event._index}.data.#{key}", value] for key, value of data}
          model.update-async {_id: session-id}, $set: update
        .then -> events.fetch event-id, session-id

    stop: (event-id, session-id, device) ->
      events.fetch event-id, session-id, open: true, device: device
        .then (event) ->
          update = {
            "events.#{event._index}.duration": Date.now! - event.start
            "events.#{event._index}.finished": true
          }

          model.update-async {_id: session-id}, $set: update
        .then -> events.fetch event-id, session-id
  }

  sessions = {create, checkin, fetch, stop, events}
