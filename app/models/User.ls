require! {
  'fs'
  'prelude-ls': {reject, empty, capitalize}
}

adjectives = fs.read-file-sync "#{__dirname}/../../data/adjectives.txt" encoding: 'utf-8'
  .split '\n' |> reject empty
nouns = fs.read-file-sync "#{__dirname}/../../data/nouns.txt" encoding: 'utf-8'
  .split '\n' |> reject empty

random = (arr) -> arr[Math.floor arr.length * Math.random!]

module.exports = (orm, db, models, BaseModel) ->
  class User extends BaseModel
    has-timestamps: true
    table-name: 'user'
    id-attribute: 'id'

    formatters:
      trim: <[email username first_name last_name]>
      lower: <[email username]>

    oauths: -> @has-many models.OAuth

    adult: -> @get 'assumeAdult'

    @username = -> "#{capitalize random adjectives}#{capitalize random nouns}#{Math.floor 100 * Math.random!}"

    @unused-username = ->
      username = User.username!
      User.exists username
        .then ({exists}) -> if exists then User.unused-username! else username

    @get-id-spec = (user-id) ->
      spec = switch (typeof user-id)
      | 'number' => id: user-id
      | 'string' => (if (user-id.index-of '@') isnt -1 then email: user-id else username: user-id)
      | 'object' => user-id

      if spec.username then spec.username .= trim!.to-lower-case!
      if spec.email then spec.email .= trim!.to-lower-case!

      spec

    @exists = (user-id) ->
      db.first 'id'
        .from User::table-name
        .where User.get-id-spec user-id
        .then (row) -> exists: !!row

    @find = (user-id) ->
      User.forge User.get-id-spec user-id
