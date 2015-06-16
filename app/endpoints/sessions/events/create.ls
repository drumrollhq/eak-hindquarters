require! {
  'joi'
  'node-uuid': uuid
}

export body = joi.object!.keys {
  type: joi.string!.required!
  data: joi.object!.required!
  has-duration: joi.boolean!.default false
}

export params = [[\session-id, joi.string!.guid!]]

export handler = ({params: {session-id}, session: {device-id}, services: {aggregate}, endpoints: {sessions}, body, store, errors}) ->
  unless body.type? and body.data? and typeof body.data is \object
    return errors.bad-request 'Event must have type and data'

  event = {
    id: uuid.v4!
    start: Date.now!
    finished: !body.has-duration
    duration: (0 if body.has-duration)
    type: body.type
    data: body.data
  }

  sessions
    .fetch session-id, device: device-id, open: true
    .then -> Promise.all [
      store.collection \games .update-async {_id: session-id}, $push: events: event
      aggregate.add-event body.type
    ]
    .then -> event
