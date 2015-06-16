require! 'joi'

export params = [[\session-id, joi.string!.guid!]]
export handler = ({session, params: {session-id}, endpoints, store}) ->
  endpoints.sessions.fetch session-id, device: session?.device-id, open: true, min: true, events: true
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

      store.collection \games .update-async {_id: session-id}, $set: update
        .then -> endpoints.sessions.fetch session-id, min: true
