require! {
  './log'
  'bluebird': Promise
  'moment'
}

log = log.create \aggregate
model = null

types = <[session kitten death edit level cutscene skip action incompatible finish page]>
intervals = <[minute hour day week month year]>

relevant-aggregate-ids = (time) ->
  ['alltime'] ++ intervals.map (interval) ->
    "#{interval}-#{time.clone!.start-of interval .unix!}"

create-blank = -> {[type, 0] for type in types}

get-blanks = (start, end) ->
  blanks = []
  blanks[*] = create-blank! <<< {t: 0, interval: 'alltime', _id: 'alltime'}

  for interval in intervals
    st = start.clone!.start-of interval
    en = end.clone!.add 1 interval

    while st.add 1 interval .is-before en
      blanks[*] = create-blank! <<< {t: st.unix!, interval: interval, _id: "#{interval}-#{st.unix!}"}

  blanks

module.exports = aggregate = {
  setup: (store) ->
    @store = store
    log.info 'setting up'
    store.collection-async \aggregate
      .then (m) ->
        log.info 'setup complete'
        model := m
        set-interval aggregate.prepare, 1000ms * 60s * 30m
        aggregate.prepare!

  add-event: (type, timestamp = Date.now!) ->
    if type not in types then throw new Error "Type #type is not allowed!"

    now = moment timestamp
    ids = relevant-aggregate-ids now
    model.update-async {_id: $in: ids}, {$inc: "#type": 1}, {multi: true}
      ..then ->
        log.debug "Updated #{ids.length} ids for event type #type."

  prepare: (start, end) ->
    now = Date.now!
    start = start or moment now .subtract 10 'minutes'
    end = end or moment now .add 50 'minutes'
    blanks = get-blanks start, end
    log.info "Preparing #{blanks.length} entries to add"

    Promise.map blanks, aggregate.prepare-one, concurrency: 5
      .then (blanks) ->
        added = blanks.filter (blank) -> blank
        log.info "Added #{added.length} entries in #{Date.now! - now}ms"
      .catch (e) ->
        log.error 'Error preparing entries' e

  prepare-one: (blank) ->
    model.find-one-async {_id: blank._id} .then (entry) ->
      if entry? then false else model.save-async blank
}
