require('LiveScript');
config = require('./config');

var conn = {
  client: 'pg',
  connection: {
    host: config.DB_HOST,
    port: config.DB_PORT,
    user: config.DB_USER,
    password: config.DB_PW,
    database: config.DB_NAME,
    ssl: config.DB_SSL
  },
  migrations: {
    tableName: '_migrations',
    extension: 'ls',
    directory: './migrations',
    database: config.DB_NAME
  }
}

module.exports = {
  development: conn,
  staging: conn,
  production: conn
};
