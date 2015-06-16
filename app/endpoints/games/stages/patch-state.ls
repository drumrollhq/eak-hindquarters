require! 'joi'

export body = joi.object!

export handler = ({params: {game-id, stage-id}, endpoints: {games}, body, user}) ->
  games.stages.get game-id, stage-id, {user}
    .then (stage) -> stage.patch-state body
