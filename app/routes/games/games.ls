require! {
  '../../errors'
  'bluebird': Promise
}

module.exports = games = (models, store, config) ->
  {Game, Stage, Level} = models

  find-or-create-level = (stage, level-data) ->
    Level.forge {url: level-data.url, stage-id: stage.id} .fetch!
      .then (level) ->
        if level then return level
        level-data.stage-id = stage.id
        Level.forge level-data .save!

  find-or-create-levels = (stage, levels) ->
    Promise.map levels, (level) -> find-or-create-level stage, level

  for-user: (id, limit) ->
    Game
      .for-user id, limit: limit
      .then ( .to-JSON! )

  create: (user-id, {game = {}}) ->
    game-model = null

    Game.forge user-id: user-id, state: (game.state or {}) .save!
      .then (game-model) -> {game: game-model.to-json!}

  get: (user-id, id, options) ->
    related = <[activeStage]>
    if options.stages then related[*] = \stages
    if options.levels then related[*] = \activeStage.levels
    if options.stages and options.levels then related[*] = \stages.levels

    Game.where {id, user_id: user-id} .fetch with-related: related .then (game) ->
      unless game? then return errors.not-found 'game not found'
      game.to-json!

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
    levels = stage-data.levels
    delete stage-data.activate
    delete stage-data.levels

    game = null
    Game.forge {id: game-id, user-id} .fetch!
      .then (g) ->
        unless g? then return errors.not-found 'game not found'
        game := g
      .then ->
        stage-data.game-id = game-id
        Stage.forge stage-data.{game-id, url, type} .fetch!
      .then (stage-model) ->
        if stage-model is null
          Stage.forge stage-data .save!
        else stage-model
      .then (stage) ->
        Promise.all [
          stage
          if levels then find-or-create-levels stage, levels
          if activate then game.save {active-stage: stage.id}, patch: true
        ]
      .spread (stage, levels) ->
        resp = stage.to-json!
        if levels then resp.levels = levels.map ( .to-json! )
        resp
