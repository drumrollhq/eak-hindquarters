require! 'joi'

export body = joi.object!

export handler = ({params: {game-id}, endpoints: {games}, user, body}) ->
  games.get game-id, {active-stage: false}, {user}
    .then (game) ->
      game.patch-state body
