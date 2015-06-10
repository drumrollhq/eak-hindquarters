export params = <[session-id]>
export handler = ({params: {session-id}, session: {device-id}, body}) ->
  unless body.ids then return errors.bad-request 'You must supply a list of ids'
