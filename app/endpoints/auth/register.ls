require! {
  '../../../lib/errors'
  '../../utils': {filtered-import}
  'bluebird': Promise
  'checkit'
  'joi'
  'prelude-ls': {empty}
}

export body = joi.object!.unknown true .keys {
  id: joi.number!.integer!.positive!.optional!
  first-name: joi.string!.trim!.min 2 .required!
  last-name: joi.string!.trim!.min 1 .optional!
  assume-adult: joi.boolean!.required!
  username: joi.string!.min 3 .max 18 .token!.required!
  password: joi.string!.min 6 .optional!
  password-confirm: joi.string!.min 6 .optional!
  email: joi.string!.email!.required!
  gender: joi.string!.optional!
  subscribed-newsletter: joi.boolean!.default false
  has-password: joi.boolean!.default true
}

export validation-options = strip-unknown: true

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
