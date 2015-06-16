process.env.NODE_ENV = 'test';
require('LiveScript');

var config = require('../config');
// Force stripe to use a bad key as all stripe stuff here should be mocked:
config.STRIPE_KEY = 'unit-test';

var knex = require('knex'),
  mongoskin = require('mongoskin'),
  Mocha = require('mocha'),
  chai = require('chai'),
  sinon = require('sinon'),
  sinonChai = require('sinon-chai'),
  Promise = require('bluebird'),
  chaiAsPromised = require('chai-as-promised'),
  glob = require('glob');

chai.use(sinonChai);
chai.use(chaiAsPromised);
chai.should();
global.expect = chai.expect;
global.sinon = sinon;

var mocha = new Mocha({
  ui: 'bdd',
  reporter: config.MOCHA_REPORTER || 'spec',
  growl: true
});

glob.sync(__dirname + '/**/*.ls').forEach(mocha.addFile.bind(mocha));

var db = knex({
  client: 'pg',
  connection: {
    host: config.DB_HOST,
    port: config.DB_PORT,
    user: config.DB_USER,
    password: config.DB_PW,
    database: config.DB_NAME,
    ssl: config.DB_SSL
  }
});

db.raw('DROP OWNED BY ' + config.DB_USER)
  .then(clearStore)
  .then(function() {
    return require('../server.js');
  })
  .then(function(ctx) {
    global.ctx = ctx;
    mocha.run(process.exit);
  })
  .catch(function(e) {
    console.error(e);
    process.exit(1);
  });

function clearStore() {
  console.log('Clearing mongo');
  var store = Promise.promisifyAll(mongoskin.db(config.MONGO_URL, {safe: true, auto_reconnect: true}));
  return store.collectionNamesAsync(null, {namesOnly: true})
    .map(function(name) {
      if (typeof name === 'object') name = name.name;
      name = name.replace(store._native.databaseName + '.', '');
      if (name.indexOf('system') === 0) return;
      return store.dropCollectionAsync(name);
    });
}
