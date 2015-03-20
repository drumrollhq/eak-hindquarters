var git = require('git-rev');

module.exports = {
  tag: 'dev',
  hash: 'abc123',
  packaged: Date.now() / 1000 | 0,
};

git.long(function(hash) {
  module.exports.hash = hash;
});

git.tag(function(tag) {
  module.exports.tag = tag;
});
