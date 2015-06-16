export use = 'users.user-id': {fetch: true, with-related: <[oauths]>}
export handler = ({user, req-user}) ->
  user.to-safe-json!
