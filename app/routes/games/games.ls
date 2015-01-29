require! {
  '../../errors'
}

module.exports = (models, store, config) ->
  {Game} = models

  for-user: (id) ->
    Game.for-user id .then ( .to-JSON! )

  create: (user-id, {active-area, name, state = {}}) ->
    Game.forge {user-id, active-area, name, state} .save!

  get: (user-id, id) ->
    Game.where {id, user_id: user-id} .fetch with-related: <[activeArea]> .then (game) ->
      unless game? then return errors.not-found 'game not found'
      g = game.to-json!
      if g.active-area? then g.active-area = game.related 'activeArea' .to-json!
      g
