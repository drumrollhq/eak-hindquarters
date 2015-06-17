require! 'joi'

export body = joi.object!
export params = use: \games.stages.get

export handler = ({params: {game-id, stage-id}, endpoints: {games}, body, user}) ->
  games.stages.get game-id, stage-id, {user}
    .then (stage) -> stage.patch-state body
