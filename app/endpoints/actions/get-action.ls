export middleware = true
export params = \key

export handler = ({models: {AuthedAction}, params, log}, type) ->
  log.debug "get-action, #type, #{params.key}"
  AuthedAction.use params.key
    .then (action) ->
      if action.action isnt type
        errors.bad-request 'action-type and url do not match!'
      else
        {action}
