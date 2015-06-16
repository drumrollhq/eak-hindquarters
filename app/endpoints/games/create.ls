require! 'joi'

export use = 'auth.logged-in'

export body = joi.object!.keys {
  state: joi.object!.default {}
}

export handler = ({body, user, models: {Game}}) ->
  Game
    .forge user-id: user.id, state: body.state
    .save!
    .then (game) -> game: game.to-json!
