require! {
  '../../../lib/errors'
  '../../utils': {filtered-import}
  'bluebird': Promise
  'checkit'
  'prelude-ls': {empty}
}

export handler = ({models: {User, AuthedAction}, body, user, config, session}) ->
  data = filtered-import body.{id, first-name, assume-adult, username, password, password-confirm, email, gender, subscribed-newsletter}
  if data.id? and data.id is user.id
    user = user.fetch with-related: <[oauths]>
      .then (user) -> user.set data
  else
    user = Promise.resolve User.forge data

  user
    .tap (user) -> user.validate role: if empty user.related \oauths then <[full password]> else \full
    .then (user) ->
      user
        .set \status if user.get \verifiedEmail then \active else \pending
        .save!
    .tap (user) ->
      if user.get \verifiedEmail
        # send welcome email
        user.send-mail \eak-normal-welcome
      else
        # Send verify + welcome email
        AuthedAction.create user, \verify-email
          .then (key) ->
            template = if user.adult! then \eak-normal-confirm-email else \eak-parent-confirm-email
            user.send-mail template, confirm: "#{config.APP_ROOT}/v1/action/verify-email/#{key}"
    .then (user) ->
      session.passport = user: user.id
      user.to-safe-json!
    .catch checkit.Error, (err) -> errors.checkit-error err
