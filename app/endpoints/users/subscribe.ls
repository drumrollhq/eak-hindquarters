require! 'joi'

export use = \users.user-id

export body = joi.object!.keys {
  plan: joi.string!.valid \eak-parent-annual \eak-parent-monthly .required!
  token: joi.string!.regex /^tok_/ .required!
  ip: joi.string!.ip!.required!
  card-country: joi.string!.length 2
  user-country: joi.string!.required!
}

export handler = ({body, user}) ->
  user.set-country body.{ip, card-country, user-country}
    .then -> user.subscribe-plan body.plan, body.token
