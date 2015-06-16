require! 'joi'

export middleware = true

export use = 'auth.logged-in'

export params = [
  [\user-id, joi.alternatives!.try(joi.number!.integer!.positive!, joi.string!)]
]

export handler = ({params: {user-id}, models: {User}, user: req-user, errors}, options = {}) ->
  user = if user-id is \me then req-user else User.find user-id

  fetch-options = require: true, with-related: options.with-related
  user.fetch fetch-options
    .tap (user) ->
      unless options.allow-any-user
        if user.id isnt req-user.id
          return errors.forbidden 'You can only access your own user'
    .then (user) -> {user, req-user}
    .catch User.NotFoundError, -> errors.not-found "User '#user-id' does not exist"
