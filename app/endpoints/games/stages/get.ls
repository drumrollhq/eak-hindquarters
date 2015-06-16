require! 'joi'

export use = 'auth.logged-in'

export params = [
  [\game-id joi.number!.integer!.positive!]
  [\stage-id joi.number!.integer!.positive!]
]

export handler = ({params: {game-id, stage-id}, models: {Stage}, user, errors}) ->
  Stage
    .query (qb) ->
      qb.select 'game.user_id' .join \game, 'game.id' '=' 'stage.game_id' .where {
        'game.id': game-id
        'stage.id': stage-id
      }
    .fetch!
    .then (stage) ->
      unless stage? then return errors.not-found 'stage not found'
      unless user.id is stage.get \userId then return errors.unauthorized 'You can only access stages on your own games'
      stage

