require! 'joi'

export body = joi.object!.keys {
  activate: joi.boolean!.default false
  levels: joi.array!.items joi.object!.keys {
    url: joi.string!.required!
    state: joi.object!.default {}
    html: joi.string!.optional!
  }
  url: joi.string!.required!
  type: joi.string!.required!
  state: joi.object!.default {}
}

export params = use: \games.get

export handler = ({params: {game-id}, endpoints: {games}, models: {Stage, Level}, body, user}) ->
  find-or-create-level = (stage, level-data) ->
    Level.forge {url: level-data.url, stage-id: stage.id} .fetch!
      .then (level) ->
        if level then return level
        level-data.stage-id = stage.id
        Level.forge level-data
          .save!

  find-or-create-levels = (stage, levels) ->
    Promise.map levels, (level) -> find-or-create-level stage, level

  var game
  activate = body.activate
  levels = body.levels

  games.get game-id, {active-stage: false}, {user}
    .then (g) ->
      game := g
      body.game-id = game-id
      Stage.forge body.{game-id, url, type} .fetch!
    .then (stage) ->
      if stage is null
        Stage.forge body.{game-id, url, type, state} .save!
      else stage
    .then (stage) ->
      Promise.all [
        stage
        if levels then find-or-create-levels stage, levels
        if activate then game.save {active-stage: stage.id}, patch: true
      ]
    .spread (stage, levels) ->
      resp = stage.to-json!
      if levels then resp.levels = levels.map (.to-json!)
      resp
