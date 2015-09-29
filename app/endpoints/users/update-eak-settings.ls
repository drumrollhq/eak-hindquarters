require! 'joi'

export use = 'users.user-id': {fetch: true}

export body = joi.object!

export handler = ({user, body}) ->
  current-settings = user.get \eakSettings
  new-settings = {} <<< current-settings <<< body
  user.save eak-settings: new-settings, {patch: true}
    .then (user) -> user.get \eakSettings
