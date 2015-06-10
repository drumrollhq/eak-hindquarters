export use = 'actions.get-action': 'verify-email'
export page = true

export handler = ({action, render, log}) ->
  user = action.user
  status = user.get \status
  update = verified-email: true
  if status is \pending then update.status = \active
  user.save update, patch: true
    .tap -> log.info "Verified email for user #user"
    .then -> render 'actions/verify-email'
