require! {
  '../../lib/errors'
  'bcrypt'
  'bluebird': Promise
  'crypto'
  'prelude-ls': {split, head, tail, join}
}

Promise.promisify-all crypto
Promise.promisify-all

const expire-time = 1000ms * 60s * 60m * 24h * 30d

module.exports = (orm, db, models, BaseModel, log) ->
  class AuthedAction extends BaseModel
    has-timestamps: true
    table-name: 'authed_action'
    id-attribute: 'id'

    user: -> @belongs-to models.User

    check-key: (key = '') ->
      bcrypt.compare-async key, @get 'digest'
        .then (res) ~>
          unless res then errors.bad-request 'Invalid hash key' else this

    use: ->
      @save {used: true}, {patch: true}

    @create-key = ->
      crypto.random-bytes-async 24 .then (bytes) -> bytes.to-string 'base64'

    @hash-key = (key) ->
      bcrypt.gen-salt-async 8
        .then (salt) -> bcrypt.hash-async key, salt

    @encode = (id, key) ->
      new Buffer "#{id}:#{key}" .to-string 'base64' |> AuthedAction.clean-key

    @decode = (str) ->
      str = AuthedAction.restore-key str
      parts = new Buffer str, 'base64' .to-string! |> split ':'
      id = head parts
      key = parts |> tail |> join ':'
      {id, key}

    @clean-key = (key) ->
      key
        .replace /\=*$/ '' # Remove trailing equals
        .replace /\//g '-' # Change / to -
        .replace /\+/g '.' # Change + to .

    @restore-key = (key) -> key.replace /\-/g '/' .replace /\./g '+'

    @create = (user, action, args = {}) ->
      AuthedAction.create-key! .then (key) ->
        AuthedAction.hash-key key
          .then (hash) ->
            AuthedAction
              .forge user-id: user.id, digest: hash, action: action, args: args, used: false
              .save!
          .then (action) ->
            AuthedAction.encode action.id, key

    @use = (key) ->
      {id, key} = AuthedAction.decode key
      AuthedAction
        .where id: id, used: false
        .where 'created_at', '>', new Date Date.now! -  expire-time
        .fetch with-related: 'user'
        .then (action) -> unless action? then return errors.not-found 'No such action' else action
        .then (action) -> action.check-key key
        .then (action) -> action.use!
        .then (action) -> action: (action.get 'action'), args: (action.get 'args'), user: (action.related 'user')
