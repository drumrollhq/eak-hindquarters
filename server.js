if (process.env.NR_ENABLED) {
  require('newrelic');
}

require('LiveScript');

var config = require('./config');
require('./lib').start(config, __dirname);

var util = require('util');
