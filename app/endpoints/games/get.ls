require! 'joi'

# export use = 'auth.logged-in'

export params = [[\game-id, joi.number!.integer!.positive!]]

export options = joi.object!.keys {
  stages: joi.boolean!.default false
  levels: joi.boolean!.default false
  active-stage: joi.boolean!.default true
}

export handler = ({params: {game-id}, options, models: {Game}, user, errors}) ->
  related = []
  if options.active-stage then related[*] = \activeStage
  if options.stages then related[*] = \stages
  if options.levels then related[*] = \activeStage.levels
  if options.stages and options.levels then related[*] = \stages.levels

  Game.where {id: game-id, user_id: user.id} .fetch with-related: related
    .tap (game) -> unless game? then return errors.not-found 'game not found'
