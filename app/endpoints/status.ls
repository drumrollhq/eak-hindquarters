require! {
  '../../version-info.js'
  'moment'
  'os'
}

start = Date.now!
packaged = new Date version-info.packaged * 1000
host = os.hostname!

export handler = ->
  d = moment.duration Date.now! - start
  {tag, hash} = version-info
  {
    tag, hash, packaged, host,
    uptime: "#{d.days!}:#{d.hours!}:#{d.minutes!}:#{d.seconds!}"
  }
