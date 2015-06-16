require! 'joi'

export use = 'auth.logged-in'

export body = joi.object!.keys {
  game: joi.object!
}

export handler = ({body, user, models: {Game}}) ->
  Game
    .forge user-id: user.id, state: body.{}game.{}state
    .save!
    .then (game) -> game: game.to-json!
