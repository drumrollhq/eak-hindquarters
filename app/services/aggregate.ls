require! {
  'bluebird': Promise
  'moment'
}

var log, model, store

types = <[session kitten death edit level cutscene skip action incompatible finish page minigame]>
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

export setup = ({store: s, log: l}) ->
  log := l
  store := s
  log.debug 'setting up'
  store.collection-async \aggregate
    .then (m) ->
      model := m
      set-interval prepare, 1000ms * 60s * 30m
      prepare!
    .then -> log.debug 'setup complete'

export add-event = (type, timestamp = Date.now!) ->
  if type not in types then throw new Error "Type #type is not allowed!"

  now = moment timestamp
  ids = relevant-aggregate-ids now
  model.update-async {_id: $in: ids}, {$inc: "#type": 1}, {multi: true}
    ..then ->
      log.debug "Updated #{ids.length} ids for event type #type."

export prepare = (start, end) ->
  now = Date.now!
  start = start or moment now .subtract 10 'minutes'
  end = end or moment now .add 50 'minutes'
  blanks = get-blanks start, end
  log.debug "Preparing #{blanks.length} entries to add"

  Promise.map blanks, prepare-one, concurrency: 5
    .then (blanks) ->
      added = blanks.filter (blank) -> blank
      log.info "Added #{added.length} entries in #{Date.now! - now}ms"
    .catch (e) ->
      log.error 'Error preparing entries' e

prepare-one = (blank) ->
  model.find-one-async {_id: blank._id} .then (entry) ->
    if entry? then false else model.save-async blank
