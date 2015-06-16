require! {
  'node-uuid': uuid
}

sessions = ctx.endpoints.sessions
store = ctx.store

device-id = uuid.v4!
user = new ctx.models.User id: 123

describe 'endpoints.sessions' ->

  describe '.create' ->
    ctx = {session: {device-id}, user}
    specify 'return some event properties' ->
      sessions.create {some: 'event', data: ooh: 'fancy'}, ctx
        .then (session) ->
          expect session.device .to.equal device-id
          expect session.user .to.equal user.id
          expect session.id .to.be.a.string

    specify 'should add a session' ->
      count = store.collection 'games' .count-async!
      count2 = count.then -> sessions.create {some: 'event'}, ctx
        .then -> store.collection 'games' .count-async!

      Promise.all [count, count2] .spread (count, count2) -> expect count2 .to.equal count + 1

    specify 'should increase the aggregate session counter' ->
      count1 = store.collection 'aggregate' .find-one-async _id: 'alltime'
      count2 = count1.then -> sessions.create {some: 'event'}, ctx
        .then -> store.collection 'aggregate' .find-one-async _id: 'alltime'

      Promise.all [count1, count2] .spread (count1, count2) ->
        expect count2.session .to.equal count1.session + 1

  context 'with an existing session' ->
    ctx = {session: {device-id}, user}
    session-id = null
    before-each ->
      sessions.create {some: 'event'} ctx
        .then (session) -> session-id := session.id

    describe '.checkin' ->
      specify 'Should return a 400 error without ids' ->
        sessions.checkin session-id, {}, ctx
          .then -> throw 'Error: checking should error'
          .catch (e) -> expect e.status .to.equal 400

      specify 'Should fetch the session with device-id and open: true' ->
        sinon.spy sessions, 'fetch'
        sessions.checkin session-id, {ids: []}, ctx
          .then ->
            expect sessions.fetch .to.have.been.called-once
            expect sessions.fetch .to.have.been.called-with session-id, device: device-id, open: true, events: true
            sessions.fetch.restore!

      specify 'Should increase the duration' ->
        duration = null
        sessions.fetch session-id
          .then (session) -> duration := session.duration
          .then -> sessions.checkin session-id, {ids: []}, ctx
          .then -> sessions.fetch session-id
          .then (session) -> expect session.duration .to.be.greater-than duration

    describe '.fetch' ->
      specify 'should return a session' ->
        sessions.fetch session-id .then (session) ->
          expect session._id .to.equal session-id
          expect session.user-id .to.equal device-id

      specify 'should 404 if the session doesn\'t exist' ->
        sessions.fetch uuid.v4!
          .then -> throw 'promise should error'
          .catch (e) -> expect e.status .to.equal 404

      specify 'should check for device id' ->
        sessions.fetch session-id, device: device-id
          .then (session) -> expect session.user-id .to.equal device-id
          .then -> sessions.fetch session-id, device: uuid.v4!
          .then -> throw 'promise should error'
          .catch (e) -> expect e.status .to.equal 403

      specify 'should check session is open' ->
        sessions.fetch session-id, open: true
          .then (session) -> expect session.finished .to.equal false
          .then -> store.collection 'games' .update-async {_id: session-id}, {$set: finished: true}
          .then -> sessions.fetch session-id, open: true
          .then -> throw 'promise should error'
          .catch (e) -> expect e.status .to.equal 400

      specify 'should only return minimal data if min: true' ->
        sessions.fetch session-id, min: true .then (session) ->
          expect session.start .to.be.a.number
          delete session.start
          expect session .to.deep.equal {
            _id: session-id
            finished: false
            user-id: device-id
            duration: 0
          }

      specify 'should only return events when flag is set' ->
        sessions.fetch session-id, events: false
          .then (session) -> expect session.events .not.to.exist
          .then -> sessions.fetch session-id, events: true
          .then (session) -> expect session.events .to.be.an.array

      specify 'min and events flags should work together' ->
        sessions.fetch session-id, events: true, min: true .then (session) ->
          expect session.start .to.be.a.number
          delete session.start
          expect session .to.deep.equal {
            _id: session-id
            finished: false
            user-id: device-id
            events: []
            duration: 0
          }

    describe '.events.create' ->
      specify 'should error without type and data' ->
        sessions.events.create session-id, {}, ctx
          .then -> throw 'promise should error'
          .catch (e) -> expect e.status .to.equal 400

      specify 'should return event data' ->
        sessions.events.create session-id, {type: 'kitten', data: some: 'event'}, ctx
          .then (event) ->
            expect event.start .to.be.a.number
            expect event.type .to.equal 'kitten'
            expect event.data .to.deep.equal some: 'event'

      specify 'should set duration depending on the has-duration property' ->
        sessions.events.create session-id, {type: 'kitten', has-duration: false, data: some: 'event'}, ctx
          .then (event) ->
            expect event.finished .to.equal true
            expect event.duration .not.to.exist
          .then -> sessions.events.create session-id, {type: 'kitten', has-duration: true, data: some: 'event'}, ctx
          .then (event) ->
            expect event.finished .to.equal false
            expect event.duration .to.be.a.number

      specify 'should add an event' ->
        sess1 = sessions.fetch session-id, events: true
        sess2 = sess1.then -> sessions.events.create session-id, {type: 'kitten', data: some: 'event'}, ctx
          .then -> sessions.fetch session-id, events: true

        Promise.all [sess1, sess2] .spread (sess1, sess2) ->
          expect sess2.events.length .to.equal sess1.events.length + 1

      specify 'should increment the aggregate counter for that event type' ->
        count1 = store.collection 'aggregate' .find-one-async _id: 'alltime'
        count2 = count1
          .then -> sessions.events.create session-id, {type: 'kitten', data: some: 'event'}, ctx
          .then -> store.collection 'aggregate' .find-one-async _id: 'alltime'

        Promise.all [count1, count2] .spread (count1, count2) ->
          expect count2.kitten .to.equal count1.kitten + 1

      specify 'should fetch session and check open' ->
        sinon.spy sessions, 'fetch'
        sessions.events.create session-id, {type: 'kitten', data: some: 'event'}, ctx
          .then ->
            expect sessions.fetch .to.have.been.called-once
            expect sessions.fetch .to.have.been.called-with session-id, device: device-id, open: true
            sessions.fetch.restore!

    describe 'with an existing event' ->
      event-id = event-id2 = null
      before-each ->
        s1 = sessions.events.create session-id, {type: 'kitten', has-duration: true, data: some: 'event'}, ctx
          .then (event) -> event-id := event.id
          .then -> sessions.events.create session-id, {type: 'death', has-duration: false, data: drama: true}, ctx
          .then (event) -> event-id2 := event.id

      describe '.checkin' ->
        specify 'should update the duration of ids passed' ->
          event1 = sessions.events.fetch session-id, event-id
          event2 = event1
            .then -> sessions.checkin session-id, {ids: [event-id]}, ctx
            .then -> sessions.events.fetch session-id, event-id

          Promise.all [event1, event2] .spread (event1, event2) ->
            expect event2.duration .to.be.greater-than event1.duration

        specify 'should not update events outside of passed ids' ->
          sess1 = sessions.fetch session-id, events: true
          sess2 = sess1
            .then -> sessions.checkin session-id, {ids: [event-id]}, ctx
            .then -> sessions.fetch session-id, events: true

          Promise.all [sess1, sess2] .spread (sess1, sess2) ->
            expect sess1.events.0.duration .to.be.less-than sess2.events.0.duration
            expect sess1.events.1.duration .to.equal sess2.events.1.duration

      describe '.stop' ->
        specify 'should use fetch under the hood' ->
          sinon.spy sessions, 'fetch'
          sessions.stop session-id, ctx .then ->
            expect sessions.fetch .to.have.been.called
            expect sessions.fetch .to.have.been.called-with session-id, device: device-id, open: true, events: true, min: true
            sessions.fetch.restore!

        specify 'should set duration and finished properties' ->
          sess1 = sessions.fetch session-id
          sess2 = sess1
            .then -> sessions.stop session-id
            .then -> sessions.fetch session-id

          Promise.all [sess1, sess2] .spread (sess1, sess2) ->
            expect sess1.duration .to.be.less-than sess2.duration
            expect sess1.finished .to.equal false
            expect sess2.finished .to.equal true

        specify 'should set duration and finish for all open events' ->
          sess1 = sessions.fetch session-id, events: true
          sess2 = sess1
            .then -> sessions.stop session-id, ctx
            .then -> sessions.fetch session-id, events: true

          Promise.all [sess1, sess2] .spread (sess1, sess2) ->
            expect sess1.events.0.finished .to.equal false
            expect sess2.events.0.finished .to.equal true
            expect sess1.events.0.duration .to.be.less-than sess2.events.0.duration
            expect sess1.events.1.duration .to.equal sess1.events.1.duration

        specify 'should return completed session' ->
          sessions.stop session-id, ctx .then (session) ->
            expect session .to.have.keys '_id' 'start' 'duration' 'finished' 'userId'

      describe '.events.fetch' ->
        specify 'should return an event' ->
          sessions.events.fetch session-id, event-id .then (event) ->
            expect event.id .to.equal event-id
            expect event.type .to.equal 'kitten'

        specify 'should use fetch with min: true and events: true' ->
          sinon.spy sessions, 'fetch'
          sessions.events.fetch session-id, event-id .then ->
            expect sessions.fetch .to.have.been.called-once
            expect sessions.fetch .to.have.been.called-with session-id, min: true, events: true, open: false
            sessions.fetch.restore!

        specify 'should return 404 when no matching event is found' ->
          sessions.events.fetch session-id, uuid.v4!
            .then -> throw 'promise should error'
            .catch (e) -> expect e.status .to.equal 404

        specify 'should check event is open' ->
          sessions.events.fetch session-id, event-id, open: true
            .then (event) -> expect event.finished .to.equal false
            .then -> store.collection 'games' .update-async {_id: session-id}, {$set: 'events.0.finished': true}
            .then -> sessions.events.fetch session-id, event-id, open: true
            .then -> throw 'promise should error'
            .catch (e) -> expect e.status .to.equal 400

      describe '.events.update' ->
        specify 'should fetch the event with events.fetch' ->
          sinon.spy sessions.events, 'fetch'
          sessions.events.update session-id, event-id, {awesome: true}, ctx .then ->
            expect sessions.events.fetch .to.have.been.called
            expect sessions.events.fetch .to.have.been.called-with session-id, event-id, open: true, device: device-id
            sessions.events.fetch.restore!

        specify 'should set the properties on the events data field' ->
          sessions.events.update session-id, event-id, {awesome: true}, ctx
            .then -> sessions.events.fetch session-id, event-id
            .then (event) ->
              expect event.data .to.deep.equal some: 'event', awesome: true

        specify 'should return the updated event' ->
          sessions.events.update session-id, event-id, {awesome: true}, ctx .then (event) ->
            expect event.id .to.equal event-id
            expect event.data.awesome .to.equal true

      describe '.events.stop' ->
        specify 'should fetch the event with events.fetch' ->
          sinon.spy sessions.events, 'fetch'
          sessions.events.stop session-id, event-id, ctx .then ->
            expect sessions.events.fetch .to.have.been.called
            expect sessions.events.fetch .to.have.been.called-with session-id, event-id, open: true, device: device-id
            sessions.events.fetch.restore!

        specify 'should update the duration and set finished' ->
          event1 = sessions.events.fetch session-id, event-id
          event2 = event1
            .then -> sessions.events.stop session-id, event-id, ctx
            .then -> sessions.events.fetch session-id, event-id

          Promise.all [event1, event2] .spread (event1, event2) ->
            expect event2.duration .to.be.greater-than event1.duration
            expect event1.finished .to.equal false
            expect event2.finished .to.equal true

        specify 'should return the stopped event' ->
          sessions.events.stop session-id, event-id, ctx .then (event) ->
            expect event.id .to.equal event-id
            expect event.data .to.deep.equal some: 'event'
