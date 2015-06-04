process.env.NODE_ENV = 'test';
require('LiveScript');

var config = require('../config');
// Force stripe to use a bad key as all stripe stuff here should be mocked:
config.STRIPE_KEY = 'unit-test';

var app = require('../app'),
  models = require('../app/models'),
  store = require('../app/store'),
  stripe = require('../app/stripe'),
  Mocha = require('mocha'),
  chai = require('chai'),
  sinon = require('sinon'),
  sinonChai = require('sinon-chai'),
  bluebird = require('bluebird'),
  chaiAsPromised = require('chai-as-promised'),
  glob = require('glob');

chai.use(sinonChai);
chai.use(chaiAsPromised);
chai.should();
global.expect = chai.expect;
global.sinon = sinon;
global.store = store;
global.models = models;
global.stripe = stripe;
global.config = config;
global.Promise = bluebird;

var mocha = new Mocha({
  ui: 'bdd',
  reporter: config.MOCHA_REPORTER || 'spec',
  growl: true
});

glob.sync(__dirname + '/**/*.ls').forEach(mocha.addFile.bind(mocha));

console.log('Dropping tables owned by', config.DB_USER);
models.db.raw('DROP OWNED BY ' + config.DB_USER)
  .then(clearStore)
  .then(app.start)
  .then(function() {
    mocha.run(process.exit);
  })
  .catch(function(e) {
    console.error(e);
    process.exit(1);
  });

function clearStore() {
  console.log('Clearing mongo');
  return store.collectionNamesAsync(null, {namesOnly: true})
    .map(function(name) {
      if (typeof name === 'object') name = name.name;
      name = name.replace(store._native.databaseName + '.', '');
      if (name.indexOf('system') === 0) return;
      return store.dropCollectionAsync(name);
    });
}
