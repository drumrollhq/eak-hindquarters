require! 'joi'

export body = joi.object!.keys {
  amount: joi.number!.integer!.min 100 .required!
  email: joi.string!.email!.required!
  token: joi.string!.required!
  ip: joi.string!.ip!.required!
  card-country: joi.string!.length 2 .required!
  user-country: joi.string!.required!
}

export handler = ({body, models: {Donation}}) ->
  Donation
    .create body
    .then (donation) -> donation.to-json!
