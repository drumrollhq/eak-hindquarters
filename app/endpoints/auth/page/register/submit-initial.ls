export page = true

export handler = ({models: {User}, body, render, http, session}) ->
  first-name = body.first-name
  assume-adult = body.over-thirteen
  unless first-name then err = 'You need to tell us your name!'
  unless assume-adult then err ?= 'You need to say whether or not you\'re over thirteen!'
  if err then return render 'users/register', {err}

  user = new User {first-name, assume-adult, status: \creating}
    .save!
    .then (user) ->
      session.passport = user: user.id
      http.redirect '/v1/auth/register/manual'
