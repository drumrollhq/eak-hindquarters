require! {
  'joi'
}

export params = [
  [\user-id, joi.alternatives!.try(joi.number!.integer!.positive!, joi.string!)]
]

export handler = ({params: {user-id}, models: {User}}) ->
  User.exists user-id
    .then (exists) -> {exists}
