export page = true
export handler = ({user, render}) ->
  render 'users/js-return', {
    user: user.fetch with-related: <[oauths]> .then ( .to-safe-json! )
  }
