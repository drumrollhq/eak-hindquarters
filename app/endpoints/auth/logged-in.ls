export middleware = true
export handler = ({user, errors}) ->
  if user then return {} else return errors.unauthorized 'You must be logged in'
