require! {
  'bcrypt'
  'bluebird': Promise
  'fs'
  'prelude-ls': {reject, empty, capitalize}
}

Promise.promisify-all bcrypt

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

    cast:
      subscribed-newsletter: 'boolean'

    validations:
      full:
        first-name: <[required]>
        username:
          * rule: \required
            message: 'You\'ve got to list a username! Please?'
          * rule: \alphaNumeric
            message: 'Hey! Letters and numbers only in your username.'
          * rule: \unique
            params: <[user username trim lower]>
            message: 'Some one has already taken that username. How could they?'
        email:
          * rule: \required
            message: 'You need to enter an email I\'m afraid :/'
          * rule: \email
            message: 'That email address... doesn\'t look like an email address'
          * rule: \unique
            params: <[user email trim lower]>
            message: 'Some one has already taken that email! How dare they!'
      password:
        password:
          * rule: \required
            message: 'You gotta come up with a password! DO IT!'
          * rule: \minLength
            params: <[4]>
            message: 'You can do better than that! A longer password, please!'
        password-confirm:
          * rule: 'required'
            message: 'Confirm your password. Or else.'
          * rule: 'matchesField'
            params: <[password]>
            message: 'Your confirmation doesn\'t match your password! FIX IT FIX IT FIX IT!'

    oauths: -> @has-many models.OAuth

    adult: -> @get 'assumeAdult'

    hash-password: ->
      pw = @get 'password'
      unless pw then return Promise.resolve @get 'passwordDigest'
      @unset 'password'
      @unset 'passwordConfirm'

      bcrypt.gen-salt-async 10
        .then (salt) -> bcrypt.hash-async pw, salt
        .tap (hash) ~> @set 'passwordDigest', hash

    save: ->
      sup = super
      args = arguments
      @hash-password!
        .tap ~> console.log @to-JSON!
        .then ~> sup.apply @, args

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
