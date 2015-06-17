require! 'joi'

export body = joi.object!.keys {
  username: joi.string!.trim!.required!
  password: joi.string!.required!
}

export http-only = true
export handler = ({errors, body, session, models: {User}}) ->
  User.find body.username
    .fetch!
    .tap (user) ->
      if user is null
        errors.not-found "Oh no! We don't seem to have a #{body.username}. Try signing up!"
      else
        user.check-password body.password
    .then (user) ->
      session.passport = user: user.id
      {logged-in: true, user: user.to-safe-json!}
