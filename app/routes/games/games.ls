require! {
  '../../errors'
}

module.exports = games = (models, store, config) ->
  {Game, Stage} = models

  for-user: (id, limit) ->
    Game
      .for-user id, limit: limit
      .then ( .to-JSON! )

  create: (user-id, {game = {}, stage = {}}) ->
    game-model = stage-model = null

    Game
      .forge user-id: user-id, state: (game.state or {}), active-stage: (game.active-stage or null)
      .save!
      .then (model) ->
        game-model := model
        Stage
          .forge game-id: game-model.id, url: stage.url, type: stage.type, state: (game.state or {})
          .save!

      .then (model) ->
        stage-model := model
        game-model.save {active-stage: stage-model.id}, patch: true

      .then (game-model) -> {game: game-model.to-json!, stage: stage-model.to-json!}


  get: (user-id, id, options) ->
    related = <[activeStage]>
    if options.stages then related[*] = \stages

    Game.where {id, user_id: user-id} .fetch with-related: related .then (game) ->
      unless game? then return errors.not-found 'game not found'
      g = game.to-json!
      if g.active-stage? then g.active-stage = game.related 'activeStage' .to-json!

      if options.stages
        console.log game.related \stages
        g.stages = game.related \stages .to-JSON!
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

  find-or-create-stage: (user-id, game-id, stage-data) ->
    activate = stage-data.activate or false
    delete stage-data.activate

    game = null
    Game.forge {id: game-id, user-id} .fetch!
      .then (g) ->
        unless g? then return errors.not-found 'game not found'
        game := g
      .then ->
        stage-data.game-id = game-id
        Stage.forge stage-data .fetch!
      .then (stage-model) ->
        if stage-model is null
          Stage.forge stage-data .save!
        else stage-data
      .tap (stage) ->
        if activate then game.save {active-stage: stage.id}, patch: true
      .then (stage) -> stage.to-json!
