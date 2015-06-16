require! 'joi'

export params = [
  [\session-id joi.string!.guid!]
  [\event-id joi.string!.guid!]
]

export handler = ({params: {session-id, event-id}, store, session, endpoints}) ->
  endpoints.sessions.events.fetch session-id, event-id, open: true, device: session?.device-id
    .then (event) ->
      update = {
        "events.#{event._index}.duration": Date.now! - event.start
        "events.#{event._index}.finished": true
      }

      store.collection \games .update-async {_id: session-id}, $set: update
    .then -> endpoints.sessions.events.fetch session-id, event-id
