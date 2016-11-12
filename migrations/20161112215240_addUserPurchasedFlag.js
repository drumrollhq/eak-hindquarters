exports.up = function(knex, Promise) {
  return knex.schema.table('user', function (table) {
    table.boolean('purchased').defaultTo(false);
  });
};

exports.down = function(knex, Promise) {
  return knex.schema.table('user', function (table) {
    table.dropColumn('purchased');
  });
};
