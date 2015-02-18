require! {
  '../../errors'
}

module.exports = (models, store, config) ->
  {Game, Area} = models

  for-user: (id, limit) ->
    Game
      .for-user id, limit: limit
      .then ( .to-JSON! )

  create: (user-id, {game = {}, area = {}}) ->
    game-model = area-model = null

    Game
      .forge user-id: user-id, state: (game.state or {}), active-area: (game.active-area or null)
      .save!
      .then (model) ->
        game-model := model
        Area
          .forge game-id: game-model.id, url: area.url, type: area.type, state: (game.state or {})
          .save!

      .then (model) ->
        area-model := model
        game-model.save {active-area: area-model.id}, patch: true

      .then (game-model) -> {game: game-model.to-json!, area: area-model.to-json!}


  get: (user-id, id) ->
    Game.where {id, user_id: user-id} .fetch with-related: <[activeArea]> .then (game) ->
      unless game? then return errors.not-found 'game not found'
      g = game.to-json!
      if g.active-area? then g.active-area = game.related 'activeArea' .to-json!
      g

  delete: (user-id, id) ->
    Game.where {id}
      .fetch!
      .then (game) ->
        unless game? then return errors.not-found 'That game doesn\'t exist!'
        if user-id isnt game.get \userId then return errors.forbidden 'That\'s not your game! You\'re not allowed to delete it!'
        attrs = game.to-json!
        game.destroy! .then -> deleted: true, game: attrs

  patch: (user-id, id, body) ->
    Game.where {id}
      .fetch!
      .then (game) ->
        unless game? then return errors.not-found 'That game doesn\'t exist!'
        if user-id isnt game.get \userId then return errors.forbidden 'That\'s not your game! You\'re not allowed to updated it!'
        game.save body, patch: true
