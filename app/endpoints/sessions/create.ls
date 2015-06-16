require! {
  'node-uuid': uuid
  'bluebird': Promise
  'joi'
}

export body = joi.object!

export handler = ({user, session: {device-id}, body, store, services: {aggregate}}) ->
  data = body <<< {
    user-id: device-id
    registered-user: user?.id or \GUEST
    _id: uuid.v4!
    finished: false
    duration: 0
    start: Date.now!
    events: []
  }

  Promise
    .all [
      store.collection \games .insert-async data
      aggregate.add-event \session
    ]
    .spread (session) -> {
      id: session.0._id
      user: session.0.registered-user
      device: session.0.user-id
    }
