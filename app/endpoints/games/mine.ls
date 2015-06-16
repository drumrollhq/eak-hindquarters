require! 'joi'

export use = 'auth.logged-in'

export options = joi.object!.keys {
  limit: joi.number!.integer!.positive!
}

export handler = ({user, options, models: {Game}}) ->
  Game.for-user user.id, options
    .then ( .to-JSON! )
