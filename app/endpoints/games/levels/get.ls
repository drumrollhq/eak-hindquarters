require! 'joi'

export use = 'auth.logged-in'

export params = [
  [\game-id joi.number!.integer!.positive!]
  [\level-id joi.number!.integer!.positive!]
]

export options = joi.object!.keys {
  stage: joi.boolean!.default false
  game: joi.boolean!.default false
}

export handler = ({params: {game-id, level-id}, models: {Level}, options, user, errors}) ->
  related = []
  if options.stage then related[*] = \stage
  if options.game then related[*] = \game

  Level
    .query (qb) ->
      qb.select 'game.user_id'
        .join \stage, 'stage.id' '=' 'level.stage_id'
        .join \game, 'game.id' '=' 'stage.game_id'
        .where {
          'game.id': game-id
          'level.id': level-id
        }
    .fetch with-related: related
    .then (level) ->
      unless level? then return errors.not-found 'Level not found'
      unless user.id is level.get \userId then errors.unauthorized 'You can only access levels from you own games'
      level
