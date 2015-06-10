require! {
  '../../../../utils': {filtered-import}
  'checkit'
}

export page = true
export handler = ({models: {User}, render, body, user}) ->
  data = filtered-import body.{username, password, password-confirm, email, gender, subscribed-newsletter}
  {has-password, has-manual} = body


  user.fetch!
    .then (saved-user) ->
      user = saved-user.clone!.set data
      user.validate role: (if has-password then <[full password]> else \full)
        .then ->
          user
            .set \status if user.get \verifiedEmail then \active else \pending
            .save!
            .then -> render 'users/show', user: user
        .catch checkit.Error, (err) ->
          username = User.unused-username!
          usernames = Promise.all [til 3].map -> User.unused-username!
          render 'users/register-next' {username, usernames, saved-user, user, err, password: has-password, manual: has-manual}
