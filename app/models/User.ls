require! {
  'fs'
  'prelude-ls': {reject, empty, capitalize}
}

adjectives = fs.read-file-sync "#{__dirname}/../../data/adjectives.txt" encoding: 'utf-8'
  .split '\n' |> reject empty
nouns = fs.read-file-sync "#{__dirname}/../../data/nouns.txt" encoding: 'utf-8'
  .split '\n' |> reject empty

random = (arr) -> arr[Math.floor arr.length * Math.random!]

module.exports = (orm, db) ->
  User = orm.Model.extend {
    table-name: 'users'
    id-attribute: 'id'
  }, {
    username: -> "#{capitalize random adjectives}#{capitalize random nouns}#{Math.floor 100 * Math.random!}"

    unused-username: ->
      username = User.username!
      User.exists username
        .then ({exists}) -> if exists then User.unused-username! else username

    exists: (user-id) ->
      spec = switch (typeof user-id)
      | 'number' => id: user-id
      | 'string' => (if (user-id.index-of '@') isnt -1 then email: user-id else username: user-id)
      | 'object' => user-id

      if spec.username then spec.username .= trim!.to-lower-case!
      if spec.email then spec.email .= trim!.to-lower-case!

      db.first 'id'
        .from 'users'
        .where spec
        .then (row) -> exists: !!row
  }
