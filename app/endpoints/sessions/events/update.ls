require! 'joi'

export params = [
  [\session-id, joi.string!.guid!]
  [\event-id, joi.string!.guid!]
]

export body = joi.object!

export handler = ({params: {session-id, event-id}, body, store, session, endpoints}) ->
  endpoints.sessions.events.fetch session-id, event-id, open: true, device: session?.device-id
    .then (event) ->
      update = {["events.#{event._index}.data.#{key}", value] for key, value of body}
      store.collection \games .update-async {_id: session-id}, $set: update
    .then -> endpoints.sessions.events.fetch session-id, event-id
