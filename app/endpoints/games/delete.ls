export params = use: \games.get

export handler = ({params: {game-id}, endpoints: {games}, user}) ->
  games.get game-id, {active-stage: false}, {user}
    .then (game) ->
      attrs = game.to-json!
      game.destroy!
        .then -> deleted: true, game: attrs
