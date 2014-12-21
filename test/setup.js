process.env.NODE_ENV = 'test';
require('LiveScript');

var config = require('../config'),
  app = require('../app'),
  models = require('../app/models'),
  store = require('../app/store'),
  Mocha = require('mocha'),
  supertest = require('supertest'),
  expect = require('chai').expect,
  glob = require('glob');

var api = supertest('http://localhost:' + config.PORT);
global.api = api;
global.expect = expect;
global.store = store;
global.models = models;
global.config = config;

var mocha = new Mocha({
  ui: 'bdd',
  reporter: 'nyan'
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
      name = name.replace(store._native.databaseName + '.', '');
      if (name.indexOf('system') === 0) return;
      return store.dropCollectionAsync(name);
    });
}
