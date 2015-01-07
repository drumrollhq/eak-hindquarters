if (process.env.NR_ENABLED) {
  require('newrelic');
}

require('LiveScript');
require('./app').start();
