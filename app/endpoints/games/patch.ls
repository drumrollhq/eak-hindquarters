require! 'joi'

export body = joi.object!.keys {
  name: joi.string!
  active-stage: joi.number!.integer!.positive!
}

export params = use: \games.get

export handler = ({params: {game-id}, models: {Game}, endpoints: {games}, user, body}) ->
  games.get game-id, {active-stage: false}, {user}
    .then (game) ->
      game.save body, patch: true
