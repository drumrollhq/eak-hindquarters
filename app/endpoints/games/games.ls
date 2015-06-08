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

  save-kitten: (user-id, game-id, level-id, kitten-id) ->
    game = null
    Game.forge {id: game-id, user-id} .fetch!
      .then (g) ->
        unless g? then return errors.not-found 'game not found'
        game := g
        Level
          .query (qb) ->
            qb.join 'stage', 'level.stage_id' '=' 'stage.id'
              .where 'stage.game_id' '=' game-id
              .andWhere 'level.id' '=' level-id
          .fetch!
      .then (level) ->
        unless level? then return errors.not-found 'level not found'
        Promise.all [
          game.update-state (state) -> if state.kitten-count then state.kitten-count += 1 else state.kitten-count = 1
          level.update-state (state) -> state.{}kittens[kitten-id] = new Date!
        ]
      .spread (game, level) -> {
        total: game.get 'state' .kitten-count
        level: level.get 'state'
      }

  patch-stage-state: (user-id, game-id, stage-id, patch) ->
    Stage
      .query (qb) ->
        qb.join \game, 'game.id' '=' 'stage.game_id'
          .where {
            'game.user_id': user-id
            'game.id': game-id
            'stage.id': stage-id
          }
      .fetch!
      .then (stage) ->
        unless stage? then return errors.not-found 'stage not found'
        stage.patch-state patch

  patch-level-state: (user-id, game-id, level-id, patch) ->
    Level
      .query (qb) ->
        qb.join \stage, 'stage.id' '=' 'level.stage_id'
          .join \game, 'game.id' '=' 'stage.game_id'
          .where {
            'game.user_id': user-id
            'game.id': game-id
            'level.id': level-id
          }
      .fetch!
      .then (level) ->
        unless level? then return error.not-found 'Level not found'
        level.patch-state patch
