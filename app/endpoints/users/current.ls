export handler = ({user, session, errors, models: {User}}) ->
  if user?
    user.fetch with-related: <[oauths]>, require: true
      .then (user) -> {logged-in: true, user: user.to-safe-json!, device: session.device-id}
      .catch User.NotFoundError, -> errors.unauthorized 'Your user does not exist'
  else
    {logged-in: false, device: session.device-id}
