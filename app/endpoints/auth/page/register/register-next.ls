require! {
  'bluebird': Promise
}

module.exports = (password, manual) -> {
  page: true
  handler: ({user, render, models: {User}}) ->
    user = user.fetch!
    render 'users/register-next' {
      username: User.unused-username!
      usernames: Promise.all [til 3].map -> User.unused-username!
      saved-user: user
      user: user
      password: password
      manual: manual
    }
}
