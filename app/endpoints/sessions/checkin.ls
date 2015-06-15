require! 'joi'

export params = [[\session-id, joi.string!.guid!]]
export body = joi.object!.keys {
  ids: joi.array!.unique!.required!
}

export handler = ({params: {session-id}, session: {device-id}, body, endpoints, store}) ->
  endpoints.sessions.fetch session-id, device: device-id, open: true, events: true
    .then (session) ->
      update = {["events.#{i}.duration", Date.now! - event.start] for event, i in session.events when event.id in body.ids}
      update.duration = Date.now! - session.start
      store.collection \games .update-async {_id: session-id}, $set: update
    .then -> success: true
