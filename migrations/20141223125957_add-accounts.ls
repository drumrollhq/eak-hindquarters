exports.up = (knex, Promise) ->
  knex.schema.create-table 'user' (table) ->
    table.increments 'id' .index!
    table.enum 'status' <[creating pending active deactivated]>
    table.string 'username' .index! .unique!
    table.string 'email' .index! .unique!
    table.string 'password_digest'
    table.string 'remember_digest'
    table.string 'first_name'
    table.string 'last_name'
    table.date 'date_of_birth'
    table.enum 'gender' <[male female other]>
    table.boolean 'subscribed_newsletter'
    table.timestamps!

exports.down = (knex, Promise) ->
  knex.schema.drop-table 'user'
