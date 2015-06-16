require! 'joi'

export options = joi.object!.keys {
  n: joi.number!.integer!.min 1 .max 100 .default 10
  unused: joi.boolean!.default false
}

export handler = ({options: {n, unused}, models: {User}}) ->
  fn = if unused then User.unused-username else User.username
  Promise.all [fn! for i from 1 to n]
