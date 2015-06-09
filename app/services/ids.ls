# generate phonetic ids from numbers:
# We use all the vowels. Consonants are chosen for pronounceability and to
# reduce the risk of naughty words (in english, at least). Words are created
# by alternating consonants and vowels. Every positive integer maps on to one
# of the words.

const vowels = 'aeiou'
const consonants = 'bdklmnrsvwy'
const default-bases = [consonants, vowels]

var store, log

num-to-char = (n, alphabet) -> alphabet[n]

get-length = (n, bases) ->
  exp = bases.0.length
  i = 1
  while exp < n
    exp = exp * bases[i % bases.length].length
    i++
  i

get-exp = (len, bases) ->
  if len is 0 then return 1
  exp = bases.0.length
  i = 1
  while i < len
    exp = exp * bases[i % bases.length].length
    i++
  exp

export setup = ({store: s, log: l}) ->
  store := s
  log := l

export generate = (n, bases = default-bases) ->
  n = n + bases[0].length
  length = get-length n, bases
  out = []
  for i from 0 to length
    d = length - i
    exp = get-exp d, bases
    digit = Math.floor n / exp
    unless digit is 0 and out.length is 0
      out.unshift num-to-char digit, bases[d % bases.length]
      n -= digit * exp

  out.join ''

export get-unique = (type) ->
  store
    .collection 'idCounters'
    .find-and-modify-async(
      { _id: type },
      [['_id' 'asc']],
      { $inc: {count: 1}},
      { new: true, upsert: true })
    .spread (counter) ->
      id = generate counter.count
      log.debug "Created ID #type##{counter.count} -> #id"
      id
