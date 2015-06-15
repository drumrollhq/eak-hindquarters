if (process.env.NR_ENABLED) {
  require('newrelic');
}

require('LiveScript');

var config = require('./config');
module.exports = require('./lib').start(config, __dirname);
global.Promise = require('bluebird');
