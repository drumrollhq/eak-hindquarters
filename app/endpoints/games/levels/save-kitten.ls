require! 'joi'

export body = joi.object!.keys {
  kitten: joi.string!.required!
}

export handler = ({params: {game-id, level-id}, endpoints: {games}, body, user}) ->
  games.levels.get game-id, level-id, {game: true}, {user}
    .then (level) ->
      game = level.related \game
      Promise.all [
        game.update-state (state) -> if state.kitten-count then state.kitten-count += 1 else state.kitten-count = 1
        level.update-state (state) -> state.{}kittens[body.kitten] = new Date!
      ]
    .spread (game, level) -> {
      total: game.get 'state' .kitten-count
      level: level.get 'state'
    }
