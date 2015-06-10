export http-only = true
export handler = ({http}) ->
  http.req.logout!
  success: true
