require! 'joi'

export use = 'auth.logged-in'

id = joi.alternatives!.try joi.string!, joi.number!.integer!

export body = joi.object!.keys {
  game: joi.object!.keys {
    id: id
    active-stage: id.optional!
    created-at: joi.date!.optional!
    updated-at: joi.date!.optional!
    user-id: id.optional!
    state: joi.object!.optional! .default {}
  }
  stages: joi.array!.items joi.object!.keys {
    id: id
    game-id: id
    type: joi.string!
    url: joi.string!
    state: joi.object!.optional! .default {}
  }
  levels: joi.array!.items joi.object!.keys {
    id: id
    stage-id: id
    url: joi.string!
    state: joi.object!.optional! .default {}
  }
}

export handler = ({body, user, models: {Game, Stage, Level}}) ->
  var stages, levels

  id-map = {}
  game = body.game.{name, state}
  game.user-id = user.id

  Game
    .forge game
    .save!
    .then (saved-game) ->
      id-map[body.game.id] = saved-game.id
      game := saved-game
      stages = body.stages.map (stage) -> {game-id: id-map[stage.game-id], stage.type, stage.url, stage.state}

      Promise.all(Stage.Collection.forge stages .invoke \save)
    .then (saved-stages) ->
      stages := saved-stages
      for stage, i in stages => id-map[body.stages[i].id] = stage.id

      levels = body.levels.map (level) -> {stage-id: id-map[level.stage-id], level.url, level.state}

      level-pr = Promise.all(Level.Collection.forge levels .invoke \save)
      active-stage-pr = if body.game.active-stage
        game.save {active-stage: id-map[body.game.active-stage]}, patch: true
      else null

      Promise.all [level-pr, active-stage-pr]
    .then ->
      Game
        .where {id: game.id, user_id: user.id}
        .fetch with-related: ['stages' 'stages.levels']

