require! 'joi'

export body = joi.object!
export params = use: \games.levels.get

export handler = ({params: {game-id, level-id}, endpoints: {games}, body, user}) ->
  games.levels.get game-id, level-id, {}, {user}
    .then (level) -> level.patch-state body
