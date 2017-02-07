if (process.env.NR_ENABLED) {
  require('newrelic');
}

require('LiveScript');
require('babel-core/register');
require('babel-polyfill');

global.Promise = require('bluebird');
var config = require('./config');
module.exports = require('./lib').start(config, __dirname);
