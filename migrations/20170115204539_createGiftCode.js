exports.up = function(knex, Promise) {
  return knex.schema.createTable('gift_code', function (table) {
    table.increments('id').index();
    table.string('code').notNullable().unique().index();
    table.integer('purchased_by').notNullable().index().references('user.id');
    table.integer('redeemed_by').index().references('user.id');
    table.timestamps();
  });
};

exports.down = function(knex, Promise) {
  return knex.schema.dropTable('gift_code');
};
