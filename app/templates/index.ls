require! {
  'glob'
  'marko'
  'prelude-ls': {pairs-to-obj}
}

templates = glob.sync __dirname + '/**/*.marko' .map (f) -> [
  f.replace __dirname + '/', '' .replace /\.marko$/, ''
  marko.load f
]

module.exports = pairs-to-obj templates
